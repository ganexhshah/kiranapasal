import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../theme/theme.dart';

/// Clean pagination bottom loading indicator for infinite-scroll lists and grids.
class AppBottomLoader extends StatelessWidget {
  const AppBottomLoader({
    super.key,
    this.message = 'Loading more...',
    this.hasMore = true,
  });

  final String message;
  final bool hasMore;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (!hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            'All items loaded',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: colors.inputLabel.withValues(alpha: 0.7),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
              ),
            ),
            const Gap(10),
            Text(
              message,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: colors.inputLabel,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

