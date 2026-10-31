<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;
use Spatie\Permission\Traits\HasRoles;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, HasRoles, HasUuids, Notifiable;

    protected string $guard_name = 'sanctum';

    protected $fillable = [
        'firebase_uid',
        'name',
        'phone',
        'email',
        'password',
        'email_verified_at',
        'verification_otp',
        'otp_expires_at',
        'current_shop_id',
        'avatar_url',
        'is_active',
        'last_login_at',
    ];

    protected $casts = [
        'is_active' => 'boolean',
        'last_login_at' => 'datetime',
        'email_verified_at' => 'datetime',
        'otp_expires_at' => 'datetime',
    ];

    protected $hidden = [
        'password',
        'verification_otp',
        'remember_token',
    ];

    public function currentShop(): BelongsTo
    {
        return $this->belongsTo(Shop::class, 'current_shop_id');
    }

    public function shops(): BelongsToMany
    {
        return $this->belongsToMany(Shop::class, 'shop_users')
            ->withPivot('role', 'pin_code_hash')
            ->withTimestamps();
    }
}
