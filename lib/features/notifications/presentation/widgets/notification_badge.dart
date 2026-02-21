import 'package:flutter/material.dart';

/// Req 9: Unread alert count badge.
class NotificationBadge extends StatelessWidget {
  const NotificationBadge({super.key, required this.count, this.child});

  final int count;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return child ?? const SizedBox.shrink();
    return Badge(
      label: Text(count > 99 ? '99+' : '$count'),
      child: child ?? const Icon(Icons.notifications),
    );
  }
}
