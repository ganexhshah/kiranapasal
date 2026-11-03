import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/auth/presentation/screens/login_screen.dart';

void main() {
  testWidgets('LoginScreen displays inputs and Continue with Google button', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LoginScreen(),
      ),
    );

    expect(find.text('Kirana Pasal'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Phone'), findsOneWidget);
  });
}

