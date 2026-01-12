import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../core/api_errors.dart';
import 'trends_dtos.dart';

final trendsVenuesProvider = FutureProvider<List<TrendsVenue>>((ref) async {
  return ref.watch(trendsRepositoryProvider).fetchTrendsVenues();
});

class TrendsScreen extends ConsumerWidget {
  const TrendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(trendsVenuesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Trends')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) {
          final msg = (err is ApiAuthException || err is ApiHttpException) ? err.toString() : '$err';
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(msg, textAlign: TextAlign.center),
            ),
          );
        },
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('No venues returned.'));
          }

          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final v = items[i];

              return ListTile(
                title: Text(v.name),
                subtitle: Text('${v.region} • VenueId ${v.id}'),
                trailing: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_currency0(v.currYtdRevenue), style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text('EBITDA ${_currency0(v.currYtdEbitda)}', style: const TextStyle(fontSize: 12)),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _currency0(double value) {
    // simple formatter (we can replace with intl later if you want)
    final rounded = value.round();
    final s = rounded.toString();
    final withCommas = s.replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    return '\$$withCommas';
  }
}
