<?php

namespace App\Models;

use App\Traits\BelongsToTenant;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Supplier extends Model
{
    use BelongsToTenant, HasFactory, HasUuids;

    protected $fillable = [
        'shop_id',
        'name',
        'company_name',
        'phone',
        'pan_number',
        'address',
        'outstanding_payable',
    ];

    protected $casts = [
        'outstanding_payable' => 'decimal:2',
    ];

    public function ledgers(): HasMany
    {
        return $this->hasMany(SupplierLedger::class)->orderByDesc('created_at');
    }
}

