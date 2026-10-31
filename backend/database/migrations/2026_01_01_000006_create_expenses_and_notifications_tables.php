<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // 1. Shop Expenses
        Schema::create('expenses', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('shop_id')->constrained('shops')->cascadeOnDelete();
            $table->string('category', 100); // Rent, Electricity, Staff Salary, Tea & Snacks, Packaging, Transport, Other
            $table->decimal('amount', 12, 2);
            $table->string('payment_method', 40)->default('Cash');
            $table->string('paid_to', 120)->nullable();
            $table->text('receipt_image_url')->nullable();
            $table->foreignUuid('recorded_by')->nullable()->constrained('users')->nullOnDelete();
            $table->text('note')->nullable();
            $table->date('expense_date');
            $table->timestamps();

            $table->index(['shop_id', 'expense_date']);
        });

        // 2. Notifications
        Schema::create('notifications', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('shop_id')->constrained('shops')->cascadeOnDelete();
            $table->foreignUuid('user_id')->nullable()->constrained('users')->cascadeOnDelete();
            $table->string('type', 50); // LOW_STOCK, UDHAR_DUE, DAILY_SALES, SECURITY
            $table->string('title', 200);
            $table->text('message');
            $table->jsonb('data')->default('{}');
            $table->boolean('is_read')->default(false);
            $table->timestamp('read_at')->nullable();
            $table->timestamps();

            $table->index(['shop_id', 'user_id', 'is_read']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('notifications');
        Schema::dropIfExists('expenses');
    }
};

