<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Default Filesystem Disk
    |--------------------------------------------------------------------------
    |
    | Here you may specify the default filesystem disk that should be used
    | by the framework. The "local" disk, as well as a variety of cloud
    | based disks are available to your application for storing files.
    |
    */

    'default' => env('FILESYSTEM_DISK', 'r2'),

    /*
    |--------------------------------------------------------------------------
    | Filesystem Disks
    |--------------------------------------------------------------------------
    |
    | Below you may configure as many filesystem disks as necessary, and you
    | may even configure multiple disks for the same driver. Examples for
    | most supported storage drivers are configured here for reference.
    |
    | Supported drivers: "local", "ftp", "sftp", "s3"
    |
    */

    'disks' => [

        'local' => [
            'driver' => 'local',
            'root' => storage_path('app/private'),
            'serve' => true,
            'throw' => false,
        ],

        'public' => [
            'driver' => 'local',
            'root' => storage_path('app/public'),
            'url' => env('APP_URL').'/storage',
            'visibility' => 'public',
            'throw' => false,
        ],

        // Cloudflare R2 (S3-Compatible Zero-Egress Storage)
        'r2' => [
            'driver' => 's3',
            'key' => env('CLOUDFLARE_R2_ACCESS_KEY_ID', '80077dcf329a6b01c33e2c44b2b31e9b'),
            'secret' => env('CLOUDFLARE_R2_SECRET_ACCESS_KEY', '506cbfc47728c0c24cb2756620e9936fcddd35f0ed9c633102454c6ddb86f2b4'),
            'region' => 'auto',
            'bucket' => env('CLOUDFLARE_R2_BUCKET', 'protofilo'),
            'url' => env('CLOUDFLARE_R2_URL', 'https://ganeshshah.com'),
            'endpoint' => env('CLOUDFLARE_R2_ENDPOINT', 'https://516d4d7c8a274b7f897979999bcb096b.r2.cloudflarestorage.com'),
            'use_path_style_endpoint' => env('CLOUDFLARE_R2_USE_PATH_STYLE_ENDPOINT', true),
            'visibility' => 'public',
            'throw' => false,
        ],

    ],

    /*
    |--------------------------------------------------------------------------
    | Symbolic Links
    |--------------------------------------------------------------------------
    |
    | Here you may configure the symbolic links that will be created when the
    | `storage:link` Artisan command is executed. The array keys should be
    | the locations of the links and the values should be their targets.
    |
    */

    'links' => [
        public_path('storage') => storage_path('app/public'),
    ],

];

