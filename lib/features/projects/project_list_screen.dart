import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'project_models.dart';
import 'project_repository.dart';

const _bg = Color.fromRGBO(7, 32, 64, 1);
const _cardBlue = Color.fromRGBO(19, 52, 98, 1);

@immutable
class ProjectListQuery {
  const ProjectListQuery({this.venueName, this.search});

  final String? venueName;
  final String? search;

  @override
  bool operator ==(Object other) =>
      other is ProjectListQuery && other.venueName == venueName && other.search == search;

  @override
  int get hashCode => Object.hash(venueName, search);
}

final projectsListProvider =
    FutureProvider.family<List<ProjectListItemDto>, ProjectListQuery>((ref, q) async {
  return ref.watch(projectsRepositoryProvider).getProjects(
        venueName: q.venueName,
        search: q.search,
      );
});

class ProjectListScreen extends ConsumerStatefulWidget {
  const ProjectListScreen({super.key, this.venueName});

  final String? venueName;

  @override
  ConsumerState<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends ConsumerState<ProjectListScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = ProjectListQuery(
      venueName: widget.venueName,
      search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
    );

    final async = ref.watch(projectsListProvider(q));

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Projects',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.white),
          onPressed: () => context.go('/'),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(projectsListProvider(q));
          await ref.read(projectsListProvider(q).future);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            _SearchBox(
              controller: _searchCtrl,
              hint: widget.venueName == null ? 'Search projects…' : 'Search ${widget.venueName}…',
              onChanged: (_) {
                // trigger provider refresh
                setState(() {});
              },
            ),
            const SizedBox(height: 14),
            async.when(
              data: (items) {
                if (items.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 80),
                    child: Text(
                      'No projects found',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.75)),
                    ),
                  );
                }

                return Column(
  crossAxisAlignment: CrossAxisAlignment.stretch, // ✅ force full-width children
  children: [
    for (final p in items) ...[
      _ProjectCard(
        item: p,
        onTap: () {
          context.go(
            '/projects/${p.projectId}',
            extra: '${p.venueName} – ${p.projectName}',
          );
        },
      ),
      const SizedBox(height: 10),
    ]
  ],
);

              },
              loading: () => Padding(
                padding: const EdgeInsets.only(top: 80),
                child: Center(
                  child: CircularProgressIndicator(color: Colors.white.withValues(alpha: 0.9)),
                ),
              ),
              error: (e, _) => _ErrorBlock(
                message: e.toString(),
                onRetry: () => ref.invalidate(projectsListProvider(q)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox({
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.55)),
        prefixIcon: Icon(Icons.search, color: Colors.white.withValues(alpha: 0.75)),
        filled: true,
        fillColor: _cardBlue.withValues(alpha: 0.9),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
        ),
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({required this.item, required this.onTap});

  final ProjectListItemDto item;
  final VoidCallback onTap;

  @override
Widget build(BuildContext context) {
  return InkWell(
    borderRadius: BorderRadius.circular(16),
    onTap: onTap,
    child: SizedBox(
      width: double.infinity, // ✅ force full width
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _cardBlue.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${item.venueName} – ${item.projectName}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Updated ${_fmtDateTime(item.updatedUtc)}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}
class _ErrorBlock extends StatelessWidget {
  const _ErrorBlock({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Column(
        children: [
          const Text(
            'Couldn’t load Projects',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12),
          ),
          const SizedBox(height: 14),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

String _fmtDateTime(DateTime dt) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  final local = dt.toLocal();
  final h = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final m = local.minute.toString().padLeft(2, '0');
  final ap = local.hour >= 12 ? 'pm' : 'am';
  return '${local.day} ${months[local.month - 1]} ${local.year}, $h:$m$ap';
}
