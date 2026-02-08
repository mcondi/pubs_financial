import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/sevenrooms_review_models.dart';
import '../state/sevenrooms_review_draft_controller.dart';

class SevenRoomsReviewFormScreen extends ConsumerWidget {
  const SevenRoomsReviewFormScreen({super.key});

  static const background = Color.fromRGBO(7, 32, 64, 1);
  static const cardBlue = Color.fromRGBO(19, 52, 98, 1);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(sevenRoomsReviewDraftProvider);
    final ctrl = ref.read(sevenRoomsReviewDraftProvider.notifier);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        foregroundColor: Colors.white,
        title: const Text('SevenRooms Checklist'),
        actions: [
          TextButton(
            onPressed: () {
              ctrl.reset();
              context.go('/');
            },
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          )
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            children: [
              ...sevenRoomsCategories.map((cat) {
                final score = draft.scores.firstWhere((s) => s.category == cat.key);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _CategoryCard(
                    title: cat.key,
                    weight: cat.weightPct,
                    help: cat.help,
                    currentScore: score.score1to5,
                    comments: score.comments,
                    onScoreChanged: (v) => ctrl.setScore(cat.key, v),
                    onCommentsChanged: (v) => ctrl.setComments(cat.key, v),
                  ),
                );
              }),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(244, 195, 64, 1),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: draft.allScored ? () => context.go('/sevenrooms-review/summary') : null,
                  child: Text(
                    draft.allScored ? 'Review Summary' : 'Score all categories to continue',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatefulWidget {
  final String title;
  final int weight;
  final String help;

  final int currentScore;
  final String comments;
  final ValueChanged<int> onScoreChanged;
  final ValueChanged<String> onCommentsChanged;

  const _CategoryCard({
    required this.title,
    required this.weight,
    required this.help,
    required this.currentScore,
    required this.comments,
    required this.onScoreChanged,
    required this.onCommentsChanged,
  });

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final badge = _scoreBadge(widget.currentScore);

    return Container(
      decoration: BoxDecoration(
        color: SevenRoomsReviewFormScreen.cardBlue.withOpacity(0.90),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Weight: ${widget.weight}%',
                          style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  badge,
                  const SizedBox(width: 10),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ],
              ),
            ),
          ),

          AnimatedCrossFade(
            crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 180),
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.help, style: TextStyle(color: Colors.white.withOpacity(0.70), fontSize: 12)),
                  const SizedBox(height: 10),
                  _ScorePills(
                    value: widget.currentScore,
                    onChanged: widget.onScoreChanged,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    minLines: 2,
                    maxLines: 5,
                    controller: TextEditingController(text: widget.comments),
                    onChanged: widget.onCommentsChanged,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Evidence / Comments (optional)',
                      labelStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: SevenRoomsReviewFormScreen.cardBlue.withOpacity(0.60),
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _scoreBadge(int score) {
    final bg = _scoreColor(score);
    final txt = score == 0 ? '—' : '$score/5';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg.withOpacity(0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bg.withOpacity(0.55)),
      ),
      child: Text(
        txt,
        style: TextStyle(color: bg, fontWeight: FontWeight.w800, fontSize: 12),
      ),
    );
  }

  Color _scoreColor(int score) {
    if (score <= 0) return Colors.white54;
    if (score <= 2) return Colors.redAccent;
    if (score == 3) return const Color(0xFFF4C340);
    return const Color(0xFF5CBC7D);
  }
}

class _ScorePills extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _ScorePills({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (i) {
        final v = i + 1;
        final selected = value == v;
        final color = _colorFor(v);

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i == 4 ? 0 : 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onChanged(v),
              child: Container(
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? color.withOpacity(0.25) : Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? color.withOpacity(0.85) : Colors.white.withOpacity(0.12),
                    width: selected ? 1.4 : 1,
                  ),
                ),
                child: Text(
                  '$v',
                  style: TextStyle(
                    color: selected ? color : Colors.white.withOpacity(0.85),
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Color _colorFor(int score) {
    if (score <= 2) return Colors.redAccent;
    if (score == 3) return const Color(0xFFF4C340);
    return const Color(0xFF5CBC7D);
  }
}
