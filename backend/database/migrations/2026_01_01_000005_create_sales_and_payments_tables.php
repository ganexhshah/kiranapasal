<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // 1. Sales (Invoices) Table
        Schema::create('sales', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('shop_id')->constrained('shops')->cascadeOnDelete();
            $table->string('receipt_number', 40);
            $table->foreignUuid('customer_id')->nullable()->constrained('customers')->nullOnDelete();
            $table->foreignUuid('cashier_id')->nullable()->constrained('users')->nullOnDelete();
            $table->decimal('subtotal', 12, 2);
            $table->string('discount_type', 20)->default('fixed'); // fixed or percentage
            $table->decimal('discount_amount', 12, 2)->default(0);
            $table->decimal('tax_percentage', 5, 2)->default(0);
            $table->decimal('tax_amount', 12, 2)->default(0);
            $table->decimal('grand_total', 12, 2);
            $table->string('payment_status', 25)->default('PAID'); // PAID, PARTIAL, CREDIT, CANCELLED
            $table->string('primary_payment_method', 30)->default('Cash'); // Cash, Fonepay_QR, Card, Credit
            $table->decimal('cash_tendered', 12, 2)->default(0);
            $table->decimal('change_returned', 12, 2)->default(0);
            $table->decimal('udhar_amount', 12, 2)->default(0);
            $table->integer('items_count');
            $table->text('note')->nullable();
            $table->boolean('is_cancelled')->default(false);
            $table->text('cancelled_reason')->nullable();
            $table->timestamp('cancelled_at')->nullable();
            $table->timestamps();

            $table->unique(['shop_id', 'receipt_number']);
            $table->index(['shop_id', 'created_at']);
            $table->index(['shop_id', 'payment_status']);
        });

        // 2. Sale Items
        Schema::create('sale_items', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('sale_id')->constrained('sales')->cascadeOnDelete();
            $table->foreignUuid('product_id')->constrained('products')->restrictOnDelete();
            $table->string('product_name', 200);
            $table->string('sku', 60);
            $table->decimal('quantity', 12, 3);
            $table->string('unit_name', 30);
            $table->decimal('unit_price', 12, 2);
            $table->decimal('purchase_cost', 12, 2)->default(0);
            $table->decimal('discount_amount', 12, 2)->default(0);
            $table->decimal('total_price', 12, 2);
            $table->timestamps();

            $table->index('sale_id');
        });

        // 3. Payments Ledger
        Schema::create('payments', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('shop_id')->constrained('shops')->cascadeOnDelete();
            $table->string('payable_type', 50); // Sale, Purchase, CustomerLedger, SupplierLedger
            $table->uuid('payable_id');
            $table->string('payment_method', 40); // Cash, Fonepay_QR, Card, Bank_Transfer, Credit
            $table->decimal('amount', 12, 2);
            $table->string('transaction_reference', 100)->nullable();
            $table->foreignUuid('received_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();

            $table->index(['shop_id', 'payable_type', 'payable_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('payments');
        Schema::dropIfExists('sale_items');
        Schema::dropIfExists('sales');
    }
};

