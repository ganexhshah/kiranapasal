import '../../../../core/utils/parse_utils.dart';

/// Customer model representing a customer for billing and Udhar (credit) ledger.
class Customer {
  final String id;
  final String name;
  final String phone;
  final String address;
  final double udharBalance;
  final double creditLimit;

  const Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.address = '',
    this.udharBalance = 0,
    this.creditLimit = 10000,
  });

  bool get isWalkIn => id == 'walk-in';

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      udharBalance: parseDouble(json['current_udhar_balance'] ?? json['udharBalance']),
      creditLimit: parseDouble(json['credit_limit'] ?? json['creditLimit'], 10000.0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'address': address,
      'credit_limit': creditLimit,
    };
  }

  Customer copyWith({
    String? id,
    String? name,
    String? phone,
    String? address,
    double? udharBalance,
    double? creditLimit,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      udharBalance: udharBalance ?? this.udharBalance,
      creditLimit: creditLimit ?? this.creditLimit,
    );
  }

  static const Customer walkIn = Customer(
    id: 'walk-in',
    name: 'Walk-in Customer',
    phone: '',
    udharBalance: 0,
  );
}

