import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../features/menu/pages/screens/menu_screen.dart';
import '../features/reading/pages/screens/consultation_screen.dart';
import '../features/splash/pages/screens/splash_screen.dart';
import '../models/tarot_card_data.dart';
import 'routes.dart';

part 'app_router.g.dart';

@Riverpod(keepAlive: true)
GoRouter appRouter(AppRouterRef ref) {
  return GoRouter(
    initialLocation: Routes.splash,
    routes: [
      GoRoute(
        path: Routes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: Routes.menu,
        builder: (context, state) => const MenuScreen(),
      ),
      GoRoute(
        path: Routes.consultation,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final spread = extra?['spreadType'] as SpreadType? ?? SpreadType.threeCard;
          return ConsultationScreen(spreadType: spread);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.uri}')),
    ),
  );
}
