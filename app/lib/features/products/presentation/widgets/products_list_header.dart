import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';

/// Reusable table header row for products list with columns: Product, Price, Stock, Actions.
class ProductsListHeader extends StatelessWidget {
  const ProductsListHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final headerStyle = TextStyle(
      fontSize: 11.5,
      fontWeight: FontWeight.w600,
      color: colors.inputLabel,
      letterSpacing: -0.1,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Product Column
          Expanded(
            flex: 4,
            child: Text('Product', style: headerStyle),
          ),

          // Price Column
          Expanded(
            flex: 2,
            child: Text('Price', style: headerStyle),
          ),

          // Stock Column
          Expanded(
            flex: 2,
            child: Text('Stock', style: headerStyle),
          ),

          // Action Column
          SizedBox(
            width: 40,
            child: Text(
              'Action',
              textAlign: TextAlign.end,
              style: headerStyle,
            ),
          ),
        ],
      ),
    );
  }
}

