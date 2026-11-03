import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/core/services/product_settings_service.dart';
import 'package:app/features/products/presentation/screens/product_settings_screen.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ProductSettingsService.instance.init();
  });

  test('ProductSettingsService updates and persists preferences', () async {
    final service = ProductSettingsService.instance;
    expect(service.lowStockThreshold, 5);
    expect(service.defaultUnit, 'pkt');

    await service.updateSettings(
      lowStockThreshold: 12,
      defaultUnit: 'kg',
      priceIncludesTax: false,
      defaultTaxRate: 13.0,
    );

    expect(service.lowStockThreshold, 12);
    expect(service.defaultUnit, 'kg');
    expect(service.priceIncludesTax, false);
    expect(service.defaultTaxRate, 13.0);

    await service.resetToDefaults();
    expect(service.lowStockThreshold, 5);
    expect(service.defaultUnit, 'pkt');
    expect(service.priceIncludesTax, true);
  });

  testWidgets('ProductSettingsScreen renders all configuration sections', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: ProductSettingsScreen(),
      ),
    );
    await tester.pump();

    // Verify header and titles
    expect(find.text('Product Settings'), findsOneWidget);
    expect(find.text('Inventory Snapshot'), findsOneWidget);
    expect(find.text('Stock & Alert Rules'), findsOneWidget);
    expect(find.text('Units, Pricing & Tax'), findsOneWidget);
    expect(find.text('Barcode & Scanning'), findsOneWidget);
    expect(find.text('Catalog Actions'), findsOneWidget);

    // Verify low stock threshold chips
    expect(find.text('3 units'), findsOneWidget);
    expect(find.text('5 units'), findsWidgets);
    expect(find.text('10 units'), findsOneWidget);
    expect(find.text('Custom'), findsOneWidget);

    // Verify quick action tiles
    expect(find.text('Add / Manage Categories'), findsOneWidget);
    expect(find.text('Re-sync Product Catalog'), findsOneWidget);
  });
}
