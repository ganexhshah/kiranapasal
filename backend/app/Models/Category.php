<?php

namespace App\Models;

use App\Traits\BelongsToTenant;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Category extends Model
{
    use BelongsToTenant, HasFactory, HasUuids;

    protected $fillable = [
        'shop_id',
        'name',
        'slug',
        'icon',
        'color',
    ];

    public function products(): HasMany
    {
        return $this->hasMany(Product::class);
    }
}

