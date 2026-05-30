import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../widgets/pressable.dart';
import '../../models/competitor_model.dart';
import '../../models/achievement_model.dart';
import '../../models/city_model.dart';
import '../../models/game_state.dart';
import '../../models/shop_model.dart';
import '../../models/time_profile_model.dart';
import '../../providers/game_provider.dart';
import '../../services/game_engine.dart';
import '../../services/review_util.dart';

/// Statistik / Imperium-Übersicht.
/// Zeigt: Markenbekanntheit, Konkurrenz, Achievements, Wochen-Charts.
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameProvider);
    if (game == null) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Text(
                  'Imperium',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),

            // Brand-Awareness Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: _BrandCard(game: game),
              ),
            ),

            // Unternehmens-Gesundheit
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: _HealthCard(health: GameEngine.healthScore(game)),
              ),
            ),

            // Tageszeit-Heatmap (für aktuell besten Shop)
            if (game.shops.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: _TimeHeatmapCard(game: game),
                ),
              ),

            // Achievements
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Pressable(
                  onTap: () => context.push('/achievements'),
                  child: _AchievementsCard(game: game),
                ),
              ),
            ),

            // Kundenbewertungen
            if (game.shops.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: _ReviewsCard(reviews: generateReviews(game)),
                ),
              ),

            // Marktanteile
            if (game.shops.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: _MarketShareCard(game: game),
                ),
              ),

            // Konkurrenz
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: _CompetitorsCard(game: game),
              ),
            ),

            // Stadt-Reputationen
            if (game.brand.cityReputation.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: _CityRepCard(game: game),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}

class _HealthCard extends StatelessWidget {
  final HealthScore health;
  const _HealthCard({required this.health});

  Color get _color {
    final s = health.score;
    if (s >= 80) return AppColors.gold;
    if (s >= 62) return AppColors.success;
    if (s >= 45) return AppColors.secondary;
    if (s >= 28) return AppColors.warning;
    return AppColors.danger;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🩺', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              const Text(
                'UNTERNEHMENS-GESUNDHEIT',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              Text(
                health.label,
                style: TextStyle(
                  fontSize: 12,
                  color: _color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                health.score.toStringAsFixed(0),
                style: AppText.display(
                    size: 34, weight: FontWeight.w800, color: _color),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 6, left: 2),
                child: Text('/ 100',
                    style:
                        TextStyle(fontSize: 13, color: AppColors.textMuted)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (health.score / 100).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: AppColors.bg.withValues(alpha: 0.5),
              valueColor: AlwaysStoppedAnimation(_color),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandCard extends StatelessWidget {
  final GameState game;
  const _BrandCard({required this.game});

  @override
  Widget build(BuildContext context) {
    final brand = game.brand;
    final stars = brand.tierStars;
    final progress = (brand.brandAwareness / 100.0).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.gold, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withAlpha(60),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('👑', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Text(
                'MARKEN-BEKANNTHEIT',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.black.withAlpha(160),
                  letterSpacing: 2,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                brand.brandAwareness.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  color: AppColors.bg,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 6),
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  '/ 100',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.bg,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            brand.tierLabel,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.bg,
            ),
          ),
          const SizedBox(height: 12),
          // Progress
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.black.withAlpha(40),
              valueColor: const AlwaysStoppedAnimation(AppColors.bg),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var i = 0; i < 5; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(
                    i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: AppColors.bg,
                    size: 22,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimeHeatmapCard extends StatelessWidget {
  final GameState game;
  const _TimeHeatmapCard({required this.game});

  @override
  Widget build(BuildContext context) {
    if (game.shops.isEmpty) return const SizedBox.shrink();
    // beste Filiale = höchste Reputation
    final shops = List<Shop>.from(game.shops);
    shops.sort((a, b) => b.reputation.compareTo(a.reputation));
    final shop = shops.first;
    final hours = GameEngine.hourlyCustomerCurve(shop, game.currentDay);
    final maxV = hours.isEmpty ? 1.0 : hours.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('⏰', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              const Text(
                'TAGESVERLAUF',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              Text(
                shop.displayName,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < hours.length; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1.5),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            height: maxV > 0
                                ? (hours[i] / maxV * 60).clamp(2.0, 60.0)
                                : 2,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.primary, AppColors.gold],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              for (var h = 10; h < 24; h += 1)
                Expanded(
                  child: Text(
                    h % 2 == 0 ? '$h' : '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 9,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${shop.personality.emoji} ${shop.personality.label} — ${shop.personality.description}',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementsCard extends StatelessWidget {
  final GameState game;
  const _AchievementsCard({required this.game});

  @override
  Widget build(BuildContext context) {
    final unlocked = game.achievementIds;
    final total = kAllAchievements.length;
    final progress = total == 0 ? 0.0 : unlocked.length / total;
    final totalPoints = unlocked.fold(0, (s, id) {
      final a = achievementById(id);
      return s + (a?.tier.points ?? 0);
    });

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🏆', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              const Text(
                'TROPHÄEN',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              Text(
                '${unlocked.length} / $total  ·  $totalPoints Pkt',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.gold,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(Icons.chevron_right_rounded,
                  size: 18, color: AppColors.textMuted),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation(AppColors.gold),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final a in kAllAchievements)
                _AchievementChip(
                  achievement: a,
                  unlocked: unlocked.contains(a.id),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AchievementChip extends StatelessWidget {
  final Achievement achievement;
  final bool unlocked;
  const _AchievementChip({required this.achievement, required this.unlocked});

  @override
  Widget build(BuildContext context) {
    final tierColor = switch (achievement.tier) {
      AchievementTier.bronze => const Color(0xFFCD7F32),
      AchievementTier.silber => const Color(0xFFC0C0C0),
      AchievementTier.gold => AppColors.gold,
      AchievementTier.platin => const Color(0xFFE5E4E2),
    };

    return Tooltip(
      message: '${achievement.title}\n${achievement.description}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: unlocked
              ? tierColor.withAlpha(45)
              : AppColors.bgSurface.withAlpha(120),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: unlocked ? tierColor : AppColors.border,
            width: unlocked ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Opacity(
              opacity: unlocked ? 1.0 : 0.35,
              child:
                  Text(achievement.emoji, style: const TextStyle(fontSize: 14)),
            ),
            const SizedBox(width: 6),
            Text(
              achievement.title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: unlocked ? AppColors.textPrimary : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewsCard extends StatelessWidget {
  final List<CustomerReview> reviews;
  const _ReviewsCard({required this.reviews});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('💬', style: TextStyle(fontSize: 16)),
              SizedBox(width: 6),
              Text(
                'KUNDENBEWERTUNGEN',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < reviews.length; i++) ...[
            _ReviewRow(review: reviews[i]),
            if (i < reviews.length - 1)
              const Divider(color: AppColors.border, height: 18),
          ],
        ],
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  final CustomerReview review;
  const _ReviewRow({required this.review});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var s = 0; s < 5; s++)
              Icon(
                s < review.stars ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 14,
                color: AppColors.gold,
              ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${review.author} · ${review.shopName}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textMuted),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          review.text,
          style: const TextStyle(
            fontSize: 12.5,
            color: AppColors.textSecondary,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}

class _MarketShareCard extends StatelessWidget {
  final GameState game;
  const _MarketShareCard({required this.game});

  @override
  Widget build(BuildContext context) {
    final cityIds =
        game.shops.map((s) => s.cityId).toSet().toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('📊', style: TextStyle(fontSize: 16)),
              SizedBox(width: 6),
              Text(
                'MARKTANTEILE',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final cityId in cityIds)
            _MarketShareRow(
              cityId: cityId,
              share: GameEngine.playerMarketShareIn(game, cityId),
            ),
        ],
      ),
    );
  }
}

class _MarketShareRow extends StatelessWidget {
  final String cityId;
  final double share;
  const _MarketShareRow({required this.cityId, required this.share});

  @override
  Widget build(BuildContext context) {
    final city = kAllCities.firstWhere(
      (c) => c.id == cityId,
      orElse: () => kAllCities.first,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(city.emoji, style: const TextStyle(fontSize: 15)),
          const SizedBox(width: 8),
          SizedBox(
            width: 86,
            child: Text(
              city.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Stack(
                children: [
                  Container(height: 10, color: AppColors.bgSurface),
                  FractionallySizedBox(
                    widthFactor: share.clamp(0.0, 1.0),
                    child: Container(height: 10, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 38,
            child: Text(
              '${(share * 100).round()}%',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompetitorsCard extends StatelessWidget {
  final GameState game;
  const _CompetitorsCard({required this.game});

  @override
  Widget build(BuildContext context) {
    final competitors = (game.competitors as List).cast<Competitor>();
    final byCity = <String, List<Competitor>>{};
    for (final c in competitors) {
      byCity.putIfAbsent(c.cityId, () => []).add(c);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('⚔️', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              const Text(
                'KONKURRENZ',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              Text(
                '${competitors.length} Wettbewerber',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (competitors.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Noch keine Konkurrenz erkundet.\nEröffne Filialen um den Markt zu lernen.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
            )
          else
            for (final entry in byCity.entries) ...[
              _CityHeader(cityId: entry.key),
              const SizedBox(height: 6),
              for (final c in entry.value) _CompetitorRow(competitor: c),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

class _CityHeader extends StatelessWidget {
  final String cityId;
  const _CityHeader({required this.cityId});

  @override
  Widget build(BuildContext context) {
    final city = kAllCities.firstWhere(
      (c) => c.id == cityId,
      orElse: () => kAllCities.first,
    );
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Text(city.emoji, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 6),
          Text(
            city.name.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.secondary,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompetitorRow extends StatelessWidget {
  final Competitor competitor;
  const _CompetitorRow({required this.competitor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                competitor.personality.emoji,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  competitor.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  competitor.personality.tagline,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textMuted,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  competitor.shortStatus(),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  const Icon(Icons.star, size: 11, color: AppColors.cream),
                  const SizedBox(width: 2),
                  Text(
                    competitor.reputation.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.cream,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              Text(
                '${(competitor.marketShare * 100).toStringAsFixed(0)}% Markt',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CityRepCard extends StatelessWidget {
  final GameState game;
  const _CityRepCard({required this.game});

  @override
  Widget build(BuildContext context) {
    final reps = game.brand.cityReputation;
    final entries = reps.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('🏙️', style: TextStyle(fontSize: 16)),
              SizedBox(width: 6),
              Text(
                'STADT-BEKANNTHEIT',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final e in entries) _CityRepRow(cityId: e.key, value: e.value),
        ],
      ),
    );
  }
}

class _CityRepRow extends StatelessWidget {
  final String cityId;
  final double value;
  const _CityRepRow({required this.cityId, required this.value});

  @override
  Widget build(BuildContext context) {
    final city = kAllCities.firstWhere(
      (c) => c.id == cityId,
      orElse: () => CityData(
        id: cityId,
        name: cityId,
        state: '',
        population: 0,
        tier: CityTier.klein,
        unlockCost: 0,
        rentBase: 0,
        footTrafficBase: 0,
        emoji: '🏙️',
      ),
    );
    final progress = (value / 100).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(city.emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: Text(
              city.name,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.bgSurface,
                valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 36,
            child: Text(
              value.toStringAsFixed(0),
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.accent,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
