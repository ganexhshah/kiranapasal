<?php

use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return response()->json([
        'status' => 'online',
        'service' => 'KRM Kirana & Retail Management API Core',
        'version' => '1.0.0',
        'time' => now()->toIso8601String(),
    ]);
});

Route::get('/login', function () {
    return response()->json([
        'success' => false,
        'message' => 'Unauthenticated. Please supply a valid Bearer token.',
    ], 401);
})->name('login');

