import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/models/venue.dart';
import '../../app/venues_provider.dart';

import 'alerts_repository.dart';

const _bg = Color.fromRGBO(7, 32, 64, 1);
const _cardBlue = Color.fromRGBO(19, 52, 98, 1);

const int groupVenueId = 26;

final alertsVenueIdProvider = StateProvider<int>((ref) => groupVenueId);

class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({super.key});

  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen> {
  bool _sending = false;

  @override
  Widget build(BuildContext context) {
    final venuesAsync = ref.watch(venuesProvider);

    return venuesAsync.when(
      loading: () => const Scaffold(
        backgroundColor: _bg,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: _bg,
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(e.toString(), style: TextStyle(color: Colors.red), textAlign: TextAlign.center),
          ),
        ),
      ),
      data: (venues) {
        if (venues.isEmpty) {
          return const Scaffold(
            backgroundColor: _bg,
            body: Center(child: Text('No venues available', style: TextStyle(color: Colors.white))),
          );
        }

        final selectedId = ref.watch(alertsVenueIdProvider);
        final safeVenueId = venues.any((v) => v.id == selectedId)
            ? selectedId
            : venues.firstWhere((v) => v.id == groupVenueId, orElse: () => venues.first).id;

        if (safeVenueId != selectedId) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(alertsVenueIdProvider.notifier).state = safeVenueId;
          });
        }

        final venue = venues.firstWhere((v) => v.id == safeVenueId, orElse: () => venues.first);

       final cards = <_AlertCardConfig>[
  _AlertCardConfig(
    type: 'health_inspector',
    title: 'Health inspector on site',
    subtitle:
        'Notify other venues and support office that an inspector is currently on site at the selected venue.',
    icon: Icons.warning_amber_rounded,
    tint: Colors.orange,
    severity: 'warning',
    message: 'Health inspector onsite at ${venue.name}',
  ),
  _AlertCardConfig(
    type: 'gaming_compliance',
    title: 'Gaming compliance onsite',
    subtitle:
        'Notify other venues and support office that a gaming compliance officer is currently onsite.',
    icon: Icons.casino,
    tint: const Color(0xFFF1C84B),
    severity: 'info',
    message: 'Gaming compliance officer onsite at ${venue.name}',
  ),
  _AlertCardConfig(
    type: 'licensing_compliance',
    title: 'Licensing compliance onsite',
    subtitle:
        'Notify other venues and support office that a licensing / liquor compliance officer is onsite.',
    icon: Icons.description_outlined,
    tint: const Color(0xFF42A5F5),
    severity: 'info',
    message: 'Licensing compliance officer onsite at ${venue.name}',
  ),
  _AlertCardConfig(
    type: 'police_onsite',
    title: 'Police onsite',
    subtitle: 'Notify Support Office that police are currently onsite at the selected venue.',
    icon: Icons.shield_outlined,
    tint: const Color(0xFFFF5A5A),
    severity: 'warning',
    message: 'Police onsite at ${venue.name}',
  ),
  _AlertCardConfig(
    type: 'armed_robbery',
    title: 'Armed robbery',
    subtitle:
        'Call Police (000). Notify Support Office of an armed robbery/hold-up AFTER YOU, YOUR TEAM AND CUSTOMERS ARE SAFE.',
    icon: Icons.report_rounded,
    tint: const Color(0xFFFF5A5A),
    severity: 'critical',
    message: 'ARMED ROBBERY / HOLD-UP at ${venue.name}',
  ),
  _AlertCardConfig(
    type: 'serious_injury',
    title: 'Serious injury',
    subtitle:
        'Notify Support Office that there is a serious injury / medical emergency at the selected venue.',
    icon: Icons.local_hospital_outlined,
    tint: const Color(0xFFFF5A5A),
    severity: 'critical',
    message: 'Serious injury / medical emergency at ${venue.name}',
  ),
];

        return Scaffold(
          backgroundColor: _bg,
          appBar: AppBar(
            backgroundColor: _bg,
            elevation: 0,
            centerTitle: true,
            title: const Text(
              'Alerts',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.white),
              onPressed: () => context.go('/'),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              const Text(
                'Alerts',
                style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 14),

              Text('Origin venue', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
              const SizedBox(height: 6),

              // Venue picker
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: _cardBlue.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: PopupMenuButton<int>(
                  initialValue: safeVenueId,
                  color: _cardBlue,
                  onSelected: (id) => ref.read(alertsVenueIdProvider.notifier).state = id,
                  itemBuilder: (context) => venues
                      .map((v) => PopupMenuItem<int>(
                            value: v.id,
                            child: Text(v.name, style: const TextStyle(color: Colors.white)),
                          ))
                      .toList(),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          venue.name,
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.expand_more, color: Colors.white.withValues(alpha: 0.85)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              for (final c in cards) ...[
                _alertCard(
                  config: c,
                  onTap: _sending ? null : () => _confirmAndSend(context, venue, c),
                ),
                const SizedBox(height: 12),
              ],

              if (_sending) ...[
                const SizedBox(height: 8),
                Center(child: CircularProgressIndicator(color: Colors.white.withValues(alpha: 0.85))),
              ],
            ],
          ),
        );
      },
    );
  }

 Future<void> _confirmAndSend(BuildContext context, Venue venue, _AlertCardConfig c) async {
  final ok =
      await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Notify other venues?'),
          content: Text(
            'This will send an alert from ${venue.name} to all other venues using this app.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Send'),
            ),
          ],
        ),
      ) ??
      false;

  if (!ok) return;

  setState(() => _sending = true);

  try {
    final pushTitle = c.message;
    final pushBody = c.subtitle;

    await ref.read(alertsRepositoryProvider).sendAlert(
          venueId: venue.id,
          venueName: venue.name,
          title: pushTitle,
          body: pushBody,
          severity: c.severity,
          type: c.type,
        );

    // ✅ correct lint-safe check (instead of relying on `mounted`)
    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Alert sent'),
        content: Text('Your alert was sent from ${venue.name} to other registered devices.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  } catch (e) {
    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Failed to send alert'),
        content: Text(e.toString()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  } finally {
    if (mounted) setState(() => _sending = false);
  }
}


  Widget _alertCard({required _AlertCardConfig config, required VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _cardBlue.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: config.tint.withValues(alpha: 0.7), width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(config.icon, color: config.tint, size: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    config.title,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    config.subtitle,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12, height: 1.25),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class _AlertCardConfig {
  final String type;      // ✅ NEW: stable alert type key
  final String title;     // card title
  final String subtitle;
  final IconData icon;
  final Color tint;
  final String severity;
  final String message;

  const _AlertCardConfig({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.tint,
    required this.severity,
    required this.message,
  });
}

