import 'package:flutter/material.dart';
import '../../../products/presentation/sheets/unit_picker_sheet.dart';

/// Modal bottom sheet allowing selection of a selling unit (kg, gram, litre, packet, piece, bora, etc.).
class SelectSellingUnitSheet {
  static const List<String> defaultSellingUnits = [
    'kg',
    'gram',
    'litre',
    'ml',
    'packet',
    'piece',
    'carton',
    'bora',
    'bottle',
    'box',
  ];

  static Future<String?> show(
    BuildContext context, {
    String? currentUnit,
    List<String> units = defaultSellingUnits,
  }) {
    return UnitPickerSheet.show(
      context,
      title: 'Select Selling Unit',
      units: units,
      selectedUnit: currentUnit,
    );
  }
}

