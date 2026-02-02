import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';

import '../../app/providers.dart';

class UnlockScreen extends ConsumerStatefulWidget {
  const UnlockScreen({super.key});

  @override
  ConsumerState<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends ConsumerState<UnlockScreen> {
  final _auth = LocalAuthentication();
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Let the first frame render before prompting biometrics
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _unlock();
    });
  }

  Future<void> _unlock() async {
    if (_busy) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final supported = await _auth.isDeviceSupported();
      final canBio = await _auth.canCheckBiometrics;

      // If device does NOT support biometrics, just unlock and continue
      if (!supported && !canBio) {
        ref.read(isUnlockedProvider.notifier).state = true;
        if (!mounted) return;
        context.go('/');
        return;
      }

      final ok = await _auth.authenticate(
        localizedReason: 'Unlock Pubs Financial',
        options: const AuthenticationOptions(
          biometricOnly: false, // allows passcode fallback
          stickyAuth: true,
        ),
      );

      if (ok) {
        ref.read(isUnlockedProvider.notifier).state = true;
        if (!mounted) return;
        context.go('/');
      } else {
        if (!mounted) return;
        setState(() => _error = 'Unlock cancelled');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Unlock failed: $e');
    } finally {
      if (!mounted) return;
      setState(() => _busy = false);
    }
  }

  Future<void> _usePasswordInstead() async {
    await ref.read(tokenStoreProvider).clear();
    ref.read(isUnlockedProvider.notifier).state = false;
    if (!mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Unlock',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Use Face ID / Touch ID to continue'),
              const SizedBox(height: 24),
              if (_error != null) ...[
                Text(_error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 16),
              ],
              ElevatedButton(
                onPressed: _busy ? null : _unlock,
                child: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Try again'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _busy ? null : _usePasswordInstead,
                child: const Text('Use password instead'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
