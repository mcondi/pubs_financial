import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/models/venue.dart';
import '../../../app/venues_sorted_provider.dart';
import '../../../app/providers.dart';

import '../state/sevenrooms_review_draft_controller.dart';

const int groupVenueId = 26;
const _bg = Color.fromRGBO(7, 32, 64, 1);
const _cardBlue = Color.fromRGBO(19, 52, 98, 1);

class SevenRoomsReviewStartScreen extends ConsumerStatefulWidget {
  const SevenRoomsReviewStartScreen({super.key});

  @override
  ConsumerState<SevenRoomsReviewStartScreen> createState() =>
      _SevenRoomsReviewStartScreenState();
}

class _SevenRoomsReviewStartScreenState
    extends ConsumerState<SevenRoomsReviewStartScreen> {
  bool _didInit = false;

  @override
  Widget build(BuildContext context) {
    final venuesAsync = ref.watch(venuesSortedProvider);
    final draft = ref.watch(sevenRoomsReviewDraftProvider);
    final ctrl = ref.read(sevenRoomsReviewDraftProvider.notifier);

    return venuesAsync.when(
      loading: () => const Scaffold(
        backgroundColor: _bg,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: _bg,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(e.toString(),
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center),
          ),
        ),
      ),
      data: (venues) {
        if (venues.isEmpty) {
          return const Scaffold(
            backgroundColor: _bg,
            body: Center(
              child: Text('No venues available.',
                  style: TextStyle(color: Colors.white)),
            ),
          );
        }

        // Init venue once when venues load
        if (!_didInit) {
          _didInit = true;
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            final settings = ref.read(settingsStoreProvider);
            final saved = await settings.readDefaultVenueId();

            int chosen;
            if (saved != null && venues.any((v) => v.id == saved)) {
              chosen = saved;
            } else if (venues.any((v) => v.id == groupVenueId)) {
              chosen = groupVenueId;
            } else {
              chosen = venues.first.id;
            }
            ctrl.setVenue(chosen);
          });
        }

        final selectedId = (draft.venueId != null && venues.any((v) => v.id == draft.venueId))
            ? draft.venueId!
            : (venues.any((v) => v.id == groupVenueId) ? groupVenueId : venues.first.id);

        final selectedName = selectedId == groupVenueId
            ? 'Group'
            : venues.firstWhere((v) => v.id == selectedId, orElse: () => venues.first).name;

        return Scaffold(
          backgroundColor: _bg,
          appBar: AppBar(
            backgroundColor: _bg,
            elevation: 0,
            centerTitle: true,
            title: const Text(
              'SevenRooms Review',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.white),
              onPressed: () => context.go('/'),
            ),
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                const Text(
                  'SevenRooms',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Venue Review Checklist',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
                ),
                const SizedBox(height: 14),

                _venuePicker(
                  venues: venues,
                  selectedVenueId: selectedId,
                  selectedVenueName: selectedName,
                  onPickVenue: (id) async {
                    ctrl.setVenue(id);
                    await ref.read(settingsStoreProvider).writeDefaultVenueId(id);
                  },
                ),

                const SizedBox(height: 12),
                _card(
                  child: Row(
                    children: [
                      Expanded(
                        child: _dateField(
                          context: context,
                          label: 'Review Date',
                          value: _fmtDate(draft.reviewDate),
                          onPick: (picked) => ctrl.setDate(picked),
                          initial: draft.reviewDate,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          initialValue: draft.reviewerName,
                          onChanged: ctrl.setReviewerName,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration('Reviewer Name'),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromRGBO(92, 188, 125, 1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => context.go('/sevenrooms-review/form'),
                    child: const Text('Start Review', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Next: score each category (1–5) and add evidence notes.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
                ),
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
        Text('Venue', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _cardBlue.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: PopupMenuButton<int>(
            initialValue: selectedVenueId,
            onSelected: onPickVenue,
            itemBuilder: (context) => venues
                .map((v) => PopupMenuItem<int>(
                      value: v.id,
                      child: Text(v.id == groupVenueId ? 'Group' : v.name),
                    ))
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
      ],
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardBlue.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: child,
    );
  }

  Widget _dateField({
    required BuildContext context,
    required String label,
    required String value,
    required DateTime initial,
    required void Function(DateTime picked) onPick,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: initial,
          firstDate: DateTime(2020, 1, 1),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) onPick(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          filled: true,
          fillColor: _cardBlue.withValues(alpha: 0.60),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
          ),
        ),
        child: Text(value, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  static InputDecoration _inputDecoration(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: _cardBlue.withValues(alpha: 0.60),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.30)),
        ),
      );

  static String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
