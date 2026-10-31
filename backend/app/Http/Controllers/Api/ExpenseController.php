<?php

namespace App\Http\Controllers\Api;

use App\Models\Expense;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class ExpenseController extends BaseApiController
{
    public function index(Request $request): JsonResponse
    {
        $query = Expense::with('recorder')->orderByDesc('expense_date');

        if ($request->filled('category')) {
            $query->where('category', $request->query('category'));
        }

        if ($request->filled('date')) {
            $query->whereDate('expense_date', $request->query('date'));
        }

        $expenses = $query->paginate($request->integer('per_page', 25));

        return $this->success($expenses);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'category' => ['required', 'string', 'max:100'],
            'amount' => ['required', 'numeric', 'min:1'],
            'payment_method' => ['required', 'string', 'in:Cash,Fonepay_QR,Card,Bank_Transfer'],
            'paid_to' => ['nullable', 'string', 'max:120'],
            'receipt_image_url' => ['nullable', 'string', 'url'],
            'note' => ['nullable', 'string'],
            'expense_date' => ['required', 'date'],
        ]);

        $validated['recorded_by'] = $request->user()?->id;

        $expense = Expense::create($validated);

        return $this->success($expense, 'Expense recorded successfully.', Response::HTTP_CREATED);
    }
}

