import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/sales/presentation/screens/transaction_details_screen.dart';

void main() {
  testWidgets('TransactionDetailsScreen renders without error', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TransactionDetailsScreen(
          receiptNumber: 'REC-001',
          title: 'Sale #REC-001',
          customerName: 'Ram Sharma',
          customerPhone: '9841000000',
          customerAddress: 'Kathmandu',
          timestamp: DateTime.now(),
          items: const [
            TransactionDetailItem(
              name: 'Wai Wai Noodles',
              quantity: 2,
              unit: 'pcs',
              rate: 25,
              total: 50,
            ),
          ],
          subtotal: 50,
          discountAmount: 0,
          taxAmount: 0,
          totalAmount: 50,
          paymentMethod: 'Split (Cash + Udhar)',
          cashReceived: 25,
          udharAmount: 25,
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Receipt'), findsOneWidget);
    expect(find.text('Details'), findsOneWidget);

    // Tap Details tab to trigger rebuild/switch
    await tester.tap(find.text('Details'));
    await tester.pumpAndSettle();
    expect(find.text('Payment Mode'), findsOneWidget);
  });
}
