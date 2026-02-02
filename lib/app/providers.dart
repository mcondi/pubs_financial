import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/api_providers.dart'; // tokenStoreProvider + apiClientProvider + secureStorageProvider
import '../features/auth/auth_repository.dart';
import '../features/trends/trends_repository.dart';
import '../features/snapshot/snapshot_repository.dart';

export '../core/api_providers.dart';

/// ------------------------------
/// Repositories
/// ------------------------------
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(apiClientProvider));
});

final trendsRepositoryProvider = Provider<TrendsRepository>((ref) {
  return TrendsRepository(ref.watch(apiClientProvider));
});

final snapshotRepositoryProvider = Provider<SnapshotRepository>((ref) {
  return SnapshotRepository(ref.watch(apiClientProvider));
});


class SettingsStore {
  static const _kDefaultVenueId = 'defaultVenueId';
  static const _kUseFaceId = 'useFaceId';

  final FlutterSecureStorage storage;
  SettingsStore(this.storage);

  Future<int?> readDefaultVenueId() async {
    final raw = await storage.read(key: _kDefaultVenueId);
    if (raw == null || raw.trim().isEmpty) return null;
    return int.tryParse(raw);
  }

  Future<void> writeDefaultVenueId(int venueId) async {
    await storage.write(key: _kDefaultVenueId, value: venueId.toString());
  }

  Future<bool> readUseFaceId() async {
    final v = await storage.read(key: _kUseFaceId);
    return v == 'true';
  }

  Future<void> writeUseFaceId(bool value) async {
    await storage.write(key: _kUseFaceId, value: value ? 'true' : 'false');
  }
}

final settingsStoreProvider = Provider<SettingsStore>((ref) {
  // Reuse the SAME secure storage instance as core
  final storage = ref.watch(secureStorageProvider);
  return SettingsStore(storage);
});

final useFaceIdProvider = FutureProvider<bool>((ref) async {
  return ref.read(settingsStoreProvider).readUseFaceId();
});

/// ------------------------------
/// Unlock state (used by unlock screen + router)
/// ------------------------------
final isUnlockedProvider = StateProvider<bool>((ref) => false);

final authTokenProvider =
    AsyncNotifierProvider<AuthTokenController, String?>(AuthTokenController.new);

class AuthTokenController extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async {
    // TokenStore.init() is awaited in main() before runApp()
    return ref.read(tokenStoreProvider).session?.accessToken;
  }

  Future<void> login(String emailOrUsername, String password) async {
    state = const AsyncLoading();

    await ref.read(authRepositoryProvider).login(emailOrUsername, password);

    final token = ref.read(tokenStoreProvider).session?.accessToken;
    state = AsyncData(token);
  }

  Future<void> logout() async {
    await ref.read(tokenStoreProvider).clear();
    ref.read(isUnlockedProvider.notifier).state = false;
    state = const AsyncData(null);
  }

  Future<void> refreshFromStorage() async {
    final token = ref.read(tokenStoreProvider).session?.accessToken;
    state = AsyncData(token);
  }
}
