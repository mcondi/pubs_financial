import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'invite_repository.dart';

class InviteScreen extends ConsumerStatefulWidget {
  const InviteScreen({super.key});

  @override
  ConsumerState<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends ConsumerState<InviteScreen> {
  final _email = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSend = _email.text.trim().isNotEmpty && !_sending;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F2F7),
        elevation: 0,
        centerTitle: true,
        title: const Text('Invite', style: TextStyle(fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          const Text(
            'Invite user',
            style: TextStyle(color: Colors.black54, fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              enableSuggestions: false,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Email',
              ),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: canSend ? _sendInvite : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE5E5EA),
                foregroundColor: Colors.black.withValues(alpha: 0.35),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _sending
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Send Invite', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendInvite() async {
    final email = _email.text.trim();
    if (email.isEmpty) return;

    setState(() => _sending = true);

    try {
      // ✅ Real API: POST /v1/invites (matches iOS)
      final resp = await ref.read(inviteRepositoryProvider).sendInvite(
            email: email,
            venueId: null,
            daysValid: 14,
          );

      final registrationUrl = (resp['registrationUrl'] ?? '').toString();
      final subject = (resp['subject'] ?? '').toString();
      final bodyPlain = (resp['bodyPlain'] ?? '').toString();

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Invite created'),
          content: const Text('Invite generated. You can copy the link or the email text below.'),
          actions: [
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: registrationUrl));
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Copy link'),
            ),
            TextButton(
              onPressed: () async {
                final full = 'Subject: $subject\n\n$bodyPlain';
                await Clipboard.setData(ClipboardData(text: full));
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Copy email'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) _showAlert('Error', e.toString());
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _showAlert(String title, String msg) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(msg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }
}
