import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'after_action_home_screen.dart';
import 'after_action_models.dart';
import 'after_action_repository.dart';

final afterActionDetailProvider =
    FutureProvider.family<AfterActionDetailDto?, int>((ref, id) async {
  return ref.watch(afterActionRepositoryProvider).getDetail(id);
});

class AfterActionDetailScreen extends ConsumerStatefulWidget {
  const AfterActionDetailScreen({
    super.key,
    required this.afterActionId,
    required this.title,
    required this.subtitle,
  });

  final int afterActionId;
  final String title;
  final String subtitle;

  @override
  ConsumerState<AfterActionDetailScreen> createState() => _AfterActionDetailScreenState();
}

class _AfterActionDetailScreenState extends ConsumerState<AfterActionDetailScreen> {
  bool _isWorking = false;
  String? _message;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(afterActionDetailProvider(widget.afterActionId));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('After Action', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _centerMsg(err.toString()),
        data: (detail) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(afterActionDetailProvider(widget.afterActionId));
              await ref.read(afterActionDetailProvider(widget.afterActionId).future);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
              children: [
                _titleBlock(widget.title, widget.subtitle),

                if (detail == null) ...[
                  const SizedBox(height: 14),
                  _centerMsg('No detail returned.'),
                ] else ...[
                  const SizedBox(height: 14),
                  _statsCard(detail),
                  const SizedBox(height: 12),

                  if (detail.actionBullets.isNotEmpty) ...[
                    _bulletsCard(detail.actionBullets),
                    const SizedBox(height: 12),
                  ],

                  _sectionIfNotEmpty('Overall Summary', detail.overallSummary),
                  _sectionIfNotEmpty('What Worked', detail.whatWorked),
                  _sectionIfNotEmpty('What Didn’t', detail.whatDidnt),
                  _sectionIfNotEmpty('Top Lessons', detail.top3Lessons),
                  _sectionIfNotEmpty('Top Actions Next Time', detail.top3ActionsNextTime),
                  _sectionIfNotEmpty('Team – What Worked', detail.allWorked),
                  _sectionIfNotEmpty('Team – What Didn’t', detail.allDidnt),
                  _sectionIfNotEmpty('Team – Notes', detail.allNotes),
                ],

                const SizedBox(height: 14),

                FilledButton(
                  onPressed: _isWorking ? null : () => _markRead(context),
                  child: _isWorking
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Mark as Read'),
                ),

                const SizedBox(height: 10),

                OutlinedButton(
                  onPressed: null,
                  child: const Text('Send Reminders (coming soon)'),
                ),

                if (_message != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _message!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black.withValues(alpha: 0.55), fontSize: 12),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _centerMsg(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(msg, textAlign: TextAlign.center),
      ),
    );
  }

  Widget _titleBlock(String title, String subtitle) {
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black.withValues(alpha: 0.55)),
        ),
      ],
    );
  }

  Widget _statsCard(AfterActionDetailDto d) {
    return _whiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${d.venueName} • ${d.eventName}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                d.isCompleted ? 'Completed' : 'Open',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: d.isCompleted ? const Color(0xFF2E7D32) : Colors.black.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${_fmtDate(d.startDate)} → ${_fmtDate(d.endDate)}',
            style: TextStyle(color: Colors.black.withValues(alpha: 0.55), fontSize: 12),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              Text('Responses ${d.responseCount}', style: TextStyle(color: Colors.black.withValues(alpha: 0.55), fontSize: 12)),
              if (d.avgRating != null)
                Text('Avg ${d.avgRating!.toStringAsFixed(1)}', style: TextStyle(color: Colors.black.withValues(alpha: 0.55), fontSize: 12)),
              if (d.pendingCount > 0)
                Text('Pending ${d.pendingCount}', style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 6),
          Text('Owner: ${d.ownerUserName}', style: TextStyle(color: Colors.black.withValues(alpha: 0.55), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _bulletsCard(List<String> bullets) {
    return _whiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Key Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          for (final b in bullets) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('•  ', style: TextStyle(fontSize: 14)),
                Expanded(child: Text(b, style: TextStyle(color: Colors.black.withValues(alpha: 0.65), fontSize: 14))),
              ],
            ),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }

  Widget _sectionIfNotEmpty(String title, String? text) {
    final trimmed = (text ?? '').trim();
    if (trimmed.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _whiteCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(trimmed, style: TextStyle(color: Colors.black.withValues(alpha: 0.65), fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _whiteCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }

  Future<void> _markRead(BuildContext context) async {
    setState(() {
      _isWorking = true;
      _message = null;
    });

    try {
      final ok = await ref.read(afterActionRepositoryProvider).markRead(widget.afterActionId);

      // refresh tasks list so it disappears from "My Tasks"
      ref.invalidate(afterActionTasksProvider);

      setState(() {
        _message = ok ? 'Marked as read ✅' : 'Could not mark as read.';
      });
    } catch (e) {
      setState(() {
        _message = e.toString();
      });
    } finally {
      setState(() => _isWorking = false);
    }
  }
}

String _fmtDate(DateTime dt) {
  const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  final local = dt.toLocal();
  return '${local.day} ${months[local.month - 1]} ${local.year}';
}
