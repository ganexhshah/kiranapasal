<?php

namespace App\Models;

use App\Traits\BelongsToTenant;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Product extends Model
{
    use BelongsToTenant, HasFactory, HasUuids;

    protected $fillable = [
        'shop_id',
        'category_id',
        'name',
        'nepali_name',
        'sku',
        'barcode',
        'description',
        'purchase_price',
        'purchase_unit',
        'selling_price',
        'selling_unit',
        'stock_quantity',
        'secondary_stock',
        'secondary_unit',
        'unit_conversion_factor',
        'low_stock_threshold',
        'enable_low_stock_alert',
        'expiry_date',
        'image_url',
        'gallery_images',
    ];

    protected $casts = [
        'purchase_price' => 'decimal:2',
        'selling_price' => 'decimal:2',
        'stock_quantity' => 'decimal:3',
        'secondary_stock' => 'decimal:3',
        'unit_conversion_factor' => 'decimal:4',
        'low_stock_threshold' => 'decimal:3',
        'enable_low_stock_alert' => 'boolean',
        'expiry_date' => 'date',
        'gallery_images' => 'array',
    ];

    public function category(): BelongsTo
    {
        return $this->belongsTo(Category::class);
    }

    public function sellingUnits(): HasMany
    {
        return $this->hasMany(SellingUnit::class);
    }

    public function stockMovements(): HasMany
    {
        return $this->hasMany(StockMovement::class)->orderByDesc('created_at');
    }

    /**
     * Scope for low stock products.
     */
    public function scopeLowStock(Builder $query): Builder
    {
        return $query->where('enable_low_stock_alert', true)
            ->whereColumn('stock_quantity', '<=', 'low_stock_threshold');
    }

    /**
     * Scope for full text search across bilingual fields, SKU, and barcode.
     */
    public function scopeSearch(Builder $query, ?string $term): Builder
    {
        if (empty($term)) {
            return $query;
        }

        $term = trim($term);

        return $query->where(function ($q) use ($term) {
            $q->where('barcode', $term)
                ->orWhere('sku', 'ILIKE', "%{$term}%")
                ->orWhere('name', 'ILIKE', "%{$term}%")
                ->orWhere('nepali_name', 'ILIKE', "%{$term}%")
                ->orWhereRaw("search_vector @@ plainto_tsquery('simple', ?)", [$term]);
        });
    }

    public function getIsLowStockAttribute(): bool
    {
        return $this->enable_low_stock_alert && $this->stock_quantity <= $this->low_stock_threshold;
    }
}

