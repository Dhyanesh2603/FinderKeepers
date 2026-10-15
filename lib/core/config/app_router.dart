import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/home/presentation/screens/splash_screen.dart';

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
      if (!isAuthenticated && currentLocation == '/home') {
        return '/login';
      }

      return null;
    },
  );
});
