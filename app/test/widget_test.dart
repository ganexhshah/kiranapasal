import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:app/core/repositories/app_data_repository.dart';
import 'package:app/features/dashboard/dashboard.dart';
import 'package:app/features/products/domain/models/product.dart';
import 'package:app/features/sales/sales.dart';
import 'package:app/features/parties/parties.dart';
import 'package:app/main.dart';

void main() {
  testWidgets('Dashboard loads with all components: header, actions, sales card, stats, transactions, and bottom nav', (WidgetTester tester) async {
    AppDataRepository.instance.setProductsForTesting([
      const Product(
        id: 'p1',
        name: 'Basmati Rice',
        category: 'Grains',
        sku: 'RICE-01',
        price: 100,
        priceUnit: 'kg',
        stock: 25,
        stockUnit: 'kg',
      ),
      const Product(
        id: 'p2',
        name: 'Sunflower Oil',
        category: 'Oils',
        sku: 'OIL-01',
        price: 220,
        priceUnit: 'ltr',
        stock: 15,
        stockUnit: 'ltr',
      ),
      const Product(
        id: 'p3',
        name: 'Maggi Noodles',
        category: 'Snacks',
        sku: 'MAG-01',
        price: 25,
        priceUnit: 'pkt',
        stock: 5,
        stockUnit: 'pkt',
        lowStockThreshold: 10,
      ),
      const Product(
        id: 'p4',
        name: 'Red Label Tea',
        category: 'Beverages',
        sku: 'TEA-01',
        price: 150,
        priceUnit: 'pkt',
        stock: 30,
        stockUnit: 'pkt',
      ),
    ]);

    AppDataRepository.instance.setCustomersForTesting([
      const Customer(
        id: 'c1',
        name: 'Ramesh Sharma',
        phone: '9841234567',
        address: 'Baluwatar, Kathmandu',
        udharBalance: 4500,
        creditLimit: 10000,
      ),
      const Customer(
        id: 'c2',
        name: 'Sita Thapa',
        phone: '9851122334',
        address: 'Patan, Lalitpur',
        udharBalance: 1200,
        creditLimit: 5000,
      ),
    ]);

    AppDataRepository.instance.setSuppliersForTesting([
      const Supplier(
        id: 's1',
        name: 'Nepal Agro Distributors',
        phone: '9851023456',
        address: 'Kalimati, Kathmandu',
        panNumber: '302918273',
        outstandingBalance: 12000,
      ),
    ]);

    AppDataRepository.instance.setTransactionsForTesting([
      FullTransactionModel(
        id: 't1',
        receiptNumber: 'S1024',
        title: 'Sale #S1024',
        subtitle: 'Cash • 3 items',
        partyName: 'Walk-in Customer',
        timestamp: DateTime.now(),
        amount: 320,
        category: TransactionCategory.sale,
        paymentMethod: 'Cash',
      ),
      FullTransactionModel(
        id: 't2',
        receiptNumber: 'S1023',
        title: 'Sale #S1023',
        subtitle: 'Fonepay QR • 1 item',
        partyName: 'Walk-in Customer',
        timestamp: DateTime.now(),
        amount: 150,
        category: TransactionCategory.sale,
        paymentMethod: 'Fonepay QR',
      ),
      FullTransactionModel(
        id: 't3',
        receiptNumber: 'PAY-101',
        title: 'Received from Ram Shrestha',
        subtitle: 'Cash • Udhar In',
        partyName: 'Ram Shrestha',
        timestamp: DateTime.now(),
        amount: 1000,
        category: TransactionCategory.udharPayment,
        paymentMethod: 'Cash',
      ),
      FullTransactionModel(
        id: 't4',
        receiptNumber: 'S1022',
        title: 'Sale #S1022',
        subtitle: 'Cash • 2 items',
        partyName: 'Walk-in Customer',
        timestamp: DateTime.now(),
        amount: 450,
        category: TransactionCategory.sale,
        paymentMethod: 'Cash',
      ),
    ]);

    await tester.pumpWidget(const MyApp(home: DashboardScreen()));
    await tester.pump();

    // Verify Dashboard Screen Components
    // 1. Header (Greeting, Search & Notifications)
    expect(find.text('Hi there!'), findsOneWidget);

    // 2. Quick Actions
    expect(find.text('New Sale'), findsOneWidget);
    expect(find.text('Products'), findsAtLeast(1));
    expect(find.text('Customers'), findsOneWidget);
    expect(find.text('View All'), findsAtLeast(1));

    // 3. Today's Sales Card
    expect(find.text("Today's Sales"), findsOneWidget);
    expect(find.text('Total Sales'), findsOneWidget);
    expect(find.text('Cash'), findsAtLeast(1));
    expect(find.text('Card'), findsAtLeast(1));
    expect(find.text('Udhar'), findsAtLeast(1));

    // 4. Statistics Cards
    expect(find.text('Total Products'), findsOneWidget);
    expect(find.text('Total Customers'), findsOneWidget);
    expect(find.text('Low Stock Items'), findsOneWidget);
    expect(find.text("Today's Bills"), findsOneWidget);

    // 5. Recent Transactions
    expect(find.text('Recent Transactions'), findsOneWidget);
    expect(find.text('Sale #S1024'), findsOneWidget);
    expect(find.text('Sale #S1023'), findsOneWidget);
    expect(find.text('Received from Ram Shrestha'), findsOneWidget);
    expect(find.text('+ Rs. 1000.00'), findsOneWidget);
    expect(find.text('Sale #S1022'), findsOneWidget);

    // 6. Bottom Navigation Bar (5 tabs: Home, Products, Sales, Parties, More)
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Products'), findsAtLeast(1));
    expect(find.text('Sales'), findsAtLeast(1));
    expect(find.text('Parties'), findsOneWidget);
    expect(find.text('More'), findsOneWidget);

    // Tap on navigation item
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();

    // Tap on Products navigation item to open ProductsScreen
    await tester.tap(find.text('Products').last);
    await tester.pumpAndSettle();

    // Verify Products Screen Components
    // 1. Header & Action Icons (Plus & Settings)
    expect(find.text('Products'), findsAtLeast(1));
    expect(find.byIcon(LucideIcons.plus), findsOneWidget);
    expect(find.byIcon(LucideIcons.settings), findsOneWidget);

    // 2. Search Bar
    expect(find.text('Search product name, barcode, or SKU...'), findsOneWidget);

    // 3. Category Filter Chips
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Grains'), findsAtLeast(1));
    expect(find.text('Snacks'), findsAtLeast(1));
    expect(find.text('Beverages'), findsAtLeast(1));
    expect(find.text('Daily Needs'), findsAtLeast(1));

    // 4. Products Table Headers
    expect(find.text('Product'), findsOneWidget);
    expect(find.text('Price'), findsOneWidget);
    expect(find.text('Stock'), findsOneWidget);
    expect(find.text('Action'), findsOneWidget);

    // 5. Products List Items
    expect(find.text('Basmati Rice'), findsOneWidget);
    expect(find.text('Sunflower Oil'), findsOneWidget);
    expect(find.text('Maggi Noodles'), findsOneWidget);
    expect(find.text('Rs. 100'), findsOneWidget);
    expect(find.text('25 kg'), findsOneWidget);
    expect(find.text('5 pkt'), findsOneWidget); // Low stock item

    // 6. Test Filtering: Tap on "Beverages" filter chip
    await tester.tap(find.text('Beverages').first);
    await tester.pumpAndSettle();
    expect(find.text('Red Label Tea'), findsOneWidget);
    expect(find.text('Basmati Rice'), findsNothing);

    // 7. Test Empty State: Search for nonexistent item
    final productSearch = find.widgetWithText(TextField, 'Search product name, barcode, or SKU...');
    await tester.enterText(productSearch, 'NonExistentItemXYZ');
    await tester.pumpAndSettle();
    expect(find.text('No products found'), findsOneWidget);

    // Clear search and reset to 'All'
    await tester.enterText(productSearch, '');
    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();
    expect(find.text('Basmati Rice'), findsOneWidget);

    // 8. Test Add Product Screen navigation
    await tester.tap(find.byIcon(LucideIcons.plus));
    await tester.pumpAndSettle();

    // Verify Add Product Screen elements
    expect(find.text('Add Product'), findsOneWidget);
    expect(find.text('Product Name *'), findsOneWidget);
    expect(find.text('Category *'), findsOneWidget);
    expect(find.text('Selling Price *'), findsOneWidget);
    expect(find.text('Available Stock *'), findsOneWidget);
    expect(find.text('Save Product'), findsOneWidget);

    // Go back to Products Screen
    await tester.tap(find.byIcon(LucideIcons.arrowLeft));
    await tester.pumpAndSettle();
    expect(find.text('Products'), findsAtLeast(1));

    // 9. Test Product Details Screen Navigation by tapping 'Basmati Rice'
    await tester.tap(find.text('Basmati Rice').first);
    await tester.pumpAndSettle();

    // Verify Product Details Screen Components matching mockup
    expect(find.text('Product Details'), findsOneWidget);
    expect(find.text('In Stock'), findsOneWidget);
    expect(find.text('Units & Conversion'), findsOneWidget);
    expect(find.text('1 Bora = 25 kg'), findsOneWidget);
    expect(find.text('kg'), findsAtLeast(1));
    expect(find.text('Current Stock'), findsOneWidget);
    expect(find.text('Low Stock Alert'), findsOneWidget);
    expect(find.text('Stock History'), findsOneWidget);
    expect(find.text('Delete Product'), findsOneWidget);
    expect(find.text('Adjust Stock'), findsAtLeast(1));

    // Test Adjust Stock Sheet opening
    await tester.tap(find.widgetWithText(ElevatedButton, 'Adjust Stock'));
    await tester.pumpAndSettle();
    expect(find.text('Adjust Stock'), findsAtLeast(1));
    expect(find.text('Add Stock'), findsOneWidget);
    expect(find.text('Remove Stock'), findsOneWidget);
    expect(find.text('Updated Stock Preview'), findsOneWidget);

    // Close Adjust Stock Sheet
    await tester.tap(find.byIcon(LucideIcons.x));
    await tester.pumpAndSettle();

    // Test Product Actions Sheet
    await tester.tap(find.byIcon(LucideIcons.moreVertical).first);
    await tester.pumpAndSettle();
    expect(find.text('Manage Selling Units'), findsOneWidget);
    expect(find.text('View Stock History'), findsOneWidget);

    // Close actions sheet by tapping outside or back
    await tester.tap(find.text('View Stock History'));
    await tester.pumpAndSettle();

    // Pop Product Details Screen back to Products Screen
    await tester.tap(find.byIcon(LucideIcons.arrowLeft));
    await tester.pumpAndSettle();
    expect(find.text('Products'), findsAtLeast(1));

    // 10. Test Sales / POS Screen Navigation via Bottom Nav
    await tester.tap(find.text('Sales'));
    await tester.pumpAndSettle();

    // Verify Sales / POS Screen elements
    expect(find.text('POS - New Sale'), findsOneWidget);
    expect(find.text('Search product name, SKU or scan barcode...'), findsOneWidget);
    expect(find.text('Grains'), findsOneWidget);
    expect(find.text('Sunflower Oil'), findsOneWidget);
    expect(find.text('Maggi Noodles'), findsOneWidget);

    // Tap on Basmati Rice POS card to open AddToSaleSheet
    await tester.tap(find.text('Basmati Rice').first);
    await tester.pumpAndSettle();
    expect(find.text('Selling Unit'), findsOneWidget);
    expect(find.text('Add to Cart'), findsOneWidget);

    // Add to cart
    await tester.tap(find.text('Add to Cart'));
    await tester.pumpAndSettle();

    // Cart Bottom Bar should appear
    expect(find.text('1 item in cart'), findsOneWidget);
    expect(find.text('Checkout'), findsOneWidget);

    // Open Checkout Sheet
    await tester.tap(find.text('Checkout'));
    await tester.pumpAndSettle();
    expect(find.text('Total Payable'), findsOneWidget);
    expect(find.text('Proceed to Payment'), findsOneWidget);
    expect(find.text('Add Tax / VAT'), findsOneWidget);
    expect(find.text('Add Charges'), findsOneWidget);
    expect(find.text('Add Item'), findsOneWidget);
    // There is a clear cart trash icon in header and a single item delete trash icon
    expect(find.byIcon(LucideIcons.trash2), findsAtLeast(2));
    expect(find.byIcon(LucideIcons.info), findsAtLeast(1));

    // Test Total Amount Breakdown Sheet
    await tester.tap(find.byIcon(LucideIcons.info));
    await tester.pumpAndSettle();
    expect(find.text('Total Amount Breakdown'), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    // Close Checkout Sheet
    await tester.tap(find.byType(CheckoutSheet));
    Navigator.of(tester.element(find.byType(CheckoutSheet))).pop();
    await tester.pumpAndSettle();

    // 11. Test Parties Screen Navigation via Bottom Nav
    await tester.tap(find.text('Parties'));
    await tester.pumpAndSettle();

    // Verify Parties Screen elements
    expect(find.text('Parties'), findsAtLeast(1));
    expect(find.textContaining('Customers'), findsAtLeast(1));
    expect(find.textContaining('Suppliers'), findsAtLeast(1));
    expect(find.text('Ramesh Sharma'), findsOneWidget);

    // Switch to Suppliers filter inside Parties
    await tester.tap(find.textContaining('Suppliers').first);
    await tester.pumpAndSettle();
    expect(find.text('Nepal Agro Distributors'), findsOneWidget);

    // Tap on Supplier card to open Supplier Details Screen
    await tester.tap(find.text('Nepal Agro Distributors'));
    await tester.pumpAndSettle();
    expect(find.text('Outstanding Payable (To Pay)'), findsOneWidget);
    expect(find.text('Pay Supplier'), findsOneWidget);
    expect(find.text('Record Bill'), findsOneWidget);
    // Pop back to Parties Screen
    await tester.tap(find.byIcon(LucideIcons.arrowLeft));
    await tester.pumpAndSettle();

    // Switch back to All/Customers to test Customer Details
    await tester.tap(find.textContaining('All').first);
    await tester.pumpAndSettle();
    expect(find.text('Ramesh Sharma'), findsOneWidget);
    await tester.tap(find.text('Ramesh Sharma'));
    await tester.pumpAndSettle();
    expect(find.text('Total Udhar Due (To Collect)'), findsOneWidget);
    expect(find.text('Receive Payment'), findsOneWidget);
    expect(find.text('Give Udhar'), findsOneWidget);
    // Pop back to Parties Screen
    await tester.tap(find.byIcon(LucideIcons.arrowLeft));
    await tester.pumpAndSettle();

    // Test Plus Icon Add Party Sheet
    await tester.tap(find.byIcon(LucideIcons.plus).first);
    await tester.pumpAndSettle();
    expect(find.text('Add Customer or Supplier'), findsOneWidget);
    expect(find.text('Add Customer'), findsOneWidget);
    expect(find.text('Add Supplier'), findsOneWidget);
    expect(find.text('Import from Contacts'), findsOneWidget);
    Navigator.of(tester.element(find.text('Add Customer or Supplier'))).pop();
    await tester.pumpAndSettle();

    // Test Gear Icon Settings Sheet
    await tester.tap(find.byIcon(LucideIcons.settings).last);
    await tester.pumpAndSettle();
    expect(find.text('Parties & Ledger Actions'), findsOneWidget);
    Navigator.of(tester.element(find.text('Parties & Ledger Actions'))).pop();
    await tester.pumpAndSettle();

    // 12. Test More Screen Navigation via Bottom Nav
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();

    // Verify More Screen elements
    expect(find.text('More'), findsAtLeast(1));
    expect(find.textContaining('Kirana Store'), findsOneWidget);
    expect(find.text('Business Operations'), findsOneWidget);
    expect(find.text('Customers Directory'), findsOneWidget);
    expect(find.text('Credit & Udhar Khata'), findsOneWidget);
    expect(find.text('Suppliers & Purchases'), findsOneWidget);
    expect(find.text('Shop Expenses'), findsOneWidget);
    expect(find.text('Settings & Preferences'), findsOneWidget);
    expect(find.text('Log Out'), findsOneWidget);

    // 12. Test Customers Screen Navigation & Contact Picker
    await tester.tap(find.text('Customers Directory'));
    await tester.pumpAndSettle();
    expect(find.text('Customers'), findsAtLeast(1));
    expect(find.text('Total Udhar Due'), findsOneWidget);
    expect(find.text('Ramesh Sharma'), findsOneWidget);
    expect(find.text('Sita Thapa'), findsOneWidget);

    // Test Pick Contact Sheet
    await tester.tap(find.byIcon(LucideIcons.contactRound).first);
    await tester.pumpAndSettle();
    expect(find.text('Select Contact'), findsOneWidget);
    expect(find.text('Aayush Karki'), findsOneWidget);
    // Tap to select contact
    await tester.tap(find.text('Aayush Karki'));
    await tester.pumpAndSettle();
    // Add customer sheet opened with prefilled contact name
    expect(find.text('Add Customer'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // Pop back to More Screen
    await tester.tap(find.byIcon(LucideIcons.arrowLeft));
    await tester.pumpAndSettle();

    // 13. Test Credit & Udhar Khata Screen Navigation
    await tester.tap(find.text('Credit & Udhar Khata'));
    await tester.pumpAndSettle();
    expect(find.text('Credit & Udhar Khata'), findsOneWidget);
    expect(find.textContaining('To Collect'), findsOneWidget);
    expect(find.textContaining('To Pay'), findsOneWidget);
    expect(find.text('Ramesh Sharma'), findsOneWidget);
    expect(find.text('Receive Payment'), findsAtLeast(1));

    // Pop back to More Screen
    await tester.tap(find.byIcon(LucideIcons.arrowLeft));
    await tester.pumpAndSettle();

    // 14. Test Suppliers Screen Navigation
    await tester.tap(find.text('Suppliers & Purchases'));
    await tester.pumpAndSettle();
    expect(find.text('Suppliers'), findsAtLeast(1));
    expect(find.text('Total Payable'), findsOneWidget);
    expect(find.text('Nepal Agro Distributors'), findsOneWidget);
    expect(find.text('Purchase'), findsAtLeast(1));

    // Pop back to More Screen
    await tester.tap(find.byIcon(LucideIcons.arrowLeft));
    await tester.pumpAndSettle();

    // 15. Test Notifications Screen & Tabs Navigation
    await tester.tap(find.byIcon(LucideIcons.bell));
    await tester.pumpAndSettle();

    // Verify Notifications Screen
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Stock Alerts'), findsOneWidget);
    expect(find.text('Sales & Udhar'), findsOneWidget);
    expect(find.text('System'), findsOneWidget);

    // Switch to 'Stock Alerts' tab
    await tester.tap(find.text('Stock Alerts'));
    await tester.pumpAndSettle();
    expect(find.text('Low Stock: Maggi Noodles'), findsOneWidget);

    // Switch to 'Sales & Udhar' tab
    await tester.tap(find.text('Sales & Udhar'));
    await tester.pumpAndSettle();
    expect(find.text('Pending Udhar: Ramesh Sharma'), findsOneWidget);

    // Switch to 'System' tab
    await tester.tap(find.text('System'));
    await tester.pumpAndSettle();
    expect(find.text('No notifications'), findsOneWidget);

    // Test Mark all read
    if (find.text('Mark all read').evaluate().isNotEmpty) {
      await tester.tap(find.text('Mark all read'));
      await tester.pumpAndSettle();
    }

    // Pop back to More Screen
    await tester.tap(find.byIcon(LucideIcons.arrowLeft));
    await tester.pumpAndSettle();
    expect(find.text('More'), findsAtLeast(1));
  });

  testWidgets('PartyDetailsScreen renders customer ledger details properly', (WidgetTester tester) async {
    const testCustomer = Customer(
      id: 'test_c1',
      name: 'Hari Bahadur',
      phone: '9841112233',
      address: 'Jawalakhel, Lalitpur',
      udharBalance: 2400,
      creditLimit: 12000,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: PartyDetailsScreen.customer(testCustomer),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Customer Profile & Balance
    expect(find.text('Hari Bahadur'), findsAtLeast(1));
    expect(find.text('9841112233'), findsOneWidget);
    expect(find.text('Customer'), findsOneWidget);
    expect(find.text('Total Udhar Due (To Collect)'), findsOneWidget);
    expect(find.text('Rs. 2400'), findsOneWidget);
    expect(find.text('Receive Payment'), findsOneWidget);
    expect(find.text('Give Udhar'), findsOneWidget);
    expect(find.text('Ledger Statement'), findsOneWidget);
  });

  testWidgets('PartyDetailsScreen renders supplier ledger details properly', (WidgetTester tester) async {
    const testSupplier = Supplier(
      id: 'test_s1',
      name: 'Kathmandu Cold Store',
      phone: '01-4433221',
      address: 'Kalimati, Kathmandu',
      panNumber: '609876543',
      outstandingBalance: 8500,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: PartyDetailsScreen.supplier(testSupplier),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Supplier Profile & Balance
    expect(find.text('Kathmandu Cold Store'), findsAtLeast(1));
    expect(find.text('PAN: 609876543'), findsOneWidget);
    expect(find.text('Supplier'), findsOneWidget);
    expect(find.text('Outstanding Payable (To Pay)'), findsOneWidget);
    expect(find.text('Rs. 8500'), findsOneWidget);
    expect(find.text('Pay Supplier'), findsOneWidget);
    expect(find.text('Record Bill'), findsOneWidget);
  });
}
