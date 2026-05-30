import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../models/mission_model.dart';
import '../../providers/game_provider.dart';
import '../../services/mission_engine.dart';
import '../../services/sound_service.dart';

final _fmtInt = NumberFormat('#,##0', 'de_DE');

/// Aktuelle Mission als Banner oben im Dashboard.
/// Zeigt Titel, Progress-Bar, Belohnung. Wenn alle erledigt → Glückwunsch-Karte.
class MissionBanner extends ConsumerWidget {
  const MissionBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameProvider);
    if (game == null) return const SizedBox.shrink();

    final mission = ref.watch(activeMissionProvider);
    final progress = ref.watch(activeMissionProgressProvider);

    if (mission == null) {
      return _AllDoneCard(missionsTotal: game.missions.length);
    }

    final cur = MissionEngine.currentValueFor(mission, game);
    final isCash = mission.id.startsWith('cash_') || mission.id == 'first_1000';
    final currentLabel =
        isCash ? '${_fmtInt.format(cur)} €' : _fmtInt.format(cur);
    final targetLabel = isCash
        ? '${_fmtInt.format(mission.target)} €'
        : _fmtInt.format(mission.target);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.gold.withAlpha(40),
            AppColors.primary.withAlpha(30),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.gold.withAlpha(80)),
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
                  color: AppColors.bg.withAlpha(160),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child:
                      Text(mission.emoji, style: const TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'AUFTRAG',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.gold,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withAlpha(40),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '+${_fmtInt.format(mission.cashReward)} €',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.gold,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      mission.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            mission.description,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          // Progress
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: AppColors.bg.withAlpha(160),
                    color: AppColors.gold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$currentLabel / $targetLabel',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AllDoneCard extends StatelessWidget {
  final int missionsTotal;
  const _AllDoneCard({required this.missionsTotal});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.success.withAlpha(40),
            AppColors.gold.withAlpha(30),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.success.withAlpha(80)),
      ),
      child: Row(
        children: [
          const Text('🏆', style: TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Alle Aufträge erledigt!',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '$missionsTotal/$missionsTotal Missionen abgeschlossen — du baust frei weiter!',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
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

/// Vollbild-Confetti-Toast wenn eine Mission gerade erledigt wurde.
/// Wird als showGeneralDialog aufgerufen.
class MissionCompletedDialog extends StatelessWidget {
  final Mission mission;
  const MissionCompletedDialog({super.key, required this.mission});

  static Future<void> show(BuildContext context, Mission mission) {
    HapticFeedback.heavyImpact();
    SoundService.play(Sfx.reward);
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Mission',
      barrierColor: Colors.black.withAlpha(180),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => MissionCompletedDialog(mission: mission),
      transitionBuilder: (_, anim, __, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: anim, child: child),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              AppColors.gold,
              AppColors.primary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withAlpha(120),
              blurRadius: 60,
              spreadRadius: 8,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 12),
            const Text(
              'AUFTRAG ERLEDIGT',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              mission.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(60),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '+ ${_fmtInt.format(mission.cashReward)} € Belohnung',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                ),
                child: const Text('Weiter machen!'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
