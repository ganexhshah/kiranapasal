<?php

namespace Tests\Feature;

use App\Models\Product;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ProductApiTest extends TestCase
{
    public function test_can_list_products(): void
    {
        $user = $this->getTestUser();
        Sanctum::actingAs($user);

        $response = $this->getJson('/api/v1/products');

        $response->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonStructure([
                'success',
                'data' => [
                    'data',
                    'current_page',
                    'total',
                ],
            ]);
    }

    public function test_can_create_update_and_delete_product(): void
    {
        $user = $this->getTestUser();
        Sanctum::actingAs($user);

        $sku = 'TEST-SKU-' . time();
        $barcode = 'BAR-' . time();

        // 1. Create Product
        $createResponse = $this->postJson('/api/v1/products', [
            'name' => 'Premium Basmati Rice 5kg',
            'category' => 'Grains',
            'sku' => $sku,
            'barcode' => $barcode,
            'description' => 'Aromatic aged long grain basmati rice',
            'purchase_price' => 450.00,
            'purchase_unit' => 'Bag',
            'selling_price' => 550.00,
            'selling_unit' => 'Bag',
            'stock_quantity' => 20,
            'low_stock_threshold' => 5,
            'enable_low_stock_alert' => true,
        ]);

        $createResponse->assertStatus(201)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.name', 'Premium Basmati Rice 5kg');

        $productId = $createResponse->json('data.id');
        $this->assertNotNull($productId);

        // 2. Fetch by ID
        $showResponse = $this->getJson('/api/v1/products/' . $productId);
        $showResponse->assertStatus(200)
            ->assertJsonPath('data.sku', $sku);

        // 3. Fetch by Barcode
        $barcodeResponse = $this->getJson('/api/v1/products/barcode/' . $barcode);
        $barcodeResponse->assertStatus(200)
            ->assertJsonPath('data.id', $productId);

        // 4. Update Product
        $updateResponse = $this->putJson('/api/v1/products/' . $productId, [
            'name' => 'Premium Basmati Rice 5kg (Updated)',
            'selling_price' => 580.00,
            'selling_unit' => 'Bag',
        ]);

        $updateResponse->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.name', 'Premium Basmati Rice 5kg (Updated)')
            ->assertJsonPath('data.selling_price', '580.00');

        // 5. Adjust Stock
        $adjustResponse = $this->postJson('/api/v1/products/' . $productId . '/adjust-stock', [
            'is_addition' => true,
            'quantity' => 10,
            'unit' => 'Bag',
            'reason' => 'Restock shipment received',
            'note' => 'Supplier bill #9921',
        ]);

        $adjustResponse->assertStatus(200)
            ->assertJsonPath('success', true);

        // 6. Check Stock History
        $historyResponse = $this->getJson('/api/v1/products/' . $productId . '/stock-history');
        $historyResponse->assertStatus(200)
            ->assertJsonPath('success', true);

        // 7. Delete Product
        $deleteResponse = $this->deleteJson('/api/v1/products/' . $productId);
        $deleteResponse->assertStatus(200)
            ->assertJsonPath('success', true);

        $this->assertNull(Product::find($productId));
    }
}

