import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/snapshot/snapshot_screen.dart';

import '../app/providers.dart';

import '../features/auth/login_screen.dart';
import '../features/auth/splash_screen.dart';
import '../features/auth/unlock_screen.dart';
import '../features/home/home_screen.dart';
import '../features/trends/trends_list_screen.dart';
import '../features/financial/financial_screen.dart';
import '../features/gaming/gaming_screen.dart';
import '../features/feedback/feedback_screen.dart';
import '../features/weekly_notes/weekly_notes_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authTokenProvider);
  final tokenStore = ref.watch(tokenStoreProvider);
  final unlocked = ref.watch(isUnlockedProvider);

  final useFaceIdAsync = ref.watch(useFaceIdProvider);
  final useFaceId = useFaceIdAsync.value ?? false;

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: tokenStore,

    redirect: (context, state) {
      final loc = state.matchedLocation;
      final token = auth.valueOrNull ?? '';
      final isAuthed = token.isNotEmpty;

      debugPrint(
        'ROUTER: loc=$loc authed=$isAuthed useFaceId=$useFaceId unlocked=$unlocked '
        'authState=${auth.runtimeType} tokenLen=${token.length}',
      );

      // 1) Not authed: always go to login (never sit on splash)
      if (!isAuthed) {
        if (loc == '/login') return null;
        return '/login';
      }

      // 2) Authed: leaving splash is mandatory
      // If FaceID is enabled and not unlocked -> unlock
      if (loc == '/splash') {
        if (useFaceId && unlocked == false) return '/unlock';
        return '/';
      }

      // 3) If FaceID required, enforce unlock
      if (useFaceId && unlocked == false) {
        if (loc == '/unlock') return null;
        return '/unlock';
      }

      // 4) If authed + unlocked, keep user out of login/unlock
      if (loc == '/login' || loc == '/unlock') {
        return '/';
      }

      return null;
    },

    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/unlock',
        builder: (context, state) => const UnlockScreen(),
      ),
      GoRoute(
        path: '/weekly-notes',
        builder: (context, state) => const WeeklyNotesScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/trends',
        builder: (context, state) => const TrendsListScreen(),
      ),
      GoRoute(
  path: '/snapshot',
  builder: (context, state) => const SnapshotScreen(),
        ),
      GoRoute(
        path: '/financial',
        builder: (context, state) => const FinancialScreen(),
      ),
      GoRoute(
        path: '/gaming',
        builder: (context, state) => const GamingScreen(),
      ),
      GoRoute(
        path: '/feedback',
        builder: (context, state) => const FeedbackScreen(),
      ),
    ],
  );
});
