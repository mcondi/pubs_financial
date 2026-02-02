import 'package:flutter_riverpod/flutter_riverpod.dart';

class LatestNotification {
  final String title;
  final String body;
  final DateTime receivedAt;

  LatestNotification({
    required this.title,
    required this.body,
    required this.receivedAt,
  });
}

final latestNotificationProvider =
    StateProvider<LatestNotification?>((ref) => null);
void clearLatestNotification(WidgetRef ref) {
  ref.read(latestNotificationProvider.notifier).state = null;
}
