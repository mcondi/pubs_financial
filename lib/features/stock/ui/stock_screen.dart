import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:pubs_financial/app/models/venue.dart';
import 'package:pubs_financial/app/venues_sorted_provider.dart';
import 'package:pubs_financial/app/providers.dart';

import 'package:pubs_financial/features/stock/data/stock_models.dart';
import 'package:pubs_financial/features/stock/data/stock_repository.dart';
import 'package:pubs_financial/features/stock/stock_gauge.dart';

const int groupVenueId = 26;

// Duxton palette
const _bg = Color.fromRGBO(7, 32, 64, 1);
const _cardBlue = Color.fromRGBO(19, 52, 98, 1);

final stockVenueIdProvider = StateProvider<int>((ref) => groupVenueId);

final stockSummaryProvider =
    FutureProvider.autoDispose<StockSummary>((ref) async {
  final repo = ref.watch(stockRepositoryProvider);
  final venueId = ref.watch(stockVenueIdProvider);

  return repo.getSummaryWithFallback(
    venueId: venueId,
    startWeekendDate: DateTime.now(),
    mode: 'weekly',
    maxWeeksBack: 104,
  );
});

class StockScreen extends ConsumerWidget {
  const StockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final venuesAsync = ref.watch(venuesSortedProvider);

    return venuesAsync.when(
      loading: () => const Scaffold(
        backgroundColor: _bg,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: _bg,
        body: _error(e.toString()),
      ),
      data: (venues) {
        if (venues.isEmpty) {
          return const Scaffold(
            backgroundColor: _bg,
            body: Center(
              child: Text('No venues available', style: TextStyle(color: Colors.white)),
            ),
          );
        }

        final currentId = ref.watch(stockVenueIdProvider);
        final safeVenueId = venues.any((v) => v.id == currentId)
            ? currentId
            : venues.firstWhere(
                (v) => v.id == groupVenueId,
                orElse: () => venues.first,
              ).id;

        if (safeVenueId != currentId) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(stockVenueIdProvider.notifier).state = safeVenueId;
          });
        }

        final venueName = safeVenueId == groupVenueId
            ? 'Group'
            : venues.firstWhere((v) => v.id == safeVenueId).name;

        final async = ref.watch(stockSummaryProvider);

        return Scaffold(
          backgroundColor: _bg,
          appBar: AppBar(
            backgroundColor: _bg,
            elevation: 0,
            centerTitle: true,
            title: const Text('Stock'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              onPressed: () => context.go('/'),
            ),
          ),
          body: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _error(e.toString()),
            data: (s) => ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                const Text(
                  'Stock',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Weeks on hand & annualised turns',
                  style: TextStyle(color: Colors.white.withOpacity(0.7)),
                ),
                const SizedBox(height: 14),

                _venuePicker(
                  venues: venues,
                  selectedVenueId: safeVenueId,
                  selectedVenueName: venueName,
                  onPickVenue: (id) {
                    ref.read(stockVenueIdProvider.notifier).state = id;
                    ref.invalidate(stockSummaryProvider);
                  },
                ),

                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Week ending ${_prettyDate(s.weekendDate)}',
                    style: TextStyle(color: Colors.white.withOpacity(0.65)),
                  ),
                ),

                const SizedBox(height: 14),

                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.25,
                  children: [
                    StockGauge(
                      title: 'Food Weeks on Hand',
                      value: s.foodWeeksOnHand,
                      min: 0,
                      max: 8,
                      suffix: ' wks',
                      lowerBetter: true,
                    ),
                    StockGauge(
                      title: 'Bev Weeks on Hand',
                      value: s.beverageWeeksOnHand,
                      min: 0,
                      max: 8,
                      suffix: ' wks',
                      lowerBetter: true,
                    ),
                    StockGauge(
                      title: 'Food Turns (Ann.)',
                      value: s.foodStockTurnsAnnualised,
                      min: 0,
                      max: 30,
                      suffix: 'x',
                      lowerBetter: false,
                    ),
                    StockGauge(
                      title: 'Bev Turns (Ann.)',
                      value: s.beverageStockTurnsAnnualised,
                      min: 0,
                      max: 30,
                      suffix: 'x',
                      lowerBetter: false,
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                _summaryCard(s),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _venuePicker({
    required List<Venue> venues,
    required int selectedVenueId,
    required String selectedVenueName,
    required void Function(int id) onPickVenue,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Venue', style: TextStyle(color: Colors.white.withOpacity(0.7))),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _cardBlue.withOpacity(0.9),
            borderRadius: BorderRadius.circular(14),
          ),
          child: PopupMenuButton<int>(
            initialValue: selectedVenueId,
            onSelected: onPickVenue,
            itemBuilder: (context) => venues
                .map(
                  (v) => PopupMenuItem<int>(
                    value: v.id,
                    child: Text(v.id == groupVenueId ? 'Group' : v.name),
                  ),
                )
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
                const Icon(Icons.keyboard_arrow_down, color: Colors.white),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _summaryCard(StockSummary s) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardBlue.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Food Purchases: \$${s.foodPurchases.toStringAsFixed(0)}',
              style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 4),
          Text('Inv Food: \$${s.inventoryFood.toStringAsFixed(0)}',
              style: TextStyle(color: Colors.white.withOpacity(0.75))),
          Text('Inv Bev: \$${s.inventoryBeverage.toStringAsFixed(0)}',
              style: TextStyle(color: Colors.white.withOpacity(0.75))),
        ],
      ),
    );
  }

  Widget _error(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(msg, style: const TextStyle(color: Colors.red)),
      ),
    );
  }
}

String _prettyDate(DateTime d) {
  const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}
