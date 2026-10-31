<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // 1. Shops Table
        Schema::create('shops', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->string('name', 150);
            $table->string('business_type', 50)->default('Kirana / Retail');
            $table->string('pan_vat_number', 30)->nullable();
            $table->string('phone', 20)->nullable();
            $table->string('email', 100)->nullable();
            $table->string('currency', 10)->default('Rs.');
            $table->text('address')->nullable();
            $table->text('receipt_header')->nullable();
            $table->text('receipt_footer')->nullable();
            $table->integer('low_stock_threshold_default')->default(5);
            $table->timestamps();
        });

        // 2. Users Table (Email/Password & Firebase Auth)
        Schema::create('users', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->string('firebase_uid', 128)->unique()->nullable();
            $table->string('name', 100);
            $table->string('phone', 20)->unique()->nullable();
            $table->string('email', 120)->unique()->nullable();
            $table->string('password')->nullable();
            $table->timestamp('email_verified_at')->nullable();
            $table->string('verification_otp', 10)->nullable();
            $table->timestamp('otp_expires_at')->nullable();
            $table->foreignUuid('current_shop_id')->nullable()->constrained('shops')->nullOnDelete();
            $table->text('avatar_url')->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamp('last_login_at')->nullable();
            $table->rememberToken();
            $table->timestamps();
        });

        // 3. Shop - Users Pivot Table
        Schema::create('shop_users', function (Blueprint $table) {
            $table->id();
            $table->foreignUuid('shop_id')->constrained('shops')->cascadeOnDelete();
            $table->foreignUuid('user_id')->constrained('users')->cascadeOnDelete();
            $table->string('role', 50)->default('cashier'); // owner, manager, cashier, accountant
            $table->string('pin_code_hash')->nullable();
            $table->timestamps();

            $table->unique(['shop_id', 'user_id']);
        });

        // 4. Laravel Sanctum Personal Access Tokens
        Schema::create('personal_access_tokens', function (Blueprint $table) {
            $table->id();
            $table->uuidMorphs('tokenable');
            $table->string('name');
            $table->string('token', 64)->unique();
            $table->text('abilities')->nullable();
            $table->timestamp('last_used_at')->nullable();
            $table->timestamp('expires_at')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('personal_access_tokens');
        Schema::dropIfExists('shop_users');
        Schema::dropIfExists('users');
        Schema::dropIfExists('shops');
    }
};

