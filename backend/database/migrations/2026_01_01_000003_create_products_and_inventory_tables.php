<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // 1. Categories
        Schema::create('categories', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('shop_id')->constrained('shops')->cascadeOnDelete();
            $table->string('name', 100);
            $table->string('slug', 120);
            $table->string('icon', 50)->nullable();
            $table->string('color', 30)->nullable();
            $table->timestamps();

            $table->unique(['shop_id', 'slug']);
        });

        // 2. Products
        Schema::create('products', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('shop_id')->constrained('shops')->cascadeOnDelete();
            $table->foreignUuid('category_id')->nullable()->constrained('categories')->nullOnDelete();
            $table->string('name', 200);
            $table->string('nepali_name', 200)->nullable();
            $table->string('sku', 60);
            $table->string('barcode', 100)->nullable();
            $table->text('description')->nullable();
            $table->decimal('purchase_price', 12, 2)->default(0);
            $table->string('purchase_unit', 30)->default('Piece');
            $table->decimal('selling_price', 12, 2);
            $table->string('selling_unit', 30)->default('Piece');
            $table->decimal('stock_quantity', 12, 3)->default(0);
            $table->decimal('secondary_stock', 12, 3)->nullable();
            $table->string('secondary_unit', 30)->nullable();
            $table->decimal('unit_conversion_factor', 10, 4)->default(1.0);
            $table->decimal('low_stock_threshold', 12, 3)->default(5);
            $table->boolean('enable_low_stock_alert')->default(true);
            $table->date('expiry_date')->nullable();
            $table->text('image_url')->nullable();
            $table->jsonb('gallery_images')->default('[]');
            $table->timestamps();

            $table->index(['shop_id', 'sku']);
            $table->index(['shop_id', 'barcode']);
            $table->index(['shop_id', 'stock_quantity']);
        });

        // Add PostgreSQL Full-Text Search tsvector column and trigger
        DB::statement('ALTER TABLE products ADD COLUMN search_vector tsvector;');
        DB::statement('CREATE INDEX products_search_vector_idx ON products USING GIN (search_vector);');

        DB::statement("
            CREATE OR REPLACE FUNCTION products_search_vector_update() RETURNS trigger AS $$
            BEGIN
                NEW.search_vector :=
                    setweight(to_tsvector('simple', COALESCE(NEW.name, '')), 'A') ||
                    setweight(to_tsvector('simple', COALESCE(NEW.nepali_name, '')), 'A') ||
                    setweight(to_tsvector('simple', COALESCE(NEW.sku, '')), 'B') ||
                    setweight(to_tsvector('simple', COALESCE(NEW.barcode, '')), 'B');
                RETURN NEW;
            END
            $$ LANGUAGE plpgsql;
        ");

        DB::statement("
            CREATE TRIGGER trg_products_search_vector_update
            BEFORE INSERT OR UPDATE ON products
            FOR EACH ROW EXECUTE FUNCTION products_search_vector_update();
        ");

        // 3. Multi-Unit Selling Units
        Schema::create('selling_units', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('shop_id')->constrained('shops')->cascadeOnDelete();
            $table->foreignUuid('product_id')->constrained('products')->cascadeOnDelete();
            $table->string('unit_name', 50);
            $table->decimal('conversion_rate', 10, 4); // relative to base stockUnit
            $table->decimal('selling_price', 12, 2);
            $table->boolean('is_default')->default(false);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        // 4. Stock Movement Audit Trail
        Schema::create('stock_movements', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('shop_id')->constrained('shops')->cascadeOnDelete();
            $table->foreignUuid('product_id')->constrained('products')->cascadeOnDelete();
            $table->foreignUuid('user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('movement_type', 30); // SALE, PURCHASE, ADJUSTMENT_ADD, ADJUSTMENT_REMOVE, RETURN
            $table->decimal('quantity', 12, 3);
            $table->string('unit', 30);
            $table->decimal('stock_before', 12, 3);
            $table->decimal('stock_after', 12, 3);
            $table->string('reference_type', 50)->nullable();
            $table->uuid('reference_id')->nullable();
            $table->string('reason', 255)->nullable();
            $table->text('note')->nullable();
            $table->timestamp('created_at')->useCurrent();

            $table->index(['shop_id', 'product_id', 'created_at']);
        });
    }

    public function down(): void
    {
        DB::statement('DROP TRIGGER IF EXISTS trg_products_search_vector_update ON products;');
        DB::statement('DROP FUNCTION IF EXISTS products_search_vector_update;');

        Schema::dropIfExists('stock_movements');
        Schema::dropIfExists('selling_units');
        Schema::dropIfExists('products');
        Schema::dropIfExists('categories');
    }
};

