import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/models/venue.dart';
import '../../app/venues_sorted_provider.dart';
import '../trends/trends_dtos.dart';
import 'weekly_notes_repository.dart';

const _bg = Color.fromRGBO(7, 32, 64, 1);
const _cardBlue = Color.fromRGBO(19, 52, 98, 1);
const int groupVenueId = 26;

final weeklyNotesVenueIdProvider = StateProvider<int>((ref) => groupVenueId);
final weeklyNotesWeekEndProvider = StateProvider<String>((ref) => _currentWeekEndISO());

// Fetch current notes record (or null if none)
final weeklyNotesDataProvider = FutureProvider.autoDispose<WeekNotesResponse?>((ref) async {
  final repo = ref.watch(weeklyNotesRepositoryProvider);
  final venueId = ref.watch(weeklyNotesVenueIdProvider);
  final weekEndISO = ref.watch(weeklyNotesWeekEndProvider);

  final apiVenueId = (venueId == groupVenueId) ? null : venueId;
  return repo.fetchWeekNotes(weekEndISO: weekEndISO, venueId: apiVenueId);
});

class WeeklyNotesScreen extends ConsumerStatefulWidget {
  const WeeklyNotesScreen({super.key});

  @override
  ConsumerState<WeeklyNotesScreen> createState() => _WeeklyNotesScreenState();
}

class _WeeklyNotesScreenState extends ConsumerState<WeeklyNotesScreen> {
  // You can make this a dropdown later; for now keep a stable default.
  static const String _defaultCategory = 'general';

  final _noteController = TextEditingController();
  final _hashtagController = TextEditingController();

  bool _dirty = false;
  bool _saving = false;

  List<String> _hashtags = const [];
  String _category = _defaultCategory;

  @override
  void dispose() {
    _noteController.dispose();
    _hashtagController.dispose();
    super.dispose();
  }

  void _applyFromServer(WeekNotesResponse? resp) {
    // Only hydrate if user hasn't started editing
    if (_dirty) return;

    _category = (resp?.category.isNotEmpty ?? false) ? resp!.category : _defaultCategory;
    _noteController.text = resp?.generalNote ?? '';
    _hashtags = resp?.hashtags ?? const [];
  }

  Future<void> _save({required int venueId, required String weekEndISO}) async {
    final repo = ref.read(weeklyNotesRepositoryProvider);
    final apiVenueId = (venueId == groupVenueId) ? null : venueId;

    setState(() => _saving = true);
    try {
      await repo.upsertWeekNotes(
        weekEndISO: weekEndISO,
        venueId: apiVenueId,
        category: _category,
        generalNote: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        hashtags: _hashtags,
      );

      // Refresh from server so UI matches canonical
      ref.invalidate(weeklyNotesDataProvider);
      await ref.read(weeklyNotesDataProvider.future);

      setState(() => _dirty = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Weekly notes saved')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _addHashtag() {
    var tag = _hashtagController.text.trim();
    if (tag.isEmpty) return;

    // Normalize
    if (tag.startsWith('#')) tag = tag.substring(1);
    tag = tag.replaceAll(' ', '');

    if (tag.isEmpty) return;

    setState(() {
      final next = [..._hashtags];
      if (!next.any((t) => t.toLowerCase() == tag.toLowerCase())) {
        next.add(tag);
      }
      _hashtags = next;
      _dirty = true;
      _hashtagController.clear();
    });
  }

  void _removeHashtag(String tag) {
    setState(() {
      _hashtags = _hashtags.where((t) => t != tag).toList();
      _dirty = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final venuesAsync = ref.watch(venuesSortedProvider);
    final notesAsync = ref.watch(weeklyNotesDataProvider);

    final weekEndISO = ref.watch(weeklyNotesWeekEndProvider);
    final selectedVenueId = ref.watch(weeklyNotesVenueIdProvider);

    // hydrate editor from server response (once)
    notesAsync.whenData(_applyFromServer);

    return venuesAsync.when(
      loading: () => const Scaffold(backgroundColor: _bg, body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(backgroundColor: _bg, body: _errorView(e.toString())),
      data: (venues) {
        final safeVenueId = venues.any((v) => v.id == selectedVenueId)
            ? selectedVenueId
            : venues.firstWhere((v) => v.id == groupVenueId, orElse: () => venues.first).id;

        if (safeVenueId != selectedVenueId) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(weeklyNotesVenueIdProvider.notifier).state = safeVenueId;
          });
        }

        final venueName = safeVenueId == groupVenueId
            ? 'Group'
            : venues.firstWhere((v) => v.id == safeVenueId, orElse: () => venues.first).name;

        return Scaffold(
          backgroundColor: _bg,
          appBar: AppBar(
            backgroundColor: _bg,
            elevation: 0,
            centerTitle: true,
            title: const Text(
              'Weekly Notes',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.white),
              onPressed: () => context.go('/'),
            ),
            actions: [
              TextButton(
                onPressed: _saving ? null : () => _save(venueId: safeVenueId, weekEndISO: weekEndISO),
                child: _saving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(
                        'Save',
                        style: TextStyle(
                          color: _dirty ? Colors.white : Colors.white.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
              const SizedBox(width: 6),
            ],
          ),
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                _dirty = false; // allow hydration again if user pulls refresh
                ref.invalidate(weeklyNotesDataProvider);
                await ref.read(weeklyNotesDataProvider.future);
                setState(() {});
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                children: [
                  const Text(
                    'Weekly Notes',
                    style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Primary place to capture, edit and maintain weekly notes.',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
                  ),
                  const SizedBox(height: 14),

                  _headerBar(
                    venues: venues,
                    selectedVenueId: safeVenueId,
                    selectedVenueName: venueName,
                    weekEndISO: weekEndISO,
                    onPickVenue: (id) {
                      ref.read(weeklyNotesVenueIdProvider.notifier).state = id;
                      _dirty = false;
                      ref.invalidate(weeklyNotesDataProvider);
                      setState(() {});
                    },
                    onPrevWeek: () {
                      ref.read(weeklyNotesWeekEndProvider.notifier).state = _shiftWeek(weekEndISO, days: -7);
                      _dirty = false;
                      ref.invalidate(weeklyNotesDataProvider);
                      setState(() {});
                    },
                    onNextWeek: () {
                      ref.read(weeklyNotesWeekEndProvider.notifier).state = _shiftWeek(weekEndISO, days: 7);
                      _dirty = false;
                      ref.invalidate(weeklyNotesDataProvider);
                      setState(() {});
                    },
                  ),

                  const SizedBox(height: 14),

                  // Editor card
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        notesAsync.when(
                          loading: () => Text(
                            'Loading notes…',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.65)),
                          ),
                          error: (e, _) => Text(
                            'Failed to load: $e',
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                          data: (resp) => Text(
                            resp?.generalNote == null
                                ? 'No notes saved for this week yet.'
                                : 'Loaded. You can edit and save.',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.65)),
                          ),
                        ),
                        const SizedBox(height: 10),

                        TextField(
                          controller: _noteController,
                          maxLines: 10,
                          style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.25),
                          onChanged: (_) => setState(() => _dirty = true),
                          decoration: InputDecoration(
                            hintText: 'Write weekly notes here…\n\n• Wins\n• Issues\n• Actions\n• Anything important',
                            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.45)),
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.06),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Hashtags
                        Text('Hashtags', style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),

                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final tag in _hashtags)
                              InputChip(
                                label: Text('#$tag'),
                                onDeleted: () => _removeHashtag(tag),
                                labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                deleteIconColor: Colors.white.withValues(alpha: 0.85),
                                backgroundColor: Colors.white.withValues(alpha: 0.10),
                                side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                              ),
                          ],
                        ),

                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _hashtagController,
                                style: const TextStyle(color: Colors.white),
                                onChanged: (_) => setState(() {}),
                                decoration: InputDecoration(
                                  hintText: 'Add hashtag (e.g. staffing)',
                                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.45)),
                                  filled: true,
                                  fillColor: Colors.white.withValues(alpha: 0.06),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: _hashtagController.text.trim().isEmpty ? null : _addHashtag,
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF42A5F5)),
                              child: const Text('Add'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Bottom Save CTA (optional)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : () => _save(venueId: safeVenueId, weekEndISO: weekEndISO),
                      icon: const Icon(Icons.save),
                      label: const Text('Save Weekly Notes'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF42A5F5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ---------- UI helpers ----------

  Widget _headerBar({
    required List<Venue> venues,
    required int selectedVenueId,
    required String selectedVenueName,
    required String weekEndISO,
    required void Function(int) onPickVenue,
    required VoidCallback onPrevWeek,
    required VoidCallback onNextWeek,
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
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          ),
          child: Row(
            children: [
              Expanded(
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
              const SizedBox(width: 10),
              IconButton(
                onPressed: onPrevWeek,
                icon: Icon(Icons.arrow_circle_left, size: 30, color: Colors.white.withValues(alpha: 0.9)),
              ),
              IconButton(
                onPressed: onNextWeek,
                icon: Icon(Icons.arrow_circle_right, size: 30, color: Colors.white.withValues(alpha: 0.9)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Week ending ${_prettyWeekEnd(weekEndISO)}',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.70), fontSize: 12),
          ),
        ),
      ],
    );
  }

  static Widget _errorView(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(msg, style: const TextStyle(color: Colors.redAccent), textAlign: TextAlign.center),
      ),
    );
  }

  Widget _card({required Widget child, double alpha = 0.9}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBlue.withValues(alpha: alpha),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: child,
    );
  }
}

// ---------- Date helpers ----------

String _currentWeekEndISO() {
  // week ending = Sunday
  final now = DateTime.now();
  final daysUntilSunday = DateTime.sunday - now.weekday;
  final sunday = now.add(Duration(days: daysUntilSunday));
  return _toISODate(sunday);
}

String _shiftWeek(String weekEndISO, {required int days}) {
  final dt = DateTime.tryParse(weekEndISO);
  if (dt == null) return weekEndISO;
  return _toISODate(dt.add(Duration(days: days)));
}

String _toISODate(DateTime dt) {
  final y = dt.year.toString().padLeft(4, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

String _prettyWeekEnd(String iso) {
  final dt = DateTime.tryParse(iso);
  if (dt == null) return iso;
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  final mon = months[dt.month - 1];
  return '${dt.day} $mon ${dt.year}';
}
