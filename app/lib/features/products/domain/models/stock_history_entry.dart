/// Record of stock movement (purchases, sales, damage adjustments, corrections).
class StockHistoryEntry {
  final String id;
  final String title;
  final DateTime timestamp;
  final double changeAmount;
  final String unit;
  final String? secondaryUnitInfo;
  final double balance;
  final bool isAddition;
  final String reason;

  const StockHistoryEntry({
    required this.id,
    required this.title,
    required this.timestamp,
    required this.changeAmount,
    required this.unit,
    this.secondaryUnitInfo,
    required this.balance,
    required this.isAddition,
    required this.reason,
  });

  String get formattedChange {
    final prefix = isAddition ? '+ ' : '- ';
    final isInt = changeAmount.abs() == changeAmount.abs().roundToDouble();
    final amountStr = isInt
        ? changeAmount.abs().toInt().toString()
        : changeAmount.abs().toStringAsFixed(1);
    return '$prefix$amountStr $unit';
  }

  String get formattedBalance {
    final isInt = balance == balance.roundToDouble();
    final balanceStr = isInt ? balance.toInt().toString() : balance.toStringAsFixed(1);
    return '$balanceStr $unit';
  }
}

