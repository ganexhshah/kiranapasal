<?php

namespace App\Http\Controllers\Api;

use App\Models\Shop;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ShopController extends BaseApiController
{
    /**
     * Update active shop profile.
     */
    public function updateProfile(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:150'],
            'business_type' => ['nullable', 'string', 'max:50'],
            'pan_vat_number' => ['nullable', 'string', 'max:30'],
            'phone' => ['nullable', 'string', 'max:20'],
            'email' => ['nullable', 'email', 'max:100'],
            'currency' => ['nullable', 'string', 'max:10'],
            'address' => ['nullable', 'string'],
            'receipt_header' => ['nullable', 'string'],
            'receipt_footer' => ['nullable', 'string'],
            'logo_url' => ['nullable', 'string'],
            'low_stock_threshold_default' => ['nullable', 'integer', 'min:1'],
        ]);

        $shopId = app('current_shop_id');
        $shop = Shop::findOrFail($shopId);
        $shop->update($validated);

        \Illuminate\Support\Facades\Cache::forget("shop:{$shopId}:settings");
        \App\Services\CacheService::clearDashboardCache($shopId);

        return $this->success($shop, 'Shop profile updated successfully.');
    }

    /**
     * Get active shop settings with Redis caching.
     */
    public function getSettings(): JsonResponse
    {
        $shopId = app('current_shop_id');
        $shop = \Illuminate\Support\Facades\Cache::remember("shop:{$shopId}:settings", 3600, function () use ($shopId) {
            return Shop::findOrFail($shopId);
        });

        return $this->success($shop);
    }
}

