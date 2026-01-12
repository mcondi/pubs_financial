import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';

const int groupVenueId = 26;

// Duxton palette
const _bg = Color.fromRGBO(7, 32, 64, 1);
const _cardBlue = Color.fromRGBO(19, 52, 98, 1);

class _SnapshotArgs {
  final int venueId;
  final String? weekEnd; // YYYY-MM-DD
  const _SnapshotArgs(this.venueId, this.weekEnd);

  @override
  bool operator ==(Object other) =>
      other is _SnapshotArgs && other.venueId == venueId && other.weekEnd == weekEnd;

  @override
  int get hashCode => Object.hash(venueId, weekEnd);
}

final snapshotVenueIdProvider = StateProvider<int>((ref) => groupVenueId);

final snapshotDataProvider =
    FutureProvider.family<Map<String, dynamic>, _SnapshotArgs>((ref, args) async {
  return ref.watch(snapshotRepositoryProvider).fetchVenueSummary(
        venueId: args.venueId,
        weekEnd: args.weekEnd,
      );
});

class SnapshotScreen extends ConsumerStatefulWidget {
  const SnapshotScreen({super.key});

  @override
  ConsumerState<SnapshotScreen> createState() => _SnapshotScreenState();
}

class _SnapshotScreenState extends ConsumerState<SnapshotScreen> {
  String? _weekEndOverride; // YYYY-MM-DD
  bool _showDebug = false;

  @override
  Widget build(BuildContext context) {
    final venueId = ref.watch(snapshotVenueIdProvider);
    final async = ref.watch(snapshotDataProvider(_SnapshotArgs(venueId, _weekEndOverride)));

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
  backgroundColor: _bg,
  elevation: 0,
  centerTitle: true,
  title: const Text(
    'Snapshot',
    style: TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w600,
    ),
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

      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _errorView(err.toString()),
        data: (json) {
          final venueName = (json['venueName'] as String?) ?? 'Venue';
          final weekEndIso = (json['weekEnd'] as String?) ?? '';
          final prevWeekEndIso = (json['prevWeekEnd'] as String?) ?? '';
          final nextWeekEndIso = (json['nextWeekEnd'] as String?) ?? '';

          final canPrev = prevWeekEndIso.isNotEmpty;
          final canNext = nextWeekEndIso.isNotEmpty;

          final metrics = (json['metrics'] as List?)
                  ?.whereType<Map>()
                  .map((e) => e.cast<String, dynamic>())
                  .toList() ??
              const <Map<String, dynamic>>[];

          final categories = (json['categories'] as List?)
                  ?.whereType<Map>()
                  .map((e) => e.cast<String, dynamic>())
                  .toList() ??
              const <Map<String, dynamic>>[];

          final notes = (json['notes'] is Map)
              ? (json['notes'] as Map).cast<String, dynamic>()
              : null;
          final notesView = notes == null ? null : _notesViewDataFromJson(notes);

          final weeklyOp = _pickMap(json, ['weeklyOperational', 'weekly_operational']);
          final ytdOp = _pickMap(json, ['ytdOperational', 'ytd_operational']);

          final weeklySummary = _buildOperationalSummary(
            isYtd: false,
            op: weeklyOp,
            metrics: metrics,
          );

          final ytdSummary = _buildYtdSummaryLikeIos(
            weeklyOp: weeklyOp,
            ytdOp: ytdOp,
            metrics: metrics,
          );

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(snapshotDataProvider);
              await ref
                  .read(snapshotDataProvider(_SnapshotArgs(venueId, _weekEndOverride)).future);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                const Text(
                  'Snapshot',
                  style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800),
                ),
                Text(
                  'Weekly and YTD performance',
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
                ),
                const SizedBox(height: 14),

                _venuePicker(
                  selectedVenueId: venueId,
                  selectedVenueName: venueName,
                  canPrev: canPrev,
                  canNext: canNext,
                  onPickVenue: (id) {
                    ref.read(snapshotVenueIdProvider.notifier).state = id;
                    setState(() => _weekEndOverride = null);
                  },
                  onPrev: !canPrev
                      ? null
                      : () => setState(() => _weekEndOverride = _toDateOnly(prevWeekEndIso)),
                  onNext: !canNext
                      ? null
                      : () => setState(() => _weekEndOverride = _toDateOnly(nextWeekEndIso)),
                ),

                if (weekEndIso.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      'Week ending ${_prettyWeekEnd(weekEndIso)}',
                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                if (weeklySummary != null) ...[
                  _budgetPiesCard(
                    title: 'Weekly vs budget',
                    revenueLabel: 'Revenue',
                    revenueActual: weeklySummary.totalRevenueValue,
                    revenueBudget: weeklySummary.revenueBudgetValue,
                    revenueRatio: weeklySummary.revenueVsBudgetRatio,
                    ebitdaLabel: 'EBITDA',
                    ebitdaActual: weeklySummary.ebitdaValue,
                    ebitdaBudget: weeklySummary.ebitdaBudgetValue,
                    ebitdaRatio: weeklySummary.ebitdaVsBudgetRatio,
                  ),
                  const SizedBox(height: 12),
                  _snapshotDetailCard(
                    title: 'Weekly snapshot',
                    revenueSublabel: 'Revenue',
                    ebitdaSublabel: 'EBITDA',
                    s: weeklySummary,
                    isYtd: false,
                  ),
                  const SizedBox(height: 12),
                  _categoryMarginsCard(
                    title: 'Weekly margins',
                    categories: categories,
                    isYtd: false,
                  ),
                  const SizedBox(height: 12),
                ],

                if (ytdSummary != null) ...[
                  _budgetPiesCard(
                    title: 'YTD vs budget',
                    revenueLabel: 'Revenue (YTD)',
                    revenueActual: ytdSummary.totalRevenueValue,
                    revenueBudget: ytdSummary.revenueBudgetValue,
                    revenueRatio: ytdSummary.revenueVsBudgetRatio,
                    ebitdaLabel: 'EBITDA (YTD)',
                    ebitdaActual: ytdSummary.ebitdaValue,
                    ebitdaBudget: ytdSummary.ebitdaBudgetValue,
                    ebitdaRatio: ytdSummary.ebitdaVsBudgetRatio,
                  ),
                  const SizedBox(height: 12),
                  _snapshotDetailCard(
                    title: 'YTD snapshot',
                    revenueSublabel: 'Revenue (YTD)',
                    ebitdaSublabel: 'EBITDA (YTD)',
                    s: ytdSummary,
                    isYtd: true,
                  ),
                  const SizedBox(height: 12),
                  _categoryMarginsCard(
                    title: 'YTD margins',
                    categories: categories,
                    isYtd: true,
                  ),
                  const SizedBox(height: 12),
                ],

                if (notesView != null) ...[
                  _notesCard(notesView),
                  const SizedBox(height: 12),
                ],

                // Debug JSON toggle (remove later)
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextButton(
                        onPressed: () => setState(() => _showDebug = !_showDebug),
                        child: Text(
                          _showDebug ? 'Hide debug JSON' : 'Show debug JSON',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      if (_showDebug)
                        Text(
                          const JsonEncoder.withIndent('  ').convert(json),
                          style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12),
                        ),
                    ],
                  ),
                ),
              ],
            ),
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

  // ------- Venue picker (SwiftUI style) -------

  Widget _venuePicker({
    required int selectedVenueId,
    required String selectedVenueName,
    required bool canPrev,
    required bool canNext,
    required void Function(int id) onPickVenue,
    required VoidCallback? onPrev,
    required VoidCallback? onNext,
  }) {
    final venues = _venueList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Venue', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _cardBlue.withOpacity(0.9),
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
                      Icon(Icons.keyboard_arrow_down, color: Colors.white.withOpacity(0.85)),
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
                  color: Colors.white.withOpacity(canPrev ? 0.9 : 0.3),
                ),
              ),
              IconButton(
                onPressed: onNext,
                icon: Icon(
                  Icons.arrow_circle_right,
                  size: 32,
                  color: Colors.white.withOpacity(canNext ? 0.9 : 0.3),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ------- Cards -------

  Widget _budgetPiesCard({
    required String title,
    required String revenueLabel,
    required String revenueActual,
    required String revenueBudget,
    required double? revenueRatio,
    required String ebitdaLabel,
    required String ebitdaActual,
    required String ebitdaBudget,
    required double? ebitdaRatio,
  }) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _donutBudgetChart(
                  title: revenueLabel,
                  actual: revenueActual,
                  budget: revenueBudget,
                  ratio: revenueRatio,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _donutBudgetChart(
                  title: ebitdaLabel,
                  actual: ebitdaActual,
                  budget: ebitdaBudget,
                  ratio: ebitdaRatio,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// ✅ iOS-style donut
  Widget _donutBudgetChart({
    required String title,
    required String actual,
    required String budget,
    required double? ratio,
  }) {
    final safeRatio = (ratio ?? 0).clamp(0.0, 10.0);
    final progress = safeRatio.clamp(0.0, 1.0);
    final tint = _colourForBudgetRatio(ratio);
    final pct = (safeRatio * 100).round();

    return Column(
      children: [
        SizedBox(
          width: 168,
          height: 168,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            builder: (context, animProgress, _) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(168, 168),
                    painter: _DonutRingPainter(
                      progress: animProgress,
                      color: tint,
                      backgroundColor: Colors.white.withOpacity(0.12),
                      showOverRing: safeRatio > 1.0,
                      overRingColor: tint.withOpacity(0.35),
                      strokeWidth: 14,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$pct%',
                          style: TextStyle(
                            color: tint,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 6),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            actual,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              height: 1.0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'of $budget',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 11,
                              height: 1.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _snapshotDetailCard({
    required String title,
    required String revenueSublabel,
    required String ebitdaSublabel,
    required _OperationalSummary s,
    required bool isYtd,
  }) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(s.totalRevenueValue, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                  Text(s.ebitdaValue, style: TextStyle(color: Colors.white.withOpacity(0.92), fontWeight: FontWeight.w800)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(revenueSublabel, style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 11)),
                Text(ebitdaSublabel, style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isYtd ? 'Revenue, EBITDA, wages and gaming (YTD)' : 'Revenue, EBITDA, wages and gaming',
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
          ),
          const SizedBox(height: 10),
          Divider(color: Colors.white.withOpacity(0.15)),
          _gridRow(isYtd ? 'Revenue budget (YTD)' : 'Revenue budget', s.revenueBudgetValue, 'Revenue vs budget',
              s.revenueVsBudgetPercent, rightColor: _colourForBudgetRatio(s.revenueVsBudgetRatio)),
          _gridRow(isYtd ? 'EBITDA budget (YTD)' : 'EBITDA budget', s.ebitdaBudgetValue, 'EBITDA vs budget',
              s.ebitdaVsBudgetPercent, rightColor: _colourForBudgetRatio(s.ebitdaVsBudgetRatio)),
          _gridRow('EBITDA margin', s.ebitdaMargin, 'Wages', s.wages),
          _gridRow('Wage %', s.wagePercent, 'Gaming turnover', s.gamingTurnover),
          _gridRow('Gaming wages', s.gamingWage, 'Gaming revenue', s.gamingRevenue),
          _gridRow('Gaming margin', s.gamingMargin, 'Accommodation', s.accommodation),
          _gridRow('Bottle shop', s.bottleShop, 'Beverage', s.beverage),
          _gridRow('Food', s.food, 'Other', s.other),
        ],
      ),
    );
  }

  Widget _categoryMarginsCard({
    required String title,
    required List<Map<String, dynamic>> categories,
    required bool isYtd,
  }) {
    Map<String, dynamic>? find(String name) {
      for (final c in categories) {
        final cat = (c['category'] as String?) ?? '';
        if (cat.toLowerCase() == name.toLowerCase()) return c;
      }
      return null;
    }

    String pct(dynamic v) {
      final d = _asDouble(v);
      if (d == null) return '—';
      return '${(d * 100).round()}%';
    }

    final food = find('Food');
    final bev = find('Beverage');
    final acc = find('Accommodation');

    final foodGp = isYtd ? pct(food == null ? null : food['ytdGrossProfit']) : pct(food == null ? null : food['weeklyGrossProfit']);
    final bevGp  = isYtd ? pct(bev == null ? null : bev['ytdGrossProfit'])  : pct(bev == null ? null : bev['weeklyGrossProfit']);
    final accGp  = isYtd ? pct(acc == null ? null : acc['ytdGrossProfit'])  : pct(acc == null ? null : acc['weeklyGrossProfit']);

    final foodW  = isYtd ? pct(food == null ? null : food['ytdWagesPercent']) : pct(food == null ? null : food['weeklyWagesPercent']);
    final bevW   = isYtd ? pct(bev == null ? null : bev['ytdWagesPercent'])  : pct(bev == null ? null : bev['weeklyWagesPercent']);

    final hasAny = foodGp != '—' || bevGp != '—' || accGp != '—' || foodW != '—' || bevW != '—';
    if (!hasAny) return const SizedBox.shrink();

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('GP% and department wages%', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
          const SizedBox(height: 10),
          Divider(color: Colors.white.withOpacity(0.15)),
          _gridRow('Food GP%', foodGp, 'Food wages%', foodW),
          _gridRow('Beverage GP%', bevGp, 'Beverage wages%', bevW),
          _gridRow('Accommodation GP%', accGp, '', ''),
        ],
      ),
    );
  }

  Widget _notesCard(_NotesViewData notes) {
    final hasCategory = (notes.category ?? '').trim().isNotEmpty;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.note_alt_outlined, color: Colors.yellow),
              const SizedBox(width: 8),
              const Text('Notes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
              const Spacer(),
              if (hasCategory)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    notes.category!,
                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 11),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if ((notes.commentText ?? '').trim().isNotEmpty)
            Text(notes.commentText!.trim(), style: const TextStyle(color: Colors.white, fontSize: 13)),
          if ((notes.generalNote ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(notes.generalNote!.trim(), style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13)),
          ],
          if (notes.hashtagsText.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(notes.hashtagsText.trim(), style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11)),
          ],
        ],
      ),
    );
  }

  Widget _gridRow(String l1, String v1, String l2, String v2, {Color? rightColor}) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: Text(l1, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12))),
                Text(v1, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: [
                Expanded(child: Text(l2, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12))),
                Text(
                  v2,
                  style: TextStyle(
                    color: rightColor ?? Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardBlue.withOpacity(0.9),
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }
}

// ------------------ donut painter ------------------

class _DonutRingPainter extends CustomPainter {
  final double progress; // 0..1
  final Color color;
  final Color backgroundColor;
  final bool showOverRing;
  final Color overRingColor;
  final double strokeWidth;

  _DonutRingPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
    required this.showOverRing,
    required this.overRingColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) / 2) - (strokeWidth / 2);

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    final rect = Rect.fromCircle(center: center, radius: radius);
    final startAngle = -math.pi / 2;
    final sweep = 2 * math.pi * progress.clamp(0.0, 1.0);
    canvas.drawArc(rect, startAngle, sweep, false, fgPaint);

    if (showOverRing) {
      final overPaint = Paint()
        ..color = overRingColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;

      canvas.drawCircle(center, radius + 8, overPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _DonutRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.showOverRing != showOverRing ||
        oldDelegate.overRingColor != overRingColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

// ------------------ view-data models ------------------

class _OperationalSummary {
  final String totalRevenueValue;
  final String revenueBudgetValue;
  final String revenueVsBudgetPercent;
  final double? revenueVsBudgetRatio;

  final String ebitdaValue;
  final String ebitdaBudgetValue;
  final String ebitdaVsBudgetPercent;
  final double? ebitdaVsBudgetRatio;

  final String ebitdaMargin;
  final String wages;
  final String wagePercent;

  final String gamingRevenue;
  final String gamingTurnover;
  final String gamingMargin;
  final String gamingWage;

  final String accommodation;
  final String bottleShop;
  final String beverage;
  final String food;
  final String other;

  _OperationalSummary({
    required this.totalRevenueValue,
    required this.revenueBudgetValue,
    required this.revenueVsBudgetPercent,
    required this.revenueVsBudgetRatio,
    required this.ebitdaValue,
    required this.ebitdaBudgetValue,
    required this.ebitdaVsBudgetPercent,
    required this.ebitdaVsBudgetRatio,
    required this.ebitdaMargin,
    required this.wages,
    required this.wagePercent,
    required this.gamingRevenue,
    required this.gamingTurnover,
    required this.gamingMargin,
    required this.gamingWage,
    required this.accommodation,
    required this.bottleShop,
    required this.beverage,
    required this.food,
    required this.other,
  });
}

class _NotesViewData {
  final bool hasComment;
  final String? commentText;
  final String? category;
  final String? generalNote;
  final String hashtagsText;

  _NotesViewData({
    required this.hasComment,
    required this.commentText,
    required this.category,
    required this.generalNote,
    required this.hashtagsText,
  });
}

// ------------------ mapping logic ------------------

_OperationalSummary? _buildOperationalSummary({
  required bool isYtd,
  required Map<String, dynamic>? op,
  required List<Map<String, dynamic>> metrics,
}) {
  if (op != null) {
    final totalRevenue = _asDouble(op['totalRevenue']);
    final revenueBudget = _asDouble(op['revenueBudget']);

    final ebitda = _asDouble(op['ebitda']);
    final ebitdaBudget = _asDouble(op['ebitdaBudget']);

    final revRatio = (totalRevenue != null && revenueBudget != null && revenueBudget != 0)
        ? totalRevenue / revenueBudget
        : null;

    final eRatio = (ebitda != null && ebitdaBudget != null && ebitdaBudget != 0)
        ? ebitda / ebitdaBudget
        : null;

    return _OperationalSummary(
      totalRevenueValue: _money0(totalRevenue),
      revenueBudgetValue: _money0(revenueBudget),
      revenueVsBudgetPercent: revRatio == null ? '–' : _formatPercent(revRatio),
      revenueVsBudgetRatio: revRatio,

      ebitdaValue: _money0(ebitda),
      ebitdaBudgetValue: _money0(ebitdaBudget),
      ebitdaVsBudgetPercent: eRatio == null ? '–' : _formatPercent(eRatio),
      ebitdaVsBudgetRatio: eRatio,

      ebitdaMargin: _formatPercent(_asDouble(op['ebitdaMargin'])),
      wages: _money0(_asDouble(op['wages'])),
      wagePercent: _formatPercent(_asDouble(op['wagePercent'])),

      gamingRevenue: _money0(_asDouble(op['gamingRevenue'])),
      gamingTurnover: _money0(_asDouble(op['gamingTurnover'])),
      gamingMargin: _formatPercent(_asDouble(op['gamingMargin'])),
      gamingWage: _money0(_asDouble(op['gamingWage'])),

      accommodation: _money0(_asDouble(op['accommodation'])),
      bottleShop: _money0(_asDouble(op['bottleShop'])),
      beverage: _money0(_asDouble(op['beverage'])),
      food: _money0(_asDouble(op['food'])),
      other: _money0(_asDouble(op['other'])),
    );
  }

  // fallback from metrics (budgets become dashes)
  Map<String, dynamic>? m(String name) => _findMetric(metrics, name);
  final revenue = m('Revenue');
  if (revenue == null) return null;

  final dash = '–';
  final revActual = _asDouble(isYtd ? revenue['ytdActual'] : revenue['weeklyActual']);

  double? pickActual(String name) {
    final mm = m(name);
    if (mm == null) return null;
    return _asDouble(isYtd ? mm['ytdActual'] : mm['weeklyActual']);
  }

  return _OperationalSummary(
    totalRevenueValue: _money0(revActual),
    revenueBudgetValue: dash,
    revenueVsBudgetPercent: dash,
    revenueVsBudgetRatio: null,

    ebitdaValue: _money0(pickActual('EBITDA')),
    ebitdaBudgetValue: dash,
    ebitdaVsBudgetPercent: dash,
    ebitdaVsBudgetRatio: null,

    ebitdaMargin: dash,
    wages: dash,
    wagePercent: dash,

    gamingRevenue: _money0(pickActual('Gaming')),
    gamingTurnover: dash,
    gamingMargin: dash,
    gamingWage: dash,

    accommodation: dash,
    bottleShop: _money0(pickActual('Retail')),
    beverage: _money0(pickActual('Beverage')),
    food: _money0(pickActual('Food')),
    other: dash,
  );
}

_OperationalSummary? _buildYtdSummaryLikeIos({
  required Map<String, dynamic>? weeklyOp,
  required Map<String, dynamic>? ytdOp,
  required List<Map<String, dynamic>> metrics,
}) {
  if (ytdOp != null && weeklyOp != null) {
    final ytdRev = _asDouble(ytdOp['totalRevenue']);
    final weeklyRev = _asDouble(weeklyOp['totalRevenue']);
    if (ytdRev != null && weeklyRev != null && (ytdRev - weeklyRev).abs() > 0.01) {
      return _buildOperationalSummary(isYtd: true, op: ytdOp, metrics: metrics);
    }
  }
  return _buildOperationalSummary(isYtd: true, op: null, metrics: metrics);
}

_NotesViewData? _notesViewDataFromJson(Map<String, dynamic> notes) {
  final hasComment = (notes['hasComment'] as bool?) ?? false;
  final commentText = notes['commentText'] as String?;
  final category = notes['category'] as String?;
  final generalNote = notes['generalNote'] as String?;

  final hashtags = (notes['hashtags'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[];
  final hashtagsText = hashtags.join(' ');

  final hasAny = hasComment || (generalNote ?? '').trim().isNotEmpty || hashtagsText.trim().isNotEmpty;
  if (!hasAny) return null;

  return _NotesViewData(
    hasComment: hasComment,
    commentText: commentText,
    category: category,
    generalNote: generalNote,
    hashtagsText: hashtagsText,
  );
}

// ------------------ helpers ------------------

Map<String, dynamic>? _pickMap(Map<String, dynamic> json, List<String> keys) {
  for (final k in keys) {
    final v = json[k];
    if (v is Map) return v.cast<String, dynamic>();
  }
  return null;
}

Map<String, dynamic>? _findMetric(List<Map<String, dynamic>> metrics, String name) {
  for (final m in metrics) {
    final metricName = (m['metric'] as String?) ?? '';
    if (metricName.toLowerCase() == name.toLowerCase()) return m;
  }
  return null;
}

double? _asDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

Color _colourForBudgetRatio(double? ratio) {
  // Swift rules: <0.65 red, <0.99 yellow, else green
  if (ratio == null) return Colors.white;
  if (ratio < 0.65) return const Color(0xFFFF5A5A);
  if (ratio < 0.99) return const Color(0xFFF1C84B);
  return const Color(0xFF61D36B);
}

String _money0(double? value) {
  if (value == null) return '–';
  final rounded = value.round();
  final s = rounded.toString();
  final withCommas = s.replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  return '\$$withCommas';
}

String _formatPercent(double? ratio) {
  if (ratio == null) return '–';
  return '${(ratio * 100).toStringAsFixed(1)}%';
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

class _Venue {
  final int id;
  final String name;
  const _Venue(this.id, this.name);
}

// Swap later with your real venue list (API)
List<_Venue> _venueList() => const [
  _Venue(26, 'Group'),
  _Venue(1, 'Lion Hotel'),
  _Venue(2, 'Cross Keys Hotel'),
  _Venue(3, 'Saracens Head Hotel'),
  _Venue(4, 'Cremorne Hotel'),
  _Venue(5, 'Alma Tavern'),
  _Venue(6, 'Little Bang Brewery'),
];
