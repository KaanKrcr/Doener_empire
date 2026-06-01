import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';
import '../core/localization.dart';
import '../models/tutorial_model.dart';
import '../providers/game_provider.dart';
import '../services/sound_service.dart';
import 'tutorial_navigation.dart';
import 'screens/dashboard_screen.dart';
import 'screens/cities_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/corporate_screen.dart';
import 'screens/finance_screen.dart';
import 'screens/bank_screen.dart';

final navIndexProvider = StateProvider<int>((ref) => 0);
final tutorialCardCollapsedProvider = StateProvider<bool>((ref) => false);

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
    final game = ref.watch(gameProvider);
    final tutorialStep =
        game == null || !game.tutorialEnabled || game.tutorialDone
            ? null
            : tutorialStepFromIndex(game.tutorialStep);
    final tutorialProgress =
        ((game?.tutorialStep ?? 0) + 1).clamp(1, kTutorialStepCount);
    final tutorialCollapsed = ref.watch(tutorialCardCollapsedProvider);
    final forceExpanded = tutorialStep != null &&
        tutorialStep.index <= TutorialStep.readDayReport.index;
    final effectiveCollapsed = forceExpanded ? false : tutorialCollapsed;
    final canSkipTutorial = ref.read(gameProvider.notifier).canSkipTutorial;

    ref.listen<int>(navIndexProvider, (prev, next) {
      ref.read(gameProvider.notifier).onTutorialTabOpened(next);
    });

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          AnimatedSwitcher(
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
          const Positioned(
            top: 12,
            right: 12,
            child: SafeArea(
              child: _GameQuickMenuButton(),
            ),
          ),
          if (tutorialStep != null)
            Positioned(
              left: 12,
              right: 12,
              top: 60,
              child: SafeArea(
                bottom: false,
                child: _TutorialCard(
                  step: tutorialStep,
                  currentStep: tutorialProgress,
                  totalSteps: kTutorialStepCount,
                  collapsed: effectiveCollapsed,
                  canSkip: canSkipTutorial,
                  allowCollapse: !forceExpanded,
                  showPauseButton: !forceExpanded,
                  onSkip: canSkipTutorial
                      ? () => ref.read(gameProvider.notifier).skipTutorial()
                      : null,
                  // „Später" klappt nur ein (Tutorial bleibt aktiv), statt es
                  // komplett zu beenden.
                  onPause: forceExpanded
                      ? null
                      : () => ref
                          .read(tutorialCardCollapsedProvider.notifier)
                          .state = true,
                  onToggleCollapse: () {
                    if (forceExpanded) return;
                    ref.read(tutorialCardCollapsedProvider.notifier).state =
                        !effectiveCollapsed;
                  },
                  onAction: () =>
                      ref.read(gameProvider.notifier).acknowledgeTutorialStep(),
                  onWhy: () => showModalBottomSheet<void>(
                    context: context,
                    backgroundColor: AppColors.bgCard,
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(18)),
                    ),
                    builder: (sheetContext) => SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Warum ist das wichtig?',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              tutorialStep.whyItMatters,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  onJump: () {
                    final currentGame = game;
                    if (currentGame == null) return;
                    final jumpTarget =
                        tutorialJumpTarget(currentGame, tutorialStep);
                    final targetTab = jumpTarget.tabIndex;
                    if (targetTab != null) {
                      ref.read(navIndexProvider.notifier).state = targetTab;
                      ref.read(gameProvider.notifier).onTutorialTabOpened(
                            targetTab,
                          );
                    }
                    final route = jumpTarget.route;
                    if (route != null) {
                      context.push(route);
                    }
                  },
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: idx,
        highlightIndex: tutorialStep?.targetTabIndex,
        strings: ref.strings,
        onTap: (i) {
          HapticFeedback.selectionClick();
          SoundService.play(Sfx.tap);
          ref.read(navIndexProvider.notifier).state = i;
        },
      ),
    );
  }
}

class _GameQuickMenuButton extends StatelessWidget {
  const _GameQuickMenuButton();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openGameMenu(context),
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.bgCard.withAlpha(220),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: const Icon(
            Icons.settings_rounded,
            size: 20,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  void _openGameMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) => _GameMenuSheet(
        onClose: () => Navigator.of(sheetContext).pop(),
      ),
    );
  }
}

class _GameMenuSheet extends ConsumerWidget {
  final VoidCallback onClose;
  const _GameMenuSheet({required this.onClose});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.strings;
    final lang = ref.watch(languageProvider);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.gameMenu,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.home_rounded, color: AppColors.primary),
              title: Text(t.backToMainMenu),
              subtitle: Text(t.backToMainMenuSub),
              onTap: () {
                onClose();
                context.go('/menu');
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.tune_rounded, color: AppColors.secondary),
              title: Text(t.settings),
              subtitle: Text(t.settingsSub),
              onTap: () {
                onClose();
                context.push('/settings');
              },
            ),
            ListTile(
              leading: const Icon(Icons.palette_rounded, color: AppColors.gold),
              title: Text(t.brandDesign),
              subtitle: Text(t.brandDesignSub),
              onTap: () {
                onClose();
                context.push('/branding');
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.share_rounded, color: AppColors.secondary),
              title: Text(t.myEmpire),
              subtitle: Text(t.myEmpireSub),
              onTap: () {
                onClose();
                context.push('/empire-card');
              },
            ),
            const Divider(height: 18, color: AppColors.border),
            _SoundToggleTile(
              title: t.soundEffects,
              onLabel: t.on,
              offLabel: t.off,
            ),
            ListTile(
              leading:
                  const Icon(Icons.language_rounded, color: AppColors.accent),
              title: Text(t.language),
              subtitle: Text('${lang.flag}  ${lang.label}'),
              onTap: () => _pickLanguage(context, ref, t),
            ),
          ],
        ),
      ),
    );
  }

  void _pickLanguage(BuildContext context, WidgetRef ref, AppStrings t) {
    showDialog<void>(
      context: context,
      builder: (ctx) => SimpleDialog(
        backgroundColor: AppColors.bgCard,
        title: Text(t.language),
        children: [
          for (final l in AppLanguage.values)
            ListTile(
              leading: Text(l.flag, style: const TextStyle(fontSize: 20)),
              title: Text(l.label),
              trailing: l == ref.read(languageProvider)
                  ? const Icon(Icons.check_rounded, color: AppColors.primary)
                  : null,
              onTap: () {
                LanguageService.setLanguage(l);
                ref.read(languageProvider.notifier).state = l;
                Navigator.pop(ctx);
              },
            ),
        ],
      ),
    );
  }
}

class _SoundToggleTile extends StatefulWidget {
  final String title;
  final String onLabel;
  final String offLabel;
  const _SoundToggleTile({
    required this.title,
    required this.onLabel,
    required this.offLabel,
  });

  @override
  State<_SoundToggleTile> createState() => _SoundToggleTileState();
}

class _SoundToggleTileState extends State<_SoundToggleTile> {
  @override
  Widget build(BuildContext context) {
    final on = SoundService.enabled;
    return SwitchListTile(
      value: on,
      activeThumbColor: AppColors.primary,
      secondary: Icon(
        on ? Icons.volume_up_rounded : Icons.volume_off_rounded,
        color: on ? AppColors.primary : AppColors.textMuted,
      ),
      title: Text(widget.title),
      subtitle: Text(on ? widget.onLabel : widget.offLabel),
      onChanged: (v) async {
        await SoundService.setEnabled(v);
        if (v) SoundService.play(Sfx.tap);
        if (mounted) setState(() {});
      },
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final int? highlightIndex;
  final ValueChanged<int> onTap;
  final AppStrings strings;

  const _BottomNav({
    required this.currentIndex,
    required this.onTap,
    required this.strings,
    this.highlightIndex,
  });

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
              _NavItem(
                icon: Icons.storefront_rounded,
                label: strings.navShop,
                index: 0,
                current: currentIndex,
                highlight: highlightIndex == 0,
                onTap: onTap,
              ),
              _NavItem(
                icon: Icons.place_rounded,
                label: strings.navCities,
                index: 1,
                current: currentIndex,
                highlight: highlightIndex == 1,
                onTap: onTap,
              ),
              _NavItem(
                icon: Icons.emoji_events_rounded,
                label: strings.navEmpire,
                index: 2,
                current: currentIndex,
                highlight: highlightIndex == 2,
                onTap: onTap,
              ),
              _NavItem(
                icon: Icons.business_center_rounded,
                label: strings.navCorporate,
                index: 3,
                current: currentIndex,
                highlight: highlightIndex == 3,
                onTap: onTap,
              ),
              _NavItem(
                icon: Icons.receipt_long_rounded,
                label: strings.navFinance,
                index: 4,
                current: currentIndex,
                highlight: highlightIndex == 4,
                onTap: onTap,
              ),
              _NavItem(
                icon: Icons.account_balance_rounded,
                label: strings.navBank,
                index: 5,
                current: currentIndex,
                highlight: highlightIndex == 5,
                onTap: onTap,
              ),
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
  final bool highlight;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
    this.highlight = false,
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
          color:
              isActive ? AppColors.primary.withAlpha(26) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: highlight && !isActive
              ? Border.all(
                  color: AppColors.gold.withAlpha(170),
                  width: 1,
                )
              : null,
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

class _TutorialCard extends StatelessWidget {
  final TutorialStep step;
  final int currentStep;
  final int totalSteps;
  final bool collapsed;
  final bool canSkip;
  final bool allowCollapse;
  final bool showPauseButton;
  final VoidCallback? onSkip;
  final VoidCallback? onPause;
  final VoidCallback onWhy;
  final VoidCallback onAction;
  final VoidCallback onJump;
  final VoidCallback onToggleCollapse;

  const _TutorialCard({
    required this.step,
    required this.currentStep,
    required this.totalSteps,
    required this.collapsed,
    required this.canSkip,
    required this.allowCollapse,
    required this.showPauseButton,
    required this.onSkip,
    required this.onPause,
    required this.onWhy,
    required this.onAction,
    required this.onJump,
    required this.onToggleCollapse,
  });

  BoxDecoration get _boxDeco => BoxDecoration(
        color: AppColors.bgCard.withAlpha(252),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withAlpha(60)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(40),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      );

  Widget get _stepBadge => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.primary.withAlpha(30),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '$currentStep/$totalSteps',
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: collapsed ? _buildCollapsed() : _buildExpanded(),
    );
  }

  /// Schlanke Ein-Zeilen-Pille - blockiert nur minimal den oberen Rand.
  Widget _buildCollapsed() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: allowCollapse ? onToggleCollapse : null,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 7, 6, 7),
          decoration: _boxDeco,
          child: Row(
            children: [
              const Text('🎓', style: TextStyle(fontSize: 15)),
              const SizedBox(width: 8),
              _stepBadge,
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  step.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(
                allowCollapse
                    ? Icons.keyboard_arrow_down_rounded
                    : Icons.lock_outline_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Aufgeklappte Detail-Karte mit allen Aktionen.
  Widget _buildExpanded() {
    final actionLabel = step.actionLabel ?? 'Weiter';
    final hasJump = step.targetTabIndex != null;
    final canConfirmStep = step.actionLabel != null;
    final progress = currentStep / totalSteps;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 12),
      decoration: _boxDeco,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🎓', style: TextStyle(fontSize: 15)),
              const SizedBox(width: 8),
              _stepBadge,
              const Spacer(),
              if (canSkip)
                TextButton(
                  onPressed: onSkip,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textMuted,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('Überspringen'),
                ),
              if (allowCollapse)
                InkWell(
                  onTap: onToggleCollapse,
                  borderRadius: BorderRadius.circular(20),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.keyboard_arrow_up_rounded,
                        color: AppColors.textSecondary, size: 22),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress.clamp(0, 1),
              minHeight: 6,
              backgroundColor: AppColors.bg.withAlpha(120),
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Text(
              step.title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Text(
              step.description,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (hasJump)
                OutlinedButton.icon(
                  onPressed: onJump,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.near_me_rounded, size: 16),
                  label: Text(step.jumpLabel ?? 'Zum Ziel'),
                ),
              OutlinedButton(
                onPressed: onWhy,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.border),
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text('Warum?'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (showPauseButton)
                Expanded(
                  child: OutlinedButton(
                    onPressed: onPause,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textMuted,
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: const Text('Später'),
                  ),
                ),
              if (canConfirmStep) ...[
                if (showPauseButton) const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onAction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(actionLabel),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Text(
              step.hint,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


