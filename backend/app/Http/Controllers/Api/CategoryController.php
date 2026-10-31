<?php

namespace App\Http\Controllers\Api;

use App\Models\Category;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class CategoryController extends BaseApiController
{
    public function index(): JsonResponse
    {
        $shopId = app()->has('current_shop_id') ? app('current_shop_id') : 'default';
        $cacheKey = "shop:{$shopId}:categories";

        $categories = \Illuminate\Support\Facades\Cache::remember($cacheKey, 600, function () {
            return Category::withCount('products')->orderBy('name')->get();
        });

        return $this->success($categories);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:100'],
            'icon' => ['nullable', 'string', 'max:50'],
            'color' => ['nullable', 'string', 'max:30'],
        ]);

        $validated['slug'] = Str::slug($validated['name']);

        $category = Category::create($validated);

        \App\Services\CacheService::clearProductCache();

        return $this->success($category, 'Category created successfully.');
    }
}

