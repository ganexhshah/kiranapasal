import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/splash/presentation/screens/splash_screen.dart';

void main() {
  testWidgets('SplashScreen renders pasal365 logo, title, and white background', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SplashScreen(
          navigateNext: false,
        ),
      ),
    );

    // Initial frame
    await tester.pump(const Duration(milliseconds: 100));

    // Verify title and subtitle
    expect(find.text('pasal365'), findsOneWidget);
    expect(find.text('Smart Kirana & Retail Management'), findsOneWidget);
    expect(find.text('pasal365 • v1.0.0'), findsOneWidget);

    // Verify white background on Scaffold
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, Colors.white);
  });
}

