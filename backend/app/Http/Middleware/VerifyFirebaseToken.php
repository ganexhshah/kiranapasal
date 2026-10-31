<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Kreait\Firebase\Contract\Auth as FirebaseAuth;
use Symfony\Component\HttpFoundation\Response;

class VerifyFirebaseToken
{
    public function __construct(
        protected FirebaseAuth $firebaseAuth
    ) {}

    /**
     * Handle an incoming request by verifying Firebase ID Token from Authorization header.
     */
    public function handle(Request $request, Closure $next): Response
    {
        $token = $request->bearerToken();

        if (! $token) {
            return response()->json([
                'success' => false,
                'message' => 'Authorization Bearer token is missing.',
            ], Response::HTTP_UNAUTHORIZED);
        }

        try {
            $verifiedIdToken = $this->firebaseAuth->verifyIdToken($token);
            $uid = $verifiedIdToken->claims()->get('sub');
            $phoneNumber = $verifiedIdToken->claims()->get('phone_number');

            // Attach verified Firebase identity to request attributes
            $request->attributes->set('firebase_uid', $uid);
            $request->attributes->set('firebase_phone', $phoneNumber);
        } catch (\Throwable $e) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid or expired Firebase identity token: '.$e->getMessage(),
            ], Response::HTTP_UNAUTHORIZED);
        }

        return $next($request);
    }
}

