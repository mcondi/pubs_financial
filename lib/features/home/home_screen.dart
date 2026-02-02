import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pubs_financial/app/push/latest_notification_provider.dart';
import 'package:pubs_financial/app/push/latest_notification_refresh.dart';
import 'package:pubs_financial/app/push/notification_dismiss_store.dart';
import 'package:pubs_financial/app/push/push_registration_service.dart';


class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  static const background = Color.fromRGBO(7, 32, 64, 1);
  static const cardBlue = Color.fromRGBO(19, 52, 98, 1);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const _debugUserName = 'markcondi'; // TODO: replace with real user
  Timer? _timer;

  // After the user dismisses the banner, pause polling briefly so it doesn't instantly reappear
  DateTime? _suppressRefreshUntil;

  @override
  void initState() {
    super.initState();

    // Initial fetch immediately
   Future.microtask(() async {
  // existing
  ref.invalidate(refreshLatestNotificationProvider(_debugUserName));

  // ✅ add this
  await ref.read(pushRegistrationServiceProvider).registerIfPossible();
});


    // Poll while Home is visible (keeps the "Latest Notification" card fresh)
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      final until = _suppressRefreshUntil;
      if (until != null && DateTime.now().isBefore(until)) return;

      ref.invalidate(refreshLatestNotificationProvider(_debugUserName));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _dismissLatestNotification(LatestNotification latest) async {
    // Build a stable key for "this exact notification"
    final key = '${latest.receivedAt.toIso8601String()}|${latest.title}|${latest.body}';

    // Persist dismissal so it stays dismissed after refresh/reload
    await ref.read(notificationDismissStoreProvider).setLastDismissed(key);

    // Clear UI immediately
    ref.read(latestNotificationProvider.notifier).state = null;

    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
    }

    // Optional extra insurance for polling loops
    setState(() {
      _suppressRefreshUntil = DateTime.now().add(const Duration(minutes: 2));
    });
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 6),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.55),
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final refresh = ref.watch(refreshLatestNotificationProvider(_debugUserName));
    final latest = ref.watch(latestNotificationProvider);

   return Scaffold(
  backgroundColor: HomeScreen.background,
  body: SafeArea(
    child: Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              const Text(
                'Duxton Pubs',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Pubs Financial',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.1,
                ),
              ),

              const SizedBox(height: 16),

              _buildLatestNotificationCard(
                context: context,
                refresh: refresh,
                latest: latest,
              ),

              const SizedBox(height: 12),

              // ---- Performance ----
              _sectionHeader('Performance'),
              GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 3.3,
                children: [
                  _HomeCard(
                    title: 'Snapshot',
                    icon: Icons.pie_chart,
                    tint: Colors.purple,
                    onTap: () => context.go('/snapshot'),
                  ),
                  _HomeCard(
                    title: 'Financial',
                    icon: Icons.bar_chart,
                    tint: const Color.fromRGBO(92, 188, 125, 1),
                    onTap: () => context.go('/financial'),
                  ),
                  _HomeCard(
                    title: 'Trends',
                    icon: Icons.show_chart,
                    tint: const Color.fromRGBO(244, 195, 64, 1),
                    onTap: () => context.go('/trends'),
                  ),
                  _HomeCard(
                    title: 'Gaming',
                    icon: Icons.casino,
                    tint: Colors.orange,
                    onTap: () => context.go('/gaming'),
                  ),
                ],
              ),

              // ---- Operations ----
              _sectionHeader('Operations'),
              GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 3.3,
                children: [
                  _HomeCard(
                    title: 'Food',
                    icon: Icons.restaurant,
                    tint: Colors.cyan,
                    onTap: () => context.go('/food'),
                  ),
                  _HomeCard(
                    title: 'Beverage',
                    icon: Icons.wine_bar,
                    tint: Colors.cyan,
                    onTap: () => context.go('/beverage'),
                  ),
                  _HomeCard(
                    title: 'Retail',
                    icon: Icons.shopping_bag,
                    tint: Colors.cyan,
                    onTap: () => context.go('/retail'),
                  ),
                  _HomeCard(
                    title: 'Accommodation',
                    icon: Icons.bed,
                    tint: Colors.cyan,
                    onTap: () => context.go('/accommodation'),
                  ),
                ],
              ),

              // ---- Governance ----
              _sectionHeader('Governance'),
              GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 3.3,
                children: [
                  _HomeCard(
                    title: 'State of Play',
                    icon: Icons.speed,
                    tint: Colors.purple,
                    onTap: () => context.go('/state-of-play'),
                  ),
                  _HomeCard(
                    title: 'Weekly Notes',
                    icon: Icons.sticky_note_2,
                    tint: Colors.blueAccent,
                    onTap: () => context.go('/weekly-notes'),
                  ),
                  _HomeCard(
                    title: 'Weekly Comms',
                    icon: Icons.campaign,
                    tint: Colors.indigoAccent,
                    onTap: () => context.go('/weekly-communication'),
                  ),
                  _HomeCard(
                    title: 'After Action',
                    icon: Icons.checklist,
                    tint: Colors.tealAccent,
                    isSecondary: true,
                    onTap: () => context.go('/after-action'),
                  ),
                  _HomeCard(
                    title: 'Projects',
                    icon: Icons.folder_open,
                    tint: Colors.tealAccent,
                    isSecondary: true,
                    onTap: () => context.go('/projects'),
                  ),
                  _HomeCard(
                    title: 'Alerts',
                    icon: Icons.notifications_active,
                    tint: Colors.pink,
                    isAlert: true,
                    onTap: () => context.go('/alerts'),
                  ),
                  _HomeCard(
                    title: 'Feedback',
                    icon: Icons.feedback_outlined,
                    tint: Colors.teal,
                    onTap: () => context.go('/feedback'),
                  ),
                ],
              ),

              const SizedBox(height: 18),
            ],
          ),
        ),

        Positioned(
          top: 16,
          right: 20,
          child: Material(
            color: HomeScreen.cardBlue.withValues(alpha: 0.95),
            shape: const CircleBorder(),
            elevation: 4,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => context.go('/settings'),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Icon(
                  Icons.settings,
                  color: Colors.white.withValues(alpha: 0.9),
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  ),
);
  }

  Widget _buildLatestNotificationCard({
    required BuildContext context,
    required AsyncValue<void> refresh,
    required LatestNotification? latest,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: latest == null ? null : () => _dismissLatestNotification(latest),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: HomeScreen.cardBlue.withValues(alpha: 0.90),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              latest == null ? 'Latest Notification' : 'Latest Notification (tap to dismiss)',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),

            refresh.when(
              data: (_) => const SizedBox.shrink(),
              loading: () => Text(
                'Refreshing…',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 12,
                ),
              ),
              error: (e, _) => Text(
                'Latest error: $e',
                style: TextStyle(
                  color: Colors.redAccent.withValues(alpha: 0.9),
                  fontSize: 12,
                ),
              ),
            ),

            const SizedBox(height: 6),

            if (latest == null) ...[
              Text(
                'No notifications yet',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 13,
                ),
              ),
            ] else ...[
             Text(
  latest.body, // ✅ make body the main message
  maxLines: 2,
  overflow: TextOverflow.ellipsis,
  style: const TextStyle(
    color: Colors.white,
    fontSize: 14,
    fontWeight: FontWeight.w700,
  ),
),
const SizedBox(height: 4),
Text(
  latest.title, // ✅ title becomes the small context line
  maxLines: 1,
  overflow: TextOverflow.ellipsis,
  style: TextStyle(
    color: Colors.white.withValues(alpha: 0.75),
    fontSize: 13,
    height: 1.2,
  ),
),

              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatReceivedAt(latest.receivedAt),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _formatReceivedAt(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _HomeCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color tint;
  final VoidCallback? onTap;

  final bool isAlert;
  final bool isSecondary;

  const _HomeCard({
    required this.title,
    required this.icon,
    required this.tint,
    this.onTap,
    this.isAlert = false,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    final bgAlpha = isSecondary ? 0.035 : 0.05;

    final borderColor = isAlert
        ? Colors.redAccent.withValues(alpha: 0.95)
        : tint.withValues(alpha: 0.6);

    final borderWidth = isAlert ? 1.6 : 1.0;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: bgAlpha),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: borderWidth),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 21, color: isAlert ? Colors.redAccent : tint),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.1,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isAlert)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
