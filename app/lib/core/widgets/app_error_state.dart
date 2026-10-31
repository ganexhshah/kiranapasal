import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'app_empty_state.dart';

/// Shown when a list could not be loaded because the server/network failed.
///
/// Without this, a backend outage looked identical to a quiet day: every screen
/// rendered zeros or "nothing here" with no way to recover.
class AppErrorState extends StatelessWidget {
  const AppErrorState({
    super.key,
    this.message,
    required this.onRetry,
  });

  /// Optional specific message; defaults to a plain connection explanation.
  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: LucideIcons.wifiOff,
      title: "Couldn't load your data",
      description: message ?? 'Check your connection and try again.',
      actionLabel: 'Try again',
      onActionTap: onRetry,
    );
  }
}
