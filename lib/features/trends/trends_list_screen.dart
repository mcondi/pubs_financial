import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/api_errors.dart';
import 'trends_dtos.dart';
import 'package:go_router/go_router.dart';

const int groupVenueId = 26;

final trendsVenuesProvider = FutureProvider<List<TrendsVenue>>((ref) async {
  final items = await ref.watch(trendsRepositoryProvider).fetchTrendsVenues();

  // Group first, then alphabetical
  items.sort((a, b) {
    final aIsGroup = a.id == groupVenueId;
    final bIsGroup = b.id == groupVenueId;
    if (aIsGroup && !bIsGroup) return -1;
    if (!aIsGroup && bIsGroup) return 1;
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  });

  return items;
});

final selectedVenueIdProvider = StateProvider<int>((ref) => groupVenueId);

class _SummaryArgs {
  final int venueId;
  final String? weekEnd; // YYYY-MM-DD
  const _SummaryArgs(this.venueId, this.weekEnd);

  @override
  bool operator ==(Object other) =>
      other is _SummaryArgs && other.venueId == venueId && other.weekEnd == weekEnd;

  @override
  int get hashCode => Object.hash(venueId, weekEnd);
}

final trendsSummaryProvider =
    FutureProvider.family<TrendsVenueWeeklySummary, _SummaryArgs>((ref, args) async {
  return ref.watch(trendsRepositoryProvider).fetchTrendsSummary(
        venueId: args.venueId,
        weekEnd: args.weekEnd,
      );
});

final notesProvider =
    FutureProvider.family<WeekNotesResponse?, _SummaryArgs>((ref, args) async {
  // Group uses venueId=null in the notes API (matches your Swift behavior)
  final apiVenueId = (args.venueId == groupVenueId) ? null : args.venueId;

  // We need a weekEndISO to load notes
  final summary = await ref.watch(trendsSummaryProvider(args).future);
  final weekEndISO = _toDateOnly(summary.weekEnd);

  return ref.watch(trendsRepositoryProvider).fetchWeekNotes(
        weekEndISO: weekEndISO,
        venueId: apiVenueId,
      );
});

class TrendsListScreen extends ConsumerStatefulWidget {
  const TrendsListScreen({super.key});

  @override
  ConsumerState<TrendsListScreen> createState() => _TrendsListScreenState();
}

class _TrendsListScreenState extends ConsumerState<TrendsListScreen> {
  String? _weekEndOverride; // YYYY-MM-DD

  @override
  Widget build(BuildContext context) {
    final asyncVenues = ref.watch(trendsVenuesProvider);
    final venueId = ref.watch(selectedVenueIdProvider);

    final summaryArgs = _SummaryArgs(venueId, _weekEndOverride);
    final asyncSummary = ref.watch(trendsSummaryProvider(summaryArgs));
    final asyncNotes = ref.watch(notesProvider(summaryArgs));

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
  appBar: AppBar(
  title: const Text('Trends'),
  centerTitle: true,
  backgroundColor: const Color(0xFFF2F2F7),
  elevation: 0,
  leading: IconButton(
    icon: const Icon(Icons.arrow_back_ios_new, size: 20),
  onPressed: () => context.go('/'),
  ),
),

      body: asyncVenues.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _centerError(err),
        data: (venues) {
          final selected = venues.firstWhere(
            (v) => v.id == venueId,
            orElse: () => venues.first,
          );

          return asyncSummary.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => _centerError(err),
            data: (summary) {
              final weekLabel = _prettyWeekEnd(summary.weekEnd);
              final canPrev = summary.prevWeekEnd != null;
              final canNext = summary.nextWeekEnd != null;

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  _HeaderBar(
                    venues: venues,
                    selected: selected,
                    onPick: (id) {
                      ref.read(selectedVenueIdProvider.notifier).state = id;
                      setState(() => _weekEndOverride = null); // reset to latest when venue changes
                    },
                    canPrev: canPrev,
                    canNext: canNext,
                    onPrev: !canPrev
                        ? null
                        : () => setState(() => _weekEndOverride = _toDateOnly(summary.prevWeekEnd!)),
                    onNext: !canNext
                        ? null
                        : () => setState(() => _weekEndOverride = _toDateOnly(summary.nextWeekEnd!)),
                    weekEndLabel: weekLabel,
                  ),
                  const SizedBox(height: 12),

                  _summaryCard(summary),
                  const SizedBox(height: 12),

                  _insightsCard(summary),
                  const SizedBox(height: 12),

                  asyncNotes.when(
                    loading: () => _notesCard(loading: true),
                    error: (err, _) => _notesCard(error: err.toString()),
                    data: (notes) => _notesCard(notes: notes),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _centerError(Object err) {
    final msg = (err is ApiAuthException || err is ApiHttpException) ? err.toString() : '$err';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(msg, textAlign: TextAlign.center),
      ),
    );
  }
}

/// --- UI (matches your right-hand card style) ---

class _HeaderBar extends StatelessWidget {
  final List<TrendsVenue> venues;
  final TrendsVenue selected;
  final void Function(int id) onPick;

  final bool canPrev;
  final bool canNext;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final String weekEndLabel;

  const _HeaderBar({
    required this.venues,
    required this.selected,
    required this.onPick,
    required this.canPrev,
    required this.canNext,
    required this.onPrev,
    required this.onNext,
    required this.weekEndLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Venue', style: TextStyle(fontSize: 12, color: Colors.black54)),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: PopupMenuButton<int>(
                initialValue: selected.id,
                onSelected: onPick,
                itemBuilder: (context) => venues
                    .map((v) => PopupMenuItem<int>(value: v.id, child: Text(v.name)))
                    .toList(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      Text(selected.name, style: const TextStyle(fontSize: 16, color: Colors.blue)),
                      const SizedBox(width: 6),
                      const Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.black54),
                    ],
                  ),
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
}

Widget _summaryCard(TrendsVenueWeeklySummary s) {
  final revVsBud = _varianceText(actual: s.currYtdRevenue, reference: s.currYtdBudgetRevenue, label: 'budget', showColor: true);
  final revVsLy = _varianceText(actual: s.currYtdRevenue, reference: s.prevYtdRevenue, label: 'last year', showColor: false);

  final eVsBud = _varianceText(actual: s.currYtdEbitda, reference: s.currYtdBudgetEbitda, label: 'budget', showColor: true);
  final eVsLy = _varianceText(actual: s.currYtdEbitda, reference: s.prevYtdEbitda, label: 'last year', showColor: false);

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
            Expanded(child: _metricColumn(title: 'Revenue', actual: _currency0(s.currYtdRevenue), vsBudget: revVsBud, vsLastYear: revVsLy)),
            const SizedBox(width: 12),
            Container(width: 1, height: 80, color: Colors.black12),
            const SizedBox(width: 12),
            Expanded(child: _metricColumn(title: 'EBITDA', actual: _currency0(s.currYtdEbitda), vsBudget: eVsBud, vsLastYear: eVsLy)),
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
        Text(vsBudget.text, style: TextStyle(fontSize: 13, color: vsBudget.color, fontWeight: FontWeight.w600)),
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

Widget _notesCard({WeekNotesResponse? notes, bool loading = false, String? error}) {
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
              onPressed: null, // next step: wire Edit/save like your Swift version
              icon: const Icon(Icons.edit, size: 16),
              label: const Text('Edit'),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (loading)
          const Text('Loading notes…', style: TextStyle(fontSize: 15, color: Colors.black54))
        else if (error != null)
          Text(error, style: const TextStyle(fontSize: 13, color: Colors.red))
        else if (notes == null || (notes.generalNote ?? '').trim().isEmpty)
          const Text('No notes for this week yet.', style: TextStyle(fontSize: 15, color: Colors.black54))
        else ...[
          Text(
            notes.generalNote!.trim(),
            style: const TextStyle(fontSize: 15, color: Colors.black87),
          ),
          if (notes.hashtags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              notes.hashtags.join(' '),
              style: const TextStyle(fontSize: 13, color: Colors.black45),
            ),
          ],
        ],
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

class _VarianceLine {
  final String text;
  final Color color;
  _VarianceLine({required this.text, required this.color});
}

_VarianceLine? _varianceText({
  required double actual,
  required double? reference,
  required String label,
  required bool showColor,
}) {
  if (reference == null || reference == 0) return null;
  final diff = actual - reference;
  final pct = diff / reference;
  final sign = diff >= 0 ? '+' : '-';
  final txt = '$sign${_currency0(diff.abs())} (${_pct(pct.abs())}) vs $label';
  final color = !showColor ? Colors.black45 : (diff >= 0 ? Colors.green : Colors.red);
  return _VarianceLine(text: txt, color: color);
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

String _toDateOnly(String iso) {
  // Accepts "yyyy-MM-dd" or "yyyy-MM-ddTHH:mm:ss..."
  return iso.split('T').first;
}

String _prettyWeekEnd(String iso) {
  // If your API returns date-only already, this is fine.
  final d = _toDateOnly(iso);
  return d; // can upgrade to "d MMM yyyy" later
}
