import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/admin/presentation/screens/admin_screen.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/chat/presentation/screens/chat_screen.dart';
import '../../features/claim/presentation/screens/claim_screen.dart';
import '../../features/claim/presentation/screens/manage_claims_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/home/presentation/screens/splash_screen.dart';
import '../../features/item/presentation/screens/item_detail_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/report/presentation/screens/report_item_screen.dart';

/// Provides the centralized, reactive routing table for Finders Keepers.
///
/// Listens to `authStateChangesProvider` so any change in student login status
/// triggers an instantaneous declarative redirect.
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateChangesProvider);

  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/report',
        name: 'report',
        builder: (context, state) => const ReportItemScreen(),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/admin',
        name: 'admin',
        builder: (context, state) => const AdminScreen(),
      ),
      GoRoute(
        path: '/items/:id',
        name: 'itemDetail',
        builder: (context, state) {
          final itemId = state.pathParameters['id'] ?? '';
          return ItemDetailScreen(itemId: itemId);
        },
      ),
      GoRoute(
        path: '/items/:id/claim',
        name: 'claimItem',
        builder: (context, state) {
          final itemId = state.pathParameters['id'] ?? '';
          return ClaimScreen(itemId: itemId);
        },
      ),
      GoRoute(
        path: '/items/:id/claims',
        name: 'manageClaims',
        builder: (context, state) {
          final itemId = state.pathParameters['id'] ?? '';
          return ManageClaimsScreen(itemId: itemId);
        },
      ),
      GoRoute(
        path: '/chat/:claimId',
        name: 'chat',
        builder: (context, state) {
          final claimId = state.pathParameters['claimId'] ?? '';
          return ChatScreen(claimId: claimId);
        },
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      final isAuthenticated = authState.value != null;
      final currentLocation = state.matchedLocation;

      final isAuthRoute = currentLocation == '/login' ||
          currentLocation == '/register' ||
          currentLocation == '/';

      // If student is signed in and visits login/splash, take them straight to home
      if (isAuthenticated && isAuthRoute) {
        return '/home';
      }

      // If student is not signed in and tries to access protected screens
      if (!isAuthenticated && !isAuthRoute) {
        return '/login';
      }

      return null;
    },
  );
});
