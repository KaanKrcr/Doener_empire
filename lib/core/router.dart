import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../ui/screens/splash_screen.dart';
import '../ui/screens/menu_screen.dart';
import '../ui/screens/new_game_screen.dart';
import '../ui/screens/open_shop_screen.dart';
import '../ui/screens/shop_detail_screen.dart';
import '../ui/main_scaffold.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/menu', builder: (_, __) => const MenuScreen()),
    GoRoute(path: '/new-game', builder: (_, __) => const NewGameScreen()),

    // Haupt-App mit Bottom Navigation
    GoRoute(
      path: '/game',
      pageBuilder: (_, __) => CustomTransitionPage(
        child: const MainScaffold(),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: anim,
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ),

    // Shop-spezifische Routen (ohne Bottom Nav)
    GoRoute(
      path: '/open-shop/:cityId',
      builder: (_, state) =>
          OpenShopScreen(cityId: state.pathParameters['cityId']!),
    ),
    GoRoute(
      path: '/shop/:shopId',
      builder: (_, state) =>
          ShopDetailScreen(shopId: state.pathParameters['shopId']!),
    ),
  ],
);
