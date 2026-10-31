<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class TenantScopeMiddleware
{
    /**
     * Handle an incoming request ensuring user has a valid active shop context.
     */
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        if (! $user) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthenticated user context.',
            ], Response::HTTP_UNAUTHORIZED);
        }

        // Check if shop header is provided or use user's default current_shop_id
        $requestedShopId = $request->header('X-Shop-Id') ?? $user->current_shop_id;

        if (! $requestedShopId) {
            return response()->json([
                'success' => false,
                'message' => 'No active shop associated with this user session. Please complete shop onboarding.',
            ], Response::HTTP_FORBIDDEN);
        }

        // Validate user belongs to this shop
        $hasAccess = $user->shops()->where('shops.id', $requestedShopId)->exists();

        if (! $hasAccess) {
            return response()->json([
                'success' => false,
                'message' => 'Access denied: You do not have permissions for this shop.',
            ], Response::HTTP_FORBIDDEN);
        }

        // Bind current tenant shop ID into the application container
        app()->instance('current_shop_id', $requestedShopId);

        return $next($request);
    }
}

