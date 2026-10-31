<?php

namespace App\Http\Controllers\Api;

use App\Models\Payment;
use App\Models\Supplier;
use App\Models\SupplierLedger;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpFoundation\Response;

class SupplierController extends BaseApiController
{
    public function index(Request $request): JsonResponse
    {
        $query = Supplier::orderBy('name');

        if ($request->filled('search')) {
            $s = $request->query('search');
            $query->where(function ($q) use ($s) {
                $q->where('name', 'ILIKE', "%{$s}%")
                    ->orWhere('company_name', 'ILIKE', "%{$s}%")
                    ->orWhere('phone', 'ILIKE', "%{$s}%");
            });
        }

        $suppliers = $query->paginate($request->integer('per_page', 25));

        return $this->success($suppliers);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:150'],
            'company_name' => ['nullable', 'string', 'max:150'],
            'phone' => ['required', 'string', 'max:25'],
            'pan_number' => ['nullable', 'string', 'max:30'],
            'address' => ['nullable', 'string'],
        ]);

        $supplier = Supplier::create($validated);

        return $this->success($supplier, 'Supplier registered successfully.', Response::HTTP_CREATED);
    }

    public function show(string $id): JsonResponse
    {
        $supplier = Supplier::with(['ledgers' => function ($q) {
            $q->orderByDesc('created_at')->limit(30);
        }])->findOrFail($id);

        return $this->success($supplier);
    }

    public function update(Request $request, string $id): JsonResponse
    {
        $validated = $request->validate([
            'name' => ['sometimes', 'string', 'max:150'],
            'company_name' => ['nullable', 'string', 'max:150'],
            'phone' => ['sometimes', 'string', 'max:25'],
            'pan_number' => ['nullable', 'string', 'max:30'],
            'address' => ['nullable', 'string'],
        ]);

        $supplier = Supplier::findOrFail($id);
        $supplier->update($validated);

        return $this->success($supplier, 'Supplier updated successfully.');
    }

    public function getLedger(string $id): JsonResponse
    {
        $ledgers = SupplierLedger::where('supplier_id', $id)
            ->orderByDesc('created_at')
            ->paginate(30);

        return $this->success($ledgers);
    }

    public function recordPayment(Request $request, string $id): JsonResponse
    {
        $validated = $request->validate([
            'amount' => ['required', 'numeric', 'min:1'],
            'payment_method' => ['required', 'string', 'in:Cash,Bank_Transfer,Cheque,Fonepay_QR'],
            'reference_no' => ['nullable', 'string', 'max:60'],
            'note' => ['nullable', 'string', 'max:255'],
        ]);

        $result = DB::transaction(function () use ($id, $validated, $request) {
            $supplier = Supplier::lockForUpdate()->findOrFail($id);

            $payAmt = (float) $validated['amount'];
            $newBalance = max(0, (float) $supplier->outstanding_payable - $payAmt);

            $supplier->update(['outstanding_payable' => $newBalance]);

            $ref = $validated['reference_no'] ?? 'PAY-'.str_pad((string) (SupplierLedger::count() + 890), 4, '0', STR_PAD_LEFT);

            $ledger = SupplierLedger::create([
                'shop_id' => $supplier->shop_id,
                'supplier_id' => $supplier->id,
                'transaction_type' => 'PAYMENT_MADE',
                'reference_no' => $ref,
                'amount' => $payAmt,
                'balance_after' => $newBalance,
                'payment_method' => $validated['payment_method'],
                'recorded_by' => $request->user()?->id,
                'note' => $validated['note'] ?? 'Supplier bill settlement',
            ]);

            Payment::create([
                'shop_id' => $supplier->shop_id,
                'payable_type' => SupplierLedger::class,
                'payable_id' => $ledger->id,
                'payment_method' => $validated['payment_method'],
                'amount' => $payAmt,
                'transaction_reference' => $ref,
                'received_by' => $request->user()?->id,
            ]);

            return [
                'supplier' => $supplier,
                'ledger' => $ledger,
            ];
        });

        return $this->success($result, 'Supplier payment recorded successfully.');
    }
}

