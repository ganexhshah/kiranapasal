<?php

namespace Database\Seeders;

use App\Models\Category;
use App\Models\Customer;
use App\Models\CustomerLedger;
use App\Models\Product;
use App\Models\Sale;
use App\Models\SaleItem;
use App\Models\Shop;
use App\Models\Supplier;
use App\Models\SupplierLedger;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Carbon;
use Illuminate\Support\Str;

class DemoShopSeeder extends Seeder
{
    public function run(): void
    {
        // 1. Create Demo Shop
        $shop = Shop::create([
            'id' => (string) Str::uuid(),
            'name' => 'KRM Kirana Store',
            'business_type' => 'Kirana / Grocery Retail',
            'pan_vat_number' => '302918291',
            'phone' => '+977 9801234567',
            'email' => 'info@krmstore.com',
            'currency' => 'Rs.',
            'address' => 'Baluwatar-4, Kathmandu, Nepal',
            'receipt_header' => 'Welcome to KRM Kirana Store! Quality Groceries at Wholesale Rates.',
            'receipt_footer' => 'Thank you for shopping with us! Goods once sold can be exchanged within 3 days.',
            'low_stock_threshold_default' => 5,
        ]);

        app()->instance('current_shop_id', $shop->id);

        // 2. Create Owner User
        $user = User::create([
            'id' => (string) Str::uuid(),
            'firebase_uid' => 'demo_firebase_uid_owner_001',
            'name' => 'Ganesh Shah',
            'phone' => '+977 9841234567',
            'email' => 'ganesh@krmstore.com',
            'password' => bcrypt('password123'),
            'email_verified_at' => now(),
            'current_shop_id' => $shop->id,
            'is_active' => true,
            'last_login_at' => now(),
        ]);

        $shop->users()->attach($user->id, ['role' => 'owner']);
        $user->assignRole('owner');

        // 3. Categories
        $catDaily = Category::create(['shop_id' => $shop->id, 'name' => 'Daily Needs', 'slug' => 'daily-needs']);
        $catGrains = Category::create(['shop_id' => $shop->id, 'name' => 'Grains', 'slug' => 'grains']);
        $catSnacks = Category::create(['shop_id' => $shop->id, 'name' => 'Snacks', 'slug' => 'snacks']);
        $catBeverages = Category::create(['shop_id' => $shop->id, 'name' => 'Beverages', 'slug' => 'beverages']);

        // 4. Products matching Flutter UI
        $pRice = Product::create([
            'shop_id' => $shop->id,
            'category_id' => $catGrains->id,
            'name' => 'Basmati Long Grain Rice (25kg)',
            'nepali_name' => 'बासमती चामल',
            'sku' => 'GRN001',
            'barcode' => '8901234567890',
            'purchase_price' => 2450.00,
            'purchase_unit' => 'bag',
            'selling_price' => 2850.00,
            'selling_unit' => 'bag',
            'stock_quantity' => 1.000,
            'low_stock_threshold' => 5.000,
            'enable_low_stock_alert' => true,
        ]);

        $pOil = Product::create([
            'shop_id' => $shop->id,
            'category_id' => $catDaily->id,
            'name' => 'Sunflower Cooking Oil (1L)',
            'nepali_name' => 'सूर्यमुखी तेल',
            'sku' => 'DLY002',
            'barcode' => '8901234567891',
            'purchase_price' => 210.00,
            'purchase_unit' => 'ltr',
            'selling_price' => 250.00,
            'selling_unit' => 'ltr',
            'stock_quantity' => 2.000,
            'low_stock_threshold' => 10.000,
            'enable_low_stock_alert' => true,
        ]);

        $pNoodles = Product::create([
            'shop_id' => $shop->id,
            'category_id' => $catSnacks->id,
            'name' => 'Maggi 2-Minute Noodles (70g)',
            'nepali_name' => 'म्यागी चाउचाउ',
            'sku' => 'SNK003',
            'barcode' => '8901234567892',
            'purchase_price' => 48.00,
            'purchase_unit' => 'pkt',
            'selling_price' => 60.00,
            'selling_unit' => 'pkt',
            'stock_quantity' => 0.000,
            'low_stock_threshold' => 15.000,
            'enable_low_stock_alert' => true,
        ]);

        $pSugar = Product::create([
            'shop_id' => $shop->id,
            'category_id' => $catDaily->id,
            'name' => 'Sugar (Pure Refined)',
            'nepali_name' => 'चिनी',
            'sku' => 'DLY004',
            'barcode' => '8901234567893',
            'purchase_price' => 78.00,
            'purchase_unit' => 'kg',
            'selling_price' => 90.00,
            'selling_unit' => 'kg',
            'stock_quantity' => 40.000,
            'low_stock_threshold' => 10.000,
            'enable_low_stock_alert' => true,
        ]);

        $pTea = Product::create([
            'shop_id' => $shop->id,
            'category_id' => $catBeverages->id,
            'name' => 'Red Label Tea (250g)',
            'nepali_name' => 'रेड लेबल चिया',
            'sku' => 'BEV005',
            'barcode' => '8901234567894',
            'purchase_price' => 180.00,
            'purchase_unit' => 'pkt',
            'selling_price' => 220.00,
            'selling_unit' => 'pkt',
            'stock_quantity' => 3.000,
            'low_stock_threshold' => 8.000,
            'enable_low_stock_alert' => true,
        ]);

        // 5. Customers
        $cRam = Customer::create([
            'shop_id' => $shop->id,
            'name' => 'Ram Shrestha',
            'phone' => '+977 9841234567',
            'address' => 'Baluwatar, Kathmandu',
            'credit_limit' => 10000.00,
            'outstanding_udhar' => 3500.00,
        ]);

        $cSita = Customer::create([
            'shop_id' => $shop->id,
            'name' => 'Sita Sharma',
            'phone' => '+977 9812345678',
            'address' => 'Lazimpat, Kathmandu',
            'credit_limit' => 5000.00,
            'outstanding_udhar' => 0.00,
        ]);

        // 6. Suppliers
        $sBishnu = Supplier::create([
            'shop_id' => $shop->id,
            'name' => 'Bishnu Prasad Adhikari',
            'company_name' => 'Bishnu Wholesale Traders',
            'phone' => '+977 9801122334',
            'pan_number' => '102938475',
            'address' => 'Ason, Kathmandu',
            'outstanding_payable' => 5400.00,
        ]);

        // 7. Today's Demo Sale (S1024)
        $sale = Sale::create([
            'shop_id' => $shop->id,
            'receipt_number' => 'S1024',
            'customer_id' => $cRam->id,
            'cashier_id' => $user->id,
            'subtotal' => 1250.00,
            'discount_amount' => 0.00,
            'tax_amount' => 0.00,
            'grand_total' => 1250.00,
            'payment_status' => 'PAID',
            'primary_payment_method' => 'Cash',
            'cash_tendered' => 1500.00,
            'change_returned' => 250.00,
            'items_count' => 3,
            'note' => 'Regular grocery purchase',
            'created_at' => Carbon::now('Asia/Kathmandu')->subHours(2),
        ]);

        SaleItem::create([
            'sale_id' => $sale->id,
            'product_id' => $pOil->id,
            'product_name' => $pOil->name,
            'sku' => $pOil->sku,
            'quantity' => 2,
            'unit_name' => 'ltr',
            'unit_price' => 250.00,
            'total_price' => 500.00,
        ]);

        SaleItem::create([
            'sale_id' => $sale->id,
            'product_id' => $pSugar->id,
            'product_name' => $pSugar->name,
            'sku' => $pSugar->sku,
            'quantity' => 3,
            'unit_name' => 'kg',
            'unit_price' => 90.00,
            'total_price' => 270.00,
        ]);

        SaleItem::create([
            'sale_id' => $sale->id,
            'product_id' => $pTea->id,
            'product_name' => $pTea->name,
            'sku' => $pTea->sku,
            'quantity' => 1,
            'unit_name' => 'pkt',
            'unit_price' => 220.00,
            'total_price' => 220.00,
        ]);

        // 8. Demo Udhar Payment
        CustomerLedger::create([
            'shop_id' => $shop->id,
            'customer_id' => $cRam->id,
            'transaction_type' => 'PAYMENT_RECEIVED',
            'reference_no' => 'RCT-501',
            'amount' => 1000.00,
            'balance_after' => 3500.00,
            'payment_method' => 'Cash',
            'recorded_by' => $user->id,
            'note' => 'Partial udhar settlement',
            'created_at' => Carbon::now('Asia/Kathmandu')->subHours(4),
        ]);

        // 9. Demo Supplier Bill
        SupplierLedger::create([
            'shop_id' => $shop->id,
            'supplier_id' => $sBishnu->id,
            'transaction_type' => 'PURCHASE_BILL',
            'reference_no' => 'PB-892',
            'amount' => 5400.00,
            'balance_after' => 5400.00,
            'payment_method' => 'Bank Transfer',
            'recorded_by' => $user->id,
            'note' => 'Bulk inventory restock',
            'created_at' => Carbon::now('Asia/Kathmandu')->subHours(6),
        ]);
    }
}

