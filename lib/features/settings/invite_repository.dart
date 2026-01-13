import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';

class InviteRepository {
  InviteRepository(this.ref);
  final Ref ref;

  Future<Map<String, dynamic>> sendInvite({
    required String email,
    int? venueId,
    int daysValid = 14,
  }) async {
    final api = ref.read(apiClientProvider);

    final res = await api.dio.post(
      '/v1/invites',
      data: <String, dynamic>{
        'email': email,
        'venueId': venueId,
        'daysValid': daysValid,
      },
    );

    return api.decodeOrThrow<Map<String, dynamic>>(
      res,
      (json) => (json as Map).cast<String, dynamic>(),
    );
  }
}

final inviteRepositoryProvider = Provider<InviteRepository>((ref) {
  return InviteRepository(ref);
});
