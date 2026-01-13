import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';

class UserControlRepository {
  UserControlRepository(this.ref);
  final Ref ref;

  Future<List<Map<String, dynamic>>> getUsers() async {
    final api = ref.read(apiClientProvider);
    final res = await api.dio.get('/v1/users');

    return api.decodeOrThrow<List<Map<String, dynamic>>>(
      res,
      (json) => (json as List)
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList(),
    );
  }

  Future<void> deleteUser(String username) async {
    final api = ref.read(apiClientProvider);

    final encoded = Uri.encodeComponent(username);
    final res = await api.dio.delete('/v1/users/$encoded');

    api.decodeOrThrow(res, (_) => true);
  }
}

final userControlRepositoryProvider = Provider<UserControlRepository>((ref) {
  return UserControlRepository(ref);
});
