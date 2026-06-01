import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../services/game_engine.dart';
import 'premium_mobile_ui.dart';

final _fmt = NumberFormat('#,##0', 'de_DE');

/// Wochenbilanz-Dialog (erscheint alle 7 Tage).
class WeeklyReportDialog extends StatelessWidget {
  final WeeklyReport report;
  const WeeklyReportDialog({super.key, required this.report});

  static Future<void> show(BuildContext context, WeeklyReport report) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => WeeklyReportDialog(report: report),
    );
  }

  @override
  Widget build(BuildContext context) {
    final positive = report.profit >= 0;
    final growth = report.profitGrowthPct;
    final growthUp = growth >= 0;

    return Dialog(
      backgroundColor: AppColors.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                decoration: const BoxDecoration(gradient: AppGradients.gold),
                child: Column(
                  children: [
                    Text('📈 WOCHENBILANZ',
                        style: AppText.label(color: AppColors.bg, size: 11)),
                    const SizedBox(height: 4),
                    Text(
                      'Woche ${report.weekNumber}',
                      style: AppText.display(
                          size: 24,
                          weight: FontWeight.w800,
                          color: AppColors.bg),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    PremiumMetricStrip(
                      items: [
                        PremiumMetricData(
                          label: 'Umsatz',
                          value: '${_fmt.format(report.revenue)} €',
                          color: AppColors.success,
                        ),
                        PremiumMetricData(
                          label: 'Gewinn',
                          value:
                              '${positive ? '+' : ''}${_fmt.format(report.profit)} €',
                          color:
                              positive ? AppColors.success : AppColors.danger,
                        ),
                        PremiumMetricData(
                          label: 'Kunden',
                          value: _fmt.format(report.customers),
                          color: AppColors.accent,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _Row(
                      icon: Icons.emoji_events_rounded,
                      color: AppColors.gold,
                      label: 'Bester Tag',
                      value:
                          'Tag ${report.bestDay} (${_fmt.format(report.bestDayRevenue)} €)',
                    ),
                    const SizedBox(height: 8),
                    _Row(
                      icon: growthUp
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      color: growthUp ? AppColors.success : AppColors.danger,
                      label: 'Gewinn ggü. Vorwoche',
                      value:
                          '${growthUp ? '+' : ''}${growth.toStringAsFixed(0)} %',
                    ),
                    const SizedBox(height: 12),
                    PremiumStatusHint(
                      text: growthUp
                          ? 'Trend positiv. Halte Servicequalität und Nachfrage im Gleichgewicht.'
                          : 'Trend negativ. Prüfe Preise, Personal und Auslastung deiner Kernfilialen.',
                      tone: growthUp
                          ? PremiumStatusTone.success
                          : PremiumStatusTone.warning,
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Weiter'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 220.ms).scale(
          begin: const Offset(0.95, 0.95),
          end: const Offset(1, 1),
        );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  const _Row({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumDecisionSheet(
      borderColor: color.withAlpha(70),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
          ),
          Text(value,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }
}
