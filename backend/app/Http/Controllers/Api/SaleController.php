<?php

namespace App\Http\Controllers\Api;

use App\Events\LowStockTriggeredEvent;
use App\Events\SaleCreatedEvent;
use App\Models\Customer;
use App\Models\CustomerLedger;
use App\Models\Product;
use App\Models\Sale;
use App\Models\SaleItem;
use App\Models\StockMovement;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpFoundation\Response;

class SaleController extends BaseApiController
{
    /**
     * List all sales with filters (date, payment mode, cashier).
     */
    public function index(Request $request): JsonResponse
    {
        $query = Sale::with(['customer', 'cashier', 'items'])
            ->orderByDesc('created_at');

        if ($request->filled('payment_method')) {
            $query->where('primary_payment_method', $request->query('payment_method'));
        }

        if ($request->filled('date')) {
            $query->whereDate('created_at', $request->query('date'));
        }

        $sales = $query->paginate($request->integer('per_page', 20));

        return $this->success($sales);
    }

    /**
     * Today's Bills specialized endpoint.
     */
    public function todayBills(Request $request): JsonResponse
    {
        $query = Sale::with(['customer', 'items'])
            ->where('is_cancelled', false)
            ->orderByDesc('created_at');

        if ($request->filled('date')) {
            try {
                $targetDate = Carbon::parse($request->query('date'), 'Asia/Kathmandu');
                $start = $targetDate->copy()->startOfDay();
                $end = $targetDate->copy()->endOfDay();
                $query->whereBetween('created_at', [$start, $end]);
            } catch (\Exception $e) {
                $query->where('created_at', '>=', Carbon::today('Asia/Kathmandu'));
            }
        } else {
            $query->where('created_at', '>=', Carbon::today('Asia/Kathmandu'));
        }

        if ($request->filled('payment_method') && $request->query('payment_method') !== 'All') {
            $method = $request->query('payment_method');
            if ($method === 'Cash') {
                $query->where('primary_payment_method', 'Cash');
            } elseif ($method === 'Online / QR') {
                $query->whereIn('primary_payment_method', ['Fonepay_QR', 'Card']);
            } elseif ($method === 'Credit (Udhar)') {
                $query->where('payment_status', 'CREDIT');
            }
        }

        $bills = $query->get()->map(function ($bill) {
            return [
                'bill_number' => $bill->receipt_number,
                'customer_name' => $bill->customer?->name ?? 'Walk-in Customer',
                'customer_phone' => $bill->customer?->phone ?? '',
                'amount' => (float) $bill->grand_total,
                'subtotal' => (float) $bill->subtotal,
                'discount' => (float) $bill->discount_amount,
                'tax' => (float) $bill->tax_amount,
                'cash_received' => (float) $bill->cash_received,
                'change_returned' => (float) $bill->change_returned,
                'udhar_amount' => (float) $bill->udhar_amount,
                'payment_method' => $bill->primary_payment_method,
                'status' => $bill->payment_status,
                'items_count' => $bill->items_count,
                'items_summary' => $bill->items->pluck('product_name')->take(4)->join(', '),
                'timestamp' => $bill->created_at->toIso8601String(),
                'items' => $bill->items->map(function ($it) {
                    return [
                        'name' => $it->product_name,
                        'product_name' => $it->product_name,
                        'quantity' => (float) $it->quantity,
                        'unit' => $it->unit_name ?? 'pkt',
                        'unit_price' => (float) $it->unit_price,
                        'total' => (float) $it->total_price,
                    ];
                })->values()->all(),
            ];
        });

        return $this->success($bills);
    }

    /**
     * Atomic POS Checkout: create sale, decrement stock with pessimistic lock,
     * record stock movements, post to customer credit ledger if udhar, and broadcast event.
     */
    public function store(Request $request): JsonResponse
    {
        // Pre-normalize incoming items to handle both 'unit' and 'unit_name'
        $items = $request->input('items', []);
        if (is_array($items)) {
            foreach ($items as &$item) {
                if (isset($item['unit']) && ! isset($item['unit_name'])) {
                    $item['unit_name'] = $item['unit'];
                }
            }
            $request->merge(['items' => $items]);
        }

        // Normalize payment method
        $pm = $request->input('payment_method', 'Cash');
        if (in_array(strtolower($pm), ['fonepay', 'fonepay_qr', 'qr', 'online', 'online / qr'])) {
            $pm = 'Fonepay_QR';
        } elseif (in_array(strtolower($pm), ['credit', 'udhar', 'credit (udhar)', 'split', 'cash + udhar', 'split (cash + udhar)'])) {
            $pm = 'Credit';
        } elseif (strtolower($pm) === 'card') {
            $pm = 'Card';
        } else {
            $pm = 'Cash';
        }
        $request->merge(['payment_method' => $pm]);

        $validated = $request->validate([
            'customer_id' => ['nullable', 'uuid', 'exists:customers,id'],
            'items' => ['required', 'array', 'min:1'],
            'items.*.product_id' => ['required', 'uuid', 'exists:products,id'],
            'items.*.quantity' => ['required', 'numeric', 'min:0.001'],
            'items.*.unit_name' => ['required', 'string'],
            'items.*.unit_price' => ['required', 'numeric', 'min:0'],
            'items.*.discount_amount' => ['nullable', 'numeric', 'min:0'],
            'subtotal' => ['required', 'numeric', 'min:0'],
            'discount_amount' => ['nullable', 'numeric', 'min:0'],
            'tax_amount' => ['nullable', 'numeric', 'min:0'],
            'grand_total' => ['required', 'numeric', 'min:0'],
            'payment_method' => ['required', 'string', 'in:Cash,Fonepay_QR,Card,Credit'],
            'cash_tendered' => ['nullable', 'numeric', 'min:0'],
            'change_returned' => ['nullable', 'numeric', 'min:0'],
            'udhar_amount' => ['nullable', 'numeric', 'min:0'],
            'note' => ['nullable', 'string', 'max:500'],
        ]);

        $sale = DB::transaction(function () use ($validated, $request) {
            $prefix = 'S'.now('Asia/Kathmandu')->format('ymd');
            $randomSuffix = strtoupper(substr(bin2hex(random_bytes(2)), 0, 4));
            $receiptNumber = $prefix.'-'.$randomSuffix;

            $udharAmount = (float) ($validated['udhar_amount'] ?? 0);
            $cashTendered = (float) ($validated['cash_tendered'] ?? 0);
            $grandTotal = (float) $validated['grand_total'];

            $effectiveUdhar = $udharAmount > 0 ? $udharAmount : ($validated['payment_method'] === 'Credit' ? $grandTotal : 0);

            if ($effectiveUdhar > 0 && $cashTendered > 0) {
                $paymentStatus = 'PARTIAL';
            } elseif ($effectiveUdhar >= $grandTotal) {
                $paymentStatus = 'CREDIT';
            } else {
                $paymentStatus = 'PAID';
            }

            // 1. Create Sale Record
            $sale = Sale::create([
                'receipt_number' => $receiptNumber,
                'customer_id' => $validated['customer_id'] ?? null,
                'cashier_id' => $request->user()?->id,
                'subtotal' => $validated['subtotal'],
                'discount_amount' => $validated['discount_amount'] ?? 0,
                'tax_amount' => $validated['tax_amount'] ?? 0,
                'grand_total' => $grandTotal,
                'payment_status' => $paymentStatus,
                'primary_payment_method' => $effectiveUdhar > 0 && $cashTendered > 0 ? 'Split' : $validated['payment_method'],
                'cash_tendered' => $cashTendered,
                'change_returned' => $validated['change_returned'] ?? 0,
                'udhar_amount' => $effectiveUdhar,
                'items_count' => count($validated['items']),
                'note' => $validated['note'] ?? null,
            ]);

            // 2. Process Items with Pessimistic Stock Lock (prevents race conditions)
            $lowStockProducts = [];

            foreach ($validated['items'] as $itemData) {
                $product = Product::lockForUpdate()->findOrFail($itemData['product_id']);

                $qty = (float) $itemData['quantity'];
                $stockBefore = (float) $product->stock_quantity;
                $stockAfter = max(0, $stockBefore - $qty);

                $product->update(['stock_quantity' => $stockAfter]);

                SaleItem::create([
                    'sale_id' => $sale->id,
                    'product_id' => $product->id,
                    'product_name' => $product->name,
                    'sku' => $product->sku,
                    'quantity' => $qty,
                    'unit_name' => $itemData['unit_name'],
                    'unit_price' => $itemData['unit_price'],
                    'purchase_cost' => $product->purchase_price * $qty,
                    'discount_amount' => $itemData['discount_amount'] ?? 0,
                    'total_price' => ($itemData['unit_price'] * $qty) - ($itemData['discount_amount'] ?? 0),
                ]);

                StockMovement::create([
                    'shop_id' => $product->shop_id,
                    'product_id' => $product->id,
                    'user_id' => $request->user()?->id,
                    'movement_type' => 'SALE',
                    'quantity' => $qty,
                    'unit' => $itemData['unit_name'],
                    'stock_before' => $stockBefore,
                    'stock_after' => $stockAfter,
                    'reference_type' => 'Sale',
                    'reference_id' => $sale->id,
                    'reason' => 'Sold on Bill #'.$receiptNumber,
                ]);

                if ($product->is_low_stock) {
                    $lowStockProducts[] = $product;
                }
            }

            // 3. Post to Customer Udhar Khata if credit or partial udhar purchase
            if ($effectiveUdhar > 0 && ! empty($validated['customer_id'])) {
                $customer = Customer::lockForUpdate()->findOrFail($validated['customer_id']);
                $newUdhar = (float) $customer->outstanding_udhar + $effectiveUdhar;
                $customer->update(['outstanding_udhar' => $newUdhar]);

                $noteText = 'Sale #' . $receiptNumber . ($cashTendered > 0 ? " (Split: Rs. {$cashTendered} cash, Rs. {$effectiveUdhar} udhar)" : ' on Credit / Udhar');

                CustomerLedger::create([
                    'shop_id' => $customer->shop_id,
                    'customer_id' => $customer->id,
                    'transaction_type' => 'CREDIT_SALE',
                    'reference_no' => $receiptNumber,
                    'amount' => $effectiveUdhar,
                    'balance_after' => $newUdhar,
                    'payment_method' => $cashTendered > 0 ? 'Split' : 'Credit',
                    'recorded_by' => $request->user()?->id,
                    'note' => $noteText,
                ]);
            }

            // Broadcast real-time events via Reverb
            try {
                broadcast(new SaleCreatedEvent($sale));

                foreach ($lowStockProducts as $lowStockProduct) {
                    broadcast(new LowStockTriggeredEvent($lowStockProduct));
                }
            } catch (\Throwable $e) {
                \Illuminate\Support\Facades\Log::warning('Reverb broadcast skipped: ' . $e->getMessage());
            }

            // Invalidate Redis dashboard and stats cache for instant freshness
            \App\Services\CacheService::clearDashboardCache();

            return $sale->load(['items', 'customer', 'cashier']);
        });

        return $this->success($sale, 'Sale processed successfully.', Response::HTTP_CREATED);
    }

    /**
     * Show single receipt details (View Details screen).
     */
    public function show(string $receiptNumber): JsonResponse
    {
        $sale = Sale::with(['customer', 'cashier', 'items.product'])
            ->where('receipt_number', $receiptNumber)
            ->firstOrFail();

        return $this->success($sale);
    }

    /**
     * Void / Cancel Sale with automatic stock reversion.
     */
    public function cancel(Request $request, string $receiptNumber): JsonResponse
    {
        $validated = $request->validate([
            'reason' => ['required', 'string', 'max:255'],
        ]);

        $sale = DB::transaction(function () use ($receiptNumber, $validated, $request) {
            $sale = Sale::with('items')->where('receipt_number', $receiptNumber)->firstOrFail();

            if ($sale->is_cancelled) {
                abort(400, 'Sale is already cancelled.');
            }

            // Revert stock for all items
            foreach ($sale->items as $item) {
                $product = Product::lockForUpdate()->findOrFail($item->product_id);
                $before = (float) $product->stock_quantity;
                $after = $before + (float) $item->quantity;
                $product->update(['stock_quantity' => $after]);

                StockMovement::create([
                    'shop_id' => $product->shop_id,
                    'product_id' => $product->id,
                    'user_id' => $request->user()?->id,
                    'movement_type' => 'RETURN',
                    'quantity' => $item->quantity,
                    'unit' => $item->unit_name,
                    'stock_before' => $before,
                    'stock_after' => $after,
                    'reference_type' => 'Sale_Void',
                    'reference_id' => $sale->id,
                    'reason' => 'Sale cancelled: '.$validated['reason'],
                ]);
            }

            // Revert udhar if credit sale
            if ($sale->payment_status === 'CREDIT' && $sale->customer_id) {
                $customer = Customer::lockForUpdate()->find($sale->customer_id);
                if ($customer) {
                    $newBalance = max(0, (float) $customer->outstanding_udhar - (float) $sale->grand_total);
                    $customer->update(['outstanding_udhar' => $newBalance]);

                    CustomerLedger::create([
                        'shop_id' => $customer->shop_id,
                        'customer_id' => $customer->id,
                        'transaction_type' => 'SALE_CANCELLED',
                        'reference_no' => $sale->receipt_number,
                        'amount' => $sale->grand_total,
                        'balance_after' => $newBalance,
                        'recorded_by' => $request->user()?->id,
                        'note' => 'Reversal due to cancelled sale #'.$sale->receipt_number,
                    ]);
                }
            }

            $sale->update([
                'is_cancelled' => true,
                'cancelled_reason' => $validated['reason'],
                'cancelled_at' => now(),
                'payment_status' => 'CANCELLED',
            ]);

            // Invalidate Redis dashboard and stats cache
            \App\Services\CacheService::clearDashboardCache();

            return $sale;
        });

        return $this->success($sale, 'Sale has been cancelled and inventory reverted.');
    }
}
