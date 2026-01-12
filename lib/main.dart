import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/router.dart';
import 'app/providers.dart';

void main() => runApp(const ProviderScope(child: App()));

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // If token was cleared (e.g. interceptor hit 401), ensure state updates
    ref.listen<AsyncValue<String?>>(authTokenProvider, (_, __) {});

    return MaterialApp.router(
      title: 'Pubs Financial',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
