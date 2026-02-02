import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pubs_financial/app/providers.dart';
import 'package:pubs_financial/core/api_errors.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  bool _useFaceId = false;
  bool _loadedSetting = false;

  @override
  void initState() {
    super.initState();
    _loadFaceIdSetting();
  }

  Future<void> _loadFaceIdSetting() async {
    final store = ref.read(settingsStoreProvider);
    final v = await store.readUseFaceId();
    if (!mounted) return;
    setState(() {
      _useFaceId = v;
      _loadedSetting = true;
    });
  }

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_loading) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Save Face ID preference BEFORE routing kicks in
      await ref.read(settingsStoreProvider).writeUseFaceId(_useFaceId);

      await ref.read(authTokenProvider.notifier).login(
            _userCtrl.text.trim(),
            _passCtrl.text,
          );
    } catch (e) {
      // ✅ CRITICAL: screen may have been popped by router already
      if (!mounted) return;

      setState(() {
        _error = (e is ApiAuthException || e is ApiHttpException)
            ? e.toString()
            : 'Login failed: $e';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 24),
              const Text(
                'Pubs Financial',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _userCtrl,
                decoration: const InputDecoration(labelText: 'Email or Username'),
                textInputAction: TextInputAction.next,
                enabled: !_loading,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passCtrl,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                enabled: !_loading,
                onSubmitted: (_) => _login(),
              ),
              const SizedBox(height: 12),

              if (_loadedSetting)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Use Face ID'),
                  subtitle: const Text('Require Face ID when opening the app'),
                  value: _useFaceId,
                  onChanged: _loading ? null : (v) => setState(() => _useFaceId = v),
                ),

              const SizedBox(height: 12),

              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(_error!, style: const TextStyle(color: Colors.red)),
                ),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  child: _loading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Login'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
