import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/coa/screens/coa_list_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/dashboard/screens/main_navigation_screen.dart';
import '../../features/foundations/providers/foundation_provider.dart';
import '../../features/foundations/screens/foundation_select_screen.dart';
import '../../features/projects/screens/public_foundation_profile_screen.dart';
import '../../features/projects/screens/public_project_detail_screen.dart';
import '../../features/projects/screens/public_project_feed_screen.dart';
import '../../features/projects/screens/project_form_screen.dart';
import '../../features/accounting/screens/journal_form_screen.dart';
import '../../features/foundations/screens/foundation_create_screen.dart';

// Listenable that triggers router refresh on Riverpod state changes
class RouterTransitionNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterTransitionNotifier(this._ref) {
    _ref.listen(authProvider, (_, __) {
      notifyListeners();
    });
    _ref.listen(foundationProvider, (_, __) {
      notifyListeners();
    });
  }
}

final routerNotifierProvider = Provider((ref) => RouterTransitionNotifier(ref));

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.read(routerNotifierProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const PublicProjectFeedScreen(showNavbar: true),
      ),
      GoRoute(
        path: '/public/project',
        builder: (context, state) {
          final id = state.uri.queryParameters['id'] ?? '';
          return PublicProjectDetailScreen(projectId: id);
        },
      ),
      GoRoute(
        path: '/public/foundation',
        builder: (context, state) {
          final id = state.uri.queryParameters['id'] ?? '';
          return PublicFoundationProfileScreen(foundationId: id);
        },
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/select-foundation',
        builder: (context, state) => const FoundationSelectScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const MainNavigationScreen(),
      ),
      GoRoute(
        path: '/dashboard/coa',
        builder: (context, state) => const CoaListScreen(),
      ),
      GoRoute(
        path: '/proyek/tambah',
        builder: (context, state) => const ProjectFormScreen(),
      ),
      GoRoute(
        path: '/proyek/:id/edit',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return ProjectFormScreen(projectId: id);
        },
      ),
      GoRoute(
        path: '/accounting/journal/form',
        builder: (context, state) {
          final id = state.uri.queryParameters['id'];
          return JournalFormScreen(entryId: id);
        },
      ),
      GoRoute(
        path: '/foundations/create',
        builder: (context, state) => const FoundationCreateScreen(),
      ),
    ],
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final foundationState = ref.read(foundationProvider);
      final loggedIn = authState.isAuthenticated;
      final hasFoundation = foundationState.activeFoundation != null;

      final path = state.uri.path;
      final isPublicRoute = path == '/' || 
          path == '/public/project' || 
          path == '/public/foundation';
      
      final isAuthRoute = path == '/login' || path == '/register';

      // 1. If not logged in:
      if (!loggedIn) {
        // Allow public routes and auth routes, redirect anything else to login
        if (isPublicRoute || isAuthRoute) return null;
        return '/login';
      }

      // 2. If logged in:
      if (isAuthRoute) {
        // Logged in users should not access login/register, redirect to dashboard or selection
        return hasFoundation ? '/dashboard' : '/select-foundation';
      }

      // If user is logged in but hasn't selected foundation, force select-foundation (unless going to foundations/create)
      if (path != '/select-foundation' && path != '/foundations/create' && !isPublicRoute && !hasFoundation) {
        return '/select-foundation';
      }

      // If user is logged in and has selected a foundation, do not allow select-foundation (redirect to dashboard)
      if (path == '/select-foundation' && hasFoundation) {
        return '/dashboard';
      }

      return null;
    },
  );
});
