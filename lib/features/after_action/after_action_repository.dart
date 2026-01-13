import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import 'after_action_models.dart';

class AfterActionRepository {
  AfterActionRepository(this.ref);
  final Ref ref;

  // ✅ Matches iOS APIClient.swift exactly
  static const _eventsPath = '/api/AfterActions';
  static const _tasksPath = '/api/AfterActions/tasks/me';
  static String _detailPath(int id) => '/api/AfterActions/$id';
  static String _markReadPath(int id) => '/api/AfterActions/$id/read';

  Future<List<AfterActionTaskDto>> getTasks() async {
    final api = ref.read(apiClientProvider);
    final res = await api.dio.get(_tasksPath);

    return api.decodeOrThrow<List<AfterActionTaskDto>>(
      res,
      (json) => (json as List)
          .whereType<Map>()
          .map((e) => AfterActionTaskDto.fromJson(e.cast<String, dynamic>()))
          .toList(),
    );
  }

  Future<List<AfterActionListItemDto>> getEvents() async {
    final api = ref.read(apiClientProvider);
    final res = await api.dio.get(_eventsPath);

    return api.decodeOrThrow<List<AfterActionListItemDto>>(
      res,
      (json) => (json as List)
          .whereType<Map>()
          .map((e) => AfterActionListItemDto.fromJson(e.cast<String, dynamic>()))
          .toList(),
    );
  }

  Future<AfterActionDetailDto?> getDetail(int afterActionId) async {
    final api = ref.read(apiClientProvider);
    final res = await api.dio.get(_detailPath(afterActionId));

    return api.decodeOrThrow<AfterActionDetailDto?>(
      res,
      (json) {
        if (json == null) return null;
        return AfterActionDetailDto.fromJson((json as Map).cast<String, dynamic>());
      },
    );
  }

  Future<bool> markRead(int afterActionId) async {
    final api = ref.read(apiClientProvider);

    // ✅ iOS sends POST + "{}" body — Dio will send JSON automatically
    final res = await api.dio.post(
      _markReadPath(afterActionId),
      data: const <String, dynamic>{},
    );

    return api.decodeOrThrow<bool>(
      res,
      (json) {
        if (json is Map) {
          final ok = json['ok'];
          if (ok is bool) return ok;
        }
        return true;
      },
    );
  }
}

final afterActionRepositoryProvider = Provider<AfterActionRepository>((ref) {
  return AfterActionRepository(ref);
});
