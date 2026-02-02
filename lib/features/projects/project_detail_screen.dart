import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'project_models.dart';
import 'project_repository.dart';

final projectDetailProvider = FutureProvider.family<ProjectDetailDto?, int>((ref, id) async {
  return ref.watch(projectsRepositoryProvider).getProjectDetail(id);
});

class ProjectDetailScreen extends ConsumerWidget {
  const ProjectDetailScreen({
    super.key,
    required this.projectId,
    required this.title,
  });

  final int projectId;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(projectDetailProvider(projectId));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/projects');
            }
          },
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: async.when(
        data: (dto) {
          if (dto == null) {
            return const Center(child: Text('Project not found'));
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            children: [
              _Header(dto: dto),
              const SizedBox(height: 16),

              if (dto.capex.isNotEmpty) ...[
                const _SectionTitle('Capex'),
                const SizedBox(height: 8),
                for (final c in dto.capex) ...[
                  _CapexCard(item: c),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 6),
              ],

              if (dto.plans.isNotEmpty) ...[
                const _SectionTitle('Plans / Files'),
                const SizedBox(height: 8),
                for (final p in dto.plans) ...[
                  _FileCard(
                    title: p.fileName,
                    subtitle: p.notes,
                    rightText: _fmtDate(p.uploadedAt),
                    url: p.blobUrl,
                  ),
                  const SizedBox(height: 10),
                ],
              ],

              if (dto.capex.isEmpty && dto.plans.isEmpty)
                Text(
                  'No capex or plan files yet.',
                  style: TextStyle(color: Colors.black.withValues(alpha: 0.65)),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Text(e.toString(), textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.dto});
  final ProjectDetailDto dto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(dto.projectName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(
            dto.venueName,
            style:
                TextStyle(color: Colors.black.withValues(alpha: 0.65), fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Updated ${_fmtDateTime(dto.updatedUtc)}',
            style: TextStyle(color: Colors.black.withValues(alpha: 0.55), fontSize: 12),
          ),
          if (dto.description != null && dto.description!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(dto.description!, style: TextStyle(color: Colors.black.withValues(alpha: 0.8))),
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800));
  }
}

class _CapexCard extends StatelessWidget {
  const _CapexCard({required this.item});
  final ProjectCapexItemDto item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.itemName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _Pill(label: item.costType),
              _Pill(label: _fmtCurrency(item.cost)),
            ],
          ),
          if (item.notes != null && item.notes!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(item.notes!, style: TextStyle(color: Colors.black.withValues(alpha: 0.75))),
          ],
          if (item.quoteUrl != null && item.quoteUrl!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: () => _openUrl(context, item.quoteUrl!),
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Open Quote'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black.withValues(alpha: 0.07)),
      ),
      child: Text(label,
          style: TextStyle(color: Colors.black.withValues(alpha: 0.75), fontSize: 12)),
    );
  }
}

class _FileCard extends StatelessWidget {
  const _FileCard({
    required this.title,
    required this.subtitle,
    required this.rightText,
    required this.url,
  });

  final String title;
  final String? subtitle;
  final String rightText;
  final String? url;

  @override
  Widget build(BuildContext context) {
    final canOpen = url != null && url!.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.insert_drive_file, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(subtitle!, style: TextStyle(color: Colors.black.withValues(alpha: 0.7))),
                ],
                const SizedBox(height: 8),
                Text(rightText,
                    style: TextStyle(color: Colors.black.withValues(alpha: 0.55), fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton(
            onPressed: canOpen ? () => _openUrl(context, url!) : null,
            child: const Text('Open'),
          ),
        ],
      ),
    );
  }
}

Future<void> _openUrl(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invalid file link')),
    );
    return;
  }

  // ✅ Block non-SAS Azure blob URLs
  if (uri.host.contains('blob.core.windows.net') && !url.contains('?sv=')) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('This file is private and missing a secure access link.'),
      ),
    );
    return;
  }

  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open file')),
    );
  }
}

String _fmtCurrency(double v) {
  final s = v.toStringAsFixed(0);
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    final left = s.length - i;
    buf.write(s[i]);
    if (left > 1 && left % 3 == 1) buf.write(',');
  }
  return '\$${buf.toString()}';
}

String _fmtDate(DateTime dt) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  final local = dt.toLocal();
  return '${local.day} ${months[local.month - 1]} ${local.year}';
}

String _fmtDateTime(DateTime dt) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  final local = dt.toLocal();
  final h = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final m = local.minute.toString().padLeft(2, '0');
  final ap = local.hour >= 12 ? 'pm' : 'am';
  return '${local.day} ${months[local.month - 1]} ${local.year}, $h:$m$ap';
}
