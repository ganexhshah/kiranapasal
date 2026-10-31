<?php

namespace App\Events;

use App\Models\Sale;
use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class SaleCreatedEvent implements ShouldBroadcastNow
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public function __construct(
        public Sale $sale
    ) {}

    public function broadcastOn(): array
    {
        return [
            new PrivateChannel('shop.'.$this->sale->shop_id),
            new PrivateChannel('pos-terminal.'.$this->sale->shop_id),
        ];
    }

    public function broadcastAs(): string
    {
        return 'sale.created';
    }

    public function broadcastWith(): array
    {
        return [
            'id' => $this->sale->id,
            'receipt_number' => $this->sale->receipt_number,
            'customer_name' => $this->sale->customer?->name ?? 'Walk-in Customer',
            'grand_total' => (float) $this->sale->grand_total,
            'payment_method' => $this->sale->primary_payment_method,
            'items_count' => $this->sale->items_count,
            'timestamp' => $this->sale->created_at->toIso8601String(),
        ];
    }
}

