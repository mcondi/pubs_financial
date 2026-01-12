import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'gaming_repository.dart';

const int groupVenueId = 26;

class _GamingArgs {
  final int venueId;
  final String? weekEnd; // YYYY-MM-DD
  const _GamingArgs(this.venueId, this.weekEnd);

  @override
  bool operator ==(Object other) =>
      other is _GamingArgs && other.venueId == venueId && other.weekEnd == weekEnd;

  @override
  int get hashCode => Object.hash(venueId, weekEnd);
}

final gamingVenueIdProvider = StateProvider<int>((ref) => groupVenueId);

final gamingDataProvider =
    FutureProvider.family<Map<String, dynamic>, _GamingArgs>((ref, args) async {
  return ref.watch(gamingRepositoryProvider).fetchGamingSummary(
        venueId: args.venueId,
        weekEnd: args.weekEnd,
      );
});

class GamingScreen extends ConsumerStatefulWidget {
  const GamingScreen({super.key});

  @override
  ConsumerState<GamingScreen> createState() => _GamingScreenState();
}

class _GamingScreenState extends ConsumerState<GamingScreen> {
  String? _weekEndOverride; // YYYY-MM-DD

  @override
  Widget build(BuildContext context) {
    final venueId = ref.watch(gamingVenueIdProvider);
    final async = ref.watch(gamingDataProvider(_GamingArgs(venueId, _weekEndOverride)));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('Gaming', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
        leading: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: _BackCircleButton(onTap: () => context.go('/')),
        ),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) {
          final msg = _extractMessage(err.toString());
          final noData = msg.toLowerCase().contains('no gaming data available');

          if (noData) {
            return _EmptyState(
              message: 'No gaming data is available for this venue/week.',
              onRetry: () => _refresh(venueId),
            );
          }

          return _ErrorState(
            message: _sanitizeError(msg),
            onRetry: () => _refresh(venueId),
          );
        },
        data: (json) {
          // DTO keys like iOS GamingSummaryDTO
          final venueName = (json['venueName'] as String?) ?? 'Venue';
          final weekEnd = (json['weekEnd'] as String?) ?? '';
          final prevWeekEnd = (json['prevWeekEnd'] as String?) ?? '';
          final nextWeekEnd = (json['nextWeekEnd'] as String?) ?? '';

          final turnoverCurrent = _asDouble(json['turnoverCurrent']) ?? 0;
          final turnoverTrend = _asDouble(json['turnoverTrend']) ?? 0;

          final winsCurrent = _asDouble(json['winsCurrent']) ?? 0;
          final winsTrend = _asDouble(json['winsTrend']) ?? 0;

          // iOS DTO has rtpCurrent as percent (e.g. 92.3) but UI computes RTP = wins/turnover.
          // We'll follow the SwiftUI view logic (wins/turnover), not the raw rtp field.
          final avgBetCurrent = _asDouble(json['avgBetCurrent']) ?? 0;
          final avgBetTrend = _asDouble(json['avgBetTrend']) ?? 0;

          final canPrev = prevWeekEnd.isNotEmpty;
          final canNext = nextWeekEnd.isNotEmpty;

          // Derived:
          final netCurrent = turnoverCurrent - winsCurrent;
          final netTrend = turnoverTrend - winsTrend;

          final holdCurrent = turnoverCurrent != 0 ? (netCurrent / turnoverCurrent) : 0.0;
          final holdTrend = turnoverTrend != 0 ? (netTrend / turnoverTrend) : 0.0;

          final rtpCurrent = turnoverCurrent != 0 ? (winsCurrent / turnoverCurrent) : 0.0;
          final rtpTrend = turnoverTrend != 0 ? (winsTrend / turnoverTrend) : 0.0;

          return RefreshIndicator(
            onRefresh: () async => _refresh(venueId),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                // Header bar (Venue + arrows)
                _HeaderBar(
                  selectedVenueId: venueId,
                  selectedVenueName: venueName,
                  canPrev: canPrev,
                  canNext: canNext,
                  onPickVenue: (id) {
                    ref.read(gamingVenueIdProvider.notifier).state = id;
                    setState(() => _weekEndOverride = null);
                  },
                  onPrev: !canPrev
                      ? null
                      : () => setState(() => _weekEndOverride = _toDateOnly(prevWeekEnd)),
                  onNext: !canNext
                      ? null
                      : () => setState(() => _weekEndOverride = _toDateOnly(nextWeekEnd)),
                ),

                const SizedBox(height: 10),

                if (weekEnd.isNotEmpty)
                  Center(
                    child: Text(
                      'Week ending ${_prettyWeekEnd(weekEnd)}',
                      style: TextStyle(color: Colors.black.withValues(alpha: 0.45), fontSize: 13),
                    ),
                  ),

                const SizedBox(height: 14),

                // Executive snapshot card
                _GamingSnapshotCard(
                  turnoverCurrent: turnoverCurrent,
                  turnoverTrend: turnoverTrend,
                  netCurrent: netCurrent,
                  netTrend: netTrend,
                  rtpCurrent: rtpCurrent,
                  rtpTrend: rtpTrend,
                ),

                const SizedBox(height: 14),

                // 2-col grid of metric cards
                LayoutBuilder(
                  builder: (context, constraints) {
                    final w = constraints.maxWidth;
                    final gap = 12.0;
                    final cardW = (w - gap) / 2;

                    return Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: [
                        SizedBox(
                          width: cardW,
                          child: _MetricCardCurrency(
                            title: 'Turnover',
                            current: turnoverCurrent,
                            trend: turnoverTrend,
                            decimals: 0,
                            higherIsBetter: true,
                          ),
                        ),
                        SizedBox(
                          width: cardW,
                          child: _MetricCardCurrency(
                            title: 'Wins',
                            current: winsCurrent,
                            trend: winsTrend,
                            decimals: 0,
                            higherIsBetter: true,
                          ),
                        ),
                        SizedBox(
                          width: cardW,
                          child: _MetricCardCurrency(
                            title: 'Net',
                            current: netCurrent,
                            trend: netTrend,
                            decimals: 0,
                            higherIsBetter: true,
                          ),
                        ),
                        SizedBox(
                          width: cardW,
                          child: _MetricCardPercent(
                            title: 'RTP',
                            current: rtpCurrent,
                            trend: rtpTrend,
                            higherIsBetter: true,
                          ),
                        ),
                        SizedBox(
                          width: cardW,
                          child: _MetricCardCurrency(
                            title: 'Average Bet',
                            current: avgBetCurrent,
                            trend: avgBetTrend,
                            decimals: 2,
                            higherIsBetter: true,
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 14),

                // Insights
                _InsightsCard(
                  turnoverCurrent: turnoverCurrent,
                  turnoverTrend: turnoverTrend,
                  netCurrent: netCurrent,
                  netTrend: netTrend,
                  holdCurrent: holdCurrent,
                  holdTrend: holdTrend,
                  rtpCurrent: rtpCurrent,
                  rtpTrend: rtpTrend,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _refresh(int venueId) async {
    ref.invalidate(gamingDataProvider);
    await ref.read(gamingDataProvider(_GamingArgs(venueId, _weekEndOverride)).future);
  }
}

/// ---------- UI bits ----------

class _BackCircleButton extends StatelessWidget {
  const _BackCircleButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.06),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(10),
          child: Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.black),
        ),
      ),
    );
  }
}

class _HeaderBar extends StatelessWidget {
  const _HeaderBar({
    required this.selectedVenueId,
    required this.selectedVenueName,
    required this.canPrev,
    required this.canNext,
    required this.onPickVenue,
    required this.onPrev,
    required this.onNext,
  });

  final int selectedVenueId;
  final String selectedVenueName;
  final bool canPrev;
  final bool canNext;
  final void Function(int id) onPickVenue;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final venues = _venueList(); // swap later with shared venue provider/list

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Venue',
          style: TextStyle(color: Colors.black.withValues(alpha: 0.45), fontSize: 13),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: PopupMenuButton<int>(
                initialValue: selectedVenueId,
                onSelected: onPickVenue,
                itemBuilder: (context) => venues
                    .map((v) => PopupMenuItem<int>(
                          value: v.id,
                          child: Text(v.name),
                        ))
                    .toList(),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        selectedVenueName,
                        style: const TextStyle(
                          color: Color(0xFF1976D2), // iOS-like blue
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.keyboard_arrow_down, color: const Color(0xFF1976D2).withValues(alpha: 0.8)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),
            IconButton(
              onPressed: onPrev,
              icon: Icon(
                Icons.chevron_left,
                color: Colors.white,
              ),
              style: IconButton.styleFrom(
                backgroundColor: canPrev ? const Color(0xFF1976D2) : Colors.grey.withValues(alpha: 0.35),
                fixedSize: const Size(44, 44),
                shape: const CircleBorder(),
              ),
            ),
            const SizedBox(width: 10),
            IconButton(
              onPressed: onNext,
              icon: const Icon(Icons.chevron_right, color: Colors.white),
              style: IconButton.styleFrom(
                backgroundColor: canNext ? const Color(0xFF1976D2) : Colors.grey.withValues(alpha: 0.35),
                fixedSize: const Size(44, 44),
                shape: const CircleBorder(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _GamingSnapshotCard extends StatelessWidget {
  const _GamingSnapshotCard({
    required this.turnoverCurrent,
    required this.turnoverTrend,
    required this.netCurrent,
    required this.netTrend,
    required this.rtpCurrent,
    required this.rtpTrend,
  });

  final double turnoverCurrent;
  final double turnoverTrend;
  final double netCurrent;
  final double netTrend;
  final double rtpCurrent;
  final double rtpTrend;

  @override
  Widget build(BuildContext context) {
    final turnoverDiff = turnoverCurrent - turnoverTrend;
    final turnoverPct = turnoverTrend != 0 ? turnoverDiff / turnoverTrend : 0.0;

    final netDiff = netCurrent - netTrend;
    final netPct = netTrend != 0 ? netDiff / netTrend : 0.0;

    final rtpDiff = rtpCurrent - rtpTrend;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Gaming snapshot', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Divider(color: Colors.black.withValues(alpha: 0.08), height: 1),
          const SizedBox(height: 12),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _SnapBlock(
                  title: 'Turnover',
                  value: _money0(turnoverCurrent),
                  deltaLine:
                      '${_signedMoney0(turnoverDiff)} (${_pct1(turnoverPct)}) vs 12-wk avg',
                  deltaColor: turnoverDiff >= 0 ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F),
                ),
              ),
              Container(
                width: 1,
                height: 76,
                color: Colors.black.withValues(alpha: 0.10),
                margin: const EdgeInsets.symmetric(horizontal: 14),
              ),
              Expanded(
                child: _SnapBlock(
                  title: 'Net',
                  value: _money0(netCurrent),
                  deltaLine: '${_signedMoney0(netDiff)} (${_pct1(netPct)}) vs 12-wk avg',
                  deltaColor: netDiff >= 0 ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          Divider(color: Colors.black.withValues(alpha: 0.08), height: 1),
          const SizedBox(height: 12),

          _SnapBlock(
            title: 'RTP',
            value: _pct1Value(rtpCurrent),
            deltaLine: '${rtpDiff >= 0 ? '+' : ''}${_pct1Value(rtpDiff)} vs 12-wk avg',
            deltaColor: rtpDiff >= 0 ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F),
          ),
        ],
      ),
    );
  }
}

class _SnapBlock extends StatelessWidget {
  const _SnapBlock({
    required this.title,
    required this.value,
    required this.deltaLine,
    required this.deltaColor,
  });

  final String title;
  final String value;
  final String deltaLine;
  final Color deltaColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(color: Colors.black.withValues(alpha: 0.55), fontSize: 15)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(
          deltaLine,
          style: TextStyle(color: deltaColor, fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _MetricCardCurrency extends StatelessWidget {
  const _MetricCardCurrency({
    required this.title,
    required this.current,
    required this.trend,
    required this.decimals,
    required this.higherIsBetter,
  });

  final String title;
  final double current;
  final double trend;
  final int decimals;
  final bool higherIsBetter;

  @override
  Widget build(BuildContext context) {
    final diff = current - trend;
    final pct = trend != 0 ? diff / trend : 0.0;

    final isDiffPositive = diff >= 0;
    final isGood = higherIsBetter ? isDiffPositive : !isDiffPositive;

    final arrowDown = !isDiffPositive;
    final arrowColor = isGood ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F);

    final valueText = decimals == 0 ? _money0(current) : _money2(current);
    final trendText = decimals == 0 ? _money0(trend) : _money2(trend);
    final diffText = decimals == 0 ? _signedMoney0(diff) : _signedMoney2(diff);

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const Spacer(),
              Icon(
                arrowDown ? Icons.arrow_downward : Icons.arrow_upward,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 6),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(color: arrowColor, shape: BoxShape.circle),
                child: Icon(
                  arrowDown ? Icons.arrow_downward : Icons.arrow_upward,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(valueText, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(
            '12-week avg: $trendText',
            style: TextStyle(color: Colors.black.withValues(alpha: 0.45), fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            'vs avg: $diffText (${_pct1(pct.abs())})',
            style: TextStyle(color: arrowColor, fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _MetricCardPercent extends StatelessWidget {
  const _MetricCardPercent({
    required this.title,
    required this.current,
    required this.trend,
    required this.higherIsBetter,
  });

  final String title;
  final double current; // 0..1
  final double trend;   // 0..1
  final bool higherIsBetter;

  @override
  Widget build(BuildContext context) {
    final diff = current - trend;
    final isDiffPositive = diff >= 0;
    final isGood = higherIsBetter ? isDiffPositive : !isDiffPositive;

    final arrowDown = !isDiffPositive;
    final arrowColor = isGood ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F);

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const Spacer(),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(color: arrowColor, shape: BoxShape.circle),
                child: Icon(
                  arrowDown ? Icons.arrow_downward : Icons.arrow_upward,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(_pct1Value(current), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(
            '12-week avg: ${_pct1Value(trend)}',
            style: TextStyle(color: Colors.black.withValues(alpha: 0.45), fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            'vs avg: ${diff >= 0 ? '+' : ''}${_pct1Value(diff)}',
            style: TextStyle(color: arrowColor, fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _InsightsCard extends StatelessWidget {
  const _InsightsCard({
    required this.turnoverCurrent,
    required this.turnoverTrend,
    required this.netCurrent,
    required this.netTrend,
    required this.holdCurrent,
    required this.holdTrend,
    required this.rtpCurrent,
    required this.rtpTrend,
  });

  final double turnoverCurrent;
  final double turnoverTrend;
  final double netCurrent;
  final double netTrend;
  final double holdCurrent;
  final double holdTrend;
  final double rtpCurrent;
  final double rtpTrend;

  @override
  Widget build(BuildContext context) {
    final lines = <String>[];

    if (turnoverTrend != 0) {
      final diff = turnoverCurrent - turnoverTrend;
      final pct = diff / turnoverTrend;
      lines.add('Turnover is ${_signedMoney0(diff)} (${_pct1(pct)}) vs 12-week average.');
    }

    if (holdTrend != 0) {
      final diff = holdCurrent - holdTrend;
      lines.add(
        'Hold (net margin) is ${_pct1Value(holdCurrent)} vs ${_pct1Value(holdTrend)} 12-week avg (${diff >= 0 ? '+' : '-'}${_pct1(diff.abs())}).',
      );
    }

    final rtpDiff = rtpCurrent - rtpTrend;
    if (rtpDiff != 0) {
      lines.add(
        'RTP is ${_pct1Value(rtpCurrent)} (${rtpDiff >= 0 ? "above" : "below"} 12-week avg of ${_pct1Value(rtpTrend)}).',
      );
    }

    if (lines.isEmpty) return const SizedBox.shrink();

    return _Card(
      elevationAlpha: 0.03,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Insights', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          for (final line in lines) ...[
            Text('• $line', style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.elevationAlpha = 0.05});
  final Widget child;
  final double elevationAlpha;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: elevationAlpha),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: child,
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        _Card(
          child: Column(
            children: [
              Icon(Icons.casino, size: 36, color: Colors.black.withValues(alpha: 0.45)),
              const SizedBox(height: 10),
              const Text('No gaming data', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black.withValues(alpha: 0.55), fontSize: 14),
              ),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        _Card(
          child: Column(
            children: [
              Icon(Icons.error_outline, size: 36, color: Colors.black.withValues(alpha: 0.55)),
              const SizedBox(height: 10),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      ],
    );
  }
}

/// ---------- formatting / parsing ----------

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

String _money0(double value) {
  final rounded = value.round();
  final s = rounded.toString();
  final withCommas = s.replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  return '\$$withCommas';
}

String _money2(double value) {
  final fixed = value.toStringAsFixed(2);
  final parts = fixed.split('.');
  final whole = parts.first;
  final frac = parts.length > 1 ? parts[1] : '00';
  final withCommas = whole.replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  return '\$$withCommas.$frac';
}

String _signedMoney0(double value) => '${value >= 0 ? '+' : '-'}${_money0(value.abs())}';
String _signedMoney2(double value) => '${value >= 0 ? '+' : '-'}${_money2(value.abs())}';

String _pct1(double value) {
  // value is ratio (e.g. -0.084) -> "-8.4%"
  final v = value * 100;
  final sign = v >= 0 ? '' : '-';
  return '$sign${v.abs().toStringAsFixed(1)}%';
}

String _pct1Value(double value) {
  // value is 0..1 (e.g. 0.919) -> "91.9%"
  return '${(value * 100).toStringAsFixed(1)}%';
}

String _extractMessage(String raw) {
  // If backend throws {"message":"..."} and it's embedded in exception string
  final idx = raw.indexOf('"message"');
  if (idx == -1) return raw;

  // crude extract: "message":"...."
  final start = raw.indexOf(':', idx);
  if (start == -1) return raw;

  final firstQuote = raw.indexOf('"', start);
  if (firstQuote == -1) return raw;

  final secondQuote = raw.indexOf('"', firstQuote + 1);
  if (secondQuote == -1) return raw;

  return raw.substring(firstQuote + 1, secondQuote);
}

String _sanitizeError(String text) {
  final t = text.toLowerCase();
  if (t.contains('microsoft.data.sqlclient') || t.contains('stacktrace')) {
    return 'Unable to load gaming summary. Please try again.';
  }
  return text;
}

/// ---------- venue list (swap later with your shared list/provider) ----------

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
