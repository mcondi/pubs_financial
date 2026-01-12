import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';

class StateOfPlayRepository {
  StateOfPlayRepository(this.ref);
  final Ref ref;

  Future<Map<String, dynamic>> fetchStateOfPlay() async {
    final api = ref.read(apiClientProvider);
    final res = await api.dio.get('/v1/stateofplay');

    return api.decodeOrThrow<Map<String, dynamic>>(
      res,
      (json) => (json as Map).cast<String, dynamic>(),
    );
  }
}

final stateOfPlayRepositoryProvider = Provider<StateOfPlayRepository>((ref) {
  return StateOfPlayRepository(ref);
});
