import 'cart_item.dart';
import 'customer.dart';

enum PaymentMethod {
  cash,
  card,
  qr,
  credit,
  split,
}

/// Represents a completed or drafted POS sale transaction.
class SaleRecord {
  final String id;
  final String receiptNumber;
  final List<CartItem> items;
  final Customer customer;
  final double subtotal;
  final double discountAmount;
  final double taxAmount;
  final double additionalCharges;
  final double totalAmount;
  final PaymentMethod paymentMethod;
  final double cashReceived;
  final double changeReturned;
  final double udharAmount;
  final String note;
  final DateTime timestamp;

  const SaleRecord({
    required this.id,
    required this.receiptNumber,
    required this.items,
    required this.customer,
    required this.subtotal,
    this.discountAmount = 0,
    this.taxAmount = 0,
    this.additionalCharges = 0,
    required this.totalAmount,
    required this.paymentMethod,
    this.cashReceived = 0,
    this.changeReturned = 0,
    this.udharAmount = 0,
    this.note = '',
    required this.timestamp,
  });

  String get paymentMethodName {
    switch (paymentMethod) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.card:
        return 'Card';
      case PaymentMethod.qr:
        return 'QR / Fonepay';
      case PaymentMethod.credit:
        return 'Credit (Udhar)';
      case PaymentMethod.split:
        return 'Split (Cash + Udhar)';
    }
  }
}

