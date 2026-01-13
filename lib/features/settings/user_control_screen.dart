import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'user_control_repository.dart';

final usersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(userControlRepositoryProvider).getUsers();
});

class UserControlScreen extends ConsumerWidget {
  const UserControlScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(usersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F2F7),
        elevation: 0,
        centerTitle: true,
        title: const Text('User control', style: TextStyle(fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(err.toString(), style: const TextStyle(color: Colors.red))),
        data: (users) {
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemBuilder: (context, i) {
              final u = users[i];
              final username = (u['username'] ?? '').toString();
              final email = u['email']?.toString();
              final role = u['role']?.toString();
              final lastLogin = u['lastLogin']?.toString();
              final venueName = u['venueName']?.toString();
              final isLoggedIn = (u['isLoggedIn'] as bool?) ?? false;

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(username, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                        if (email != null && email.trim().isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(email, style: TextStyle(color: Colors.black.withValues(alpha: 0.55))),
                        ],
                        const SizedBox(height: 8),
                        Wrap(spacing: 8, runSpacing: 6, children: [
                          if (role != null && role.trim().isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0A84FF).withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(role, style: const TextStyle(fontSize: 12)),
                            ),
                          if (lastLogin != null && lastLogin.trim().isNotEmpty)
                            Text('Last login: $lastLogin',
                                style: TextStyle(color: Colors.black.withValues(alpha: 0.45), fontSize: 12)),
                          if (venueName != null && venueName.trim().isNotEmpty)
                            Text(venueName,
                                style: TextStyle(color: Colors.black.withValues(alpha: 0.45), fontSize: 12)),
                        ]),
                      ]),
                    ),
                    if (isLoggedIn)
                      Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                    const SizedBox(width: 10),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () async {
                        final ok = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Delete user?'),
                                content: Text('Delete $username?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                  TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                                ],
                              ),
                            ) ??
                            false;

                        if (!ok) return;

                        await ref.read(userControlRepositoryProvider).deleteUser(username);
                        ref.invalidate(usersProvider);
                      },
                    ),
                  ],
                ),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemCount: users.length,
          );
        },
      ),
    );
  }
}
