import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../models/game_state.dart';
import '../../models/shop_model.dart';
import '../../models/event_model.dart';
import '../../models/achievement_model.dart';
import '../../providers/game_provider.dart';
import '../../services/game_engine.dart';
import 'animated_money.dart';
import 'confetti_overlay.dart';

final _fmt = NumberFormat('#,##0', 'de_DE');

const _kWeekdays = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];

/// Dialog der nach dem Tag-Ende erscheint und das Ergebnis zusammenfasst.
/// Bei Event: zeigt Event-Karte mit Auswahl. Bei Mission: zeigt zusätzlich
/// Mission-Complete-Animation.
class DayEndDialog extends ConsumerWidget {
  final DayEndResult result;
  const DayEndDialog({super.key, required this.result});

  static Future<void> show(BuildContext context, DayEndResult result) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => DayEndDialog(result: result),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = result;
    final game = ref.watch(gameProvider);
    final isGoodDay = r.profit >= 0;
    final weekday = _kWeekdays[r.day % 7];
    final insights = _buildInsights(r, game);

    return Dialog(
      backgroundColor: AppColors.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Stack(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header mit Gradient
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isGoodDay
                            ? [AppColors.success, AppColors.accent]
                            : [AppColors.danger, AppColors.primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withAlpha(40),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'TAG ${r.day}  ·  $weekday',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                            Text(
                              isGoodDay ? '😊' : '😬',
                              style: const TextStyle(fontSize: 28),
                            ).animate().scale(
                                  delay: 120.ms,
                                  duration: 460.ms,
                                  begin: const Offset(0.3, 0.3),
                                  end: const Offset(1, 1),
                                  curve: Curves.elasticOut,
                                ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isGoodDay ? 'Erfolgreicher Tag!' : 'Schwieriger Tag',
                          style: AppText.display(
                            size: 22,
                            weight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        AnimatedMoney(
                          amount: r.profit,
                          fontSize: 34,
                          showSign: true,
                          compact: true,
                          color: Colors.white,
                          fontFamily: AppTheme.displayFont,
                        )
                            .animate()
                            .fadeIn(delay: 200.ms, duration: 400.ms)
                            .slideY(
                                begin: 0.3, end: 0, curve: Curves.easeOutCubic),
                      ],
                    ),
                  ),

                  // Zahlen-Aufschlüsselung
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _SummaryRow(
                          label: 'Umsatz',
                          value: '+${_fmt.format(r.revenue)} €',
                          color: AppColors.success,
                          icon: Icons.trending_up,
                        )
                            .animate()
                            .fadeIn(delay: 320.ms)
                            .slideX(begin: -0.1, end: 0),
                        _SummaryRow(
                          label: 'Kosten',
                          value: '-${_fmt.format(r.costs)} €',
                          color: AppColors.danger,
                          icon: Icons.trending_down,
                        )
                            .animate()
                            .fadeIn(delay: 400.ms)
                            .slideX(begin: -0.1, end: 0),
                        _SummaryRow(
                          label: 'Kunden bedient',
                          value: _fmt.format(r.customers),
                          color: AppColors.accent,
                          icon: Icons.people_alt_rounded,
                        )
                            .animate()
                            .fadeIn(delay: 480.ms)
                            .slideX(begin: -0.1, end: 0),
                        const Divider(color: AppColors.border, height: 24),
                        _InsightCard(insights: insights),
                        if (r.missionCompleted != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withAlpha(30),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: AppColors.gold.withAlpha(80)),
                            ),
                            child: Row(
                              children: [
                                const Text('🏆',
                                    style: TextStyle(fontSize: 24)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'AUFTRAG ERFÜLLT!',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: AppColors.gold,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 2,
                                        ),
                                      ),
                                      Text(
                                        r.missionCompleted!.title,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '+${_fmt.format(r.missionCompleted!.cashReward)} €',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.gold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (r.newAchievements.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          for (final a in r.newAchievements)
                            Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withAlpha(30),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: AppColors.secondary.withAlpha(80)),
                              ),
                              child: Row(
                                children: [
                                  Text(a.emoji,
                                      style: const TextStyle(fontSize: 18)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'TROPHÄE!',
                                          style: TextStyle(
                                            fontSize: 9,
                                            color: AppColors.secondary,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 2,
                                          ),
                                        ),
                                        Text(
                                          a.title,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '+${a.tier.points} Pkt',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.secondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              // Wenn Event vorhanden → Event-Dialog direkt zeigen
                              if (r.event != null) {
                                Future.microtask(() {
                                  if (context.mounted) {
                                    EventDialog.show(context, r.event!);
                                  }
                                });
                              }
                            },
                            icon: Icon(
                                r.event != null
                                    ? Icons.local_fire_department
                                    : Icons.arrow_forward_rounded,
                                size: 18),
                            label: Text(r.event != null
                                ? 'Ereignis ansehen'
                                : 'Weiter zum nächsten Tag'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (isGoodDay && r.profit > 0)
                const Positioned.fill(
                  child: ConfettiOverlay(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<_InsightLine> _buildInsights(DayEndResult r, GameState? game) {
    final insights = <_InsightLine>[];

    final margin = r.revenue > 0 ? r.profit / r.revenue : 0.0;
    if (r.profit < 0) {
      insights.add(
        _InsightLine(
          text:
              'Verlusttag: Kosten lagen ${_fmt.format(r.costs - r.revenue)} EUR über dem Umsatz.',
          tone: _InsightTone.danger,
        ),
      );
    } else if (margin < 0.12) {
      insights.add(
        _InsightLine(
          text:
              'Gewinn ist knapp (${(margin * 100).round()}% Marge): Preis und Kosten eng monitoren.',
          tone: _InsightTone.warning,
        ),
      );
    } else {
      insights.add(
        _InsightLine(
          text:
              'Solider Tag: ${(margin * 100).round()}% Marge bei ${_fmt.format(r.customers)} Kunden.',
          tone: _InsightTone.success,
        ),
      );
    }

    DailyRecord? yesterday;
    if (game != null) {
      for (final record in game.history) {
        if (record.day == r.day - 1) {
          yesterday = record;
          break;
        }
      }
    }
    if (yesterday != null) {
      final delta = r.customers - yesterday.customers;
      if (delta >= 20) {
        insights.add(
          _InsightLine(
            text: 'Kundenzahl stieg um +$delta vs. gestern.',
            tone: _InsightTone.success,
          ),
        );
      } else if (delta <= -20) {
        insights.add(
          _InsightLine(
            text:
                'Kundenzahl fiel um ${delta.abs()} vs. gestern: Standortfit und Preis prüfen.',
            tone: _InsightTone.warning,
          ),
        );
      } else {
        insights.add(
          _InsightLine(
            text: 'Kundenzahl stabil (Delta ${delta >= 0 ? '+' : ''}$delta).',
            tone: _InsightTone.neutral,
          ),
        );
      }
    } else {
      insights.add(
        const _InsightLine(
          text:
              'Tag 1 Referenz: erst mit Tag 2 wird ein sauberer Trendvergleich möglich.',
          tone: _InsightTone.neutral,
        ),
      );
    }

    if (game == null || game.shops.isEmpty) {
      insights.add(
        const _InsightLine(
          text:
              'Nächster Schritt: erste Filiale eröffnen und dann Preise nachziehen.',
          tone: _InsightTone.neutral,
        ),
      );
      return insights;
    }

    Shop? capacityShop;
    for (final shop in game.shops) {
      if (GameEngine.isCapacityLimited(shop, day: r.day, state: game)) {
        capacityShop = shop;
        break;
      }
    }

    if (capacityShop != null) {
      final capStats =
          GameEngine.calculateShopStats(capacityShop, day: r.day, state: game);
      final demandServedPct =
          (capStats.utilization * 100).clamp(0, 100).round();
      final maxEmp = GameEngine.maxEmployeesForShop(capacityShop);
      final atEmployeeCap = capacityShop.employees.length >= maxEmp;
      insights.add(
        _InsightLine(
          text: atEmployeeCap
              ? 'Kapazitätslimit bei ${capacityShop.displayName}: $demandServedPct% der Nachfrage bedient. Personal-Cap erreicht → Filiale ausbauen.'
              : 'Kapazitätslimit bei ${capacityShop.displayName}: $demandServedPct% der Nachfrage bedient. Mehr Personal oder Kapazitäts-Upgrades helfen.',
          tone: _InsightTone.warning,
        ),
      );
      return insights;
    }

    var cheapestDeposit = double.infinity;
    for (final shop in game.shops) {
      final deposit = shop.weeklyRent * 2;
      if (deposit < cheapestDeposit) cheapestDeposit = deposit;
    }

    final hasExpansionBudget =
        cheapestDeposit.isFinite && game.cash >= cheapestDeposit * 1.2;
    if (r.profit > 0 && hasExpansionBudget) {
      insights.add(
        const _InsightLine(
          text:
              'Expansion möglich: Cash reicht für eine zweite Filiale in ähnlicher Lage.',
          tone: _InsightTone.success,
        ),
      );
    } else {
      insights.add(
        const _InsightLine(
          text:
              'Vor Expansion zuerst Upgrade-Zyklus fahren: Preis, Team oder Equipment stabilisieren.',
          tone: _InsightTone.warning,
        ),
      );
    }

    return insights;
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _SummaryRow({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                )),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final List<_InsightLine> insights;

  const _InsightCard({required this.insights});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TOP 3 INSIGHTS',
            style: TextStyle(
              fontSize: 10,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(height: 8),
          for (final insight in insights)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _iconForTone(insight.tone),
                    size: 14,
                    color: _colorForTone(insight.tone),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      insight.text,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  IconData _iconForTone(_InsightTone tone) {
    switch (tone) {
      case _InsightTone.success:
        return Icons.check_circle_outline;
      case _InsightTone.warning:
        return Icons.warning_amber_rounded;
      case _InsightTone.danger:
        return Icons.error_outline_rounded;
      case _InsightTone.neutral:
        return Icons.info_outline_rounded;
    }
  }

  Color _colorForTone(_InsightTone tone) {
    switch (tone) {
      case _InsightTone.success:
        return AppColors.success;
      case _InsightTone.warning:
        return AppColors.warning;
      case _InsightTone.danger:
        return AppColors.danger;
      case _InsightTone.neutral:
        return AppColors.textMuted;
    }
  }
}

class _InsightLine {
  final String text;
  final _InsightTone tone;

  const _InsightLine({
    required this.text,
    required this.tone,
  });
}

enum _InsightTone {
  success,
  warning,
  danger,
  neutral,
}

// ── Event-Dialog ──────────────────────────────────────────────────────────

class EventDialog extends ConsumerWidget {
  final GameEvent event;
  const EventDialog({super.key, required this.event});

  /// Backwards-kompatible Signatur — `ref` wird ignoriert weil der Dialog
  /// jetzt selbst ein ConsumerWidget ist und ref über `WidgetRef` im build
  /// bekommt. Dadurch funktioniert der Pop-Context zuverlässig.
  static Future<void> show(BuildContext context, GameEvent event,
      [WidgetRef? ref]) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => EventDialog(event: event),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryColor = switch (event.category) {
      EventCategory.good => AppColors.success,
      EventCategory.bad => AppColors.danger,
      EventCategory.neutral => AppColors.warning,
      EventCategory.opportunity => AppColors.gold,
    };
    final categoryLabel = switch (event.category) {
      EventCategory.good => 'GUTE NACHRICHT',
      EventCategory.bad => 'ÄRGER',
      EventCategory.neutral => 'EREIGNIS',
      EventCategory.opportunity => 'CHANCE',
    };

    return Dialog(
      backgroundColor: AppColors.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    categoryColor.withAlpha(80),
                    categoryColor.withAlpha(30),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(40),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      categoryLabel,
                      style: TextStyle(
                        color: categoryColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(event.emoji, style: const TextStyle(fontSize: 48)),
                  const SizedBox(height: 8),
                  Text(
                    event.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                children: [
                  Text(
                    event.description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  for (final c in event.choices) ...[
                    _ChoiceButton(
                      choice: c,
                      onTap: () {
                        // Erst State anwenden (synchron), dann Dialog schließen,
                        // dann Snackbar zeigen (außerhalb des Dialog-Contexts).
                        ref
                            .read(gameProvider.notifier)
                            .applyEventChoice(event, c);
                        final navigator = Navigator.of(context);
                        final messenger = ScaffoldMessenger.maybeOf(context);
                        navigator.pop();
                        messenger?.showSnackBar(
                          SnackBar(
                            content: Text(c.effect.resultMessage),
                            duration: const Duration(seconds: 4),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  final EventChoice choice;
  final VoidCallback onTap;
  const _ChoiceButton({required this.choice, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Material-Wrapper ist nötig damit InkWell-Taps registriert werden.
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
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  choice.label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (choice.cost != null && choice.cost! > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withAlpha(30),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '-${_fmt.format(choice.cost!)} €',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.danger,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textMuted, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
