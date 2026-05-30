import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../models/branding_model.dart';
import '../../models/achievement_model.dart';
import '../../providers/game_provider.dart';
import '../widgets/pressable.dart';

/// Marken-Anpassung: kosmetische Themen, die über Trophäen freigeschaltet werden.
class BrandingScreen extends ConsumerWidget {
  const BrandingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameProvider);
    if (game == null) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final achievements = game.achievementIds.toSet();
    final activeId = game.activeThemeId;
    final unlockedCount =
        kBrandThemes.where((t) => t.unlocked(achievements)).length;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Marken-Design')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Text('🎨', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Wähle das Erscheinungsbild deiner Kette. '
                    'Weitere Designs schaltest du über Trophäen frei '
                    '($unlockedCount/${kBrandThemes.length} verfügbar).',
                    style: const TextStyle(
                        fontSize: 12.5, color: AppColors.textSecondary, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < kBrandThemes.length; i++)
            _ThemeCard(
              theme: kBrandThemes[i],
              unlocked: kBrandThemes[i].unlocked(achievements),
              active: kBrandThemes[i].id == activeId,
              onSelect: () =>
                  ref.read(gameProvider.notifier).setActiveTheme(kBrandThemes[i].id),
            )
                .animate()
                .fadeIn(delay: (40 * i).ms, duration: 240.ms)
                .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
        ],
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final BrandTheme theme;
  final bool unlocked;
  final bool active;
  final VoidCallback onSelect;

  const _ThemeCard({
    required this.theme,
    required this.unlocked,
    required this.active,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final unlockHint = theme.unlockAchievementId == null
        ? null
        : achievementById(theme.unlockAchievementId!)?.title;

    return Pressable(
      onTap: unlocked && !active ? onSelect : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active ? theme.accent : AppColors.border,
            width: active ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Akzent-Swatch mit Emoji
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [theme.accent, theme.accentDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: unlocked
                    ? [
                        BoxShadow(
                          color: theme.accent.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: unlocked
                    ? Text(theme.emoji, style: const TextStyle(fontSize: 24))
                    : const Icon(Icons.lock_outline_rounded,
                        color: Colors.white70, size: 22),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    theme.name,
                    style: AppText.display(
                      size: 16,
                      weight: FontWeight.w700,
                      color: unlocked
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    unlocked
                        ? (active ? 'Aktiv' : 'Tippen zum Aktivieren')
                        : 'Trophäe nötig: ${unlockHint ?? "?"}',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: active
                          ? theme.accent
                          : AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (active)
              Icon(Icons.check_circle_rounded, color: theme.accent, size: 22)
            else if (!unlocked)
              const Icon(Icons.lock_rounded,
                  color: AppColors.textMuted, size: 18),
          ],
        ),
      ),
    );
  }
}
