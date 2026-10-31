import '../../../../core/utils/parse_utils.dart';

/// Supplier model representing wholesale inventory distributors.
class Supplier {
  final String id;
  final String name;
  final String phone;
  final String address;
  final String panNumber;
  final double outstandingBalance;

  const Supplier({
    required this.id,
    required this.name,
    required this.phone,
    this.address = '',
    this.panNumber = '',
    this.outstandingBalance = 0,
  });

  Supplier copyWith({
    String? id,
    String? name,
    String? phone,
    String? address,
    String? panNumber,
    double? outstandingBalance,
  }) {
    return Supplier(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      panNumber: panNumber ?? this.panNumber,
      outstandingBalance: outstandingBalance ?? this.outstandingBalance,
    );
  }

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      panNumber: json['pan_number']?.toString() ??
          json['panNumber']?.toString() ??
          '',
      outstandingBalance: parseDouble(
        json['current_outstanding_balance'] ?? json['outstandingBalance'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'address': address,
      'pan_number': panNumber,
    };
  }
}

