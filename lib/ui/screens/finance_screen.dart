import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../models/game_state.dart';
import '../../models/product_model.dart';
import '../../models/shop_model.dart';
import '../../providers/game_provider.dart';
import '../../services/game_engine.dart';

final _fmt = NumberFormat('#,##0', 'de_DE');

class FinanceScreen extends ConsumerStatefulWidget {
  const FinanceScreen({super.key});

  @override
  ConsumerState<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends ConsumerState<FinanceScreen> {
  int _rangeDays = 14;

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(gameProvider)!;
    final dailyRevenue = ref.watch(dailyRevenueProvider);
    final dailyCosts = ref.watch(dailyCostsProvider);
    final dailyProfit = ref.watch(dailyProfitProvider);

    final history = game.history.length > _rangeDays
        ? game.history.sublist(game.history.length - _rangeDays)
        : game.history;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Finanzen'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Übersicht
          const _Section('HEUTE'),
          const SizedBox(height: 8),
          _FinanceRow(
            label: 'Tagesumsatz',
            value: '+ ${_fmt.format(dailyRevenue)} €',
            color: AppColors.success,
            icon: Icons.trending_up,
          ),
          _FinanceRow(
            label: 'Tageskosten',
            value: '- ${_fmt.format(dailyCosts)} €',
            color: AppColors.danger,
            icon: Icons.trending_down,
          ),
          _FinanceRow(
            label: 'Tagesprofit',
            value:
                '${dailyProfit >= 0 ? "+" : ""}${_fmt.format(dailyProfit)} €',
            color: dailyProfit >= 0 ? AppColors.success : AppColors.danger,
            icon: Icons.account_balance_wallet_outlined,
            bold: true,
          ),
          const SizedBox(height: 20),

          // Verlauf mit Zeitraum-Filter
          if (history.length >= 2) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const _Section('FINANZVERLAUF'),
                _RangeSelector(
                  selected: _rangeDays,
                  onChanged: (n) => setState(() => _rangeDays = n),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const _ChartLegend(),
            const SizedBox(height: 8),
            SizedBox(
              height: 220,
              child: _FinanceChart(history: history),
            ),
            const SizedBox(height: 16),
            _PeriodSummary(
              history: history,
              activeLoanDebt: game.activeLoansTotal,
            ),
            const SizedBox(height: 20),
          ],

          // Kostenstruktur (letzte 7 Tage)
          if (game.history.isNotEmpty) ...[
            const _Section('KOSTENSTRUKTUR (letzte 7 Tage)'),
            const SizedBox(height: 8),
            _CostBreakdownCard(
              history: game.history.length > 7
                  ? game.history.sublist(game.history.length - 7)
                  : game.history,
            ),
            const SizedBox(height: 20),
          ],

          // Produkt-Profitabilität
          if (game.shops.isNotEmpty) ...[
            const _Section('PRODUKT-PROFITABILITÄT (heute, geschätzt)'),
            const SizedBox(height: 8),
            _ProductProfitCard(
              products: GameEngine.productProfitBreakdown(game),
            ),
            const SizedBox(height: 20),
          ],

          // Gesamtbilanz
          const _Section('GESAMTBILANZ'),
          const SizedBox(height: 8),
          _FinanceRow(
            label: 'Gesamtumsatz',
            value: '${_fmt.format(game.totalRevenue)} €',
            color: AppColors.success,
            icon: Icons.bar_chart,
          ),
          _FinanceRow(
            label: 'Gesamtprofit',
            value: '${_fmt.format(game.totalProfit)} €',
            color: game.totalProfit >= 0 ? AppColors.success : AppColors.danger,
            icon: Icons.stacked_bar_chart,
          ),
          _FinanceRow(
            label: 'Aktive Kredite',
            value: game.activeLoansTotal > 0
                ? '- ${_fmt.format(game.activeLoansTotal)} €'
                : 'Keine',
            color: game.activeLoansTotal > 0
                ? AppColors.warning
                : AppColors.textMuted,
            icon: Icons.account_balance_outlined,
          ),
          const SizedBox(height: 20),

          // Filial-Ranking
          if (game.shops.length >= 2) ...[
            const _Section('FILIAL-RANKING (heute, geschätzt)'),
            const SizedBox(height: 8),
            _ShopRankingCard(ranking: GameEngine.shopsByProfit(game)),
            const SizedBox(height: 20),
          ],

          // Filialen
          const _Section('FILIALEN'),
          const SizedBox(height: 8),
          if (game.shops.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Noch keine Filialen',
                    style: TextStyle(color: AppColors.textMuted)),
              ),
            )
          else
            for (final shop in game.shops)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(40),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                          child: Text('🥙', style: TextStyle(fontSize: 22))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(shop.displayName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary)),
                          Text(shop.locationName,
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.textMuted)),
                          if (shop.wasAcquired && shop.acquiredHint != null)
                            Text(
                              shop.acquiredHint!,
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.secondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${_fmt.format(shop.weeklyRent)} €/Wo Miete',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textMuted),
                        ),
                        Text(
                          '${shop.employees.length} Mitarbeiter',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Zeitraum-Auswahl ────────────────────────────────────────────────────

class _RangeSelector extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;
  const _RangeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final n in [7, 14, 30])
            GestureDetector(
              onTap: () => onChanged(n),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: selected == n ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${n}T',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: selected == n ? Colors.white : AppColors.textMuted,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Legende ─────────────────────────────────────────────────────────────

class _ChartLegend extends StatelessWidget {
  const _ChartLegend();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 12,
      runSpacing: 6,
      children: [
        _LegendItem(color: AppColors.success, label: 'Umsatz'),
        _LegendItem(color: AppColors.danger, label: 'Ausgaben gesamt'),
        _LegendItem(color: AppColors.gold, label: 'Nettogewinn'),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(label,
            style:
                const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}

// ── Hauptchart mit 3 Linien (Umsatz, Kosten, Profit) ────────────────────

class _FinanceChart extends StatelessWidget {
  final List<DailyRecord> history;
  const _FinanceChart({required this.history});

  @override
  Widget build(BuildContext context) {
    final revSpots = <FlSpot>[];
    final costSpots = <FlSpot>[];
    final profitSpots = <FlSpot>[];

    for (int i = 0; i < history.length; i++) {
      final r = history[i];
      final fullCosts = r.costs + r.loanPayments + r.investments;
      final profit = r.revenue - fullCosts;
      revSpots.add(FlSpot(i.toDouble(), r.revenue));
      costSpots.add(FlSpot(i.toDouble(), fullCosts));
      profitSpots.add(FlSpot(i.toDouble(), profit));
    }

    double maxY = 0, minY = 0;
    for (final r in history) {
      final full = r.costs + r.loanPayments + r.investments;
      final p = r.revenue - full;
      if (r.revenue > maxY) maxY = r.revenue;
      if (full > maxY) maxY = full;
      if (p < minY) minY = p;
      if (p > maxY) maxY = p;
    }
    if (maxY == 0) maxY = 100;
    maxY *= 1.15;
    minY = (minY * 1.15).clamp(double.negativeInfinity, 0);

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: ((maxY - minY) / 4).clamp(1, double.infinity),
          getDrawingHorizontalLine: (_) => const FlLine(
            color: AppColors.border,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (v, _) => Text(
                _fmt.format(v),
                style: const TextStyle(fontSize: 9, color: AppColors.textMuted),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: (history.length / 6).clamp(1, double.infinity),
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= history.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'T${history[i].day}',
                    style: const TextStyle(
                        fontSize: 9, color: AppColors.textMuted),
                  ),
                );
              },
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (history.length - 1).toDouble(),
        minY: minY,
        maxY: maxY,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.bgSurface,
            tooltipBorder: const BorderSide(color: AppColors.border),
            getTooltipItems: (spots) => spots.map((s) {
              final labels = ['Umsatz', 'Ausgaben gesamt', 'Nettogewinn'];
              return LineTooltipItem(
                '${labels[s.barIndex]}: ${_fmt.format(s.y)} €',
                TextStyle(
                  color: [
                    AppColors.success,
                    AppColors.danger,
                    AppColors.gold
                  ][s.barIndex],
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              );
            }).toList(),
          ),
        ),
        lineBarsData: [
          _line(revSpots, AppColors.success, fill: true),
          _line(costSpots, AppColors.danger),
          _line(profitSpots, AppColors.gold, dashed: true),
        ],
      ),
    );
  }

  LineChartBarData _line(List<FlSpot> spots, Color color,
      {bool fill = false, bool dashed = false}) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      curveSmoothness: 0.25,
      color: color,
      barWidth: 2.5,
      isStrokeCapRound: true,
      dashArray: dashed ? [6, 4] : null,
      dotData: const FlDotData(show: false),
      belowBarData: fill
          ? BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  color.withAlpha(60),
                  color.withAlpha(0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            )
          : BarAreaData(show: false),
    );
  }
}

// ── Zusammenfassung des gewählten Zeitraums ─────────────────────────────

class _PeriodSummary extends StatelessWidget {
  final List<DailyRecord> history;
  final double activeLoanDebt;
  const _PeriodSummary({
    required this.history,
    required this.activeLoanDebt,
  });

  @override
  Widget build(BuildContext context) {
    double revSum = 0;
    double operatingCostsSum = 0;
    double deliveryCommissionSum = 0;
    double profSum = 0;
    double invSum = 0;
    double loanSum = 0;
    for (final r in history) {
      revSum += r.revenue;
      operatingCostsSum += r.costs;
      deliveryCommissionSum += r.deliveryCommissionCosts;
      profSum += r.revenue - r.costs - r.loanPayments - r.investments;
      invSum += r.investments;
      loanSum += r.loanPayments;
    }
    final operatingExcludingDelivery =
        (operatingCostsSum - deliveryCommissionSum).clamp(0.0, double.infinity);
    final totalOutflow = operatingCostsSum + invSum + loanSum;
    final bestDay = history.fold<DailyRecord?>(
        null, (b, r) => b == null || r.revenue > b.revenue ? r : b);
    final worstDay = history.fold<DailyRecord?>(
        null,
        (b, r) => b == null ||
                (r.revenue - r.costs - r.loanPayments - r.investments) <
                    (b.revenue - b.costs - b.loanPayments - b.investments)
            ? r
            : b);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _SummaryItem(
                label: 'Umsatz',
                value: '${_fmt.format(revSum)} €',
                color: AppColors.success,
              ),
              _SummaryItem(
                label: 'Ausgaben',
                value: '${_fmt.format(totalOutflow)} €',
                color: AppColors.danger,
              ),
              _SummaryItem(
                label: 'Gewinn',
                value: '${profSum >= 0 ? "+" : ""}${_fmt.format(profSum)} €',
                color: profSum >= 0 ? AppColors.success : AppColors.danger,
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 10),
          _DetailRow(
            label: 'Operative Kosten (ohne Lieferprovision)',
            value: '${_fmt.format(operatingExcludingDelivery)} €',
            color: AppColors.textSecondary,
          ),
          _DetailRow(
            label: 'Lieferprovision (separat)',
            value: '${_fmt.format(deliveryCommissionSum)} €',
            color: AppColors.danger,
          ),
          _DetailRow(
            label: 'Investitionen/Upgrades (einmalig)',
            value: '${_fmt.format(invSum)} €',
            color: AppColors.secondary,
          ),
          _DetailRow(
            label: 'Kreditraten',
            value: '${_fmt.format(loanSum)} €',
            color: AppColors.warning,
          ),
          _DetailRow(
            label: 'Offene Kreditschulden',
            value: '${_fmt.format(activeLoanDebt)} €',
            color: AppColors.warning,
          ),
          const SizedBox(height: 6),
          Text(
            'Zeitraum: ${history.length} Tage',
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          if (bestDay != null && worstDay != null) ...[
            const SizedBox(height: 10),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.emoji_events,
                          size: 14, color: AppColors.success),
                      const SizedBox(width: 4),
                      Text(
                        'Bester Tag: T${bestDay.day} (${_fmt.format(bestDay.revenue)} €)',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.trending_down,
                    size: 14, color: AppColors.danger),
                const SizedBox(width: 4),
                Text(
                  'Schlechtester Tag: T${worstDay.day} (${_fmt.format(worstDay.revenue - worstDay.costs - worstDay.loanPayments - worstDay.investments)} €)',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryItem(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
          Text(value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: color,
              )),
        ],
      ),
    );
  }
}

// ── Kostenstruktur als gestapelter Bar ──────────────────────────────────

class _CostBreakdownCard extends StatelessWidget {
  final List<DailyRecord> history;
  const _CostBreakdownCard({required this.history});

  @override
  Widget build(BuildContext context) {
    final rent = history.fold(0.0, (s, r) => s + r.rentCosts);
    final sal = history.fold(0.0, (s, r) => s + r.salaryCosts);
    final ing = history.fold(0.0, (s, r) => s + r.ingredientCosts);
    final del = history.fold(0.0, (s, r) => s + r.deliveryCommissionCosts);
    final loan = history.fold(0.0, (s, r) => s + r.loanPayments);
    final inv = history.fold(0.0, (s, r) => s + r.investments);
    final total = rent + sal + ing + del + loan + inv;
    if (total == 0) {
      return const SizedBox(
        height: 80,
        child: Center(
          child: Text('Noch keine Kostendaten',
              style: TextStyle(color: AppColors.textMuted)),
        ),
      );
    }

    final items = [
      ('Miete', rent, AppColors.warning),
      ('Gehälter', sal, AppColors.accent),
      ('Zutaten', ing, AppColors.tomato),
      ('Lieferprovision', del, AppColors.danger),
      ('Kreditraten', loan, AppColors.onion),
      ('Investitionen', inv, AppColors.secondary),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Gestapelter Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 14,
              child: Row(
                children: [
                  for (final it in items)
                    if (it.$2 > 0)
                      Expanded(
                        flex: ((it.$2 / total) * 1000).round(),
                        child: Container(color: it.$3),
                      ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Legende mit Werten
          for (final it in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: it.$3,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(it.$1,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ),
                  Text(
                    '${_fmt.format(it.$2)} €  (${((it.$2 / total) * 100).toStringAsFixed(0)}%)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: it.$3,
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

class _ShopRankingCard extends StatelessWidget {
  final List<({Shop shop, double profit})> ranking;
  const _ShopRankingCard({required this.ranking});

  @override
  Widget build(BuildContext context) {
    final maxAbs = ranking.fold<double>(
        1, (m, e) => e.profit.abs() > m ? e.profit.abs() : m);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < ranking.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 18,
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          ranking[i].shop.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        '${ranking[i].profit >= 0 ? "+" : ""}${_fmt.format(ranking[i].profit)} €',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: ranking[i].profit >= 0
                              ? AppColors.success
                              : AppColors.danger,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Padding(
                    padding: const EdgeInsets.only(left: 26),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (ranking[i].profit.abs() / maxAbs).clamp(0.0, 1.0),
                        minHeight: 5,
                        backgroundColor: AppColors.bg.withValues(alpha: 0.5),
                        color: ranking[i].profit >= 0
                            ? AppColors.success
                            : AppColors.danger,
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
}

class _ProductProfitCard extends StatelessWidget {
  final List<ProductProfit> products;
  const _ProductProfitCard({required this.products});

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: const Text(
          'Noch keine Verkäufe heute. Sobald Kunden kommen, siehst du hier, '
          'welches Gericht am meisten Gewinn bringt.',
          style: TextStyle(fontSize: 12.5, color: AppColors.textMuted, height: 1.4),
        ),
      );
    }

    final maxProfit = products.fold<double>(
        0, (m, p) => p.profit > m ? p.profit : m);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < products.length; i++)
            _ProductProfitRow(
              rank: i + 1,
              data: products[i],
              maxProfit: maxProfit,
            ),
        ],
      ),
    );
  }
}

class _ProductProfitRow extends StatelessWidget {
  final int rank;
  final ProductProfit data;
  final double maxProfit;
  const _ProductProfitRow({
    required this.rank,
    required this.data,
    required this.maxProfit,
  });

  @override
  Widget build(BuildContext context) {
    final pd = kAllProducts.firstWhere(
      (p) => p.id == data.productId,
      orElse: () => const ProductData(
        id: '?',
        name: 'Produkt',
        emoji: '🍽️',
        basePrice: 0,
        ingredientCostPerUnit: 0,
        category: ProductCategory.beilage,
      ),
    );
    final barFrac = maxProfit > 0 ? (data.profit / maxProfit).clamp(0.0, 1.0) : 0.0;
    final marginPct = (data.margin * 100).round();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 18,
                child: Text(
                  '$rank',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              Text(pd.emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  pd.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '+${_fmt.format(data.profit)} €',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              const SizedBox(width: 26),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: barFrac,
                    minHeight: 5,
                    backgroundColor: AppColors.bg.withValues(alpha: 0.5),
                    color: AppColors.gold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${data.units.round()} Stk · $marginPct% Marge',
                style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String text;
  const _Section(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        color: AppColors.textMuted,
        letterSpacing: 2,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _FinanceRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final bool bold;

  const _FinanceRow({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: bold ? color.withAlpha(80) : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: bold ? 15 : 13,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: bold ? 16 : 14,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
