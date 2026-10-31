<?php

namespace App\Http\Controllers\Api;

use App\Events\LowStockTriggeredEvent;
use App\Models\Category;
use App\Models\Product;
use App\Models\StockMovement;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpFoundation\Response;

class ProductController extends BaseApiController
{
    /**
     * Display paginated products with category and search filters.
     */
    public function index(Request $request): JsonResponse
    {
        $query = Product::with(['category', 'sellingUnits']);

        // Category filter
        if ($request->filled('category_id')) {
            $query->where('category_id', $request->query('category_id'));
        }

        // Low stock filter
        if ($request->boolean('low_stock_only')) {
            $query->lowStock();
        }

        // Search filter (PostgreSQL Full-Text Search + Trigram)
        if ($request->filled('search')) {
            $query->search($request->query('search'));
        }

        $products = $query->orderBy('name')->paginate($request->integer('per_page', 25));

        return $this->success($products);
    }

    /**
     * Store a newly created product.
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'category_id' => ['nullable', 'uuid', 'exists:categories,id'],
            'category' => ['nullable', 'string', 'max:100'],
            'name' => ['required', 'string', 'max:200'],
            'nepali_name' => ['nullable', 'string', 'max:200'],
            'sku' => ['required', 'string', 'max:60'],
            'barcode' => ['nullable', 'string', 'max:100'],
            'description' => ['nullable', 'string'],
            'purchase_price' => ['nullable', 'numeric', 'min:0'],
            'purchase_unit' => ['nullable', 'string', 'max:30'],
            'selling_price' => ['required', 'numeric', 'min:0'],
            'selling_unit' => ['required', 'string', 'max:30'],
            'stock_quantity' => ['required', 'numeric'],
            'secondary_stock' => ['nullable', 'numeric'],
            'secondary_unit' => ['nullable', 'string', 'max:30'],
            'unit_conversion_factor' => ['nullable', 'numeric', 'min:0.0001'],
            'low_stock_threshold' => ['nullable', 'numeric', 'min:0'],
            'enable_low_stock_alert' => ['nullable', 'boolean'],
            'image_url' => ['nullable', 'string'],
            'selling_units' => ['nullable', 'array'],
            'selling_units.*.unit_name' => ['required', 'string'],
            'selling_units.*.conversion_rate' => ['required', 'numeric', 'min:0.0001'],
            'selling_units.*.selling_price' => ['required', 'numeric', 'min:0'],
        ]);

        if (empty($validated['category_id']) && ! empty($validated['category'])) {
            $catName = trim($validated['category']);
            $shopId = app()->has('current_shop_id') ? app('current_shop_id') : ($request->user()?->current_shop_id ?? '50837759-37db-4820-818a-9fd828f25b05');
            $category = Category::firstOrCreate(
                ['shop_id' => $shopId, 'name' => $catName],
                ['slug' => \Illuminate\Support\Str::slug($catName)]
            );
            $validated['category_id'] = $category->id;
        }
        unset($validated['category']);

        $product = DB::transaction(function () use ($validated, $request) {
            $product = Product::create($validated);

            // Record initial stock opening movement
            if ($product->stock_quantity > 0) {
                StockMovement::create([
                    'shop_id' => $product->shop_id,
                    'product_id' => $product->id,
                    'user_id' => $request->user()?->id,
                    'movement_type' => 'OPENING_STOCK',
                    'quantity' => $product->stock_quantity,
                    'unit' => $product->selling_unit,
                    'stock_before' => 0,
                    'stock_after' => $product->stock_quantity,
                    'reason' => 'Product initial inventory setup',
                ]);
            }

            // Create alternate selling units
            if (! empty($validated['selling_units'])) {
                foreach ($validated['selling_units'] as $unit) {
                    $product->sellingUnits()->create($unit);
                }
            }

            return $product->load(['category', 'sellingUnits']);
        });

        \App\Services\CacheService::clearProductCache();

        return $this->success($product, 'Product created successfully.', Response::HTTP_CREATED);
    }

    /**
     * Show single product details.
     */
    public function show(string $id): JsonResponse
    {
        $product = Product::with(['category', 'sellingUnits'])->findOrFail($id);

        return $this->success($product);
    }

    /**
     * Find product by barcode scanner.
     */
    public function findByBarcode(string $code): JsonResponse
    {
        $product = Product::with(['category', 'sellingUnits'])
            ->where('barcode', $code)
            ->first();

        if (! $product) {
            return $this->error('Product with barcode not found.', Response::HTTP_NOT_FOUND);
        }

        return $this->success($product);
    }

    /**
     * Adjust physical inventory stock with movement tracking.
     */
    public function adjustStock(Request $request, string $id): JsonResponse
    {
        $validated = $request->validate([
            'is_addition' => ['required', 'boolean'],
            'quantity' => ['required', 'numeric', 'min:0.001'],
            'unit' => ['required', 'string'],
            'reason' => ['required', 'string', 'max:255'],
            'note' => ['nullable', 'string'],
        ]);

        $result = DB::transaction(function () use ($id, $validated, $request) {
            $product = Product::lockForUpdate()->findOrFail($id);

            $before = (float) $product->stock_quantity;
            $qty = (float) $validated['quantity'];
            $after = $validated['is_addition'] ? ($before + $qty) : max(0, $before - $qty);

            $product->update(['stock_quantity' => $after]);

            StockMovement::create([
                'shop_id' => $product->shop_id,
                'product_id' => $product->id,
                'user_id' => $request->user()?->id,
                'movement_type' => $validated['is_addition'] ? 'ADJUSTMENT_ADD' : 'ADJUSTMENT_REMOVE',
                'quantity' => $qty,
                'unit' => $validated['unit'],
                'stock_before' => $before,
                'stock_after' => $after,
                'reason' => $validated['reason'],
                'note' => $validated['note'] ?? null,
            ]);

            // Broadcast real-time alert if stock is now low
            if ($product->is_low_stock) {
                broadcast(new LowStockTriggeredEvent($product));
            }

            return $product;
        });

        \App\Services\CacheService::clearProductCache();

        return $this->success($result, 'Stock adjusted successfully.');
    }

    /**
     * Update an existing product.
     */
    public function update(Request $request, string $id): JsonResponse
    {
        $product = Product::findOrFail($id);

        $validated = $request->validate([
            'category_id' => ['nullable', 'uuid', 'exists:categories,id'],
            'category' => ['nullable', 'string', 'max:100'],
            'name' => ['sometimes', 'required', 'string', 'max:200'],
            'nepali_name' => ['nullable', 'string', 'max:200'],
            'sku' => ['sometimes', 'required', 'string', 'max:60'],
            'barcode' => ['nullable', 'string', 'max:100'],
            'description' => ['nullable', 'string'],
            'purchase_price' => ['nullable', 'numeric', 'min:0'],
            'purchase_unit' => ['nullable', 'string', 'max:30'],
            'selling_price' => ['sometimes', 'required', 'numeric', 'min:0'],
            'selling_unit' => ['sometimes', 'required', 'string', 'max:30'],
            'stock_quantity' => ['nullable', 'numeric'],
            'secondary_stock' => ['nullable', 'numeric'],
            'secondary_unit' => ['nullable', 'string', 'max:30'],
            'unit_conversion_factor' => ['nullable', 'numeric', 'min:0.0001'],
            'low_stock_threshold' => ['nullable', 'numeric', 'min:0'],
            'enable_low_stock_alert' => ['nullable', 'boolean'],
            'image_url' => ['nullable', 'string'],
        ]);

        if (empty($validated['category_id']) && ! empty($validated['category'])) {
            $catName = trim($validated['category']);
            $shopId = app()->has('current_shop_id') ? app('current_shop_id') : ($request->user()?->current_shop_id ?? '50837759-37db-4820-818a-9fd828f25b05');
            $category = Category::firstOrCreate(
                ['shop_id' => $shopId, 'name' => $catName],
                ['slug' => \Illuminate\Support\Str::slug($catName)]
            );
            $validated['category_id'] = $category->id;
        }
        unset($validated['category']);

        $product->update($validated);
        \App\Services\CacheService::clearProductCache();

        return $this->success($product->load(['category', 'sellingUnits']), 'Product updated successfully.');
    }

    /**
     * Remove the specified product.
     */
    public function destroy(string $id): JsonResponse
    {
        $product = Product::findOrFail($id);
        $product->delete();

        \App\Services\CacheService::clearProductCache();

        return $this->success(null, 'Product deleted successfully.');
    }

    /**
     * Set low stock alert threshold.
     */
    public function setLowStockAlert(Request $request, string $id): JsonResponse
    {
        $validated = $request->validate([
            'threshold' => ['required', 'numeric', 'min:0'],
            'enabled' => ['required', 'boolean'],
        ]);

        $product = Product::findOrFail($id);
        $product->update([
            'low_stock_threshold' => $validated['threshold'],
            'enable_low_stock_alert' => $validated['enabled'],
        ]);

        \App\Services\CacheService::clearProductCache();

        return $this->success($product, 'Low stock threshold updated.');
    }

    /**
     * Dedicated endpoint for Low Stock Items screen with Redis caching.
     */
    public function getLowStockItems(): JsonResponse
    {
        $shopId = app()->has('current_shop_id') ? app('current_shop_id') : 'default';
        $cacheKey = "shop:{$shopId}:products:low_stock";

        $items = \Illuminate\Support\Facades\Cache::remember($cacheKey, 120, function () {
            return Product::lowStock()
                ->with('category')
                ->orderBy('stock_quantity')
                ->get()
                ->map(function ($p) {
                    $deficit = max(0, (float) $p->lowStockThreshold - (float) $p->stock_quantity);

                    return [
                        'id' => $p->id,
                        'name' => $p->name,
                        'category' => $p->category?->name ?? 'General',
                        'sku' => $p->sku,
                        'price' => (float) $p->selling_price,
                        'purchase_price' => (float) $p->purchase_price,
                        'stock' => (float) $p->stock_quantity,
                        'unit' => $p->selling_unit,
                        'threshold' => (float) $p->low_stock_threshold,
                        'deficit' => $deficit,
                        'estimated_reorder_cost' => $deficit * (float) $p->purchase_price,
                        'is_out_of_stock' => $p->stock_quantity <= 0,
                        'image_url' => $p->image_url,
                    ];
                })
                ->all();
        });

        return $this->success($items);
    }

    /**
     * Get real stock movement history for a specific product.
     */
    public function stockHistory(string $id): JsonResponse
    {
        $product = Product::findOrFail($id);

        $movements = StockMovement::where('product_id', $product->id)
            ->with('user:id,name')
            ->orderByDesc('created_at')
            ->limit(50)
            ->get()
            ->map(function ($m) {
                $isAdd = in_array($m->movement_type, ['ADJUSTMENT_ADD', 'PURCHASE', 'RETURN', 'OPENING_STOCK']);
                return [
                    'id' => (string) $m->id,
                    'title' => match ($m->movement_type) {
                        'OPENING_STOCK' => 'Opening Stock Setup',
                        'ADJUSTMENT_ADD' => 'Stock Added (Manual)',
                        'ADJUSTMENT_REMOVE' => 'Stock Removed (Manual)',
                        'SALE' => 'Sold Product',
                        'PURCHASE' => 'Stock Added (Purchase)',
                        default => 'Stock Movement',
                    },
                    'timestamp' => $m->created_at?->toIso8601String() ?? now()->toIso8601String(),
                    'change_amount' => (float) $m->quantity,
                    'unit' => $m->unit ?? 'pcs',
                    'balance' => (float) $m->stock_after,
                    'is_addition' => $isAdd,
                    'reason' => $m->reason ?? $m->movement_type,
                    'note' => $m->note,
                    'user_name' => $m->user?->name,
                ];
            });

        return $this->success($movements);
    }
}

