<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // 1. Customers Table
        Schema::create('customers', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('shop_id')->constrained('shops')->cascadeOnDelete();
            $table->string('name', 150);
            $table->string('phone', 25);
            $table->text('address')->nullable();
            $table->decimal('credit_limit', 12, 2)->default(0);
            $table->decimal('outstanding_udhar', 12, 2)->default(0);
            $table->boolean('is_active')->default(true);
            $table->timestamps();

            $table->unique(['shop_id', 'phone']);
            $table->index(['shop_id', 'outstanding_udhar']);
        });

        // 2. Customer Double-Entry Ledgers (Udhar Khata)
        Schema::create('customer_ledgers', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('shop_id')->constrained('shops')->cascadeOnDelete();
            $table->foreignUuid('customer_id')->constrained('customers')->cascadeOnDelete();
            $table->string('transaction_type', 30); // CREDIT_SALE, PAYMENT_RECEIVED, DISCOUNT_ALLOWED, OPENING_BALANCE
            $table->string('reference_no', 60)->nullable();
            $table->decimal('amount', 12, 2);
            $table->decimal('balance_after', 12, 2);
            $table->string('payment_method', 40)->nullable(); // Cash, Fonepay_QR, Card
            $table->foreignUuid('recorded_by')->nullable()->constrained('users')->nullOnDelete();
            $table->text('note')->nullable();
            $table->timestamp('created_at')->useCurrent();

            $table->index(['shop_id', 'customer_id', 'created_at']);
        });

        // 3. Suppliers Table
        Schema::create('suppliers', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('shop_id')->constrained('shops')->cascadeOnDelete();
            $table->string('name', 150);
            $table->string('company_name', 150)->nullable();
            $table->string('phone', 25);
            $table->string('pan_number', 30)->nullable();
            $table->text('address')->nullable();
            $table->decimal('outstanding_payable', 12, 2)->default(0);
            $table->timestamps();

            $table->index(['shop_id', 'phone']);
        });

        // 4. Supplier Ledgers
        Schema::create('supplier_ledgers', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('shop_id')->constrained('shops')->cascadeOnDelete();
            $table->foreignUuid('supplier_id')->constrained('suppliers')->cascadeOnDelete();
            $table->string('transaction_type', 30); // PURCHASE_BILL, PAYMENT_MADE, PURCHASE_RETURN
            $table->string('reference_no', 60)->nullable();
            $table->decimal('amount', 12, 2);
            $table->decimal('balance_after', 12, 2);
            $table->string('payment_method', 40)->nullable(); // Cash, Bank_Transfer, Cheque
            $table->foreignUuid('recorded_by')->nullable()->constrained('users')->nullOnDelete();
            $table->text('note')->nullable();
            $table->timestamp('created_at')->useCurrent();

            $table->index(['shop_id', 'supplier_id', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('supplier_ledgers');
        Schema::dropIfExists('suppliers');
        Schema::dropIfExists('customer_ledgers');
        Schema::dropIfExists('customers');
    }
};

