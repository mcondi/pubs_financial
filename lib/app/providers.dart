import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/api_client.dart';
import '../core/token_store.dart';
import '../features/auth/auth_repository.dart';
import '../features/trends/trends_repository.dart';
import '../features/snapshot/snapshot_repository.dart';


final secureStorageProvider = Provider((ref) => const FlutterSecureStorage());

final tokenStoreProvider = Provider((ref) => TokenStore(ref.watch(secureStorageProvider)));

final apiClientProvider = Provider((ref) => ApiClient.create(ref.watch(tokenStoreProvider)));

final authRepositoryProvider = Provider((ref) => AuthRepository(ref.watch(apiClientProvider)));

final trendsRepositoryProvider = Provider((ref) => TrendsRepository(ref.watch(apiClientProvider)));

final snapshotRepositoryProvider =
    Provider((ref) => SnapshotRepository(ref.watch(apiClientProvider)));

/// Auth controller to keep router redirects synchronous
final authTokenProvider =
    AsyncNotifierProvider<AuthTokenController, String?>(AuthTokenController.new);

class AuthTokenController extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async {
    return ref.read(tokenStoreProvider).readToken();
  }

  Future<void> login(String emailOrUsername, String password) async {
    state = const AsyncLoading();
    final token = await ref.read(authRepositoryProvider).login(emailOrUsername, password);
    state = AsyncData(token);
  }

 Future<void> logout() async {
  await ref.read(tokenStoreProvider).clear();
  state = const AsyncData(null);
}
Future<void> refreshFromStorage() async {
  final token = await ref.read(tokenStoreProvider).readToken();
  state = AsyncData(token);
}
}
