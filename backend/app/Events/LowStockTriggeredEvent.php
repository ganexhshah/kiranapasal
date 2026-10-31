<?php

namespace App\Events;

use App\Models\Product;
use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class LowStockTriggeredEvent implements ShouldBroadcastNow
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public function __construct(
        public Product $product
    ) {}

    public function broadcastOn(): array
    {
        return [
            new PrivateChannel('shop.'.$this->product->shop_id),
        ];
    }

    public function broadcastAs(): string
    {
        return 'stock.low_alert';
    }

    public function broadcastWith(): array
    {
        return [
            'product_id' => $this->product->id,
            'name' => $this->product->name,
            'sku' => $this->product->sku,
            'current_stock' => (float) $this->product->stock_quantity,
            'threshold' => (float) $this->product->low_stock_threshold,
            'unit' => $this->product->selling_unit,
            'is_out_of_stock' => $this->product->stock_quantity <= 0,
        ];
    }
}

