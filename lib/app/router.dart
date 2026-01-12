import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'providers.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/splash_screen.dart';
import '../features/home/home_screen.dart';
import '../features/trends/trends_list_screen.dart';
import '../features/snapshot/snapshot_screen.dart';
import '../features/financial/financial_screen.dart';
import '../features/gaming/gaming_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authTokenProvider);

  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/trends', builder: (_, __) => const TrendsListScreen()),
      GoRoute(path: '/snapshot', builder: (_, __) => const SnapshotScreen()),
      GoRoute(path: '/financial', builder: (context, state) => const FinancialScreen()),
      GoRoute(path: '/gaming', builder: (context, state) => const GamingScreen()),
    ],
    redirect: (context, state) {
      final loc = state.matchedLocation;

      if (auth.isLoading) return loc == '/splash' ? null : '/splash';

      final token = auth.valueOrNull;
      final loggedIn = token != null && token.isNotEmpty;

      if (!loggedIn) return loc == '/login' ? null : '/login';
      if (loc == '/login' || loc == '/splash') return '/';

      return null;
    },
  );
});
