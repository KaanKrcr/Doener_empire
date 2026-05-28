import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../providers/game_provider.dart';

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
          _sectionTitle('Spiel'),
          const SizedBox(height: 8),
          Card(
            color: AppColors.bgCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.border),
            ),
            child: ListTile(
              leading: const Icon(Icons.home_rounded, color: AppColors.primary),
              title: const Text('Zurück zum Hauptmenü'),
              subtitle: const Text('Aktueller Spielstand bleibt gespeichert.'),
              onTap: () => context.go('/menu'),
            ),
          ),
          if (game != null) ...[
            const SizedBox(height: 12),
            Card(
              color: AppColors.bgCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tutorial',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
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
                            onPressed: () => ref
                                .read(gameProvider.notifier)
                                .resumeTutorial(),
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
            ),
          ],
          const SizedBox(height: 16),
          _sectionTitle('Audio'),
          const SizedBox(height: 8),
          Card(
            color: AppColors.bgCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.border),
            ),
            child: SwitchListTile(
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
          const SizedBox(height: 16),
          _sectionTitle('Sprache'),
          const SizedBox(height: 8),
          Card(
            color: AppColors.bgCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.border),
            ),
            child: ListTile(
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
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        color: AppColors.textMuted,
        letterSpacing: 1.4,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
