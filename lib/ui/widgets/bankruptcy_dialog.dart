import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme.dart';
import '../../models/game_state.dart';
import '../../providers/game_provider.dart';

final _fmt = NumberFormat('#,##0', 'de_DE');
const _uuid = Uuid();

/// Dialog wenn der Spieler ins Minus rutscht.
/// Drei Optionen:
/// 1) Notkredit aufnehmen (hoher Zins, aber sofortige Rettung)
/// 2) Filiale schließen (eine Filiale aufgeben, Mietkaution zurück)
/// 3) Insolvenz anmelden (Game Over, Restart)
class BankruptcyDialog extends ConsumerWidget {
  const BankruptcyDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const BankruptcyDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameProvider);
    if (game == null) return const SizedBox.shrink();

    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.danger, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    const Text('💸', style: TextStyle(fontSize: 56)),
                    const SizedBox(height: 8),
                    const Text(
                      'Du bist pleite!',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Kontostand: ${_fmt.format(game.cash)} €',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      'Du musst handeln, sonst ist Schluss. Drei Optionen:',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Option 1: Notkredit
                    _OptionTile(
                      emoji: '🏦',
                      title: 'Notkredit aufnehmen',
                      subtitle:
                          '20.000 € sofort  ·  12% Zinsen  ·  180 Tage Laufzeit',
                      color: AppColors.warning,
                      onTap: () {
                        final loan = Loan(
                          id: _uuid.v4(),
                          amount: 20000,
                          interestRate: 0.12,
                          durationDays: 180,
                          dayTaken: game.currentDay,
                        );
                        ref.read(gameProvider.notifier).takeLoan(loan);
                        Navigator.of(context).pop();
                      },
                    ),
                    const SizedBox(height: 10),

                    // Option 2: Filiale schließen
                    if (game.shops.isNotEmpty)
                      _OptionTile(
                        emoji: '🚪',
                        title: 'Filiale schließen',
                        subtitle:
                            'Die schwächste Filiale aufgeben, Mietkaution zurück.',
                        color: AppColors.secondary,
                        onTap: () {
                          final worstShop = _findWorstShop(game);
                          if (worstShop != null) {
                            ref
                                .read(gameProvider.notifier)
                                .closeShop(worstShop.id);
                          }
                          Navigator.of(context).pop();
                        },
                      ),
                    if (game.shops.isNotEmpty) const SizedBox(height: 10),

                    // Option 3: Insolvenz
                    _OptionTile(
                      emoji: '⚰️',
                      title: 'Insolvenz anmelden',
                      subtitle: 'Game Over — neues Spiel starten.',
                      color: AppColors.danger,
                      onTap: () async {
                        await ref.read(gameProvider.notifier).deleteGame();
                        if (context.mounted) {
                          Navigator.of(context).pop();
                          context.go('/menu');
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Findet die schlechteste Filiale (geringste Reputation).
  static dynamic _findWorstShop(GameState game) {
    if (game.shops.isEmpty) return null;
    final sorted = List.from(game.shops);
    sorted.sort(
        (a, b) => (a.reputation as double).compareTo(b.reputation as double));
    return sorted.first;
  }
}

class _OptionTile extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _OptionTile({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.bgSurface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withAlpha(80)),
          ),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textMuted, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
