<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class ResendEmailService
{
    protected string $apiKey;
    protected string $fromEmail;
    protected string $apiUrl = 'https://api.resend.com/emails';

    public function __construct()
    {
        $this->apiKey = (string) config('services.resend.key', env('RESEND_API_KEY', ''));
        $this->fromEmail = (string) config('services.resend.from', env('RESEND_FROM_EMAIL', 'krm@ganeshshah.com'));
    }

    /**
     * Send 6-digit verification code for new user registration
     */
    public function sendVerificationOtp(string $to, string $name, string $otp): bool
    {
        $subject = "Your KRM Verification Code: {$otp}";
        $html = $this->renderOtpTemplate(
            title: "Verify Your KRM Account",
            greeting: "Hello, {$name}!",
            message: "Thank you for registering your retail business with KRM Kirana Management. Please use the 6-digit verification code below to verify your email address and activate your shop:",
            otp: $otp,
            expiryMinutes: 15,
            note: "If you did not request this verification code, please ignore this email or contact support."
        );

        return $this->sendEmail($to, $subject, $html);
    }

    /**
     * Send Password Reset OTP
     */
    public function sendPasswordResetOtp(string $to, string $name, string $otp): bool
    {
        $subject = "KRM Password Reset Code: {$otp}";
        $html = $this->renderOtpTemplate(
            title: "Reset Your KRM Password",
            greeting: "Hello, {$name}!",
            message: "We received a request to reset the password for your KRM account. Enter the 6-digit code below to set a new password:",
            otp: $otp,
            expiryMinutes: 15,
            note: "For your security, never share this code with anyone. If you did not initiate this request, your account is still secure and no changes were made."
        );

        return $this->sendEmail($to, $subject, $html);
    }

    /**
     * Send Welcome Onboarding Email
     */
    public function sendWelcomeEmail(string $to, string $name, string $shopName): bool
    {
        $subject = "Welcome to KRM Retail Management, {$name}!";
        $html = <<<HTML
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Welcome to KRM</title>
</head>
<body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background-color: #f8fafc; margin: 0; padding: 30px 10px;">
  <div style="max-width: 540px; margin: 0 auto; background: #ffffff; border-radius: 16px; border: 1px solid #e2e8f0; overflow: hidden; box-shadow: 0 4px 12px rgba(0,0,0,0.03);">
    <div style="background: linear-gradient(135deg, #0284c7 0%, #0369a1 100%); padding: 32px 24px; text-align: center; color: #ffffff;">
      <h1 style="margin: 0; font-size: 24px; font-weight: 800; letter-spacing: -0.5px;">KRM Retail POS</h1>
      <p style="margin: 6px 0 0 0; font-size: 14px; opacity: 0.9;">Store Setup Complete</p>
    </div>
    <div style="padding: 32px 28px; color: #1e293b; line-height: 1.6;">
      <h2 style="margin: 0 0 12px 0; font-size: 18px; color: #0f172a;">Welcome, {$name}! 👋</h2>
      <p style="margin: 0 0 16px 0; font-size: 14px; color: #475569;">
        Your retail shop <strong style="color: #0284c7;">{$shopName}</strong> has been successfully registered on KRM POS.
      </p>
      <div style="background: #f1f5f9; border-radius: 12px; padding: 18px; margin: 20px 0;">
        <p style="margin: 0 0 8px 0; font-size: 13px; font-weight: bold; color: #334155;">What you can do right away:</p>
        <ul style="margin: 0; padding-left: 20px; font-size: 13px; color: #475569;">
          <li>Add products with Barcode scanning and image upload</li>
          <li>Fast POS checkout with cash, QR code, and Udhar support</li>
          <li>Print 58mm/80mm thermal receipts & A4 barcode sticker sheets</li>
          <li>Track customer credit khata and supplier payments</li>
        </ul>
      </div>
      <p style="margin: 24px 0 0 0; font-size: 13px; color: #64748b;">
        Need help? Contact support directly via your account settings.
      </p>
    </div>
    <div style="background: #f8fafc; border-top: 1px solid #e2e8f0; padding: 16px 24px; text-align: center; font-size: 11.5px; color: #94a3b8;">
      &copy; 2026 KRM Kirana & Retail Management System &bull; ganeshshah.com
    </div>
  </div>
</body>
</html>
HTML;

        return $this->sendEmail($to, $subject, $html);
    }

    /**
     * Dispatch email to Resend API
     */
    protected function sendEmail(string $to, string $subject, string $html): bool
    {
        try {
            $response = Http::withToken($this->apiKey)
                ->acceptJson()
                ->post($this->apiUrl, [
                    'from' => "KRM POS <{$this->fromEmail}>",
                    'to' => [$to],
                    'subject' => $subject,
                    'html' => $html,
                ]);

            if ($response->successful()) {
                Log::info("Resend Email successfully sent to {$to}: {$subject}");
                return true;
            }

            Log::error("Resend Email failed to {$to}: Status {$response->status()} - {$response->body()}");
            return false;
        } catch (\Throwable $e) {
            Log::error("Resend API Exception while sending to {$to}: {$e->getMessage()}");
            return false;
        }
    }

    /**
     * Helper to render branded OTP HTML
     */
    protected function renderOtpTemplate(
        string $title,
        string $greeting,
        string $message,
        string $otp,
        int $expiryMinutes,
        string $note
    ): string {
        return <<<HTML
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>{$title}</title>
</head>
<body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background-color: #f8fafc; margin: 0; padding: 30px 10px;">
  <div style="max-width: 520px; margin: 0 auto; background: #ffffff; border-radius: 16px; border: 1px solid #e2e8f0; overflow: hidden; box-shadow: 0 4px 14px rgba(0,0,0,0.03);">
    <!-- Header -->
    <div style="background: linear-gradient(135deg, #0284c7 0%, #0369a1 100%); padding: 30px 24px; text-align: center; color: #ffffff;">
      <h1 style="margin: 0; font-size: 22px; font-weight: 800; letter-spacing: -0.5px;">KRM Kirana & POS</h1>
      <p style="margin: 4px 0 0 0; font-size: 13px; opacity: 0.9;">{$title}</p>
    </div>
    
    <!-- Body -->
    <div style="padding: 32px 28px; color: #1e293b; line-height: 1.6;">
      <h2 style="margin: 0 0 10px 0; font-size: 17px; color: #0f172a;">{$greeting}</h2>
      <p style="margin: 0 0 24px 0; font-size: 13.5px; color: #475569;">{$message}</p>
      
      <!-- OTP Box -->
      <div style="background: #f0fdf4; border: 1.5px dashed #22c55e; border-radius: 12px; padding: 20px; text-align: center; margin: 24px 0;">
        <span style="font-family: 'Courier New', Courier, monospace; font-size: 36px; font-weight: 900; letter-spacing: 10px; color: #15803d; display: inline-block;">{$otp}</span>
        <p style="margin: 8px 0 0 0; font-size: 12px; color: #16a34a; font-weight: 600;">Valid for {$expiryMinutes} minutes</p>
      </div>
      
      <p style="margin: 20px 0 0 0; font-size: 12px; color: #64748b; font-style: italic;">{$note}</p>
    </div>
    
    <!-- Footer -->
    <div style="background: #f8fafc; border-top: 1px solid #e2e8f0; padding: 16px 24px; text-align: center; font-size: 11px; color: #94a3b8;">
      This email was sent from <strong>{$this->fromEmail}</strong> for your KRM account.<br>
      &copy; 2026 KRM Kirana & Retail Management System
    </div>
  </div>
</body>
</html>
HTML;
    }
}

