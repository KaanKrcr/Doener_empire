import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../ui/screens/splash_screen.dart';
import '../ui/screens/menu_screen.dart';
import '../ui/screens/new_game_screen.dart';
import '../ui/screens/city_map_screen.dart';
import '../ui/screens/open_shop_screen.dart';
import '../ui/screens/shop_detail_screen.dart';
import '../ui/screens/campaign_screen.dart';
import '../ui/screens/achievements_screen.dart';
import '../ui/screens/branding_screen.dart';
import '../ui/screens/empire_card_screen.dart';
import '../ui/screens/settings_screen.dart';
import '../ui/main_scaffold.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/menu', builder: (_, __) => const MenuScreen()),
    GoRoute(path: '/new-game', builder: (_, __) => const NewGameScreen()),
    GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),

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

    // Shop-spezifische Routen (ohne Bottom Nav) — mit Slide-Up-Übergang
    GoRoute(
      path: '/city-map/:cityId',
      pageBuilder: (_, state) => _slideUpPage(
        CityMapScreen(cityId: state.pathParameters['cityId']!),
      ),
    ),
    GoRoute(
      path: '/open-shop/:cityId',
      pageBuilder: (_, state) => _slideUpPage(
        OpenShopScreen(
          cityId: state.pathParameters['cityId']!,
          initialLocationName: state.uri.queryParameters['location'],
        ),
      ),
    ),
    GoRoute(
      path: '/shop/:shopId',
      pageBuilder: (_, state) => _slideUpPage(
        ShopDetailScreen(shopId: state.pathParameters['shopId']!),
      ),
    ),
    GoRoute(
      path: '/campaign',
      pageBuilder: (_, __) => _slideUpPage(const CampaignScreen()),
    ),
    GoRoute(
      path: '/achievements',
      pageBuilder: (_, __) => _slideUpPage(const AchievementsScreen()),
    ),
    GoRoute(
      path: '/branding',
      pageBuilder: (_, __) => _slideUpPage(const BrandingScreen()),
    ),
    GoRoute(
      path: '/empire-card',
      pageBuilder: (_, __) => _slideUpPage(const EmpireCardScreen()),
    ),
  ],
);

/// Flüssiger Slide-Up + Fade-Übergang für Detail-Screens.
CustomTransitionPage<void> _slideUpPage(Widget child) {
  return CustomTransitionPage<void>(
    child: child,
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 240),
    transitionsBuilder: (_, anim, __, child) {
      final curved = CurvedAnimation(
        parent: anim,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}
