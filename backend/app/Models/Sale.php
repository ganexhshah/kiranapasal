<?php

namespace App\Models;

use App\Traits\BelongsToTenant;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Sale extends Model
{
    use BelongsToTenant, HasFactory, HasUuids;

    protected $fillable = [
        'shop_id',
        'receipt_number',
        'customer_id',
        'cashier_id',
        'subtotal',
        'discount_type',
        'discount_amount',
        'tax_percentage',
        'tax_amount',
        'grand_total',
        'payment_status',
        'primary_payment_method',
        'cash_tendered',
        'change_returned',
        'udhar_amount',
        'items_count',
        'note',
        'is_cancelled',
        'cancelled_reason',
        'cancelled_at',
    ];

    protected $casts = [
        'subtotal' => 'decimal:2',
        'discount_amount' => 'decimal:2',
        'tax_percentage' => 'decimal:2',
        'tax_amount' => 'decimal:2',
        'grand_total' => 'decimal:2',
        'cash_tendered' => 'decimal:2',
        'change_returned' => 'decimal:2',
        'udhar_amount' => 'decimal:2',
        'items_count' => 'integer',
        'is_cancelled' => 'boolean',
        'cancelled_at' => 'datetime',
    ];

    public function customer(): BelongsTo
    {
        return $this->belongsTo(Customer::class);
    }

    public function cashier(): BelongsTo
    {
        return $this->belongsTo(User::class, 'cashier_id');
    }

    public function items(): HasMany
    {
        return $this->hasMany(SaleItem::class);
    }

    public function payments(): HasMany
    {
        return $this->hasMany(Payment::class, 'payable_id')->where('payable_type', self::class);
    }
}

