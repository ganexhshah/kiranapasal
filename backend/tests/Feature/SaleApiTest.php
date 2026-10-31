<?php

namespace Tests\Feature;

use App\Models\Product;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class SaleApiTest extends TestCase
{
    public function test_can_checkout_sale_and_void(): void
    {
        $this->withoutExceptionHandling();
        $user = $this->getTestUser();
        Sanctum::actingAs($user);

        // Ensure we have a product for the test user's shop with stock
        $product = Product::where('shop_id', $user->current_shop_id)->first();
        if (!$product) {
            $product = Product::create([
                'shop_id' => $user->current_shop_id,
                'name' => 'Basmati Rice 20kg',
                'sku' => 'BAS-20KG-' . time(),
                'selling_price' => 2400.00,
                'purchase_price' => 2100.00,
                'selling_unit' => 'Sack',
                'stock_quantity' => 25,
            ]);
        }

        $initialStock = (float) $product->stock_quantity;
        if ($initialStock < 5) {
            $product->update(['stock_quantity' => 20]);
            $initialStock = 20;
        }

        // 1. Checkout Sale
        $saleResponse = $this->postJson('/api/v1/sales', [
            'items' => [
                [
                    'product_id' => $product->id,
                    'quantity' => 2,
                    'unit_name' => $product->selling_unit,
                    'unit_price' => (float) $product->selling_price,
                    'discount_amount' => 0,
                    'subtotal' => (float) $product->selling_price * 2,
                ],
            ],
            'subtotal' => (float) $product->selling_price * 2,
            'discount_amount' => 0,
            'tax_amount' => 0,
            'grand_total' => (float) $product->selling_price * 2,
            'payment_method' => 'Cash',
            'cash_tendered' => (float) $product->selling_price * 2,
            'change_returned' => 0,
            'note' => 'Test sale automated test',
        ]);

        $saleResponse->assertStatus(201)
            ->assertJsonPath('success', true);

        $receiptNumber = $saleResponse->json('data.receipt_number');
        $this->assertNotEmpty($receiptNumber);

        // Verify stock deducted
        $product->refresh();
        $this->assertEquals($initialStock - 2, (float) $product->stock_quantity);

        // 2. Fetch sale by receipt number
        $showResponse = $this->getJson('/api/v1/sales/' . $receiptNumber);
        $showResponse->assertStatus(200)
            ->assertJsonPath('data.receipt_number', $receiptNumber);

        // 3. Fetch today's bills
        $todayResponse = $this->getJson('/api/v1/sales/today');
        $todayResponse->assertStatus(200)
            ->assertJsonPath('success', true);

        // 4. Cancel / void bill
        $cancelResponse = $this->postJson('/api/v1/sales/' . $receiptNumber . '/cancel', [
            'reason' => 'Customer returned goods',
        ]);

        $cancelResponse->assertStatus(200)
            ->assertJsonPath('success', true);

        // Verify stock restored
        $product->refresh();
        $this->assertEquals($initialStock, (float) $product->stock_quantity);
    }
}
