import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import 'project_models.dart';

class ProjectsRepository {
  ProjectsRepository(this.ref);
  final Ref ref;

  static const _listPath = '/api/projects';
  static String _detailPath(int id) => '/api/projects/$id';

  Future<List<ProjectListItemDto>> getProjects({
    String? venueName,
    String? search,
  }) async {
    final api = ref.read(apiClientProvider);

    final qp = <String, dynamic>{};
    if (venueName != null && venueName.trim().isNotEmpty) qp['venueName'] = venueName.trim();
    if (search != null && search.trim().isNotEmpty) qp['search'] = search.trim();

    final res = await api.dio.get(_listPath, queryParameters: qp);

    return api.decodeOrThrow<List<ProjectListItemDto>>(
      res,
      (json) => (json as List)
          .whereType<Map>()
          .map((e) => ProjectListItemDto.fromJson(e.cast<String, dynamic>()))
          .toList(),
    );
  }

  Future<ProjectDetailDto?> getProjectDetail(int projectId) async {
    final api = ref.read(apiClientProvider);
    final res = await api.dio.get(_detailPath(projectId));

    return api.decodeOrThrow<ProjectDetailDto?>(
      res,
      (json) {
        if (json == null) return null;
        return ProjectDetailDto.fromJson((json as Map).cast<String, dynamic>());
      },
    );
  }
}

final projectsRepositoryProvider = Provider<ProjectsRepository>((ref) {
  return ProjectsRepository(ref);
});
