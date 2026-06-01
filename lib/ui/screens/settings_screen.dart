import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../providers/game_provider.dart';
import '../widgets/premium_mobile_ui.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const bool _hasSoundSystem = false;
  static const bool _hasLanguageSystem = false;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Einstellungen'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (game != null) ...[
            PremiumMetricStrip(
              items: [
                PremiumMetricData(
                  label: 'Tutorial',
                  value: game.tutorialDone
                      ? 'Fertig'
                      : game.tutorialEnabled
                          ? 'Aktiv'
                          : 'Pausiert',
                  color: game.tutorialDone
                      ? AppColors.success
                      : game.tutorialEnabled
                          ? AppColors.accent
                          : AppColors.warning,
                ),
                const PremiumMetricData(
                  label: 'Audio',
                  value: _hasSoundSystem ? 'Verfügbar' : 'Platzhalter',
                  color: AppColors.textSecondary,
                ),
                const PremiumMetricData(
                  label: 'Sprache',
                  value: _hasLanguageSystem ? 'Verfügbar' : 'Platzhalter',
                  color: AppColors.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          _sectionTitle('Spiel'),
          const SizedBox(height: 8),
          PremiumDecisionSheet(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.home_rounded, color: AppColors.primary),
              title: const Text('Zurück zum Hauptmenü'),
              subtitle: const Text('Aktueller Spielstand bleibt gespeichert.'),
              onTap: () => context.go('/menu'),
            ),
          ),
          if (game != null) ...[
            const SizedBox(height: 12),
            PremiumDecisionSheet(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PremiumSectionLabel(text: 'TUTORIAL'),
                  const SizedBox(height: 6),
                  Text(
                    game.tutorialDone
                        ? 'Abgeschlossen'
                        : game.tutorialEnabled
                            ? 'Aktiv (Schritt ${game.tutorialStep + 1}/10)'
                            : 'Pausiert',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (!game.tutorialDone && !game.tutorialEnabled)
                        ElevatedButton(
                          onPressed: () =>
                              ref.read(gameProvider.notifier).resumeTutorial(),
                          child: const Text('Tutorial fortsetzen'),
                        ),
                      if (!game.tutorialDone)
                        OutlinedButton(
                          onPressed: () => ref
                              .read(gameProvider.notifier)
                              .resumeTutorial(restart: true),
                          child: const Text('Neu starten'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          _sectionTitle('Audio'),
          const SizedBox(height: 8),
          PremiumDecisionSheet(
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: true,
              onChanged: _hasSoundSystem ? (_) {} : null,
              title: const Text('Sound an/aus'),
              subtitle: const Text(
                'Platzhalter: Sound-System ist noch nicht vorhanden.',
              ),
              secondary: const Icon(Icons.volume_up_rounded,
                  color: AppColors.textMuted),
            ),
          ),
          if (!_hasSoundSystem) ...[
            const SizedBox(height: 8),
            const PremiumStatusHint(
              text: 'Audio folgt in einem späteren Update.',
              tone: PremiumStatusTone.warning,
            ),
          ],
          const SizedBox(height: 16),
          _sectionTitle('Sprache'),
          const SizedBox(height: 8),
          PremiumDecisionSheet(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              enabled: _hasLanguageSystem,
              leading: const Icon(Icons.language_rounded,
                  color: AppColors.textMuted),
              title: const Text('Sprache ändern'),
              subtitle: const Text(
                'Platzhalter: Sprachsystem ist noch nicht vorhanden.',
              ),
              trailing: _hasLanguageSystem
                  ? const Icon(Icons.chevron_right_rounded)
                  : const Icon(Icons.block_rounded),
              onTap: _hasLanguageSystem ? () {} : null,
            ),
          ),
          if (!_hasLanguageSystem) ...[
            const SizedBox(height: 8),
            const PremiumStatusHint(
              text: 'Sprachauswahl ist noch nicht aktiviert.',
              tone: PremiumStatusTone.warning,
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return PremiumSectionLabel(text: title.toUpperCase());
  }
}
