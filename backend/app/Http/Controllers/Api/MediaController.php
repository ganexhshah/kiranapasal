<?php

namespace App\Http\Controllers\Api;

use App\Services\CloudflareR2Service;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class MediaController extends BaseApiController
{
    public function __construct(
        protected CloudflareR2Service $r2Service
    ) {}

    /**
     * Upload an image file directly to Cloudflare R2 bucket (protofilo).
     */
    public function uploadImage(Request $request): JsonResponse
    {
        $request->validate([
            'image' => ['required', 'image', 'max:10240'], // 10MB max
        ]);

        $file = $request->file('image');
        $shopId = app('current_shop_id');

        $url = $this->r2Service->uploadProductImage($file, $shopId);

        return $this->success([
            'url' => $url,
            'filename' => $file->getClientOriginalName(),
            'size' => $file->getSize(),
        ], 'Image uploaded successfully to Cloudflare R2.');
    }

    /**
     * Get presigned upload URL for direct client-to-R2 upload.
     */
    public function presignedUpload(Request $request): JsonResponse
    {
        $request->validate([
            'filename' => ['required', 'string'],
        ]);

        $shopId = app('current_shop_id');
        $result = $this->r2Service->getPresignedUploadUrl($shopId, $request->input('filename'));

        return $this->success($result, 'Presigned upload URL generated.');
    }
}

