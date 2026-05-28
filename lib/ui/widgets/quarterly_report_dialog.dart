import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../models/stock_model.dart';

final _fmt = NumberFormat('#,##0', 'de_DE');

/// Dialog der nach jedem Quartal (90 Tage) erscheint.
/// Zeigt: Performance, Aktienkurs-Reaktion, Headline.
class QuarterlyReportDialog extends StatelessWidget {
  final QuarterlyReport report;
  const QuarterlyReportDialog({super.key, required this.report});

  static Future<void> show(BuildContext context, QuarterlyReport report) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => QuarterlyReportDialog(report: report),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isGood = report.beatsExpectation;

    return Dialog(
      backgroundColor: AppColors.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isGood
                      ? [AppColors.gold, AppColors.secondary]
                      : [AppColors.danger, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  const Text('📊', style: TextStyle(fontSize: 36)),
                  const SizedBox(height: 6),
                  const Text(
                    'QUARTALSBERICHT',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      letterSpacing: 3,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    report.headline,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
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
                  _Row(
                    label: 'Umsatz Q.',
                    value: '${_fmt.format(report.revenue)} €',
                    color: AppColors.success,
                  ),
                  _Row(
                    label: 'Gewinn Q.',
                    value: '${_fmt.format(report.profit)} €',
                    color: AppColors.gold,
                  ),
                  _Row(
                    label: 'Analysten-Erwartung',
                    value: '${_fmt.format(report.expectation)} €',
                    color: AppColors.textSecondary,
                  ),
                  _Row(
                    label: 'Kunden Q.',
                    value: _fmt.format(report.customers),
                    color: AppColors.accent,
                  ),
                  const Divider(color: AppColors.border, height: 24),
                  _Row(
                    label: 'Aktienkurs',
                    value:
                        '${report.priceMovePercent >= 0 ? "+" : ""}${report.priceMovePercent.toStringAsFixed(1)}%',
                    color: report.priceMovePercent >= 0
                        ? AppColors.success
                        : AppColors.danger,
                  ),
                  const SizedBox(height: 16),
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
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Row({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
          ),
          Text(value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: color,
              )),
        ],
      ),
    );
  }
}
