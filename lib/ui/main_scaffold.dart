import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import 'screens/dashboard_screen.dart';
import 'screens/cities_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/corporate_screen.dart';
import 'screens/finance_screen.dart';
import 'screens/bank_screen.dart';

final navIndexProvider = StateProvider<int>((ref) => 0);

const int kTabDashboard = 0;
const int kTabCities = 1;
const int kTabStats = 2;
const int kTabCorporate = 3;
const int kTabFinance = 4;
const int kTabBank = 5;

class MainScaffold extends ConsumerWidget {
  const MainScaffold({super.key});

  static final _screens = [
    const DashboardScreen(),
    const CitiesScreen(),
    const StatsScreen(),
    const CorporateScreen(),
    const FinanceScreen(),
    const BankScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final idx = ref.watch(navIndexProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.03),
              end: Offset.zero,
            ).animate(anim),
            child: child,
          ),
        ),
        child: KeyedSubtree(
          key: ValueKey(idx),
          child: _screens[idx],
        ),
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: idx,
        onTap: (i) {
          HapticFeedback.selectionClick();
          ref.read(navIndexProvider.notifier).state = i;
        },
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgTab,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: Icons.storefront_rounded, label: 'Imbiss', index: 0, current: currentIndex, onTap: onTap),
              _NavItem(icon: Icons.place_rounded, label: 'Städte', index: 1, current: currentIndex, onTap: onTap),
              _NavItem(icon: Icons.emoji_events_rounded, label: 'Imperium', index: 2, current: currentIndex, onTap: onTap),
              _NavItem(icon: Icons.business_center_rounded, label: 'Konzern', index: 3, current: currentIndex, onTap: onTap),
              _NavItem(icon: Icons.receipt_long_rounded, label: 'Finanzen', index: 4, current: currentIndex, onTap: onTap),
              _NavItem(icon: Icons.account_balance_rounded, label: 'Bank', index: 5, current: currentIndex, onTap: onTap),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int current;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index == current;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withAlpha(26) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: isActive ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                icon,
                size: 20,
                color: isActive ? AppColors.primary : AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color: isActive ? AppColors.primary : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
