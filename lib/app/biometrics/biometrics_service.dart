import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

class BiometricsService {
  BiometricsService(this._auth);
  final LocalAuthentication _auth;

  Future<bool> canUseBiometrics() async {
    final canCheck = await _auth.canCheckBiometrics;
    final supported = await _auth.isDeviceSupported();
    return canCheck && supported;
  }
}

final biometricsServiceProvider = Provider<BiometricsService>((ref) {
  return BiometricsService(LocalAuthentication());
});
