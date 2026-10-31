<?php

namespace App\Http\Controllers\Api;

use App\Models\CustomerLedger;
use App\Models\Sale;
use App\Models\SupplierLedger;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;

class TransactionController extends BaseApiController
{
    /**
     * Unified transactions feed across Sales, Udhar collections, and Supplier purchases.
     */
    public function index(Request $request): JsonResponse
    {
        $limit = $request->integer('limit', 50);

        // Fetch sales with items
        $sales = Sale::with(['customer', 'items'])
            ->orderByDesc('created_at')
            ->limit($limit)
            ->get()
            ->map(function ($s) {
                return [
                    'id' => $s->id,
                    'receipt_number' => $s->receipt_number,
                    'title' => 'Sale #'.$s->receipt_number,
                    'party_name' => $s->customer?->name ?? 'Walk-in Customer',
                    'party_phone' => $s->customer?->phone ?? '',
                    'category' => $s->payment_status === 'CREDIT' ? 'creditSale' : 'sale',
                    'amount' => (float) $s->grand_total,
                    'subtotal' => (float) $s->subtotal,
                    'discount_amount' => (float) $s->discount_amount,
                    'tax_amount' => (float) $s->tax_amount,
                    'cash_received' => (float) $s->cash_received,
                    'change_returned' => (float) $s->change_returned,
                    'udhar_amount' => (float) $s->udhar_amount,
                    'payment_method' => $s->primary_payment_method,
                    'status' => $s->payment_status,
                    'is_inflow' => true,
                    'timestamp' => $s->created_at->toIso8601String(),
                    'items' => $s->items->map(function ($it) {
                        return [
                            'name' => $it->product_name,
                            'product_name' => $it->product_name,
                            'quantity' => (float) $it->quantity,
                            'unit' => $it->unit_name ?? 'pkt',
                            'unit_price' => (float) $it->unit_price,
                            'total' => (float) $it->total_price,
                        ];
                    })->values()->all(),
                ];
            });

        // Fetch udhar settlements
        $udharSettlements = CustomerLedger::with('customer')
            ->where('transaction_type', 'PAYMENT_RECEIVED')
            ->orderByDesc('created_at')
            ->limit($limit)
            ->get()
            ->map(function ($l) {
                return [
                    'id' => $l->id,
                    'receipt_number' => $l->reference_no ?? 'RCT-'.substr($l->id, 0, 6),
                    'title' => 'Udhar Payment Received',
                    'party_name' => $l->customer?->name ?? 'Customer',
                    'party_phone' => $l->customer?->phone ?? '',
                    'category' => 'udharPayment',
                    'amount' => (float) $l->amount,
                    'payment_method' => $l->payment_method ?? 'Cash',
                    'status' => 'PAID',
                    'is_inflow' => true,
                    'timestamp' => $l->created_at->toIso8601String(),
                ];
            });

        // Fetch supplier purchases
        $purchases = SupplierLedger::with('supplier')
            ->where('transaction_type', 'PURCHASE_BILL')
            ->orderByDesc('created_at')
            ->limit($limit)
            ->get()
            ->map(function ($p) {
                return [
                    'id' => $p->id,
                    'receipt_number' => $p->reference_no ?? 'PB-'.substr($p->id, 0, 6),
                    'title' => 'Purchase Bill #'.($p->reference_no ?? 'PB-01'),
                    'party_name' => $p->supplier?->name ?? 'Supplier',
                    'party_phone' => $p->supplier?->phone ?? '',
                    'category' => 'purchase',
                    'amount' => (float) $p->amount,
                    'payment_method' => $p->payment_method ?? 'Bank Transfer',
                    'status' => 'PAID',
                    'is_inflow' => false,
                    'timestamp' => $p->created_at->toIso8601String(),
                ];
            });

        // Merge and sort chronologically
        $all = $sales->concat($udharSettlements)->concat($purchases)
            ->sortByDesc('timestamp')
            ->values()
            ->take($limit);

        // Compute summary metrics
        $inflow = $all->where('is_inflow', true)->sum('amount');
        $outflow = $all->where('is_inflow', false)->sum('amount');

        return $this->success([
            'summary' => [
                'total_inflow' => $inflow,
                'total_outflow' => $outflow,
                'net_turnover' => $inflow - $outflow,
            ],
            'transactions' => $all,
        ]);
    }
}

