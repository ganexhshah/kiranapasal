<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Spatie\Permission\Models\Permission;
use Spatie\Permission\Models\Role;

class RolePermissionSeeder extends Seeder
{
    public function run(): void
    {
        // Reset cached roles and permissions
        app()[\Spatie\Permission\PermissionRegistrar::class]->forgetCachedPermissions();

        $permissions = [
            'view-dashboard',
            'create-sale',
            'view-sale',
            'cancel-sale',
            'manage-products',
            'adjust-stock',
            'view-customers',
            'manage-customers',
            'collect-udhar',
            'view-suppliers',
            'manage-suppliers',
            'record-purchase',
            'manage-expenses',
            'view-reports',
            'manage-shop-settings',
        ];

        foreach ($permissions as $perm) {
            Permission::firstOrCreate(['name' => $perm, 'guard_name' => 'sanctum']);
        }

        // 1. Owner Role
        $owner = Role::firstOrCreate(['name' => 'owner', 'guard_name' => 'sanctum']);
        $owner->syncPermissions(Permission::all());

        // 2. Manager Role
        $manager = Role::firstOrCreate(['name' => 'manager', 'guard_name' => 'sanctum']);
        $manager->syncPermissions([
            'view-dashboard',
            'create-sale',
            'view-sale',
            'manage-products',
            'adjust-stock',
            'view-customers',
            'manage-customers',
            'collect-udhar',
            'view-suppliers',
            'manage-suppliers',
            'record-purchase',
            'manage-expenses',
            'view-reports',
        ]);

        // 3. Cashier Role
        $cashier = Role::firstOrCreate(['name' => 'cashier', 'guard_name' => 'sanctum']);
        $cashier->syncPermissions([
            'view-dashboard',
            'create-sale',
            'view-sale',
            'view-customers',
            'collect-udhar',
        ]);

        // 4. Accountant Role
        $accountant = Role::firstOrCreate(['name' => 'accountant', 'guard_name' => 'sanctum']);
        $accountant->syncPermissions([
            'view-dashboard',
            'view-sale',
            'view-customers',
            'collect-udhar',
            'view-suppliers',
            'manage-expenses',
            'view-reports',
        ]);
    }
}

