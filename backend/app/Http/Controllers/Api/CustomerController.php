<?php

namespace App\Http\Controllers\Api;

use App\Events\UdharPaymentReceivedEvent;
use App\Models\Customer;
use App\Models\CustomerLedger;
use App\Models\Payment;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpFoundation\Response;

class CustomerController extends BaseApiController
{
    public function index(Request $request): JsonResponse
    {
        $query = Customer::orderBy('name');

        if ($request->filled('search')) {
            $s = $request->query('search');
            $query->where(function ($q) use ($s) {
                $q->where('name', 'ILIKE', "%{$s}%")
                    ->orWhere('phone', 'ILIKE', "%{$s}%");
            });
        }

        if ($request->boolean('udhar_only')) {
            $query->where('outstanding_udhar', '>', 0);
        }

        $customers = $query->paginate($request->integer('per_page', 25));

        return $this->success($customers);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:150'],
            'phone' => ['required', 'string', 'max:25'],
            'address' => ['nullable', 'string'],
            'credit_limit' => ['nullable', 'numeric', 'min:0'],
        ]);

        $existing = Customer::where('phone', $validated['phone'])->first();
        if ($existing) {
            $existing->update($validated);
            return $this->success($existing, 'Customer record retrieved and updated.', Response::HTTP_OK);
        }

        $customer = Customer::create($validated);

        return $this->success($customer, 'Customer registered successfully.', Response::HTTP_CREATED);
    }

    public function show(string $id): JsonResponse
    {
        $customer = Customer::with(['ledgers' => function ($q) {
            $q->orderByDesc('created_at')->limit(30);
        }])->findOrFail($id);

        return $this->success($customer);
    }

    public function update(Request $request, string $id): JsonResponse
    {
        $validated = $request->validate([
            'name' => ['sometimes', 'string', 'max:150'],
            'phone' => ['sometimes', 'string', 'max:25'],
            'address' => ['nullable', 'string'],
            'credit_limit' => ['sometimes', 'numeric', 'min:0'],
        ]);

        $customer = Customer::findOrFail($id);
        $customer->update($validated);

        return $this->success($customer, 'Customer updated successfully.');
    }

    public function getLedger(string $id): JsonResponse
    {
        $ledgers = CustomerLedger::where('customer_id', $id)
            ->orderByDesc('created_at')
            ->paginate(30);

        return $this->success($ledgers);
    }

    public function receivePayment(Request $request, string $id): JsonResponse
    {
        $validated = $request->validate([
            'amount' => ['required', 'numeric', 'min:1'],
            'payment_method' => ['required', 'string', 'in:Cash,Fonepay_QR,Card,Bank_Transfer'],
            'reference_no' => ['nullable', 'string', 'max:60'],
            'note' => ['nullable', 'string', 'max:255'],
        ]);

        $result = DB::transaction(function () use ($id, $validated, $request) {
            $customer = Customer::lockForUpdate()->findOrFail($id);

            $payAmt = (float) $validated['amount'];
            $newBalance = max(0, (float) $customer->outstanding_udhar - $payAmt);

            $customer->update(['outstanding_udhar' => $newBalance]);

            $ref = $validated['reference_no'] ?? 'RCT-'.str_pad((string) (CustomerLedger::count() + 501), 4, '0', STR_PAD_LEFT);

            $ledger = CustomerLedger::create([
                'shop_id' => $customer->shop_id,
                'customer_id' => $customer->id,
                'transaction_type' => 'PAYMENT_RECEIVED',
                'reference_no' => $ref,
                'amount' => $payAmt,
                'balance_after' => $newBalance,
                'payment_method' => $validated['payment_method'],
                'recorded_by' => $request->user()?->id,
                'note' => $validated['note'] ?? 'Udhar payment collected',
            ]);

            Payment::create([
                'shop_id' => $customer->shop_id,
                'payable_type' => CustomerLedger::class,
                'payable_id' => $ledger->id,
                'payment_method' => $validated['payment_method'],
                'amount' => $payAmt,
                'transaction_reference' => $ref,
                'received_by' => $request->user()?->id,
            ]);

            // Broadcast real-time event via Reverb
            try {
                broadcast(new UdharPaymentReceivedEvent($customer, $ledger));
            } catch (\Throwable $e) {
                \Illuminate\Support\Facades\Log::warning('Reverb broadcast skipped: ' . $e->getMessage());
            }

            return [
                'customer' => $customer,
                'ledger' => $ledger,
            ];
        });

        return $this->success($result, 'Payment recorded and ledger balance updated.');
    }
}

