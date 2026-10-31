<?php

namespace Tests;

use App\Models\Shop;
use App\Models\User;
use Illuminate\Foundation\Testing\TestCase as BaseTestCase;

abstract class TestCase extends BaseTestCase
{
    protected function getTestUser(): User
    {
        $user = User::where('email', 'ganesh@krmstore.com')->first();
        if (!$user) {
            $shop = Shop::firstOrCreate(
                ['name' => 'KRM Test Kirana'],
                ['business_type' => 'Kirana / Retail', 'currency' => 'Rs.', 'low_stock_threshold_default' => 5]
            );
            $user = User::create([
                'name' => 'Ganesh Shah',
                'email' => 'ganesh@krmstore.com',
                'password' => bcrypt('password123'),
                'current_shop_id' => $shop->id,
            ]);
        }
        return $user;
    }
}

