import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../models/achievement_model.dart';
import '../../models/campaign_model.dart';
import '../../models/branding_model.dart';
import '../../core/constants.dart';
import '../../providers/game_provider.dart';
import '../../services/campaign_engine.dart';
import '../../services/game_engine.dart';
import '../../services/share_util.dart';
import '../../services/sound_service.dart';

final _fmt = NumberFormat('#,##0', 'de_DE');
final _fmtPrice = NumberFormat('#,##0.00', 'de_DE');

/// „Mein Imperium"-Karte — teilbare Zusammenfassung mit Kopier-Funktion.
class EmpireCardScreen extends ConsumerWidget {
  const EmpireCardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameProvider);
    if (game == null) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final theme = brandThemeById(game.activeThemeId);
    final avgRep = game.shops.isEmpty
        ? 0.0
        : game.shops.fold<double>(0, (s, sh) => s + sh.reputation) /
            game.shops.length;
    final chapters = CampaignEngine.completedCount(game);
    final avgDoener = GameEngine.playerAvgDoenerPrice(game);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Mein Imperium')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [theme.accent, theme.accentDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: theme.accent.withValues(alpha: 0.4),
                  blurRadius: 26,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(theme.emoji, style: const TextStyle(fontSize: 30)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        game.companyName,
                        style: AppText.display(
                            size: 24,
                            weight: FontWeight.w800,
                            color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Tag ${game.currentDay}',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 13,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 18),
                _StatLine(label: 'Kasse', value: '${_fmt.format(game.cash)} €'),
                _StatLine(label: 'Filialen', value: '${game.shopCount}'),
                _StatLine(label: 'Mitarbeiter', value: '${game.employeeCount}'),
                _StatLine(
                    label: 'Markenbekanntheit',
                    value: '${game.brand.brandAwareness.toStringAsFixed(0)}/100'),
                _StatLine(
                    label: 'Ø Reputation', value: '${avgRep.toStringAsFixed(1)} ⭐'),
                _StatLine(
                    label: 'Gesamtumsatz',
                    value: '${_fmt.format(game.totalRevenue)} €'),
                if (avgDoener != null) _DoenerIndexLine(avgDoener: avgDoener),
                _StatLine(
                    label: 'Trophäen',
                    value:
                        '${game.achievementIds.length}/${kAllAchievements.length}'),
                _StatLine(
                    label: 'Story-Kapitel',
                    value: '$chapters/${kCampaignChapters.length}'),
                if (game.prestigePoints > 0)
                  _StatLine(
                      label: 'Prestige-Stufe',
                      value: '${game.prestigePoints} 🏅'),
                const SizedBox(height: 14),
                Text(
                  '#DönerEmpire',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms).scale(
              begin: const Offset(0.97, 0.97), end: const Offset(1, 1)),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                await Clipboard.setData(
                    ClipboardData(text: empireSummaryText(game)));
                SoundService.play(Sfx.tap);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('In die Zwischenablage kopiert 📋'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: const Text('In Zwischenablage kopieren'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Spezial-Zeile: vergleicht den eigenen Ø-Döner-Preis mit dem Bundesschnitt.
class _DoenerIndexLine extends StatelessWidget {
  final double avgDoener;
  const _DoenerIndexLine({required this.avgDoener});

  @override
  Widget build(BuildContext context) {
    final diff = avgDoener - kNationalAvgDoenerPrice;
    final cheaper = diff <= -0.01;
    final pricier = diff >= 0.01;
    final note = cheaper
        ? '👍 günstiger als der Schnitt'
        : pricier
            ? '💎 über dem Schnitt'
            : '⚖️ genau im Schnitt';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Ø Döner-Preis',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                '${_fmtPrice.format(avgDoener)} €',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          Text(
            '$note · Bundesschnitt ${_fmtPrice.format(kNationalAvgDoenerPrice)} €',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatLine extends StatelessWidget {
  final String label;
  final String value;
  const _StatLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 13,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
