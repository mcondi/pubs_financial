import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers.dart';
import '../data/sevenrooms_review_models.dart';
import '../state/sevenrooms_review_draft_controller.dart';

class SevenRoomsReviewSummaryScreen extends ConsumerStatefulWidget {
  const SevenRoomsReviewSummaryScreen({super.key});

  static const background = Color.fromRGBO(7, 32, 64, 1);
  static const cardBlue = Color.fromRGBO(19, 52, 98, 1);

  @override
  ConsumerState<SevenRoomsReviewSummaryScreen> createState() => _SevenRoomsReviewSummaryScreenState();
}

class _SevenRoomsReviewSummaryScreenState extends ConsumerState<SevenRoomsReviewSummaryScreen> {
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(sevenRoomsReviewDraftProvider);
    final ctrl = ref.read(sevenRoomsReviewDraftProvider.notifier);

    return Scaffold(
      backgroundColor: SevenRoomsReviewSummaryScreen.background,
      appBar: AppBar(
        backgroundColor: SevenRoomsReviewSummaryScreen.background,
        foregroundColor: Colors.white,
        title: const Text('Review Summary'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            children: [
              _Card(
                title: 'Classification (required)',
                child: Column(
                  children: [
                    _Radio(
                      label: 'Optimised',
                      value: 'Optimised',
                      group: draft.classification,
                      onChanged: ctrl.setClassification,
                    ),
                    _Radio(
                      label: 'Functional but Inconsistent',
                      value: 'Functional but Inconsistent',
                      group: draft.classification,
                      onChanged: ctrl.setClassification,
                    ),
                    _Radio(
                      label: 'Under-Utilised',
                      value: 'Under-Utilised',
                      group: draft.classification,
                      onChanged: ctrl.setClassification,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _Card(
                title: 'Scores',
                child: Column(
                  children: draft.scores.map((s) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              s.category,
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            s.score1to5 == 0 ? '—' : '${s.score1to5}/5',
                            style: TextStyle(
                              color: _colorFor(s.score1to5),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
              _Card(
                title: 'Overall Notes (optional)',
                child: TextField(
                  minLines: 3,
                  maxLines: 7,
                  onChanged: ctrl.setNotes,
                  controller: TextEditingController(text: draft.notes),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Key observations, coaching opportunities, follow-ups…',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.55)),
                    filled: true,
                    fillColor: SevenRoomsReviewSummaryScreen.cardBlue.withOpacity(0.60),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.30)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5CBC7D),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _submitting
                      ? null
                      : () async {
                          if (!draft.allScored) {
                            _toast(context, 'Please score all categories.');
                            return;
                          }
                          if ((draft.classification ?? '').trim().isEmpty) {
                            _toast(context, 'Please select a classification.');
                            return;
                          }

                          setState(() => _submitting = true);
                          try {
                            await ref.read(sevenRoomsReviewRepositoryProvider).submitReview(draft);
                            ctrl.reset();
                            if (mounted) {
                              _toast(context, 'SevenRooms review saved ✅');
                              context.go('/');
                            }
                          } catch (e) {
                            if (mounted) _toast(context, 'Save failed: $e');
                          } finally {
                            if (mounted) setState(() => _submitting = false);
                          }
                        },
                  child: Text(_submitting ? 'Submitting…' : 'Submit Review',
                      style: const TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.go('/sevenrooms-review/form'),
                child: const Text('Back to checklist', style: TextStyle(color: Colors.white70)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  Color _colorFor(int score) {
    if (score <= 0) return Colors.white54;
    if (score <= 2) return Colors.redAccent;
    if (score == 3) return const Color(0xFFF4C340);
    return const Color(0xFF5CBC7D);
  }
}

class _Card extends StatelessWidget {
  final String title;
  final Widget child;
  const _Card({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: SevenRoomsReviewSummaryScreen.cardBlue.withOpacity(0.90),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(),
              style: TextStyle(
                color: Colors.white.withOpacity(0.70),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              )),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _Radio extends StatelessWidget {
  final String label;
  final String value;
  final String? group;
  final ValueChanged<String> onChanged;

  const _Radio({
    required this.label,
    required this.value,
    required this.group,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = group == value;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.white.withOpacity(0.10) : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(selected ? 0.25 : 0.12)),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? const Color(0xFF5CBC7D) : Colors.white54,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}
