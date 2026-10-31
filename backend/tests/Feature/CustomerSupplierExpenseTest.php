<?php

namespace Tests\Feature;

use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class CustomerSupplierExpenseTest extends TestCase
{
    public function test_customer_supplier_expense_and_dashboard(): void
    {
        $user = $this->getTestUser();
        Sanctum::actingAs($user);

        $phone = '+977 98' . rand(10000000, 99999999);

        // 1. Create and update customer
        $custResponse = $this->postJson('/api/v1/customers', [
            'name' => 'Bikram Thapa',
            'phone' => $phone,
            'address' => 'Baneshwor, Kathmandu',
            'credit_limit' => 15000,
        ]);
        $custResponse->assertStatus(201)
            ->assertJsonPath('success', true);
        $customerId = $custResponse->json('data.id');

        $custUpdate = $this->putJson('/api/v1/customers/' . $customerId, [
            'name' => 'Bikram Thapa (VIP)',
        ]);
        $custUpdate->assertStatus(200)
            ->assertJsonPath('data.name', 'Bikram Thapa (VIP)');

        // 2. Receive customer udhar payment
        $payResponse = $this->postJson('/api/v1/customers/' . $customerId . '/receive-payment', [
            'amount' => 500,
            'payment_method' => 'Cash',
            'note' => 'Partial deposit',
        ]);
        $payResponse->assertStatus(200)
            ->assertJsonPath('success', true);

        // 3. Customer ledger
        $ledgerResponse = $this->getJson('/api/v1/customers/' . $customerId . '/ledger');
        $ledgerResponse->assertStatus(200)
            ->assertJsonPath('success', true);

        // 4. Create and update supplier
        $suppPhone = '+977 98' . rand(10000000, 99999999);
        $suppResponse = $this->postJson('/api/v1/suppliers', [
            'name' => 'Himalayan Distributors',
            'company_name' => 'Himalayan Pvt Ltd',
            'phone' => $suppPhone,
            'pan_number' => '601234567',
            'address' => 'Balaju Industrial Area',
        ]);
        $suppResponse->assertStatus(201)
            ->assertJsonPath('success', true);
        $supplierId = $suppResponse->json('data.id');

        $suppUpdate = $this->putJson('/api/v1/suppliers/' . $supplierId, [
            'company_name' => 'Himalayan Logistics Pvt Ltd',
        ]);
        $suppUpdate->assertStatus(200)
            ->assertJsonPath('data.company_name', 'Himalayan Logistics Pvt Ltd');

        // 5. Record supplier payment
        $suppPay = $this->postJson('/api/v1/suppliers/' . $supplierId . '/make-payment', [
            'amount' => 1200,
            'payment_method' => 'Cash',
            'note' => 'Weekly payment',
        ]);
        $suppPay->assertStatus(200)
            ->assertJsonPath('success', true);

        // 6. Record Expense
        $expResponse = $this->postJson('/api/v1/expenses', [
            'category' => 'Shop Rent',
            'amount' => 2500.00,
            'payment_method' => 'Cash',
            'expense_date' => now()->format('Y-m-d'),
            'note' => 'Monthly shop rent advance',
        ]);
        $expResponse->assertStatus(201)
            ->assertJsonPath('success', true);

        // 7. Dashboard Overview & Stats
        $overviewResponse = $this->getJson('/api/v1/dashboard/overview');
        $overviewResponse->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonStructure([
                'data' => [
                    'total_sales',
                    'cash_amount',
                    'card_amount',
                    'udhar_amount',
                    'bills_count',
                ],
            ]);

        $statsResponse = $this->getJson('/api/v1/dashboard/stats');
        $statsResponse->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonStructure([
                'data' => [
                    'total_products',
                    'total_customers',
                    'low_stock_items',
                    'todays_bills',
                ],
            ]);
    }
}
