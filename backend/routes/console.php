<?php

use Illuminate\Support\Facades\Schedule;

// Run automated nightly database backup to offsite Cloudflare R2
Schedule::command('backup:run --only-db')
    ->dailyAt('02:00')
    ->timezone('Asia/Kathmandu')
    ->withoutOverlapping();

// Auto-snapshot daily ledger summaries
Schedule::command('krm:snapshot-daily-ledger')
    ->dailyAt('23:59')
    ->timezone('Asia/Kathmandu');

