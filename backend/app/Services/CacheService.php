<?php

namespace App\Services;

use Illuminate\Support\Facades\Cache;

class CacheService
{
    /**
     * Clear all dashboard caches for a specific shop.
     */
    public static function clearDashboardCache(?string $shopId = null): void
    {
        $shopId = $shopId ?? (app()->has('current_shop_id') ? app('current_shop_id') : 'default');

        Cache::forget("shop:{$shopId}:dashboard:overview");
        Cache::forget("shop:{$shopId}:dashboard:stats");
        Cache::forget("shop:{$shopId}:dashboard:recent");
    }

    /**
     * Clear product and catalog caches for a specific shop.
     */
    public static function clearProductCache(?string $shopId = null): void
    {
        $shopId = $shopId ?? (app()->has('current_shop_id') ? app('current_shop_id') : 'default');

        Cache::forget("shop:{$shopId}:products:low_stock");
        Cache::forget("shop:{$shopId}:categories");

        // Clear dashboard cache as well since inventory/products count changes
        self::clearDashboardCache($shopId);
    }
}

