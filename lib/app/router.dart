import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/providers.dart';

// Auth
import '../features/auth/login_screen.dart';
import '../features/auth/splash_screen.dart';
import '../features/auth/unlock_screen.dart';

// Home
import '../features/home/home_screen.dart';

// Performance
import '../features/snapshot/snapshot_screen.dart';
import '../features/financial/financial_screen.dart';
import '../features/trends/trends_list_screen.dart';
import '../features/gaming/gaming_screen.dart';

// Operations
import '../features/category/category_screen.dart';
import '../features/category/category_type.dart';

// Governance
import '../features/state_of_play/state_of_play_screen.dart';
import '../features/weekly_notes/weekly_notes_screen.dart';
import '../features/after_action/after_action_home_screen.dart';

// Projects
import '../features/projects/project_list_screen.dart';
import '../features/projects/project_detail_screen.dart';

// Other
import '../features/alerts/alerts_screen.dart';
import '../features/feedback/feedback_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/common/coming_soon_screen.dart';
import 'package:pubs_financial/features/stock/ui/stock_screen.dart';
import '../features/sevenrooms_review/ui/sevenrooms_review_start_screen.dart';
import '../features/sevenrooms_review/ui/sevenrooms_review_form_screen.dart';
import '../features/sevenrooms_review/ui/sevenrooms_review_summary_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authTokenProvider);
  final tokenStore = ref.watch(tokenStoreProvider);
  final unlocked = ref.watch(isUnlockedProvider);
  final useFaceId = ref.watch(useFaceIdProvider).value ?? false;

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: tokenStore,

    redirect: (context, state) {
      final loc = state.matchedLocation;
      final token = auth.valueOrNull ?? '';
      final isAuthed = token.isNotEmpty;

      // Not logged in → always login
      if (!isAuthed) {
        return loc == '/login' ? null : '/login';
      }

      // Leaving splash
      if (loc == '/splash') {
        if (useFaceId && unlocked == false) return '/unlock';
        return '/';
      }

      // FaceID lock
      if (useFaceId && unlocked == false) {
        return loc == '/unlock' ? null : '/unlock';
      }

      // Keep authed users out of login/unlock
      if (loc == '/login' || loc == '/unlock') return '/';

      return null;
    },

    routes: [
      // ---- Auth ----
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/unlock', builder: (_, __) => const UnlockScreen()),

      // ---- Home ----
      GoRoute(path: '/', builder: (_, __) => HomeScreen()),

      // ---- Performance ----
      GoRoute(path: '/snapshot', builder: (_, __) => const SnapshotScreen()),
      GoRoute(path: '/financial', builder: (_, __) => const FinancialScreen()),
      GoRoute(path: '/trends', builder: (_, __) => const TrendsListScreen()),
      GoRoute(path: '/gaming', builder: (_, __) => const GamingScreen()),

      // ---- Operations ----
      GoRoute(
        path: '/food',
        builder: (_, __) => const CategoryScreen(category: CategoryType.food),
      ),
      GoRoute(
        path: '/beverage',
        builder: (_, __) => const CategoryScreen(category: CategoryType.beverage),
      ),
      GoRoute(
        path: '/retail',
        builder: (_, __) => const CategoryScreen(category: CategoryType.retail),
      ),
      GoRoute(
        path: '/accommodation',
        builder: (_, __) => const CategoryScreen(category: CategoryType.accommodation),
      ),

      // ---- Governance ----
      GoRoute(path: '/state-of-play', builder: (_, __) => const StateOfPlayScreen()),
      GoRoute(path: '/weekly-notes', builder: (_, __) => const WeeklyNotesScreen()),

      GoRoute(
        path: '/weekly-communication',
        builder: (_, __) => const ComingSoonScreen(
          title: 'Weekly Comms',
          emoji: '🗞️',
          subtitle: 'Weekly Comms are being polished. No smudgy ink on launch day 😄',
        ),
      ),

      GoRoute(path: '/after-action', builder: (_, __) => const AfterActionHomeScreen()),

      // ---- Projects (THIS WAS MISSING) ----
      GoRoute(
        path: '/projects',
        builder: (_, __) => const ProjectListScreen(),
      ),

      GoRoute(
        path: '/projects/:id',
        builder: (context, state) {
          final idStr = state.pathParameters['id'] ?? '';
          final projectId = int.tryParse(idStr);

          if (projectId == null) {
            return const Scaffold(
              body: Center(child: Text('Invalid project id')),
            );
          }

          final title = state.extra is String && (state.extra as String).trim().isNotEmpty
              ? state.extra as String
              : 'Project';

          return ProjectDetailScreen(
            projectId: projectId,
            title: title,
          );
        },
      ),

      // ---- Other ----
      GoRoute(path: '/alerts', builder: (_, __) => const AlertsScreen()),
      GoRoute(path: '/feedback', builder: (_, __) => const FeedbackScreen()),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),

      GoRoute(
  path: '/stock',
  name: 'stock',
  builder: (context, state) => const StockScreen(),
),
GoRoute(
  path: '/sevenrooms-review',
  builder: (_, __) => const SevenRoomsReviewStartScreen(),
),
GoRoute(
  path: '/sevenrooms-review/form',
  builder: (_, __) => const SevenRoomsReviewFormScreen(),
),
GoRoute(
  path: '/sevenrooms-review/summary',
  builder: (_, __) => const SevenRoomsReviewSummaryScreen(),
),


    ],
  );
});
