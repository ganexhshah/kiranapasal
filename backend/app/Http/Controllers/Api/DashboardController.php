<?php

namespace App\Http\Controllers\Api;

use App\Models\Customer;
use App\Models\Product;
use App\Models\Sale;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Cache;

class DashboardController extends BaseApiController
{
    /**
     * Get real-time dashboard overview with Redis caching.
     */
    public function getOverview(): JsonResponse
    {
        $shopId = app()->has('current_shop_id') ? app('current_shop_id') : 'default';
        $cacheKey = "shop:{$shopId}:dashboard:overview";

        $data = Cache::remember($cacheKey, 60, function () {
            $todayStart = Carbon::today('Asia/Kathmandu');

            $salesQuery = Sale::where('created_at', '>=', $todayStart)
                ->where('is_cancelled', false);

            $totalSales = (clone $salesQuery)->sum('grand_total');
            $cashAmount = (clone $salesQuery)->where('primary_payment_method', 'Cash')->sum('grand_total');
            $cardAmount = (clone $salesQuery)->whereIn('primary_payment_method', ['Card', 'Fonepay_QR'])->sum('grand_total');
            $udharAmount = (clone $salesQuery)->where('payment_status', 'CREDIT')->sum('grand_total');
            $billsCount = (clone $salesQuery)->count();

            return [
                'date' => Carbon::now('Asia/Kathmandu')->format('D, d M Y'),
                'total_sales' => (float) $totalSales,
                'cash_amount' => (float) $cashAmount,
                'card_amount' => (float) $cardAmount,
                'udhar_amount' => (float) $udharAmount,
                'bills_count' => $billsCount,
            ];
        });

        return $this->success($data);
    }

    /**
     * Get 2x2 statistics grid with Redis caching.
     */
    public function getStatsGrid(): JsonResponse
    {
        $shopId = app()->has('current_shop_id') ? app('current_shop_id') : 'default';
        $cacheKey = "shop:{$shopId}:dashboard:stats";

        $data = Cache::remember($cacheKey, 120, function () {
            $todayStart = Carbon::today('Asia/Kathmandu');

            $totalProducts = Product::count();
            $totalCustomers = Customer::count();
            $lowStockItems = Product::lowStock()->count();
            $todaysBills = Sale::where('created_at', '>=', $todayStart)->where('is_cancelled', false)->count();

            return [
                'total_products' => $totalProducts,
                'total_customers' => $totalCustomers,
                'low_stock_items' => $lowStockItems,
                'todays_bills' => $todaysBills,
            ];
        });

        return $this->success($data);
    }

    /**
     * Get recent transactions list for dashboard with Redis caching.
     */
    public function getRecentTransactions(): JsonResponse
    {
        $shopId = app()->has('current_shop_id') ? app('current_shop_id') : 'default';
        $cacheKey = "shop:{$shopId}:dashboard:recent";

        $data = Cache::remember($cacheKey, 60, function () {
            return Sale::with('customer')
                ->orderByDesc('created_at')
                ->limit(10)
                ->get()
                ->map(function ($sale) {
                    return [
                        'id' => $sale->id,
                        'receipt_number' => $sale->receipt_number,
                        'title' => 'Sale #'.$sale->receipt_number,
                        'subtitle' => $sale->created_at->format('h:i A').' | '.$sale->primary_payment_method,
                        'amount' => 'Rs. '.number_format($sale->grand_total, 2),
                        'payment_method' => $sale->primary_payment_method,
                        'customer_name' => $sale->customer?->name ?? 'Walk-in Customer',
                        'timestamp' => $sale->created_at->toIso8601String(),
                    ];
                })
                ->all();
        });

        return $this->success($data);
    }
}

