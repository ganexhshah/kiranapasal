<?php

namespace App\Events;

use App\Models\Customer;
use App\Models\CustomerLedger;
use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class UdharPaymentReceivedEvent implements ShouldBroadcastNow
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public function __construct(
        public Customer $customer,
        public CustomerLedger $ledger
    ) {}

    public function broadcastOn(): array
    {
        return [
            new PrivateChannel('shop.'.$this->customer->shop_id),
        ];
    }

    public function broadcastAs(): string
    {
        return 'udhar.payment_received';
    }

    public function broadcastWith(): array
    {
        return [
            'customer_id' => $this->customer->id,
            'customer_name' => $this->customer->name,
            'amount_paid' => (float) $this->ledger->amount,
            'remaining_balance' => (float) $this->customer->outstanding_udhar,
            'payment_method' => $this->ledger->payment_method,
            'reference_no' => $this->ledger->reference_no,
        ];
    }
}

