import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'state_of_play_repository.dart';

const _bg = Color.fromRGBO(7, 32, 64, 1);

final stateOfPlayProvider = FutureProvider<List<_VenueStateOfPlay>>((ref) async {
  final json = await ref.watch(stateOfPlayRepositoryProvider).fetchStateOfPlay();
  final venues = (json['venues'] as List? ?? const [])
      .whereType<Map>()
      .map((e) => e.cast<String, dynamic>())
      .map(_VenueStateOfPlay.fromJson)
      .toList();

  // Replace underscores like SwiftUI does
  for (final v in venues) {
    v.venueName = v.venueName.replaceAll('_', ' ');
  }
  return venues;
});

class StateOfPlayScreen extends ConsumerWidget {
  const StateOfPlayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(stateOfPlayProvider);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'State of Play',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.white),
          onPressed: () => context.go('/'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              const Text(
                'State of Play',
                style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                'Weekly & YTD performance vs budget',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 15),
              ),
              const SizedBox(height: 14),

              Expanded(
                child: async.when(
                  loading: () => Center(
                    child: CircularProgressIndicator(color: Colors.white.withValues(alpha: 0.9)),
                  ),
                  error: (err, _) => Center(
                    child: Text(
                      err.toString(),
                      style: const TextStyle(color: Colors.redAccent),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  data: (venues) {
                    final group = venues.where((v) => v.isGroup).toList();
                    final others = venues.where((v) => !v.isGroup).toList()
                      ..sort((a, b) => b.ebPct.compareTo(a.ebPct));

                    final ordered = <_VenueStateOfPlay>[
                      ...group,
                      ...others,
                    ];

                    return RefreshIndicator(
                      onRefresh: () async => ref.refresh(stateOfPlayProvider.future),
                      child: ListView.separated(
                        padding: const EdgeInsets.only(top: 6, bottom: 10),
                        itemCount: ordered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, i) => _StateOfPlayRow(venue: ordered[i]),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VenueStateOfPlay {
  _VenueStateOfPlay({
    required this.venueName,
    required this.isGroup,
    required this.revActual,
    required this.revBudget,
    required this.ebActual,
    required this.ebBudget,
  });

  String venueName;
  final bool isGroup;

  final double revActual;
  final double revBudget;
  final double ebActual;
  final double ebBudget;

  double get revPct => revBudget == 0 ? 0 : (revActual / revBudget) * 100.0;
  double get ebPct => ebBudget == 0 ? 0 : (ebActual / ebBudget) * 100.0;

  static double _asDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  factory _VenueStateOfPlay.fromJson(Map<String, dynamic> j) {
    return _VenueStateOfPlay(
      venueName: (j['venue'] as String?) ?? 'Unknown',
      isGroup: (j['isGroup'] as bool?) ?? false,
      revActual: _asDouble(j['revActual']),
      revBudget: _asDouble(j['revBudget']),
      ebActual: _asDouble(j['ebActual']),
      ebBudget: _asDouble(j['ebBudget']),
    );
  }
}

class _StateOfPlayRow extends StatelessWidget {
  const _StateOfPlayRow({required this.venue});
  final _VenueStateOfPlay venue;

  Color get _revColor => venue.revPct >= 100 ? const Color(0xFF61D36B) : const Color(0xFFFF5A5A);
  Color get _ebColor => venue.ebPct >= 100 ? const Color(0xFF61D36B) : const Color(0xFFFF5A5A);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  venue.venueName,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (venue.isGroup)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Group',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Revenue column
              Expanded(
                child: _MetricBlock(
                  title: 'Revenue YTD',
                  actual: venue.revActual,
                  budget: venue.revBudget,
                  pct: venue.revPct,
                  pctColor: _revColor,
                ),
              ),
              const SizedBox(width: 14),
              // EBITDA column
              Expanded(
                child: _MetricBlock(
                  title: 'EBITDA YTD',
                  actual: venue.ebActual,
                  budget: venue.ebBudget,
                  pct: venue.ebPct,
                  pctColor: _ebColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricBlock extends StatelessWidget {
  const _MetricBlock({
    required this.title,
    required this.actual,
    required this.budget,
    required this.pct,
    required this.pctColor,
  });

  final String title;
  final double actual;
  final double budget;
  final double pct;
  final Color pctColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          _money2(actual),
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 2),
        Text(
          'Budget: ${_money2(budget)}',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          '${pct.toStringAsFixed(1)}%',
          style: TextStyle(color: pctColor, fontSize: 14, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

String _money2(double value) {
  final fixed = value.toStringAsFixed(2);
  final parts = fixed.split('.');
  final whole = parts.first;
  final frac = parts.length > 1 ? parts[1] : '00';
  final withCommas = whole.replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  return '\$$withCommas.$frac';
}
