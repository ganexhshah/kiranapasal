<?php

use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| KRM API Routes — Version 1.0 (REST + JSON)
|--------------------------------------------------------------------------
| Open, Authenticated (Sanctum + Tenant), and Role-protected endpoints.
*/

Route::prefix('v1')->group(function () {

    // 1. Authentication Endpoints
    Route::prefix('auth')->middleware('throttle:30,1')->group(function () {
        Route::post('/login', 'App\Http\Controllers\Api\AuthController@login');
        Route::post('/register', 'App\Http\Controllers\Api\AuthController@register');
        Route::post('/verify-otp', 'App\Http\Controllers\Api\AuthController@verifyOtp');
        Route::post('/resend-otp', 'App\Http\Controllers\Api\AuthController@resendOtp');
        Route::post('/forgot-password', 'App\Http\Controllers\Api\AuthController@forgotPassword');
        Route::post('/reset-password', 'App\Http\Controllers\Api\AuthController@resetPassword');
        Route::post('/firebase-login', 'App\Http\Controllers\Api\AuthController@firebaseLogin');
        Route::post('/google', 'App\Http\Controllers\Api\AuthController@googleLogin');
        Route::post('/refresh-token', 'App\Http\Controllers\Api\AuthController@refreshToken');
    });

    // Authenticated Endpoints (Sanctum + Tenant Context + Standard API throttle: 120 req/min)
    Route::middleware(['auth:sanctum', 'tenant', 'throttle:120,1'])->group(function () {

        // User & Shop Profile
        Route::get('/auth/me', 'App\Http\Controllers\Api\AuthController@me');
        Route::put('/auth/profile', 'App\Http\Controllers\Api\AuthController@updateProfile');
        Route::post('/auth/logout', 'App\Http\Controllers\Api\AuthController@logout');
        Route::put('/shop/profile', 'App\Http\Controllers\Api\ShopController@updateProfile');
        Route::get('/shop/settings', 'App\Http\Controllers\Api\ShopController@getSettings');

        // Cloudflare R2 Media Uploads
        Route::prefix('media')->group(function () {
            Route::post('/upload', 'App\Http\Controllers\Api\MediaController@uploadImage');
            Route::post('/presigned-url', 'App\Http\Controllers\Api\MediaController@presignedUpload');
        });

        // Dashboard & Real-Time Stats
        Route::prefix('dashboard')->group(function () {
            Route::get('/overview', 'App\Http\Controllers\Api\DashboardController@getOverview');
            Route::get('/stats', 'App\Http\Controllers\Api\DashboardController@getStatsGrid');
            Route::get('/recent-transactions', 'App\Http\Controllers\Api\DashboardController@getRecentTransactions');
        });

        // Products & Inventory Management
        Route::prefix('products')->group(function () {
            Route::get('/', 'App\Http\Controllers\Api\ProductController@index');
            Route::post('/', 'App\Http\Controllers\Api\ProductController@store');
            Route::get('/barcode/{code}', 'App\Http\Controllers\Api\ProductController@findByBarcode');
            Route::get('/{id}', 'App\Http\Controllers\Api\ProductController@show');
            Route::put('/{id}', 'App\Http\Controllers\Api\ProductController@update');
            Route::delete('/{id}', 'App\Http\Controllers\Api\ProductController@destroy');

            // Stock Adjustments & Low Stock Alert
            Route::post('/{id}/adjust-stock', 'App\Http\Controllers\Api\ProductController@adjustStock');
            Route::put('/{id}/low-stock-alert', 'App\Http\Controllers\Api\ProductController@setLowStockAlert');
            Route::get('/{id}/stock-history', 'App\Http\Controllers\Api\ProductController@stockHistory');
        });

        // Dedicated Low Stock Items endpoint
        Route::get('/inventory/low-stock', 'App\Http\Controllers\Api\ProductController@getLowStockItems');
        Route::get('/categories', 'App\Http\Controllers\Api\CategoryController@index');
        Route::post('/categories', 'App\Http\Controllers\Api\CategoryController@store');

        // POS Sales & Invoices
        Route::prefix('sales')->group(function () {
            Route::get('/', 'App\Http\Controllers\Api\SaleController@index');
            Route::post('/', 'App\Http\Controllers\Api\SaleController@store'); // POS Checkout
            Route::get('/today', 'App\Http\Controllers\Api\SaleController@todayBills'); // Today's Bills Screen
            Route::get('/{receiptNumber}', 'App\Http\Controllers\Api\SaleController@show'); // View Details Screen
            Route::post('/{receiptNumber}/cancel', 'App\Http\Controllers\Api\SaleController@cancel'); // Void bill
            Route::post('/{receiptNumber}/print', 'App\Http\Controllers\Api\SaleController@generatePrintPayload');
        });

        // All Transactions Ledger
        Route::get('/transactions', 'App\Http\Controllers\Api\TransactionController@index');

        // Customers & Udhar (Credit) Khata
        Route::prefix('customers')->group(function () {
            Route::get('/', 'App\Http\Controllers\Api\CustomerController@index');
            Route::post('/', 'App\Http\Controllers\Api\CustomerController@store');
            Route::get('/{id}', 'App\Http\Controllers\Api\CustomerController@show');
            Route::put('/{id}', 'App\Http\Controllers\Api\CustomerController@update');
            Route::get('/{id}/ledger', 'App\Http\Controllers\Api\CustomerController@getLedger');
            Route::post('/{id}/receive-payment', 'App\Http\Controllers\Api\CustomerController@receivePayment');
            Route::put('/{id}/credit-limit', 'App\Http\Controllers\Api\CustomerController@updateCreditLimit');
        });

        // Suppliers & Purchases
        Route::prefix('suppliers')->group(function () {
            Route::get('/', 'App\Http\Controllers\Api\SupplierController@index');
            Route::post('/', 'App\Http\Controllers\Api\SupplierController@store');
            Route::get('/{id}', 'App\Http\Controllers\Api\SupplierController@show');
            Route::put('/{id}', 'App\Http\Controllers\Api\SupplierController@update');
            Route::get('/{id}/ledger', 'App\Http\Controllers\Api\SupplierController@getLedger');
            Route::post('/{id}/make-payment', 'App\Http\Controllers\Api\SupplierController@recordPayment');
        });

        // Supplier Inventory Purchases
        Route::post('/purchases', 'App\Http\Controllers\Api\PurchaseController@store');

        // Shop Expenses
        Route::prefix('expenses')->group(function () {
            Route::get('/', 'App\Http\Controllers\Api\ExpenseController@index');
            Route::post('/', 'App\Http\Controllers\Api\ExpenseController@store');
        });

        // Notifications
        Route::prefix('notifications')->group(function () {
            Route::get('/', 'App\Http\Controllers\Api\NotificationController@index');
            Route::post('/{id}/mark-as-read', 'App\Http\Controllers\Api\NotificationController@markAsRead');
            Route::post('/mark-all-read', 'App\Http\Controllers\Api\NotificationController@markAllRead');
        });
    });
});

