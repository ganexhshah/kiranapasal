import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/theme/theme.dart';
import 'package:app/features/sales/presentation/screens/transaction_details_screen.dart';
import 'package:app/features/sales/presentation/sheets/cancel_return_bill_sheet.dart';

void main() {
  testWidgets('CancelReturnBillSheet renders tabs, item steppers and reasons properly', (WidgetTester tester) async {
    final testItems = [
      const TransactionDetailItem(
        name: 'Wai Wai Noodles 75g',
        quantity: 3,
        unit: 'pkt',
        rate: 25.0,
        total: 75.0,
      ),
      const TransactionDetailItem(
        name: 'Mustard Oil 1L',
        quantity: 1,
        unit: 'ltr',
        rate: 280.0,
        total: 280.0,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: const [AppColorsExtension.light],
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  CancelReturnBillSheet.show(
                    context,
                    billNumber: 'INV-2611-D1-00001',
                    totalAmount: 355.0,
                    paymentMethod: 'Cash',
                    items: testItems,
                    customerName: 'Shyam Sundar',
                  );
                },
                child: const Text('Open Sheet'),
              );
            },
          ),
        ),
      ),
    );

    // Tap to open sheet
    await tester.tap(find.text('Open Sheet'));
    await tester.pumpAndSettle();

    // Verify Header details
    expect(find.text('Bill #INV-2611-D1-00001'), findsOneWidget);
    expect(find.textContaining('Shyam Sundar'), findsOneWidget);
    expect(find.text('Void Entire Bill'), findsOneWidget);
    expect(find.text('Return Items'), findsOneWidget);

    // Verify Void Tab contents
    expect(find.text('Reason'), findsOneWidget);
    expect(find.text('Customer cancelled'), findsOneWidget);
    expect(find.text('Void Bill'), findsOneWidget);

    // Switch to Return Items Tab
    await tester.tap(find.text('Return Items'));
    await tester.pumpAndSettle();

    // Verify Return Tab contents
    expect(find.text('Wai Wai Noodles 75g'), findsOneWidget);
    expect(find.text('Mustard Oil 1L'), findsOneWidget);
    expect(find.text('Restock items to inventory'), findsOneWidget);
    expect(find.text('Total Refund'), findsOneWidget);
    expect(find.text('Rs. 355'), findsOneWidget);
    expect(find.text('Process Return (Rs. 355)'), findsOneWidget);
  });
}
