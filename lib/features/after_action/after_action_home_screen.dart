import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'after_action_detail_screen.dart';
import 'after_action_models.dart';
import 'after_action_repository.dart';
import 'package:go_router/go_router.dart';

const _bg = Color.fromRGBO(7, 32, 64, 1);
const _cardBlue = Color.fromRGBO(19, 52, 98, 1);

final afterActionTasksProvider = FutureProvider<List<AfterActionTaskDto>>((ref) async {
  return ref.watch(afterActionRepositoryProvider).getTasks();
});

final afterActionEventsProvider = FutureProvider<List<AfterActionListItemDto>>((ref) async {
  return ref.watch(afterActionRepositoryProvider).getEvents();
});

class AfterActionHomeScreen extends ConsumerWidget {
  const AfterActionHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(afterActionTasksProvider);
    final eventsAsync = ref.watch(afterActionEventsProvider);

    final isLoading = tasksAsync.isLoading || eventsAsync.isLoading;
    final err = tasksAsync.error ?? eventsAsync.error;

    return Scaffold(
      backgroundColor: _bg,
     appBar: AppBar(
  backgroundColor: _bg,
  elevation: 0,
  centerTitle: true,
  title: const Text(
    'After Action',
    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
  ),
  leading: IconButton(
    icon: const Icon(
      Icons.arrow_back_ios_new,
      size: 20,
      color: Colors.white,
    ),
    onPressed: () => context.go('/'),
  ),
),

      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(afterActionTasksProvider);
          ref.invalidate(afterActionEventsProvider);
          await Future.wait([
            ref.read(afterActionTasksProvider.future),
            ref.read(afterActionEventsProvider.future),
          ]);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          children: [
            if (isLoading) ...[
              const SizedBox(height: 30),
              Center(child: CircularProgressIndicator(color: Colors.white.withValues(alpha: 0.9))),
            ] else if (err != null) ...[
              _ErrorBlock(
                message: err.toString(),
                onRetry: () async {
                  ref.invalidate(afterActionTasksProvider);
                  ref.invalidate(afterActionEventsProvider);
                },
              ),
            ] else ...[
              // Safe unwrap
              ...tasksAsync.when(
                data: (tasks) {
                  if (tasks.isEmpty) return const <Widget>[];
                  return [
                    const Text('My Tasks',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    for (final t in tasks) ...[
                      _TaskCard(task: t),
                      const SizedBox(height: 10),
                    ],
                    const SizedBox(height: 8),
                  ];
                },
                loading: () => const [],
                error: (_, __) => const [],
              ),

              const Text('All Reviews',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),

              ...eventsAsync.when(
                data: (events) => [
                  for (final e in events) ...[
                    _EventCard(event: e),
                    const SizedBox(height: 10),
                  ],
                ],
                loading: () => const [],
                error: (_, __) => const [],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.task});
  final AfterActionTaskDto task;

  @override
  Widget build(BuildContext context) {
    final tint = Color(task.taskTypeColorArgb);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AfterActionDetailScreen(
              afterActionId: task.afterActionId,
              title: '${task.venueName} – ${task.eventName}',
              subtitle: task.taskTypeLabel,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _cardBlue.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${task.venueName} – ${task.eventName}',
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(task.taskTypeLabel,
                style: TextStyle(color: tint, fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
              'Updated ${_fmtDateTime(task.updatedUtc)}',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event});
  final AfterActionListItemDto event;

  @override
  Widget build(BuildContext context) {
    final statusColor = event.isCompleted ? const Color(0xFF61D36B) : Colors.white.withValues(alpha: 0.65);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AfterActionDetailScreen(
              afterActionId: event.afterActionId,
              title: '${event.venueName} – ${event.eventName}',
              subtitle: event.isCompleted ? 'Completed' : 'Open',
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _cardBlue.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${event.venueName} – ${event.eventName}',
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                Text('Responses ${event.responseCount}',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
                if (event.avgRating != null)
                  Text('Avg ${event.avgRating!.toStringAsFixed(1)}',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
                if (event.pendingCount > 0)
                  Text('Pending ${event.pendingCount}',
                      style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              event.isCompleted ? 'Completed' : 'Open',
              style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  const _ErrorBlock({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Column(
        children: [
          const Text(
            'Couldn’t load After Actions',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

String _fmtDateTime(DateTime dt) {
  // “Updated 4 Jan 2026, 9:10am” style
  const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  final local = dt.toLocal();
  final h = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final m = local.minute.toString().padLeft(2, '0');
  final ap = local.hour >= 12 ? 'pm' : 'am';
  return '${local.day} ${months[local.month - 1]} ${local.year}, $h:$m$ap';
}
