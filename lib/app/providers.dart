import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/api_providers.dart'; // tokenStoreProvider + apiClientProvider + secureStorageProvider
import '../features/auth/auth_repository.dart';
import '../features/trends/trends_repository.dart';
import '../features/snapshot/snapshot_repository.dart';
import 'package:pubs_financial/features/stock/data/stock_repository.dart';
import '../features/sevenrooms_review/data/sevenrooms_review_repository.dart';

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

// ✅ Stock repository provider (TOP-LEVEL)
final stockRepositoryProvider = Provider<StockRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  // ApiClient in your app is passed into repos above; it likely exposes dio.
  return StockRepository(api.dio);
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
  final storage = ref.watch(secureStorageProvider);
  return SettingsStore(storage);
});

final useFaceIdProvider = FutureProvider<bool>((ref) async {
  return ref.read(settingsStoreProvider).readUseFaceId();
});

final isUnlockedProvider = StateProvider<bool>((ref) => false);

final authTokenProvider =
    AsyncNotifierProvider<AuthTokenController, String?>(AuthTokenController.new);

class AuthTokenController extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async {
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
  final sevenRoomsReviewRepositoryProvider = Provider<SevenRoomsReviewRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return SevenRoomsReviewRepository(api);
});




