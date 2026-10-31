<?php

namespace App\Traits;

use App\Models\Shop;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Str;

trait BelongsToTenant
{
    /**
     * Boot the tenant scoping and UUID assignment.
     */
    protected static function bootBelongsToTenant(): void
    {
        static::creating(function (Model $model) {
            // Auto-generate UUID if not present
            if (empty($model->{$model->getKeyName()})) {
                $model->{$model->getKeyName()} = (string) Str::uuid();
            }

            // Auto-assign current tenant shop_id if missing
            if (empty($model->shop_id) && app()->has('current_shop_id')) {
                $model->shop_id = app('current_shop_id');
            }
        });

        // Global query scope: isolate records strictly to current shop
        static::addGlobalScope('shop', function (Builder $builder) {
            if (app()->has('current_shop_id')) {
                $builder->where($builder->getModel()->getTable().'.shop_id', app('current_shop_id'));
            }
        });
    }

    /**
     * Relationship to tenant shop.
     */
    public function shop(): BelongsTo
    {
        return $this->belongsTo(Shop::class, 'shop_id');
    }
}

