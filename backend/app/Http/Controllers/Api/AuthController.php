<?php

namespace App\Http\Controllers\Api;

use App\Models\Shop;
use App\Models\User;
use App\Services\ResendEmailService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Kreait\Firebase\Contract\Auth as FirebaseAuth;
use Symfony\Component\HttpFoundation\Response;

class AuthController extends BaseApiController
{
    public function __construct(
        protected ResendEmailService $resendEmail
    ) {}

    protected function getFirebaseAuth(): ?FirebaseAuth
    {
        try {
            return app(FirebaseAuth::class);
        } catch (\Throwable $e) {
            return null;
        }
    }

    /**
     * Standard Email & Password Registration with Resend OTP Verification
     */
    public function register(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:100'],
            'email' => ['required', 'string', 'email', 'max:120', 'unique:users,email'],
            'password' => ['required', 'string', 'min:6'],
            'phone' => ['nullable', 'string', 'max:20', 'unique:users,phone'],
            'shop_name' => ['nullable', 'string', 'max:150'],
        ]);

        $otp = str_pad((string) random_int(100000, 999999), 6, '0', STR_PAD_LEFT);

        $result = DB::transaction(function () use ($validated, $otp) {
            // 1. Create Default Shop for user
            $shop = Shop::create([
                'name' => $validated['shop_name'] ?: ($validated['name'] . "'s Store"),
                'phone' => $validated['phone'] ?? null,
                'email' => $validated['email'],
                'currency' => 'Rs.',
                'low_stock_threshold_default' => 5,
            ]);

            // 2. Create User
            $user = User::create([
                'name' => $validated['name'],
                'email' => strtolower(trim($validated['email'])),
                'phone' => $validated['phone'] ? trim($validated['phone']) : null,
                'password' => Hash::make($validated['password']),
                'current_shop_id' => $shop->id,
                'verification_otp' => $otp,
                'otp_expires_at' => now()->addMinutes(15),
                'is_active' => true,
                'last_login_at' => now(),
            ]);

            // 3. Attach User as Shop Owner
            $shop->users()->attach($user->id, ['role' => 'owner']);
            $user->assignRole('owner');

            return [$user, $shop];
        });

        /** @var User $user */
        [$user, $shop] = $result;

        // 4. Send Verification Code via Resend
        $this->resendEmail->sendVerificationOtp($user->email, $user->name, $otp);

        // 5. Issue API Token
        $token = $user->createToken('krm-mobile-client', ['*'], now()->addDays(90))->plainTextToken;

        return $this->success([
            'token' => $token,
            'token_type' => 'Bearer',
            'expires_at' => now()->addDays(90)->toIso8601String(),
            'is_new_user' => true,
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'phone' => $user->phone,
                'email_verified' => false,
                'current_shop_id' => $user->current_shop_id,
            ],
            'shop' => $shop,
            'roles' => $user->getRoleNames(),
            'permissions' => $user->getAllPermissions()->pluck('name'),
            'otp_sent' => true,
        ], 'Registration successful. Verification code has been sent to your email.');
    }

    /**
     * Standard Login via Email or Phone with Password
     */
    public function login(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'identifier' => ['required', 'string'], // Email or Phone
            'password' => ['required', 'string'],
        ]);

        $identifier = trim($validated['identifier']);

        // Find user by email or phone
        $user = User::where('email', strtolower($identifier))
            ->orWhere('phone', $identifier)
            ->first();

        if (! $user || ! Hash::check($validated['password'], $user->password)) {
            return $this->error('Invalid email/phone or password credentials.', Response::HTTP_UNAUTHORIZED);
        }

        if (! $user->is_active) {
            return $this->error('Your account is deactivated. Please contact support.', Response::HTTP_FORBIDDEN);
        }

        $user->update(['last_login_at' => now()]);

        // Load active shop
        $shop = $user->currentShop ?: $user->shops()->first();
        if ($shop && $user->current_shop_id !== $shop->id) {
            $user->update(['current_shop_id' => $shop->id]);
        }

        $token = $user->createToken('krm-mobile-client', ['*'], now()->addDays(90))->plainTextToken;

        return $this->success([
            'token' => $token,
            'token_type' => 'Bearer',
            'expires_at' => now()->addDays(90)->toIso8601String(),
            'is_new_user' => false,
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'phone' => $user->phone,
                'email_verified' => $user->email_verified_at !== null,
                'current_shop_id' => $user->current_shop_id,
            ],
            'shop' => $shop,
            'roles' => $user->getRoleNames(),
            'permissions' => $user->getAllPermissions()->pluck('name'),
        ], 'Logged in successfully.');
    }

    /**
     * Verify 6-digit Email OTP
     */
    public function verifyOtp(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'email' => ['required', 'string', 'email'],
            'otp' => ['required', 'string', 'size:6'],
        ]);

        $user = User::where('email', strtolower(trim($validated['email'])))->first();

        if (! $user) {
            return $this->error('No account registered with this email address.', Response::HTTP_NOT_FOUND);
        }

        if ($user->verification_otp !== $validated['otp']) {
            return $this->error('Incorrect verification code. Please check your email and try again.', Response::HTTP_UNPROCESSABLE_ENTITY);
        }

        if ($user->otp_expires_at && $user->otp_expires_at->isPast()) {
            return $this->error('Verification code has expired. Please request a new code.', Response::HTTP_UNPROCESSABLE_ENTITY);
        }

        $user->update([
            'email_verified_at' => now(),
            'verification_otp' => null,
            'otp_expires_at' => null,
        ]);

        // Send Welcome email via Resend
        $shopName = $user->currentShop ? $user->currentShop->name : 'Your Store';
        $this->resendEmail->sendWelcomeEmail($user->email, $user->name, $shopName);

        return $this->success([
            'verified' => true,
            'email' => $user->email,
            'user' => $user,
        ], 'Email verified successfully! Welcome to KRM.');
    }

    /**
     * Resend fresh OTP verification code via Resend
     */
    public function resendOtp(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'email' => ['required', 'string', 'email'],
        ]);

        $user = User::where('email', strtolower(trim($validated['email'])))->first();

        if (! $user) {
            return $this->error('No user found with this email.', Response::HTTP_NOT_FOUND);
        }

        $otp = str_pad((string) random_int(100000, 999999), 6, '0', STR_PAD_LEFT);
        $user->update([
            'verification_otp' => $otp,
            'otp_expires_at' => now()->addMinutes(15),
        ]);

        $this->resendEmail->sendVerificationOtp($user->email, $user->name, $otp);

        return $this->success(null, 'Fresh verification code has been sent to your email.');
    }

    /**
     * Request Password Reset OTP
     */
    public function forgotPassword(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'email' => ['required', 'string', 'email'],
        ]);

        $user = User::where('email', strtolower(trim($validated['email'])))->first();

        if (! $user) {
            return $this->error('No account registered with this email address.', Response::HTTP_NOT_FOUND);
        }

        $otp = str_pad((string) random_int(100000, 999999), 6, '0', STR_PAD_LEFT);
        $user->update([
            'verification_otp' => $otp,
            'otp_expires_at' => now()->addMinutes(15),
        ]);

        $this->resendEmail->sendPasswordResetOtp($user->email, $user->name, $otp);

        return $this->success(null, 'Password reset instructions and 6-digit PIN sent to your email.');
    }

    /**
     * Reset Password using OTP
     */
    public function resetPassword(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'email' => ['required', 'string', 'email'],
            'otp' => ['required', 'string', 'size:6'],
            'password' => ['required', 'string', 'min:6'],
        ]);

        $user = User::where('email', strtolower(trim($validated['email'])))->first();

        if (! $user) {
            return $this->error('No user found with this email.', Response::HTTP_NOT_FOUND);
        }

        if ($user->verification_otp !== $validated['otp']) {
            return $this->error('Invalid reset PIN code.', Response::HTTP_UNPROCESSABLE_ENTITY);
        }

        if ($user->otp_expires_at && $user->otp_expires_at->isPast()) {
            return $this->error('Reset PIN has expired. Please request a new one.', Response::HTTP_UNPROCESSABLE_ENTITY);
        }

        $user->update([
            'password' => Hash::make($validated['password']),
            'verification_otp' => null,
            'otp_expires_at' => null,
        ]);

        // Revoke previous tokens
        $user->tokens()->delete();

        $token = $user->createToken('krm-mobile-client', ['*'], now()->addDays(90))->plainTextToken;

        return $this->success([
            'token' => $token,
            'token_type' => 'Bearer',
        ], 'Password has been reset successfully. You are now logged in.');
    }

    /**
     * Firebase Phone Auth handshake fallback
     */
    public function firebaseLogin(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'firebase_token' => ['required', 'string'],
            'shop_name' => ['nullable', 'string', 'max:150'],
            'owner_name' => ['nullable', 'string', 'max:100'],
        ]);

        $firebaseAuth = $this->getFirebaseAuth();
        if (! $firebaseAuth) {
            return $this->error('Firebase authentication driver not configured.', Response::HTTP_SERVICE_UNAVAILABLE);
        }

        try {
            $verifiedToken = $firebaseAuth->verifyIdToken($validated['firebase_token']);
            $firebaseUid = $verifiedToken->claims()->get('sub');
            $phoneNumber = $verifiedToken->claims()->get('phone_number') ?? $request->input('phone');

            if (! $phoneNumber) {
                return $this->error('Phone number missing in Firebase identity token.', Response::HTTP_UNPROCESSABLE_ENTITY);
            }
        } catch (\Throwable $e) {
            return $this->error('Firebase token verification failed: '.$e->getMessage(), Response::HTTP_UNAUTHORIZED);
        }

        $user = DB::transaction(function () use ($firebaseUid, $phoneNumber, $validated) {
            $user = User::where('firebase_uid', $firebaseUid)
                ->orWhere('phone', $phoneNumber)
                ->first();

            if (! $user) {
                $shop = Shop::create([
                    'name' => $validated['shop_name'] ?? 'My Kirana Store',
                    'phone' => $phoneNumber,
                    'currency' => 'Rs.',
                    'low_stock_threshold_default' => 5,
                ]);

                $user = User::create([
                    'firebase_uid' => $firebaseUid,
                    'phone' => $phoneNumber,
                    'name' => $validated['owner_name'] ?? 'Shop Owner',
                    'current_shop_id' => $shop->id,
                    'is_active' => true,
                    'last_login_at' => now(),
                ]);

                $shop->users()->attach($user->id, ['role' => 'owner']);
                $user->assignRole('owner');
            } else {
                $user->update([
                    'firebase_uid' => $firebaseUid,
                    'last_login_at' => now(),
                ]);
            }

            return $user;
        });

        $token = $user->createToken('krm-mobile-client', ['*'], now()->addDays(90))->plainTextToken;

        return $this->success([
            'token' => $token,
            'token_type' => 'Bearer',
            'expires_at' => now()->addDays(90)->toIso8601String(),
            'is_new_user' => false,
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'phone' => $user->phone,
                'current_shop_id' => $user->current_shop_id,
            ],
            'shop' => $user->currentShop,
            'roles' => $user->getRoleNames(),
            'permissions' => $user->getAllPermissions()->pluck('name'),
        ], 'Authenticated successfully.');
    }

    /**
     * Google Sign-In authentication & user synchronization
     */
    public function googleLogin(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'email' => ['required', 'string', 'email'],
            'name' => ['nullable', 'string', 'max:100'],
            'avatar_url' => ['nullable', 'string'],
            'google_id' => ['nullable', 'string'],
            'id_token' => ['nullable', 'string'],
            'shop_name' => ['nullable', 'string', 'max:150'],
        ]);

        $email = strtolower(trim($validated['email']));
        $name = trim($validated['name'] ?? '') ?: 'Store Owner';
        $avatarUrl = $validated['avatar_url'] ?? null;
        $googleId = $validated['google_id'] ?? null;

        // If an id_token is provided, verify it with Google's public tokeninfo endpoint
        if (! empty($validated['id_token'])) {
            try {
                $response = \Illuminate\Support\Facades\Http::timeout(5)->get('https://oauth2.googleapis.com/tokeninfo', [
                    'id_token' => $validated['id_token'],
                ]);
                if ($response->successful()) {
                    $googleData = $response->json();
                    if (! empty($googleData['email'])) {
                        $email = strtolower(trim($googleData['email']));
                    }
                    if (! empty($googleData['name'])) {
                        $name = $googleData['name'];
                    }
                    if (! empty($googleData['picture'])) {
                        $avatarUrl = $googleData['picture'];
                    }
                    if (! empty($googleData['sub'])) {
                        $googleId = $googleData['sub'];
                    }
                }
            } catch (\Throwable $e) {
                \Illuminate\Support\Facades\Log::warning('Google token verification network warning: '.$e->getMessage());
            }
        }

        $isNewUser = false;

        $user = DB::transaction(function () use ($email, $name, $avatarUrl, $googleId, $validated, &$isNewUser) {
            $user = User::where('email', $email)->first();

            if (! $user) {
                $isNewUser = true;
                // Create Default Shop for the new Google user
                $shopName = $validated['shop_name'] ?? ($name . "'s Kirana Store");
                $shop = Shop::create([
                    'name' => $shopName,
                    'email' => $email,
                    'currency' => 'Rs.',
                    'low_stock_threshold_default' => 5,
                ]);

                $user = User::create([
                    'name' => $name,
                    'email' => $email,
                    'avatar_url' => $avatarUrl,
                    'email_verified_at' => now(),
                    'current_shop_id' => $shop->id,
                    'is_active' => true,
                    'last_login_at' => now(),
                ]);

                $shop->users()->attach($user->id, ['role' => 'owner']);
                $user->assignRole('owner');
            } else {
                $user->update([
                    'last_login_at' => now(),
                    'email_verified_at' => $user->email_verified_at ?? now(),
                    'avatar_url' => $avatarUrl ?: $user->avatar_url,
                ]);

                // Ensure user has a shop
                $shop = $user->currentShop ?: $user->shops()->first();
                if (! $shop) {
                    $shop = Shop::create([
                        'name' => ($user->name ?: 'My') . "'s Kirana Store",
                        'email' => $user->email,
                        'currency' => 'Rs.',
                        'low_stock_threshold_default' => 5,
                    ]);
                    $shop->users()->attach($user->id, ['role' => 'owner']);
                    $user->update(['current_shop_id' => $shop->id]);
                    if (! $user->hasRole('owner')) {
                        $user->assignRole('owner');
                    }
                }
            }

            return $user;
        });

        $token = $user->createToken('krm-mobile-client', ['*'], now()->addDays(90))->plainTextToken;

        return $this->success([
            'token' => $token,
            'token_type' => 'Bearer',
            'expires_at' => now()->addDays(90)->toIso8601String(),
            'is_new_user' => $isNewUser,
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'phone' => $user->phone,
                'avatar_url' => $user->avatar_url,
                'current_shop_id' => $user->current_shop_id,
            ],
            'shop' => $user->currentShop,
            'roles' => $user->getRoleNames(),
            'permissions' => $user->getAllPermissions()->pluck('name'),
        ], 'Google authentication successful.');
    }

    /**
     * Get authenticated user profile.
     */
    public function me(Request $request): JsonResponse
    {
        $user = $request->user()->load('currentShop');

        return $this->success([
            'user' => $user,
            'roles' => $user->getRoleNames(),
            'permissions' => $user->getAllPermissions()->pluck('name'),
        ]);
    }

    /**
     * Update authenticated user profile.
     */
    public function updateProfile(Request $request): JsonResponse
    {
        $user = $request->user();
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:100'],
            'phone' => ['nullable', 'string', 'max:20'],
            'avatar_url' => ['nullable', 'string'],
        ]);

        $user->update($validated);

        return $this->success($user->fresh(), 'Profile updated successfully.');
    }

    /**
     * Revoke current token (Logout).
     */
    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();

        return $this->success(null, 'Logged out successfully.');
    }
}
