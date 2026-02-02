import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart'; // ✅ ADD

import '../../app/providers.dart';
import '../../core/api_errors.dart';
import 'trends_dtos.dart';


final trendsDetailProvider =
    FutureProvider.family<TrendsVenueWeeklySummary, TrendsDetailArgs>((ref, args) async {
  return ref.watch(trendsRepositoryProvider).fetchTrendsSummary(
        venueId: args.venueId,
        weekEnd: args.weekEnd,
      );
});

class TrendsDetailArgs {
  final int venueId;
  final String? weekEnd; // YYYY-MM-DD
  const TrendsDetailArgs({required this.venueId, this.weekEnd});
}

class TrendsDetailScreen extends ConsumerStatefulWidget {
  final int initialVenueId;
  const TrendsDetailScreen({super.key, required this.initialVenueId});

  @override
  ConsumerState<TrendsDetailScreen> createState() => _TrendsDetailScreenState();
}

class _TrendsDetailScreenState extends ConsumerState<TrendsDetailScreen> {
  late int _venueId;
  String? _weekEnd;

  @override
  void initState() {
    super.initState();
    _venueId = widget.initialVenueId;
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(
      trendsDetailProvider(
        TrendsDetailArgs(venueId: _venueId, weekEnd: _weekEnd),
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: const Text('Trends'),
        centerTitle: true,
        backgroundColor: const Color(0xFFF2F2F7),
        elevation: 0,

        // ✅ ADD BACK ARROW TO MAIN MENU
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.go('/'),
        ),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) {
          final msg = (err is ApiAuthException || err is ApiHttpException) ? err.toString() : '$err';
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(msg, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(trendsDetailProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        },
        data: (summary) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(trendsDetailProvider);
              await ref.read(
                trendsDetailProvider(TrendsDetailArgs(venueId: _venueId, weekEnd: _weekEnd)).future,
              );
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                _headerBar(
                  venueName: summary.venueName,
                  weekEndLabel: _prettyWeekEnd(summary.weekEnd),
                  canPrev: summary.prevWeekEnd != null,
                  canNext: summary.nextWeekEnd != null,
                  onPrev: summary.prevWeekEnd == null
                      ? null
                      : () => setState(() => _weekEnd = _toDateOnly(summary.prevWeekEnd!)),
                  onNext: summary.nextWeekEnd == null
                      ? null
                      : () => setState(() => _weekEnd = _toDateOnly(summary.nextWeekEnd!)),
                ),
                const SizedBox(height: 12),
                _summaryCard(summary),
                const SizedBox(height: 12),
                _insightsCard(summary),
                const SizedBox(height: 12),
                _notesCard(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _headerBar({
    required String venueName,
    required String weekEndLabel,
    required bool canPrev,
    required bool canNext,
    required VoidCallback? onPrev,
    required VoidCallback? onNext,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Venue', style: TextStyle(fontSize: 12, color: Colors.black54)),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(venueName, style: const TextStyle(fontSize: 16, color: Colors.blue)),
                    const SizedBox(width: 6),
                    const Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.black54),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              onPressed: onPrev,
              icon: Icon(Icons.chevron_left, color: canPrev ? Colors.black54 : Colors.black26),
            ),
            IconButton(
              onPressed: onNext,
              icon: Icon(Icons.chevron_right, color: canNext ? Colors.black54 : Colors.black26),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Center(
          child: Text('Week ending $weekEndLabel', style: const TextStyle(fontSize: 12, color: Colors.black45)),
        ),
      ],
    );
  }

  Widget _summaryCard(TrendsVenueWeeklySummary s) {
    final revVsBud = _varianceText(actual: s.currYtdRevenue, reference: s.currYtdBudgetRevenue, label: 'budget');
    final revVsLy =
        _varianceText(actual: s.currYtdRevenue, reference: s.prevYtdRevenue, label: 'last year', showColor: false);

    final ebitdaVsBud = _varianceText(actual: s.currYtdEbitda, reference: s.currYtdBudgetEbitda, label: 'budget');
    final ebitdaVsLy =
        _varianceText(actual: s.currYtdEbitda, reference: s.prevYtdEbitda, label: 'last year', showColor: false);

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.venueName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text('Executive snapshot', style: TextStyle(fontSize: 13, color: Colors.black54)),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _metricColumn(
                  title: 'Revenue',
                  actual: _currency0(s.currYtdRevenue),
                  vsBudget: revVsBud,
                  vsLastYear: revVsLy,
                ),
              ),
              const SizedBox(width: 12),
              Container(width: 1, height: 80, color: Colors.black12),
              const SizedBox(width: 12),
              Expanded(
                child: _metricColumn(
                  title: 'EBITDA',
                  actual: _currency0(s.currYtdEbitda),
                  vsBudget: ebitdaVsBud,
                  vsLastYear: ebitdaVsLy,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricColumn({
    required String title,
    required String actual,
    required _VarianceLine? vsBudget,
    required _VarianceLine? vsLastYear,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 13, color: Colors.black54)),
        const SizedBox(height: 6),
        Text(actual, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        if (vsBudget != null)
          Text(
            vsBudget.text,
            style: TextStyle(fontSize: 13, color: vsBudget.color, fontWeight: FontWeight.w600),
          ),
        if (vsLastYear != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(vsLastYear.text, style: const TextStyle(fontSize: 13, color: Colors.black45)),
          ),
      ],
    );
  }

  Widget _insightsCard(TrendsVenueWeeklySummary s) {
    final insights = <String>[];

    if (s.currYtdBudgetRevenue != null && s.currYtdBudgetRevenue != 0) {
      final diff = s.currYtdRevenue - s.currYtdBudgetRevenue!;
      final pct = diff / s.currYtdBudgetRevenue!;
      insights.add('Revenue YTD ${diff >= 0 ? "ahead of" : "behind"} budget: '
          '${_currency0(s.currYtdRevenue)} is ${_signedCurrency(diff)} (${_pct(pct)}) vs budget.');
    }

    if (s.currYtdBudgetEbitda != null && s.currYtdBudgetEbitda != 0) {
      final diff = s.currYtdEbitda - s.currYtdBudgetEbitda!;
      final pct = diff / s.currYtdBudgetEbitda!;
      insights.add('EBITDA YTD ${diff >= 0 ? "ahead of" : "behind"} budget: '
          '${_currency0(s.currYtdEbitda)} is ${_signedCurrency(diff)} (${_pct(pct)}) vs budget.');
    }

    if (insights.isEmpty) return const SizedBox.shrink();

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.auto_awesome, size: 18, color: Colors.blue),
              SizedBox(width: 8),
              Text('Insights', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 10),
          ...insights.map((line) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('•  $line', style: const TextStyle(fontSize: 15)),
              )),
        ],
      ),
    );
  }

  Widget _notesCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.sticky_note_2_outlined, size: 18, color: Colors.orange),
              const SizedBox(width: 8),
              const Text('Notes', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              const Spacer(),
              TextButton.icon(
                onPressed: null,
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Edit'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text('No notes for this week yet.', style: TextStyle(fontSize: 15, color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: child,
    );
  }

  _VarianceLine? _varianceText({
    required double actual,
    required double? reference,
    required String label,
    bool showColor = true,
  }) {
    if (reference == null || reference == 0) return null;
    final diff = actual - reference;
    final pct = diff / reference;
    final sign = diff >= 0 ? '+' : '-';
    final text = '$sign${_currency0(diff.abs())} (${_pct(pct.abs())}) vs $label';
    final color = !showColor ? Colors.black45 : (diff >= 0 ? Colors.green : Colors.red);
    return _VarianceLine(text: text, color: color);
  }

  String _currency0(double value) {
    final rounded = value.round();
    final s = rounded.toString();
    final withCommas = s.replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    return '\$$withCommas';
  }

  String _signedCurrency(double value) {
    final sign = value >= 0 ? '+' : '-';
    return '$sign${_currency0(value.abs())}';
  }

  String _pct(double value) {
    final p = (value * 100);
    return '${p.abs().toStringAsFixed(1)}%';
  }

  String _toDateOnly(String iso) => iso.split('T').first;

  String _prettyWeekEnd(String iso) => _toDateOnly(iso);
}

class _VarianceLine {
  final String text;
  final Color color;
  _VarianceLine({required this.text, required this.color});
}
