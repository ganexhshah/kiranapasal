<?php

use Illuminate\Support\Facades\Broadcast;

Broadcast::routes(['middleware' => ['auth:sanctum']]);

// Private channel for specific shop events (Sale created, stock updated, notifications)
Broadcast::channel('shop.{shopId}', function ($user, $shopId) {
    return (string) $user->current_shop_id === (string) $shopId;
});

// POS presence channel for multi-counter terminals
Broadcast::channel('pos-terminal.{shopId}', function ($user, $shopId) {
    if ((string) $user->current_shop_id === (string) $shopId) {
        return [
            'id' => $user->id,
            'name' => $user->name,
            'role' => $user->roles->first()?->name ?? 'Cashier',
        ];
    }
    return false;
});

