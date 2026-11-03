import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/sales/presentation/screens/today_bills_screen.dart';
import 'package:app/features/sales/presentation/sheets/bill_date_picker_sheet.dart';

void main() {
  testWidgets('TodayBillsScreen renders cleanly with date action and filter chips', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TodayBillsScreen(),
      ),
    );
    await tester.pump();

    // Verify header and date picker button exist
    expect(find.text("Today's Bills"), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    // Verify payment chips
    expect(find.textContaining('All ('), findsOneWidget);
    expect(find.textContaining('Cash ('), findsOneWidget);
    expect(find.textContaining('Online / QR ('), findsOneWidget);
    expect(find.textContaining('Credit / Udhar ('), findsOneWidget);

    // Verify create new bill CTA button
    expect(find.text('Create New Bill (POS)'), findsOneWidget);
  });

  testWidgets('BillDatePickerSheet renders date preset options and custom date option', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BillDatePickerSheet(selectedDate: DateTime.now()),
        ),
      ),
    );

    expect(find.text('Select Bills Date'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Yesterday'), findsOneWidget);
    expect(find.text('2 Days Ago'), findsOneWidget);
    expect(find.text('3 Days Ago'), findsOneWidget);
    expect(find.text('Choose Custom Date from Calendar'), findsOneWidget);
  });
}
