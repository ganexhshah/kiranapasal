<?php

namespace App\Http\Controllers\Api;

use App\Models\Product;
use App\Models\StockMovement;
use App\Models\Supplier;
use App\Models\SupplierLedger;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpFoundation\Response;

class PurchaseController extends BaseApiController
{
    /**
     * Record supplier purchase order, increment product stock, and record supplier ledger.
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'supplier_id' => ['required', 'uuid', 'exists:suppliers,id'],
            'bill_number' => ['required', 'string', 'max:60'],
            'items' => ['required', 'array', 'min:1'],
            'items.*.product_id' => ['required', 'uuid', 'exists:products,id'],
            'items.*.quantity' => ['required', 'numeric', 'min:0.001'],
            'items.*.unit' => ['required', 'string'],
            'items.*.unit_cost' => ['required', 'numeric', 'min:0'],
            'total_amount' => ['required', 'numeric', 'min:0'],
            'is_paid' => ['required', 'boolean'],
            'payment_method' => ['nullable', 'string', 'in:Cash,Bank_Transfer,Cheque'],
            'note' => ['nullable', 'string'],
        ]);

        $result = DB::transaction(function () use ($validated, $request) {
            $supplier = Supplier::lockForUpdate()->findOrFail($validated['supplier_id']);

            // 1. Increment Stock for every purchased product
            foreach ($validated['items'] as $item) {
                $product = Product::lockForUpdate()->findOrFail($item['product_id']);

                $qty = (float) $item['quantity'];
                $before = (float) $product->stock_quantity;
                $after = $before + $qty;

                $product->update([
                    'stock_quantity' => $after,
                    'purchase_price' => $item['unit_cost'],
                ]);

                StockMovement::create([
                    'shop_id' => $product->shop_id,
                    'product_id' => $product->id,
                    'user_id' => $request->user()?->id,
                    'movement_type' => 'PURCHASE',
                    'quantity' => $qty,
                    'unit' => $item['unit'],
                    'stock_before' => $before,
                    'stock_after' => $after,
                    'reference_type' => 'PurchaseBill',
                    'reason' => 'Inventory restocked from Bill #'.$validated['bill_number'],
                    'note' => $validated['note'] ?? null,
                ]);
            }

            // 2. Record in Supplier Ledger
            $newPayable = $validated['is_paid']
                ? (float) $supplier->outstanding_payable
                : (float) $supplier->outstanding_payable + (float) $validated['total_amount'];

            $supplier->update(['outstanding_payable' => $newPayable]);

            $ledger = SupplierLedger::create([
                'shop_id' => $supplier->shop_id,
                'supplier_id' => $supplier->id,
                'transaction_type' => 'PURCHASE_BILL',
                'reference_no' => $validated['bill_number'],
                'amount' => $validated['total_amount'],
                'balance_after' => $newPayable,
                'payment_method' => $validated['is_paid'] ? ($validated['payment_method'] ?? 'Cash') : 'Credit / Payable',
                'recorded_by' => $request->user()?->id,
                'note' => $validated['note'] ?? 'Bulk inventory restock purchase',
            ]);

            return [
                'supplier' => $supplier,
                'ledger' => $ledger,
            ];
        });

        return $this->success($result, 'Purchase recorded and stock levels updated.', Response::HTTP_CREATED);
    }
}

