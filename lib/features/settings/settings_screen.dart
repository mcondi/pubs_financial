import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/models/venue.dart';
import '../../app/venues_provider.dart';
import '../../app/biometrics/biometrics_service.dart';
import '../../app/providers.dart';
import 'settings_store.dart';

const _sheetBg = Color(0xFFF2F2F7);

final defaultVenueIdProvider = FutureProvider<int>((ref) async {
  final id = await ref.watch(settingsStoreProvider).readDefaultVenueId();
  return id ?? 26;
});

final defaultVenueIdStateProvider = StateProvider<int>((ref) => 26);

// ✅ persisted toggle state
final useFaceIdStateProvider = StateProvider<bool>((ref) => false);

// ✅ can device use biometrics
final canUseBiometricsProvider = FutureProvider<bool>((ref) async {
  return ref.watch(biometricsServiceProvider).canUseBiometrics();
});

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  void initState() {
    super.initState();

    // Load persisted settings once on entry
    Future.microtask(() async {
      final store = ref.read(settingsStoreProvider);

      final venueId = await store.readDefaultVenueId();
      ref.read(defaultVenueIdStateProvider.notifier).state = venueId ?? 26;

      final useFaceId = await store.readUseFaceId();
      ref.read(useFaceIdStateProvider.notifier).state = useFaceId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final venuesAsync = ref.watch(venuesProvider);
    final bioAsync = ref.watch(canUseBiometricsProvider);

    return venuesAsync.when(
      loading: () => _loadingScaffold(context),
      error: (e, _) => _errorScaffold(context, e.toString()),
      data: (venues) {
        final selectedId = ref.watch(defaultVenueIdStateProvider);
        final selectedVenue = venues.firstWhere(
          (v) => v.id == selectedId,
          orElse: () => venues.firstWhere(
            (v) => v.id == 26,
            orElse: () => venues.first,
          ),
        );

        return Scaffold(
          backgroundColor: _sheetBg,
          appBar: _settingsAppBar(context),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _sectionHeader('Default venue'),
              _roundedGroup(
                children: [
                  _row(
                    leading: const Text('Default venue', style: TextStyle(fontWeight: FontWeight.w600)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(selectedVenue.name, style: TextStyle(color: Colors.black.withValues(alpha: 0.45))),
                        const SizedBox(width: 6),
                        Icon(Icons.unfold_more, color: Colors.black.withValues(alpha: 0.35)),
                      ],
                    ),
                    onTap: () async {
                      final picked = await _pickVenue(context, venues, selectedId);
                      if (picked == null) return;

                      ref.read(defaultVenueIdStateProvider.notifier).state = picked;
                      await ref.read(settingsStoreProvider).writeDefaultVenueId(picked);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Used as the default selection in venue dropdowns across\nthe app.',
                style: TextStyle(color: Colors.black.withValues(alpha: 0.45)),
              ),

              const SizedBox(height: 18),

              _sectionHeader('Security'),

              // ✅ Biometrics-powered section
              bioAsync.when(
                loading: () => _roundedGroup(
                  children: [
                    _row(
                      leading: Row(
                        children: [
                          const Icon(Icons.face, color: Color(0xFF0A84FF)),
                          const SizedBox(width: 10),
                          const Text('Use Face ID to unlock', style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      trailing: const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      onTap: null,
                    ),
                  ],
                ),
                error: (e, _) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _roundedGroup(
                      children: [
                        _row(
                          leading: Row(
                            children: [
                              const Icon(Icons.face, color: Color(0xFF0A84FF)),
                              const SizedBox(width: 10),
                              const Text('Use Face ID to unlock', style: TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                          trailing: const Switch(value: false, onChanged: null),
                          onTap: null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Face ID check failed: $e',
                      style: TextStyle(color: Colors.black.withValues(alpha: 0.45)),
                    ),
                  ],
                ),
                data: (canUse) {
                  final useFaceId = ref.watch(useFaceIdStateProvider);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _roundedGroup(
                        children: [
                          _row(
                            leading: Row(
                              children: [
                                const Icon(Icons.face, color: Color(0xFF0A84FF)),
                                const SizedBox(width: 10),
                                const Text('Use Face ID to unlock', style: TextStyle(fontWeight: FontWeight.w600)),
                              ],
                            ),
                            trailing: Switch(
                              value: canUse ? useFaceId : false,
                              onChanged: !canUse
                                  ? null
                                  : (v) async {
                                      ref.read(useFaceIdStateProvider.notifier).state = v;
                                      await ref.read(settingsStoreProvider).writeUseFaceId(v);
                                    },
                            ),
                            onTap: null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        canUse
                            ? 'Use Face ID to unlock Pubs Financial.'
                            : 'Face ID is not available or not configured on this device.',
                        style: TextStyle(color: Colors.black.withValues(alpha: 0.45)),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 18),

              _sectionHeader('Invitations'),
              _roundedGroup(
                children: [
                  _row(
                    leading: Row(
                      children: [
                        const Icon(Icons.mail_outline, color: Colors.black),
                        const SizedBox(width: 10),
                        const Text('Invite user', style: TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    trailing: Icon(Icons.chevron_right, color: Colors.black.withValues(alpha: 0.25)),
                    onTap: () => context.push('/settings/invite'),
                  ),
                  _divider(),
                  _row(
                    leading: Row(
                      children: [
                        const Icon(Icons.group_outlined, color: Color(0xFF0A84FF)),
                        const SizedBox(width: 10),
                        const Text('User control', style: TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    trailing: Icon(Icons.chevron_right, color: Colors.black.withValues(alpha: 0.25)),
                    onTap: () => context.push('/settings/users'),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              _roundedGroup(
                children: [
                  _row(
                    leading: Row(
                      children: [
                        const Icon(Icons.logout, color: Colors.red),
                        const SizedBox(width: 10),
                        const Text(
                          'Log out',
                          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.red),
                        ),
                      ],
                    ),
                    trailing: const SizedBox.shrink(),
                    onTap: () async {
                      final tokenStore = ref.read(tokenStoreProvider);
                      await tokenStore.clear();
                      if (context.mounted) context.go('/login');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'You will need to sign in again with your PubsFinancial\ncredentials.',
                style: TextStyle(color: Colors.black.withValues(alpha: 0.45)),
              ),
            ],
          ),
        );
      },
    );
  }

  AppBar _settingsAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: _sheetBg,
      elevation: 0,
      centerTitle: true,
      title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.w700)),
      leadingWidth: 72,
      leading: TextButton(
        onPressed: () => context.go('/'),
        child: const Text(
          'Done',
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.visible,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Scaffold _loadingScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: _sheetBg,
      appBar: _settingsAppBar(context),
      body: const Center(child: CircularProgressIndicator()),
    );
  }

  Scaffold _errorScaffold(BuildContext context, String msg) {
    return Scaffold(
      backgroundColor: _sheetBg,
      appBar: _settingsAppBar(context),
      body: Center(child: Text(msg)),
    );
  }

  Future<int?> _pickVenue(BuildContext context, List<Venue> venues, int selected) async {
    return showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final v in venues)
              ListTile(
                title: Text(v.name),
                trailing: v.id == selected ? const Icon(Icons.check, color: Color(0xFF0A84FF)) : null,
                onTap: () => Navigator.pop(context, v.id),
              ),
          ],
        ),
      ),
    );
  }
}

Widget _sectionHeader(String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: TextStyle(
        color: Colors.black.withValues(alpha: 0.40),
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

Widget _roundedGroup({required List<Widget> children}) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(children: children),
  );
}

Widget _row({
  required Widget leading,
  required Widget trailing,
  required VoidCallback? onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Expanded(child: leading),
          trailing,
        ],
      ),
    ),
  );
}

Widget _divider() => Divider(height: 1, thickness: 1, color: Colors.black.withValues(alpha: 0.06));
