<?php

namespace App\Services;

use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class CloudflareR2Service
{
    protected string $disk = 'r2';
    protected string $baseUrl;

    public function __construct()
    {
        $this->baseUrl = rtrim(config('filesystems.disks.r2.url', 'https://ganeshshah.com'), '/');
    }

    /**
     * Upload product image or attachment to Cloudflare R2 bucket (protofilo).
     */
    public function uploadProductImage(UploadedFile $file, string $shopId): string
    {
        $extension = $file->getClientOriginalExtension() ?: 'webp';
        $filename = Str::uuid().'.'.$extension;
        $path = "shops/{$shopId}/products/{$filename}";

        Storage::disk($this->disk)->put($path, file_get_contents($file), [
            'visibility' => 'public',
            'mimetype' => $file->getMimeType(),
        ]);

        return "{$this->baseUrl}/{$path}";
    }

    /**
     * Upload an invoice PDF or receipt file to R2.
     */
    public function uploadInvoicePdf(string $pdfContent, string $shopId, string $receiptNumber): string
    {
        $year = now()->format('Y');
        $month = now()->format('m');
        $path = "shops/{$shopId}/invoices/{$year}/{$month}/INV_{$receiptNumber}.pdf";

        Storage::disk($this->disk)->put($path, $pdfContent, [
            'visibility' => 'public',
            'mimetype' => 'application/pdf',
        ]);

        return "{$this->baseUrl}/{$path}";
    }

    /**
     * Delete an object from Cloudflare R2.
     */
    public function delete(string $pathOrUrl): bool
    {
        $relativePath = str_replace($this->baseUrl.'/', '', $pathOrUrl);

        return Storage::disk($this->disk)->delete($relativePath);
    }

    /**
     * Get temporary presigned upload URL for direct client-to-R2 uploads.
     */
    public function getPresignedUploadUrl(string $shopId, string $filename, int $expiryMinutes = 15): array
    {
        $path = "shops/{$shopId}/uploads/{$filename}";

        /** @var \Illuminate\Filesystem\AwsS3V3Adapter $adapter */
        $adapter = Storage::disk($this->disk);
        $client = $adapter->getClient();

        $command = $client->getCommand('PutObject', [
            'Bucket' => config('filesystems.disks.r2.bucket', 'protofilo'),
            'Key' => $path,
            'ACL' => 'public-read',
        ]);

        $request = $client->createPresignedRequest($command, "+{$expiryMinutes} minutes");

        return [
            'upload_url' => (string) $request->getUri(),
            'file_url' => "{$this->baseUrl}/{$path}",
            'path' => $path,
            'expires_in_minutes' => $expiryMinutes,
        ];
    }
}

