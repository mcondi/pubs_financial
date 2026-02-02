import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'latest_notification_api.dart';
import 'latest_notification_provider.dart';
import 'notification_dismiss_store.dart';

final refreshLatestNotificationProvider =
    FutureProvider.family.autoDispose<void, String>((ref, userName) async {
  if (userName.trim().isEmpty) return;

  final api = ref.read(latestNotificationApiProvider);
  final dismissStore = ref.read(notificationDismissStoreProvider);

  final latest = await api.fetchLatest(userName: userName);

  // Nothing from server
  if (latest == null) {
    ref.read(latestNotificationProvider.notifier).state = null;
    return;
  }

  // Build a stable identity for this notification
  final latestKey =
      '${latest.receivedAt.toIso8601String()}|${latest.title}|${latest.body}';

  // Read last dismissed notification key
  final dismissedKey = await dismissStore.getLastDismissed();

  // 🚫 User already dismissed this exact notification
  if (dismissedKey == latestKey) {
    return;
  }

  // ✅ New notification → show it
  ref.read(latestNotificationProvider.notifier).state = latest;
});
