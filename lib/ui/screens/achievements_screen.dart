import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../models/achievement_model.dart';
import '../../providers/game_provider.dart';

/// Vollständige Trophäen-Galerie — alle Achievements nach Tier gruppiert,
/// freigeschaltet/gesperrt, mit Punkten und Gesamtfortschritt.
class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  Color _tierColor(AchievementTier t) => switch (t) {
        AchievementTier.bronze => const Color(0xFFCD7F32),
        AchievementTier.silber => const Color(0xFFC0C0C0),
        AchievementTier.gold => AppColors.gold,
        AchievementTier.platin => const Color(0xFFE5E4E2),
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameProvider);
    if (game == null) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final unlocked = game.achievementIds.toSet();
    final total = kAllAchievements.length;
    final earnedPoints = kAllAchievements
        .where((a) => unlocked.contains(a.id))
        .fold(0, (s, a) => s + a.tier.points);
    final maxPoints =
        kAllAchievements.fold(0, (s, a) => s + a.tier.points);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Trophäen')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          _Header(
            unlocked: unlocked.length,
            total: total,
            earnedPoints: earnedPoints,
            maxPoints: maxPoints,
          ),
          const SizedBox(height: 18),
          for (final tier in AchievementTier.values) ...[
            _TierSection(
              tier: tier,
              color: _tierColor(tier),
              unlockedIds: unlocked,
            ),
            const SizedBox(height: 18),
          ],
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final int unlocked;
  final int total;
  final int earnedPoints;
  final int maxPoints;
  const _Header({
    required this.unlocked,
    required this.total,
    required this.earnedPoints,
    required this.maxPoints,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : unlocked / total;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.gold, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.3),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🏆', style: TextStyle(fontSize: 26)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Trophäen-Sammlung',
                  style: AppText.display(
                      size: 20, weight: FontWeight.w800, color: AppColors.bg),
                ),
              ),
              Text(
                '$earnedPoints / $maxPoints Pkt',
                style: AppText.display(
                    size: 16, weight: FontWeight.w800, color: AppColors.bg),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 9,
              backgroundColor: Colors.black.withValues(alpha: 0.25),
              valueColor: const AlwaysStoppedAnimation(AppColors.bg),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$unlocked von $total freigeschaltet · ${(pct * 100).round()}%',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.bg.withValues(alpha: 0.85),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TierSection extends StatelessWidget {
  final AchievementTier tier;
  final Color color;
  final Set<String> unlockedIds;
  const _TierSection({
    required this.tier,
    required this.color,
    required this.unlockedIds,
  });

  @override
  Widget build(BuildContext context) {
    final items = kAllAchievements.where((a) => a.tier == tier).toList();
    final done = items.where((a) => unlockedIds.contains(a.id)).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              tier.label.toUpperCase(),
              style: AppText.label(color: color, size: 12),
            ),
            const SizedBox(width: 8),
            Text(
              '$done/${items.length}  ·  ${tier.points} Pkt',
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < items.length; i++)
          _AchievementTile(
            achievement: items[i],
            unlocked: unlockedIds.contains(items[i].id),
            color: color,
          )
              .animate()
              .fadeIn(delay: (40 * i).ms, duration: 260.ms)
              .slideX(begin: 0.06, end: 0, curve: Curves.easeOutCubic),
      ],
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final Achievement achievement;
  final bool unlocked;
  final Color color;
  const _AchievementTile({
    required this.achievement,
    required this.unlocked,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: unlocked ? color.withValues(alpha: 0.6) : AppColors.border,
          width: unlocked ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: unlocked
                  ? color.withValues(alpha: 0.18)
                  : AppColors.bgSurface.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: unlocked
                    ? color.withValues(alpha: 0.5)
                    : AppColors.border,
              ),
            ),
            child: Center(
              child: unlocked
                  ? Text(achievement.emoji,
                      style: const TextStyle(fontSize: 24))
                  : const Icon(Icons.lock_outline_rounded,
                      size: 20, color: AppColors.textMuted),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color:
                        unlocked ? AppColors.textPrimary : AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  achievement.description,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textMuted,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+${achievement.tier.points}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: unlocked ? color : AppColors.textMuted,
                ),
              ),
              if (unlocked)
                Icon(Icons.check_circle_rounded, size: 14, color: color)
              else
                const Text('gesperrt',
                    style: TextStyle(fontSize: 9, color: AppColors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }
}
