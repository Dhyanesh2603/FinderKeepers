import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/home/presentation/screens/splash_screen.dart';

/// Provides the central declarative routing table for Finders Keepers.
///
/// By exposing GoRouter through a Riverpod provider, authentication state changes
/// can reactively redirect users without tight coupling between UI and navigation.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
    ],
  );
});
