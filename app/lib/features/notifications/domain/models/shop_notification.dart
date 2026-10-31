enum NotificationCategory {
  stock,
  sales,
  system,
}

/// Notification domain model representing in-app store alerts and updates.
class ShopNotification {
  final String id;
  final String title;
  final String message;
  final NotificationCategory category;
  final DateTime timestamp;
  final bool isRead;
  final String? actionLabel;

  const ShopNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.category,
    required this.timestamp,
    this.isRead = false,
    this.actionLabel,
  });

  ShopNotification copyWith({
    String? id,
    String? title,
    String? message,
    NotificationCategory? category,
    DateTime? timestamp,
    bool? isRead,
    String? actionLabel,
  }) {
    return ShopNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      category: category ?? this.category,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      actionLabel: actionLabel ?? this.actionLabel,
    );
  }
}

