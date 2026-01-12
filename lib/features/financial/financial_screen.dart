import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'financial_repository.dart';

const int groupVenueId = 26;

// Duxton palette
const _bg = Color.fromRGBO(7, 32, 64, 1);
const _cardBlue = Color.fromRGBO(19, 52, 98, 1);

class _FinancialArgs {
  final int venueId;
  final String? weekEnd; // YYYY-MM-DD
  const _FinancialArgs(this.venueId, this.weekEnd);

  @override
  bool operator ==(Object other) =>
      other is _FinancialArgs && other.venueId == venueId && other.weekEnd == weekEnd;

  @override
  int get hashCode => Object.hash(venueId, weekEnd);
}

final financialVenueIdProvider = StateProvider<int>((ref) => groupVenueId);

final financialDataProvider =
    FutureProvider.family<Map<String, dynamic>, _FinancialArgs>((ref, args) async {
  return ref.watch(financialRepositoryProvider).fetchVenueSummary(
        venueId: args.venueId,
        weekEnd: args.weekEnd,
      );
});

class FinancialScreen extends ConsumerStatefulWidget {
  const FinancialScreen({super.key});

  @override
  ConsumerState<FinancialScreen> createState() => _FinancialScreenState();
}

class _FinancialScreenState extends ConsumerState<FinancialScreen> {
  String? _weekEndOverride; // YYYY-MM-DD

  @override
  Widget build(BuildContext context) {
    final venueId = ref.watch(financialVenueIdProvider);
    final async = ref.watch(financialDataProvider(_FinancialArgs(venueId, _weekEndOverride)));

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Financial',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.white),
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

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(financialDataProvider);
              await ref.read(financialDataProvider(_FinancialArgs(venueId, _weekEndOverride)).future);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                const Text(
                  'Financial',
                  style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800),
                ),
                Text(
                  'Performance Gauges',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
                ),
                const SizedBox(height: 14),

                _venuePicker(
                  selectedVenueId: venueId,
                  selectedVenueName: venueName,
                  canPrev: canPrev,
                  canNext: canNext,
                  onPickVenue: (id) {
                    ref.read(financialVenueIdProvider.notifier).state = id;
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
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                for (final m in metrics) ...[
                  _gaugeMetricCard(m),
                  const SizedBox(height: 12),
                ],
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

  // ------- Venue picker (same as Snapshot) -------

  Widget _venuePicker({
    required int selectedVenueId,
    required String selectedVenueName,
    required bool canPrev,
    required bool canNext,
    required void Function(int id) onPickVenue,
    required VoidCallback? onPrev,
    required VoidCallback? onNext,
  }) {
    final venues = _venueList(); // swap later with your real venue list provider/API

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

  // ------- Metric card -------

  Widget _gaugeMetricCard(Map<String, dynamic> m) {
    final name = (m['metric'] as String?) ?? (m['name'] as String?) ?? 'Metric';

    final weeklyActual = _money0(_asDouble(m['weeklyActual']));
    final ytdActual = _money0(_asDouble(m['ytdActual']));

    final weeklyPct = _asDouble(m['weeklyPercent']);
    final ytdPct = _asDouble(m['ytdPercent']);

    final weeklyRatio = weeklyPct == null ? null : (weeklyPct / 100.0);
    final ytdRatio = ytdPct == null ? null : (ytdPct / 100.0);

    final weeklyPctText = weeklyPct == null ? '–' : '${weeklyPct.round()}%';
    final ytdPctText = ytdPct == null ? '–' : '${ytdPct.round()}%';

    return _card(
      child: Row(
        children: [
          _smallGauge(label: 'WTD', ratio: weeklyRatio, percentText: weeklyPctText),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              children: [
                Text(
                  name,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Week: $weeklyActual',
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                Text(
                  'YTD:  $ytdActual',
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          _smallGauge(label: 'YTD', ratio: ytdRatio, percentText: ytdPctText),
        ],
      ),
    );
  }

  Widget _smallGauge({
    required String label,
    required double? ratio,
    required String percentText,
  }) {
    final safeRatio = (ratio ?? 0).clamp(0.0, 10.0);
    final progress = safeRatio.clamp(0.0, 1.0);
    final tint = _financialGaugeColour(ratio);

    return Column(
      children: [
        SizedBox(
          width: 74,
          height: 74,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            builder: (context, animProgress, _) {
              return CustomPaint(
                painter: _GaugeRingPainter(
                  progress: animProgress,
                  color: tint,
                  backgroundColor: Colors.white.withValues(alpha: 0.12),
                  strokeWidth: 10,
                ),
                child: Center(
                  child: Text(
                    percentText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      height: 1.0,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardBlue.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }
}

class _GaugeRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;

  _GaugeRingPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
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
  }

  @override
  bool shouldRepaint(covariant _GaugeRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

// helpers

double? _asDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

Color _financialGaugeColour(double? ratio) {
  if (ratio == null) return Colors.white;
  if (ratio < 0.50) return const Color(0xFFFF5A5A);
  if (ratio < 0.85) return const Color(0xFFFF9E3D);
  if (ratio < 1.00) return const Color(0xFFF1C84B);
  if (ratio <= 1.10) return const Color(0xFF61D36B);
  return const Color(0xFF42A5F5);
}

String _money0(double? value) {
  if (value == null) return '–';
  final rounded = value.round();
  final s = rounded.toString();
  final withCommas = s.replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  return '\$$withCommas';
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

List<_Venue> _venueList() => const [
  _Venue(26, 'Group'),
  _Venue(1, 'Lion Hotel'),
  _Venue(2, 'Cross Keys Hotel'),
  _Venue(3, 'Saracens Head Hotel'),
  _Venue(4, 'Cremorne Hotel'),
  _Venue(5, 'Alma Tavern'),
  _Venue(6, 'Little Bang Brewery'),
];
