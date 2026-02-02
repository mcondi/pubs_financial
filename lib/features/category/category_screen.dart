import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/models/venue.dart';
import '../../app/venues_provider.dart';

import 'category_repository.dart';
import 'category_type.dart';

const int groupVenueId = 26;

// Duxton palette
const _bg = Color.fromRGBO(7, 32, 64, 1);
const _cardBlue = Color.fromRGBO(19, 52, 98, 1);

class _Args {
  final int venueId;
  final String? weekEnd; // YYYY-MM-DD
  final CategoryType category;
  const _Args(this.venueId, this.weekEnd, this.category);

  @override
  bool operator ==(Object other) =>
      other is _Args &&
      other.venueId == venueId &&
      other.weekEnd == weekEnd &&
      other.category == category;

  @override
  int get hashCode => Object.hash(venueId, weekEnd, category);
}

final categoryVenueIdProvider = StateProvider<int>((ref) => groupVenueId);

final categoryDataProvider =
    FutureProvider.family<Map<String, dynamic>, _Args>((ref, args) async {
  return ref.watch(categoryRepositoryProvider).fetchVenueSummary(
        venueId: args.venueId,
        weekEnd: args.weekEnd,
      );
});

class CategoryScreen extends ConsumerStatefulWidget {
  const CategoryScreen({super.key, required this.category});
  final CategoryType category;

  @override
  ConsumerState<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends ConsumerState<CategoryScreen> {
  String? _weekEndOverride; // YYYY-MM-DD

  @override
  Widget build(BuildContext context) {
    final venuesAsync = ref.watch(venuesProvider);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        centerTitle: true,
        title: Text(
          widget.category.title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.white),
          onPressed: () => context.go('/'),
        ),
      ),
      body: venuesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _errorView(e.toString()),
        data: (venues) {
          if (venues.isEmpty) {
            return _errorView('No venues available.');
          }

          final currentId = ref.watch(categoryVenueIdProvider);
          final safeVenueId = venues.any((v) => v.id == currentId)
              ? currentId
              : venues
                  .firstWhere((v) => v.id == groupVenueId, orElse: () => venues.first)
                  .id;

          if (safeVenueId != currentId) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(categoryVenueIdProvider.notifier).state = safeVenueId;
            });
          }

          final async = ref.watch(
            categoryDataProvider(_Args(safeVenueId, _weekEndOverride, widget.category)),
          );

          return async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => _errorView(err.toString()),
            data: (json) {
              final venueName = (json['venueName'] as String?) ??
                  venues.firstWhere((v) => v.id == safeVenueId, orElse: () => venues.first).name;

              final weekEndIso = (json['weekEnd'] as String?) ?? '';
              final prevWeekEndIso = (json['prevWeekEnd'] as String?) ?? '';
              final nextWeekEndIso = (json['nextWeekEnd'] as String?) ?? '';

              final canPrev = prevWeekEndIso.isNotEmpty;
              final canNext = nextWeekEndIso.isNotEmpty;

              final categories = (json['categories'] as List?)
                      ?.whereType<Map>()
                      .map((e) => e.cast<String, dynamic>())
                      .toList() ??
                  const <Map<String, dynamic>>[];

              final metrics = (json['metrics'] as List?)
                      ?.whereType<Map>()
                      .map((e) => e.cast<String, dynamic>())
                      .toList() ??
                  const <Map<String, dynamic>>[];

              final cat = _findCategory(categories, widget.category.apiKey);
              final metric = _findMetric(metrics, widget.category.apiKey);

              final budgets = _deriveBudgetsFromMetrics(metric);

              final accFallback =
                  (widget.category == CategoryType.accommodation && cat == null && metric != null)
                      ? _buildAccommodationFallback(metric)
                      : null;

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(categoryDataProvider);
                  await ref.read(
                    categoryDataProvider(_Args(safeVenueId, _weekEndOverride, widget.category)).future,
                  );
                },
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    _headerBar(
                      venues: venues,
                      selectedVenueId: safeVenueId,
                      selectedVenueName: venueName,
                      canPrev: canPrev,
                      canNext: canNext,
                      onPickVenue: (id) {
                        ref.read(categoryVenueIdProvider.notifier).state = id;
                        setState(() => _weekEndOverride = null);
                      },
                      onPrev: !canPrev
                          ? null
                          : () => setState(() => _weekEndOverride = _toDateOnly(prevWeekEndIso)),
                      onNext: !canNext
                          ? null
                          : () => setState(() => _weekEndOverride = _toDateOnly(nextWeekEndIso)),
                    ),
                    const SizedBox(height: 8),
                    if (weekEndIso.isNotEmpty)
                      Center(
                        child: Text(
                          'Week ending ${_prettyWeekEnd(weekEndIso)}',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.70), fontSize: 12),
                        ),
                      ),
                    const SizedBox(height: 14),
                    if (cat != null) ...[
                      _summaryCard(
                        title: '${widget.category.title} snapshot',
                        weeklyRevenue: _asDouble(cat['weeklyRevenue']) ?? 0,
                        ytdRevenue: _asDouble(cat['ytdRevenue']) ?? 0,
                        weeklyBudget: budgets.weekly,
                        ytdBudget: budgets.ytd,
                        weeklyGp: _asDouble(cat['weeklyGrossProfit']),
                        ytdGp: _asDouble(cat['ytdGrossProfit']),
                        weeklyWage: _asDouble(cat['weeklyWagesPercent']),
                        ytdWage: _asDouble(cat['ytdWagesPercent']),
                        showWages: widget.category.showsWages,
                      ),
                      _detailCard(
                        weeklyRevenue: _asDouble(cat['weeklyRevenue']) ?? 0,
                        ytdRevenue: _asDouble(cat['ytdRevenue']) ?? 0,
                        weeklyBudget: budgets.weekly,
                        ytdBudget: budgets.ytd,
                        weeklyGp: _asDouble(cat['weeklyGrossProfit']),
                        ytdGp: _asDouble(cat['ytdGrossProfit']),
                        weeklyWage: _asDouble(cat['weeklyWagesPercent']),
                        ytdWage: _asDouble(cat['ytdWagesPercent']),
                        showWages: widget.category.showsWages,
                      ),
                      _insightsCard(
                        category: widget.category,
                        weeklyRevenue: _asDouble(cat['weeklyRevenue']) ?? 0,
                        ytdRevenue: _asDouble(cat['ytdRevenue']) ?? 0,
                        weeklyBudget: budgets.weekly,
                        ytdBudget: budgets.ytd,
                        weeklyGp: _asDouble(cat['weeklyGrossProfit']),
                        ytdGp: _asDouble(cat['ytdGrossProfit']),
                        weeklyWage: _asDouble(cat['weeklyWagesPercent']),
                        ytdWage: _asDouble(cat['ytdWagesPercent']),
                      ),
                    ] else if (accFallback != null) ...[
                      _summaryCard(
                        title: '${widget.category.title} snapshot',
                        weeklyRevenue: accFallback.weeklyRevenue,
                        ytdRevenue: accFallback.ytdRevenue,
                        weeklyBudget: accFallback.weeklyBudget,
                        ytdBudget: accFallback.ytdBudget,
                        weeklyGp: null,
                        ytdGp: null,
                        weeklyWage: null,
                        ytdWage: null,
                        showWages: false,
                        note: 'Note: Accommodation is sourced from summary metrics (GP/Wages not available yet).',
                        forceNeutralVariance: true,
                      ),
                      _detailAccommodationFallback(accFallback),
                    ] else ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: Text(
                          'No data available',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.70)),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _errorView(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(msg, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
      ),
    );
  }

  Widget _headerBar({
    required List<Venue> venues,
    required int selectedVenueId,
    required String selectedVenueName,
    required bool canPrev,
    required bool canNext,
    required void Function(int id) onPickVenue,
    required VoidCallback? onPrev,
    required VoidCallback? onNext,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Venue', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _cardBlue.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(
                child: PopupMenuButton<int>(
                  initialValue: selectedVenueId,
                  onSelected: onPickVenue,
                  itemBuilder: (context) => venues
                      .map((v) => PopupMenuItem<int>(value: v.id, child: Text(v.name)))
                      .toList(),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          selectedVenueName,
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.keyboard_arrow_down, color: Colors.white.withValues(alpha: 0.85)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: onPrev,
                icon: Icon(
                  Icons.arrow_circle_left,
                  size: 32,
                  color: Colors.white.withValues(alpha: canPrev ? 0.9 : 0.3),
                ),
              ),
              IconButton(
                onPressed: onNext,
                icon: Icon(
                  Icons.arrow_circle_right,
                  size: 32,
                  color: Colors.white.withValues(alpha: canNext ? 0.9 : 0.3),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// --------- Cards / helpers ---------

Widget _card({required Widget child, double alpha = 0.9}) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _cardBlue.withValues(alpha: alpha),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1),
    ),
    child: child,
  );
}

Widget _summaryCard({
  required String title,
  required double weeklyRevenue,
  required double ytdRevenue,
  required double? weeklyBudget,
  required double? ytdBudget,
  required double? weeklyGp, // ratio 0..1
  required double? ytdGp,
  required double? weeklyWage, // ratio 0..1
  required double? ytdWage,
  required bool showWages,
  String? note,
  bool forceNeutralVariance = false,
}) {
  return Column(
    children: [
      _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(height: 10),
            Divider(color: Colors.white.withValues(alpha: 0.15), height: 1),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _summaryMetricCurrency(
                    title: 'Weekly revenue',
                    actual: weeklyRevenue,
                    budget: weeklyBudget,
                    forceNeutral: forceNeutralVariance,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _summaryMetricCurrency(
                    title: 'YTD revenue',
                    actual: ytdRevenue,
                    budget: ytdBudget,
                    forceNeutral: forceNeutralVariance,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: Colors.white.withValues(alpha: 0.15), height: 1),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _summaryMetricPercent(title: 'Weekly GP%', value: weeklyGp)),
                const SizedBox(width: 16),
                Expanded(child: _summaryMetricPercent(title: 'YTD GP%', value: ytdGp)),
              ],
            ),
            if (showWages) ...[
              const SizedBox(height: 12),
              Divider(color: Colors.white.withValues(alpha: 0.15), height: 1),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _summaryMetricPercent(title: 'Weekly wage%', value: weeklyWage)),
                  const SizedBox(width: 16),
                  Expanded(child: _summaryMetricPercent(title: 'YTD wage%', value: ytdWage)),
                ],
              ),
            ],
            if (note != null) ...[
              const SizedBox(height: 10),
              Text(note, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11)),
            ],
          ],
        ),
      ),
      const SizedBox(height: 16),
    ],
  );
}

Widget _detailCard({
  required double weeklyRevenue,
  required double ytdRevenue,
  required double? weeklyBudget,
  required double? ytdBudget,
  required double? weeklyGp,
  required double? ytdGp,
  required double? weeklyWage,
  required double? ytdWage,
  required bool showWages,
}) {
  final dash = '—';

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Detail', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
      const SizedBox(height: 10),
      _card(
        alpha: 0.8,
        child: Column(
          children: [
            _detailRowCurrency('Weekly revenue', weeklyRevenue, weeklyBudget),
            const SizedBox(height: 10),
            _detailRowCurrency('YTD revenue', ytdRevenue, ytdBudget),
            const SizedBox(height: 10),
            Divider(color: Colors.white.withValues(alpha: 0.15), height: 1),
            const SizedBox(height: 10),
            _detailRowPlain('Weekly GP%', weeklyGp == null ? dash : _pct1Value(weeklyGp)),
            const SizedBox(height: 10),
            _detailRowPlain('YTD GP%', ytdGp == null ? dash : _pct1Value(ytdGp)),
            const SizedBox(height: 10),
            _detailRowPlain('Weekly wage%', showWages ? (weeklyWage == null ? dash : _pct1Value(weeklyWage)) : dash),
            const SizedBox(height: 10),
            _detailRowPlain('YTD wage%', showWages ? (ytdWage == null ? dash : _pct1Value(ytdWage)) : dash),
          ],
        ),
      ),
      const SizedBox(height: 16),
    ],
  );
}

Widget _detailAccommodationFallback(_AccFallback s) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Detail', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
      const SizedBox(height: 10),
      _card(
        alpha: 0.8,
        child: Column(
          children: [
            _detailRowPlain('Weekly revenue', _money2(s.weeklyRevenue)),
            const SizedBox(height: 10),
            _detailRowPlain('Weekly budget', s.weeklyBudget == null ? '—' : _money2(s.weeklyBudget!)),
            const SizedBox(height: 10),
            _detailRowPlain('Weekly vs budget', s.weeklyVsBudget == null ? '—' : _pct1Value(s.weeklyVsBudget!)),
            const SizedBox(height: 10),
            Divider(color: Colors.white.withValues(alpha: 0.15), height: 1),
            const SizedBox(height: 10),
            _detailRowPlain('YTD revenue', _money2(s.ytdRevenue)),
            const SizedBox(height: 10),
            _detailRowPlain('YTD budget', s.ytdBudget == null ? '—' : _money2(s.ytdBudget!)),
            const SizedBox(height: 10),
            _detailRowPlain('YTD vs budget', s.ytdVsBudget == null ? '—' : _pct1Value(s.ytdVsBudget!)),
            const SizedBox(height: 10),
            Divider(color: Colors.white.withValues(alpha: 0.15), height: 1),
            const SizedBox(height: 10),
            _detailRowPlain('Weekly GP', '—'),
            const SizedBox(height: 10),
            _detailRowPlain('YTD GP', '—'),
            const SizedBox(height: 10),
            _detailRowPlain('Weekly wage %', '—'),
            const SizedBox(height: 10),
            _detailRowPlain('YTD wage %', '—'),
          ],
        ),
      ),
      const SizedBox(height: 16),
    ],
  );
}

Widget _insightsCard({
  required CategoryType category,
  required double weeklyRevenue,
  required double ytdRevenue,
  required double? weeklyBudget,
  required double? ytdBudget,
  required double? weeklyGp,
  required double? ytdGp,
  required double? weeklyWage,
  required double? ytdWage,
}) {
  final lines = <String>[];

  if (weeklyBudget != null && weeklyBudget != 0) {
    final diff = weeklyRevenue - weeklyBudget;
    final pct = diff / weeklyBudget;
    lines.add('Weekly revenue is ${_signedMoney0(diff)} (${_pct1(pct)}) vs budget.');
  }

  if (ytdBudget != null && ytdBudget != 0) {
    final diff = ytdRevenue - ytdBudget;
    final pct = diff / ytdBudget;
    lines.add('YTD revenue is ${_signedMoney0(diff)} (${_pct1(pct)}) vs budget.');
  }

  if (weeklyGp != null) lines.add('Weekly GP% is ${_pct1Value(weeklyGp)}.');
  if (ytdGp != null) lines.add('YTD GP% is ${_pct1Value(ytdGp)}.');

  if (category.showsWages) {
    if (weeklyWage != null) lines.add('Weekly wage% is ${_pct1Value(weeklyWage)}.');
    if (ytdWage != null) lines.add('YTD wage% is ${_pct1Value(ytdWage)}.');
  }

  if (lines.isEmpty) return const SizedBox.shrink();

  return _card(
    alpha: 0.8,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Insights', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
        const SizedBox(height: 10),
        for (final l in lines) ...[
          Text('• $l', style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14)),
          const SizedBox(height: 6),
        ],
      ],
    ),
  );
}

Widget _summaryMetricCurrency({
  required String title,
  required double actual,
  required double? budget,
  required bool forceNeutral,
}) {
  final variance = _varianceCurrency(actual, budget);
  final showVariance = variance != null && !forceNeutral;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14)),
      const SizedBox(height: 6),
      Text(_money0(actual), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
      const SizedBox(height: 4),
      Text(
        budget == null ? 'Budget —' : 'Budget ${_money0(budget)}',
        style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
      ),
      const SizedBox(height: 4),
      if (showVariance)
        Text(
          variance.text,
          style: TextStyle(color: variance.color, fontSize: 12, fontWeight: FontWeight.w600),
        ),
    ],
  );
}

Widget _summaryMetricPercent({required String title, required double? value}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14)),
      const SizedBox(height: 6),
      Text(
        value == null ? '—' : _pct1Value(value),
        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
      ),
    ],
  );
}

Widget _detailRowCurrency(String title, double actual, double? budget) {
  final variance = _varianceCurrency(actual, budget);

  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15))),
      const SizedBox(width: 16),
      Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(_money2(actual), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          if (budget != null)
            Text('Budget ${_money2(budget)}', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
          if (variance != null)
            Text(variance.text, style: TextStyle(color: variance.color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    ],
  );
}

Widget _detailRowPlain(String title, String value) {
  return Row(
    children: [
      Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15))),
      Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
    ],
  );
}

class _Variance {
  final String text;
  final Color color;
  _Variance(this.text, this.color);
}

_Variance? _varianceCurrency(double actual, double? budget) {
  if (budget == null || budget == 0) return null;
  final diff = actual - budget;
  final pct = diff / budget;
  final direction = diff >= 0 ? 'above' : 'below';
  final text = '${_signedMoney0(diff)} (${_pct1(pct)}) $direction budget';
  final color = diff >= 0 ? const Color(0xFF61D36B) : const Color(0xFFFF5A5A);
  return _Variance(text, color);
}

class _Budgets {
  final double? weekly;
  final double? ytd;
  const _Budgets(this.weekly, this.ytd);
}

_Budgets _deriveBudgetsFromMetrics(Map<String, dynamic>? metric) {
  if (metric == null) return const _Budgets(null, null);

  final weeklyActual = _asDouble(metric['weeklyActual']);
  final ytdActual = _asDouble(metric['ytdActual']);
  final weeklyPercent = _asDouble(metric['weeklyPercent']); // e.g. 113.0
  final ytdPercent = _asDouble(metric['ytdPercent']);

  double? weeklyBudget;
  if (weeklyActual != null && weeklyPercent != null && weeklyPercent != 0) {
    weeklyBudget = weeklyActual / (weeklyPercent / 100.0);
  }

  double? ytdBudget;
  if (ytdActual != null && ytdPercent != null && ytdPercent != 0) {
    ytdBudget = ytdActual / (ytdPercent / 100.0);
  }

  return _Budgets(weeklyBudget, ytdBudget);
}

class _AccFallback {
  final double weeklyRevenue;
  final double ytdRevenue;
  final double? weeklyBudget;
  final double? ytdBudget;
  final double? weeklyVsBudget; // ratio 0..?
  final double? ytdVsBudget;
  const _AccFallback({
    required this.weeklyRevenue,
    required this.ytdRevenue,
    required this.weeklyBudget,
    required this.ytdBudget,
    required this.weeklyVsBudget,
    required this.ytdVsBudget,
  });
}

_AccFallback _buildAccommodationFallback(Map<String, dynamic> metric) {
  final weeklyRev = _asDouble(metric['weeklyActual']) ?? 0;
  final ytdRev = _asDouble(metric['ytdActual']) ?? 0;

  final weeklyPercent = _asDouble(metric['weeklyPercent']); // 98 means 98%
  final ytdPercent = _asDouble(metric['ytdPercent']);

  final weeklyBudget = (weeklyPercent != null && weeklyPercent != 0) ? weeklyRev / (weeklyPercent / 100.0) : null;
  final ytdBudget = (ytdPercent != null && ytdPercent != 0) ? ytdRev / (ytdPercent / 100.0) : null;

  final weeklyVsBudget = (weeklyPercent != null && weeklyPercent != 0) ? (weeklyPercent / 100.0) : null;
  final ytdVsBudget = (ytdPercent != null && ytdPercent != 0) ? (ytdPercent / 100.0) : null;

  return _AccFallback(
    weeklyRevenue: weeklyRev,
    ytdRevenue: ytdRev,
    weeklyBudget: weeklyBudget,
    ytdBudget: ytdBudget,
    weeklyVsBudget: weeklyVsBudget,
    ytdVsBudget: ytdVsBudget,
  );
}

Map<String, dynamic>? _findCategory(List<Map<String, dynamic>> categories, String key) {
  for (final c in categories) {
    final name = (c['category'] as String?) ?? '';
    if (name.toLowerCase() == key.toLowerCase()) return c;
  }
  return null;
}

Map<String, dynamic>? _findMetric(List<Map<String, dynamic>> metrics, String key) {
  for (final m in metrics) {
    final name = (m['metric'] as String?) ?? '';
    if (name.toLowerCase() == key.toLowerCase()) return m;
  }
  return null;
}

double? _asDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

String _toDateOnly(String iso) => iso.split('T').first;

String _prettyWeekEnd(String iso) {
  final d = _toDateOnly(iso);
  final parts = d.split('-');
  if (parts.length != 3) return d;

  final y = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (y == null || m == null || day == null) return d;

  const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  final mon = (m >= 1 && m <= 12) ? months[m - 1] : parts[1];
  return '$day $mon $y';
}

String _money2(double value) {
  final fixed = value.toStringAsFixed(2);
  final parts = fixed.split('.');
  final whole = parts.first;
  final frac = parts.length > 1 ? parts[1] : '00';
  final withCommas = whole.replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  return '\$$withCommas.$frac';
}

String _signedMoney0(double value) {
  final prefix = value >= 0 ? '+' : '-';
  return '$prefix${_money0(value.abs())}';
}

String _money0(double value) {
  final rounded = value.round();
  final s = rounded.toString();
  final withCommas = s.replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  return '\$$withCommas';
}

String _pct1(double ratio) {
  final v = ratio * 100;
  final sign = v >= 0 ? '' : '-';
  return '$sign${v.abs().toStringAsFixed(1)}%';
}

String _pct1Value(double ratio0to1) => '${(ratio0to1 * 100).toStringAsFixed(1)}%';
