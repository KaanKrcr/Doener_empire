import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../services/sound_service.dart';
import '../../models/campaign_model.dart';
import '../../models/game_state.dart';
import '../../providers/game_provider.dart';
import '../../services/campaign_engine.dart';
import '../widgets/confetti_overlay.dart';

final _fmt = NumberFormat('#,##0', 'de_DE');

class CampaignScreen extends ConsumerWidget {
  const CampaignScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameProvider);
    if (game == null) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final activeId = CampaignEngine.activeChapter(game)?.id;
    final doneCount = CampaignEngine.completedCount(game);
    final total = kCampaignChapters.length;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Story-Kampagne')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          _ProgressHeader(done: doneCount, total: total),
          const SizedBox(height: 14),
          _ActivePerksCard(state: game),
          const SizedBox(height: 16),
          for (var i = 0; i < kCampaignChapters.length; i++)
            _ChapterCard(
              chapter: kCampaignChapters[i],
              state: game,
              status: game.completedChapterIds.contains(kCampaignChapters[i].id)
                  ? _ChapterStatus.done
                  : kCampaignChapters[i].id == activeId
                      ? _ChapterStatus.active
                      : _ChapterStatus.locked,
            )
                .animate()
                .fadeIn(delay: (60 * i).ms, duration: 300.ms)
                .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
        ],
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  final int done;
  final int total;
  const _ProgressHeader({required this.done, required this.total});

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : done / total;
    final complete = done >= total;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.35),
            AppColors.gold.withValues(alpha: 0.18),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📖', style: TextStyle(fontSize: 26)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  complete ? 'Imperium vollendet!' : 'Dein Aufstieg',
                  style: AppText.display(size: 20, weight: FontWeight.w800),
                ),
              ),
              Text(
                '$done / $total',
                style: AppText.display(
                    size: 18, weight: FontWeight.w800, color: AppColors.gold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: AppColors.bg.withValues(alpha: 0.5),
              color: AppColors.gold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Sammelanzeige aller bisher freigeschalteten Kampagnen-Perks + ihrer
/// summierten Gesamtwirkung.
class _ActivePerksCard extends StatelessWidget {
  final GameState state;
  const _ActivePerksCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final unlocked = kCampaignChapters
        .where((c) => state.completedChapterIds.contains(c.id) && c.perk != null)
        .map((c) => c.perk!)
        .toList();
    final total = aggregateCampaignPerks(state.completedChapterIds);

    final stats = <(String, String)>[
      if (total.customerBoost > 0)
        ('Kunden', '+${(total.customerBoost * 100).round()}%'),
      if (total.avgOrderBoost > 0)
        ('Bestellwert', '+${(total.avgOrderBoost * 100).round()}%'),
      if (total.ingredientSaving > 0)
        ('Zutaten', '−${(total.ingredientSaving * 100).round()}%'),
      if (total.rentSaving > 0)
        ('Miete', '−${(total.rentSaving * 100).round()}%'),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('⭐', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text('AKTIVE BONI', style: AppText.label(color: AppColors.secondary)),
              const Spacer(),
              Text(
                '${unlocked.length} Perk${unlocked.length == 1 ? "" : "s"}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (unlocked.isEmpty)
            const Text(
              'Noch keine Boni. Schließe Kapitel ab, um dauerhafte '
              'Konzern-Vorteile freizuschalten.',
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.textMuted,
                height: 1.4,
              ),
            )
          else ...[
            // Summierte Gesamtwirkung als Stat-Kacheln
            Row(
              children: [
                for (final s in stats) ...[
                  Expanded(child: _PerkStatTile(label: s.$1, value: s.$2)),
                  if (s != stats.last) const SizedBox(width: 8),
                ],
              ],
            ),
            const SizedBox(height: 14),
            // Liste der freigeschalteten Perks
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in unlocked)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                          color: AppColors.secondary.withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(p.emoji, style: const TextStyle(fontSize: 13)),
                        const SizedBox(width: 5),
                        Text(
                          p.title,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PerkStatTile extends StatelessWidget {
  final String label;
  final String value;
  const _PerkStatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.bg.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppText.display(
                size: 17, weight: FontWeight.w800, color: AppColors.secondary),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

enum _ChapterStatus { locked, active, done }

class _ChapterCard extends StatelessWidget {
  final CampaignChapter chapter;
  final GameState state;
  final _ChapterStatus status;

  const _ChapterCard({
    required this.chapter,
    required this.state,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final locked = status == _ChapterStatus.locked;
    final done = status == _ChapterStatus.done;
    final active = status == _ChapterStatus.active;

    final accent = done
        ? AppColors.success
        : active
            ? AppColors.primary
            : AppColors.textMuted;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: active ? AppColors.primary.withValues(alpha: 0.6) : AppColors.border,
          width: active ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accent.withValues(alpha: 0.5)),
                ),
                child: Center(
                  child: done
                      ? const Icon(Icons.check_rounded,
                          color: AppColors.success, size: 24)
                      : locked
                          ? const Icon(Icons.lock_outline_rounded,
                              color: AppColors.textMuted, size: 20)
                          : Text(chapter.emoji,
                              style: const TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'KAPITEL ${chapter.number}',
                      style: AppText.label(color: accent, size: 10),
                    ),
                    Text(
                      locked ? 'Noch gesperrt' : chapter.title,
                      style: AppText.display(
                        size: 16,
                        weight: FontWeight.w700,
                        color: locked
                            ? AppColors.textMuted
                            : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!locked) ...[
            const SizedBox(height: 12),
            Text(
              chapter.story,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 14),
            for (final obj in chapter.objectives)
              _ObjectiveRow(
                objective: obj,
                state: state,
                forceDone: done,
              ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.card_giftcard_rounded,
                    size: 16, color: AppColors.gold),
                const SizedBox(width: 6),
                Text(
                  '+${_fmt.format(chapter.cashReward)} €',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.gold,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '· ${chapter.rewardLabel}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
            if (chapter.perk != null) ...[
              const SizedBox(height: 8),
              _PerkChip(perk: chapter.perk!, unlocked: done),
            ],
          ],
        ],
      ),
    );
  }
}

class _PerkChip extends StatelessWidget {
  final CampaignPerk perk;
  final bool unlocked;
  const _PerkChip({required this.perk, required this.unlocked});

  @override
  Widget build(BuildContext context) {
    final color = unlocked ? AppColors.secondary : AppColors.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Text(perk.emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'PERK: ${perk.title}',
                      style: AppText.label(color: color, size: 9),
                    ),
                    if (unlocked) ...[
                      const SizedBox(width: 5),
                      Icon(Icons.check_circle_rounded, size: 11, color: color),
                    ],
                  ],
                ),
                Text(
                  perk.effectLabel,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ObjectiveRow extends StatelessWidget {
  final CampaignObjective objective;
  final GameState state;
  final bool forceDone;

  const _ObjectiveRow({
    required this.objective,
    required this.state,
    required this.forceDone,
  });

  @override
  Widget build(BuildContext context) {
    final cur = CampaignEngine.objectiveCurrent(objective, state);
    final progress =
        forceDone ? 1.0 : CampaignEngine.objectiveProgress(objective, state);
    final isDone = forceDone || cur >= objective.target;

    String fmtVal(double v) =>
        objective.target >= 1000 ? _fmt.format(v) : v.toStringAsFixed(0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isDone
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked,
                size: 16,
                color: isDone ? AppColors.success : AppColors.textMuted,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  objective.label,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDone
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (!forceDone)
                Text(
                  '${fmtVal(cur.clamp(0, objective.target))}/${fmtVal(objective.target)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: AppColors.bg.withValues(alpha: 0.5),
              color: isDone ? AppColors.success : AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Kapitel-Abschluss-Dialog (mit Konfetti) ──────────────────────────────────

class CampaignChapterDialog extends StatelessWidget {
  final CampaignChapter chapter;
  const CampaignChapterDialog({super.key, required this.chapter});

  static Future<void> show(BuildContext context, CampaignChapter chapter) {
    HapticFeedback.heavyImpact();
    SoundService.play(Sfx.reward);
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => CampaignChapterDialog(chapter: chapter),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
                  decoration: const BoxDecoration(
                    gradient: AppGradients.gold,
                  ),
                  child: Column(
                    children: [
                      Text(chapter.emoji, style: const TextStyle(fontSize: 44))
                          .animate()
                          .scale(
                            duration: 500.ms,
                            curve: Curves.elasticOut,
                            begin: const Offset(0.3, 0.3),
                            end: const Offset(1, 1),
                          ),
                      const SizedBox(height: 8),
                      Text(
                        'KAPITEL ${chapter.number} GESCHAFFT',
                        style: AppText.label(color: AppColors.bg, size: 11),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        chapter.title,
                        textAlign: TextAlign.center,
                        style: AppText.display(
                            size: 22,
                            weight: FontWeight.w800,
                            color: AppColors.bg),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
                  child: Column(
                    children: [
                      Text(
                        chapter.rewardLabel,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.gold.withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          '+${_fmt.format(chapter.cashReward)} € Belohnung',
                          style: AppText.display(
                              size: 18,
                              weight: FontWeight.w800,
                              color: AppColors.gold),
                        ),
                      ),
                      if (chapter.perk != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color:
                                    AppColors.secondary.withValues(alpha: 0.5)),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '${chapter.perk!.emoji}  Perk freigeschaltet: ${chapter.perk!.title}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.secondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                chapter.perk!.effectLabel,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Weiter zum nächsten Kapitel'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Positioned.fill(child: ConfettiOverlay()),
          ],
        ),
      ),
    );
  }
}
