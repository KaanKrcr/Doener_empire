import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../models/competitor_model.dart';
import '../../models/marketing_model.dart';
import '../../models/product_model.dart';
import '../../models/production_model.dart';
import '../../models/stock_model.dart';
import '../../models/game_state.dart';
import '../../models/hr_manager_model.dart';
import '../../models/combo_model.dart';
import '../../models/quality_model.dart';
import '../../providers/game_provider.dart';
import '../../services/corporate_engine.dart';
import '../../services/game_engine.dart';
import '../../services/hr_engine.dart';
import '../../models/upgrade_model.dart';

final _fmt = NumberFormat('#,##0', 'de_DE');
final _fmtPrice = NumberFormat('#,##0.00', 'de_DE');

/// Corporate-/Konzern-Ebene — Phase 4 des Spiels.
///
/// Tabs:
/// 1. Börse — IPO oder Aktienkurs-Chart
/// 2. Produktion — eigene Fabriken bauen
/// 3. M&A — Konkurrenten aufkaufen
class CorporateScreen extends ConsumerStatefulWidget {
  const CorporateScreen({super.key});

  @override
  ConsumerState<CorporateScreen> createState() => _CorporateScreenState();
}

class _CorporateScreenState extends ConsumerState<CorporateScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(gameProvider);
    if (game == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  Text(
                    'Konzern',
                    style: AppText.display(size: 28, weight: FontWeight.w800),
                  ),
                  const Spacer(),
                  if (game.stocks.isPublic)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.gold, AppColors.secondary],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_fmtPrice.format(game.stocks.sharePrice)} €',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.bg,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: TabBar(
                controller: _tabs,
                indicatorColor: AppColors.primary,
                dividerColor: Colors.transparent,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textMuted,
                tabs: const [
                  Tab(text: 'Börse'),
                  Tab(text: 'Produktion'),
                  Tab(text: 'M&A'),
                  Tab(text: 'Upgrades'),
                  Tab(text: 'Strategie'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _StockTab(game: game),
                  _ProductionTab(game: game),
                  _MATab(game: game),
                  _GlobalUpgradesTab(game: game),
                  _StrategieTab(game: game),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── BÖRSE-TAB ──────────────────────────────────────────────────────────

class _StockTab extends ConsumerWidget {
  final GameState game;
  const _StockTab({required this.game});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canIPO = CorporateEngine.canDoIPO(game);
    final isPublic = game.stocks.isPublic;

    if (!isPublic) {
      // Exakt dieselben Werte wie in CorporateEngine.canDoIPO verwenden,
      // damit UI-grün und Button-aktiv übereinstimmen (kein Rundungs-Drift).
      final shopsOk = game.shops.length >= IPORequirements.minShops;
      final brandOk =
          game.brand.brandAwareness >= IPORequirements.minBrandAwareness;
      final revenueOk = game.totalRevenue >= IPORequirements.minTotalRevenue;

      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // IPO-Voraussetzungen
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.gold.withAlpha(40),
                  AppColors.secondary.withAlpha(30),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.gold.withAlpha(80)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'BÖRSENGANG (IPO)',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.gold,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Lass dein Imperium öffentlich handeln und sichere dir massive Cash-Zuflüsse.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                _RequirementRow(
                  label: 'Filialen',
                  met: shopsOk,
                  currentLabel: '${game.shops.length}',
                  requiredLabel: '${IPORequirements.minShops}',
                ),
                _RequirementRow(
                  label: 'Markenbekanntheit',
                  met: brandOk,
                  currentLabel: game.brand.brandAwareness.toStringAsFixed(1),
                  requiredLabel: '${IPORequirements.minBrandAwareness}',
                ),
                _RequirementRow(
                  label: 'Gesamtumsatz',
                  met: revenueOk,
                  currentLabel: '${_fmt.format(game.totalRevenue)} €',
                  requiredLabel:
                      '${_fmt.format(IPORequirements.minTotalRevenue)} €',
                ),
                const SizedBox(height: 16),
                if (canIPO) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showIPODialog(context, ref, game),
                      icon: const Icon(Icons.rocket_launch, size: 18),
                      label: const Text('Börsengang einleiten'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: AppColors.bg,
                      ),
                    ),
                  ),
                ] else
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text(
                      'Voraussetzungen noch nicht erfüllt.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      );
    }

    // Public: Aktienkurs-Chart + Bewertung
    final history = game.stocks.priceHistory;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.gold, AppColors.secondary],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'AKTIENKURS',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.bg,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_fmtPrice.format(game.stocks.sharePrice)} €',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: AppColors.bg,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 92,
                child: _StockChart(history: history),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _MetricRow(
          label: 'Marktkapitalisierung',
          value: '${_fmt.format(game.stocks.marketCap)} €',
        ),
        _MetricRow(
          label: 'Dein Anteil',
          value: '${(game.stocks.playerShareRatio * 100).toStringAsFixed(1)}%',
        ),
        _MetricRow(
          label: 'Dein Aktienwert',
          value: '${_fmt.format(game.stocks.playerStockValue)} €',
        ),
        _MetricRow(
          label: 'Letztes Quartal',
          value: '${_fmt.format(game.stocks.lastQuarterProfit)} € Gewinn',
        ),
        _MetricRow(
          label: 'Analysten-Erwartung',
          value: '${_fmt.format(game.stocks.analystExpectation)} €',
        ),
      ],
    );
  }

  void _showIPODialog(BuildContext context, WidgetRef ref, GameState game) {
    final valuation = CorporateEngine.estimateValuation(game);
    double floatPercent = 0.20;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: AppColors.bgCard,
          title: const Text('Börsengang vorbereiten'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Bewertung: ${_fmt.format(valuation)} €',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.gold,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Wieviel Prozent der Firma ausgeben?',
                style: TextStyle(fontSize: 13),
              ),
              Slider(
                min: 0.10,
                max: 0.49,
                divisions: 39,
                value: floatPercent,
                label: '${(floatPercent * 100).toStringAsFixed(0)}%',
                onChanged: (v) => setState(() => floatPercent = v),
              ),
              const SizedBox(height: 6),
              Text(
                'Cash-Erlös: ≈ ${_fmt.format(valuation * floatPercent * 0.95)} €',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Dein Anteil danach: ${((1 - floatPercent) * 100).toStringAsFixed(0)}%',
                style:
                    const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () {
                ref.read(gameProvider.notifier).performIPO(floatPercent);
                Navigator.pop(ctx);
              },
              child: const Text('IPO durchführen'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequirementRow extends StatelessWidget {
  final String label;
  final bool met;
  final String currentLabel;
  final String requiredLabel;
  const _RequirementRow({
    required this.label,
    required this.met,
    required this.currentLabel,
    required this.requiredLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: met ? AppColors.success : AppColors.textMuted,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style:
                  const TextStyle(fontSize: 13, color: AppColors.textPrimary),
            ),
          ),
          Text(
            '$currentLabel / $requiredLabel',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: met ? AppColors.success : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  const _MetricRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Aktienkurs-Chart (fl_chart) ─────────────────────────────────────────

class _StockChart extends StatelessWidget {
  final List<double> history;
  const _StockChart({required this.history});

  @override
  Widget build(BuildContext context) {
    final data =
        history.length > 40 ? history.sublist(history.length - 40) : history;
    if (data.length < 2) {
      return const Center(
        child: Text(
          'Noch keine Kursdaten',
          style: TextStyle(fontSize: 12, color: AppColors.bg),
        ),
      );
    }

    double maxP = data.reduce((a, b) => a > b ? a : b);
    double minP = data.reduce((a, b) => a < b ? a : b);
    if (maxP == minP) {
      maxP += 1;
      minP -= 1;
    }
    final pad = (maxP - minP) * 0.12;

    final spots = [
      for (var i = 0; i < data.length; i++) FlSpot(i.toDouble(), data[i]),
    ];

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        minX: 0,
        maxX: (data.length - 1).toDouble(),
        minY: minP - pad,
        maxY: maxP + pad,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.2,
            color: AppColors.bg,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppColors.bg.withValues(alpha: 0.30),
                  AppColors.bg.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── PRODUKTIONS-TAB ────────────────────────────────────────────────────

class _ProductionTab extends ConsumerWidget {
  final GameState game;
  const _ProductionTab({required this.game});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final facilities = game.facilities;
    final groupedTemplates = <ProductionType, List<FacilityTemplate>>{};
    for (final t in kAllFacilityTemplates) {
      groupedTemplates.putIfAbsent(t.type, () => []).add(t);
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (facilities.isNotEmpty) ...[
          const Text(
            'AKTIVE ANLAGEN',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
              letterSpacing: 2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          for (final f in facilities) _ActiveFacilityCard(facility: f),
          const SizedBox(height: 20),
        ],
        const Text(
          'NEU BAUEN',
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textMuted,
            letterSpacing: 2,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        for (final type in ProductionType.values) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Text(type.emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(
                  type.label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          for (final t in groupedTemplates[type] ?? <FacilityTemplate>[])
            _FacilityTemplateCard(template: t, cash: game.cash),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _ActiveFacilityCard extends StatelessWidget {
  final ProductionFacility facility;
  const _ActiveFacilityCard({required this.facility});

  @override
  Widget build(BuildContext context) {
    final t = kAllFacilityTemplates.firstWhere(
      (x) => x.type == facility.type && x.tier == facility.tier,
      orElse: () => kAllFacilityTemplates.first,
    );
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accent.withAlpha(20),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accent.withAlpha(80)),
      ),
      child: Row(
        children: [
          Text(facility.type.emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${facility.type.label} (${facility.tier.label})',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Versorgt bis ${facility.tier.maxShops} Filialen · -${(facility.tier.ingredientSaving * 100).round()}% Zutaten',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_fmt.format(t.b2bRevenuePerDay)} €/Tag B2B · ${_fmt.format(t.dailyOperatingCost)} €/Tag Betrieb',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textMuted,
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

class _FacilityTemplateCard extends ConsumerWidget {
  final FacilityTemplate template;
  final double cash;
  const _FacilityTemplateCard({required this.template, required this.cash});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canAfford = cash >= template.buildCost;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${template.tier.label} (${template.tier.maxShops} Filialen)',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '-${(template.tier.ingredientSaving * 100).round()}% Zutaten · ${_fmt.format(template.b2bRevenuePerDay)}€/Tag B2B',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                ),
                Text(
                  'Betrieb: ${_fmt.format(template.dailyOperatingCost)} €/Tag',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: canAfford
                ? () => ref.read(gameProvider.notifier).buildFacility(template)
                : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              textStyle: const TextStyle(fontSize: 12),
            ),
            child: Text('${_fmt.format(template.buildCost)} €'),
          ),
        ],
      ),
    );
  }
}

// ── M&A-TAB ────────────────────────────────────────────────────────────

class _MATab extends ConsumerWidget {
  final GameState game;
  const _MATab({required this.game});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final competitors = game.competitors;
    if (competitors.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Text(
            'Keine Konkurrenten erkundet.\nEröffne Filialen in mehr Städten.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
      );
    }

    final byCity = <String, List<Competitor>>{};
    for (final c in competitors) {
      byCity.putIfAbsent(c.cityId, () => []).add(c);
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Konkurrenten aufkaufen - übernimm Marktanteile und Filialen.',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textMuted,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        for (final entry in byCity.entries) ...[
          _CityHeader(cityId: entry.key),
          for (final c in entry.value)
            _AcquisitionCard(competitor: c, cash: game.cash),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _CityHeader extends StatelessWidget {
  final String cityId;
  const _CityHeader({required this.cityId});

  @override
  Widget build(BuildContext context) {
    final city = kAllCities.firstWhere(
      (c) => c.id == cityId,
      orElse: () => kAllCities.first,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(city.emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            city.name.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.secondary,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}

class _AcquisitionCard extends ConsumerWidget {
  final Competitor competitor;
  final double cash;
  const _AcquisitionCard({required this.competitor, required this.cash});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final price = CorporateEngine.acquisitionPrice(competitor);
    final canAfford = cash >= price;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(competitor.personality.emoji,
                  style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      competitor.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${competitor.shopCount} Filialen · ${competitor.reputation.toStringAsFixed(1)}★ · ${(competitor.marketShare * 100).toStringAsFixed(0)}% Markt',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Akquisitionspreis: ${_fmt.format(price)} €',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.gold,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: canAfford
                    ? () => _confirmAcquisition(context, ref, competitor)
                    : null,
                icon: const Icon(Icons.handshake, size: 14),
                label: const Text('Übernehmen'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmAcquisition(BuildContext context, WidgetRef ref, Competitor c) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: Text('${c.name} übernehmen?'),
        content: Text(
          '${c.shopCount} Filialen werden Teil deines Imperiums.\n\nKaufpreis: ${_fmt.format(CorporateEngine.acquisitionPrice(c))} €',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(gameProvider.notifier).acquireCompetitor(c);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${c.name} übernommen!')),
              );
            },
            child: const Text('Übernehmen'),
          ),
        ],
      ),
    );
  }
}

// ── KONZERN-UPGRADES-TAB ─────────────────────────────────────────────────────

class _GlobalUpgradesTab extends ConsumerWidget {
  final GameState game;
  const _GlobalUpgradesTab({required this.game});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final globalIds = List<String>.from(game.globalUpgradeIds);
    final cash = game.cash;
    final shopCount = game.shops.length;
    final ownDeliveryReady = GameEngine.canUnlockOwnDeliveryApp(game);

    // Monatliche Laufkosten aller aktiven globalen Upgrades
    final monthlyRunning = globalIds
        .map((id) => upgradeById(id))
        .whereType<UpgradeData>()
        .fold(0.0, (s, u) => s + u.monthlyCost);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Info-Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.secondary.withAlpha(40),
                AppColors.primary.withAlpha(30),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.secondary.withAlpha(80)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.apartment_rounded,
                      size: 24, color: AppColors.textPrimary),
                  SizedBox(width: 10),
                  Text(
                    'Konzern-Upgrades',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Einmalig kaufen - gilt automatisch für alle bestehenden '
                'und neuen Filialen. Im Gegensatz zu Shop-Upgrades skalieren '
                'Konzern-Upgrades kostenlos mit der Filialzahl.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              if (globalIds.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.check_circle_outline,
                        color: AppColors.success, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      '${globalIds.length} aktiv • ${_fmt.format(monthlyRunning)} €/Monat laufend',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.success),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Upgrade-Karten
        for (final u in kGlobalUpgrades) ...[
          _GlobalUpgradeCard(
            upgrade: u,
            owned: globalIds.contains(u.id),
            canAfford: (cash >= u.installCost) &&
                (u.id != 'eigen_lieferdienst' || ownDeliveryReady),
            shopCount: shopCount,
            lockReason: u.id == 'eigen_lieferdienst' && !ownDeliveryReady
                ? 'Benötigt aktiven Lieferdienst in mindestens 3 Filialen.'
                : null,
            onBuy: () {
              if (cash < u.installCost) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Nicht genug Kapital'),
                    duration: Duration(milliseconds: 1500),
                  ),
                );
                return;
              }
              if (u.id == 'eigen_lieferdienst' &&
                  !GameEngine.canUnlockOwnDeliveryApp(game)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Eigene Liefer-App erst ab 3 Filialen mit aktivem Lieferdienst.'),
                    duration: Duration(milliseconds: 1700),
                  ),
                );
                return;
              }
              // Globale Upgrades brauchen keine shopId —
              // leere String wird in buyUpgrade für scope=global ignoriert.
              ref.read(gameProvider.notifier).buyUpgrade('', u);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${u.name} konzernweit aktiviert'),
                  duration: const Duration(milliseconds: 1500),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _GlobalUpgradeCard extends StatelessWidget {
  final UpgradeData upgrade;
  final bool owned;
  final bool canAfford;
  final int shopCount;
  final String? lockReason;
  final VoidCallback onBuy;

  const _GlobalUpgradeCard({
    required this.upgrade,
    required this.owned,
    required this.canAfford,
    required this.shopCount,
    this.lockReason,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: owned ? AppColors.secondary.withAlpha(140) : AppColors.border,
          width: owned ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_globalUpgradeIcon(upgrade.id),
                  size: 28, color: AppColors.secondary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            upgrade.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withAlpha(30),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'GLOBAL',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: AppColors.secondary,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      upgrade.description,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Effekt-Chips
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (upgrade.customerBoost > 0)
                _Chip(
                  '+${(upgrade.customerBoost * 100).round()}% Kunden',
                  AppColors.accent,
                ),
              if (upgrade.avgOrderValueBoost > 0)
                _Chip(
                  '+${(upgrade.avgOrderValueBoost * 100).round()}% Bestellwert',
                  AppColors.success,
                ),
              if (upgrade.reputationPerDay > 0)
                const _Chip('+Reputation', AppColors.gold),
              if (upgrade.brandPerDay > 0)
                const _Chip('+Markenbekanntheit', AppColors.secondary),
              if (shopCount > 0)
                _Chip('Wirkt in $shopCount Filiale${shopCount == 1 ? "" : "n"}',
                    AppColors.textMuted),
              if (lockReason != null) _Chip(lockReason!, AppColors.warning),
            ],
          ),

          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      upgrade.installCost > 0
                          ? 'Einmalig ${_fmt.format(upgrade.installCost)} €'
                          : 'Kostenlos aktivieren',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '${_fmt.format(upgrade.monthlyCost)} €/Monat laufend',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.warning),
                    ),
                  ],
                ),
              ),
              if (owned)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withAlpha(35),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Konzernweit aktiv',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                )
              else
                ElevatedButton(
                  onPressed: canAfford ? onBuy : null,
                  style: ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                  child: const Text('Kaufen'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

IconData _globalUpgradeIcon(String id) {
  if (kGlobalSpiessUpgradeOrder.contains(id)) {
    return Icons.local_fire_department_rounded;
  }
  switch (id) {
    case 'lieferdienst':
      return Icons.delivery_dining_rounded;
    case 'loyalty_app':
      return Icons.loyalty_rounded;
    case 'kassensystem_zentral':
      return Icons.point_of_sale_rounded;
    case 'schulung_online':
      return Icons.school_rounded;
    case 'eigen_lieferdienst':
      return Icons.rocket_launch_rounded;
    default:
      return Icons.business_center_rounded;
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

IconData _marketingCampaignIcon(String id) {
  switch (id) {
    case 'city_plakat':
      return Icons.campaign_rounded;
    case 'city_social':
      return Icons.phone_iphone_rounded;
    case 'city_event':
      return Icons.festival_rounded;
    case 'city_radio':
      return Icons.radio_rounded;
    case 'tv_werbung':
      return Icons.tv_rounded;
    case 'influencer_national':
      return Icons.auto_awesome_rounded;
    case 'brand_launch':
      return Icons.label_important_rounded;
    case 'treue_programm':
      return Icons.card_membership_rounded;
    default:
      return Icons.campaign_outlined;
  }
}

// ── STRATEGIE-TAB ─────────────────────────────────────────────────────────────

class _StrategieTab extends ConsumerWidget {
  final GameState game;
  const _StrategieTab({required this.game});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cash = game.cash;
    final currentDay = game.currentDay;
    final globalPrices = Map<String, double>.from(game.globalPrices);
    final shops = game.shops;
    final activeCityCampaigns = game.activeCityCampaigns;
    final activeGlobalCampaigns = game.activeGlobalCampaigns;

    final citiesWithShops = shops.map((s) => s.cityId).toSet().toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ── Preisstrategie ────────────────────────────────────────────────
        _buildSectionHeader(Icons.groups_rounded, 'HR-ABTEILUNG'),
        const SizedBox(height: 10),
        _HrDepartmentCard(game: game),
        const SizedBox(height: 28),
        _buildSectionHeader(Icons.payments_outlined, 'PREISSTRATEGIE'),
        const SizedBox(height: 10),
        _PriceStrategySection(globalPrices: globalPrices),
        const SizedBox(height: 28),

        // ── Zutaten-Qualität ──────────────────────────────────────────────
        _buildSectionHeader(Icons.eco_rounded, 'ZUTATEN-QUALITÄT'),
        const SizedBox(height: 4),
        const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: Text(
            'Premium = teurere Zutaten, aber besserer Ruf. Günstig spart Kosten, '
            'kostet aber Reputation.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.35),
          ),
        ),
        for (final p in kAllProducts)
          _QualityRow(
            product: p,
            quality: ingredientQualityFromName(game.productQuality[p.id]),
            onChanged: (q) =>
                ref.read(gameProvider.notifier).setProductQuality(p.id, q),
          ),
        const SizedBox(height: 28),

        // ── Menü-Angebote / Kombos ────────────────────────────────────────
        _buildSectionHeader(Icons.lunch_dining_rounded, 'MENÜ-ANGEBOTE'),
        const SizedBox(height: 4),
        const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: Text(
            'Konzernweite Angebote. Wirken nur in Filialen, die alle nötigen '
            'Produkte führen. Kleine Tagespauschale, dafür mehr Kundschaft.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.35),
          ),
        ),
        for (final combo in kAllCombos)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ComboCard(
              combo: combo,
              active: game.activeComboIds.contains(combo.id),
              supportingShops:
                  shops.where((s) => GameEngine.shopSupportsCombo(s, combo)).length,
              totalShops: shops.length,
              onToggle: () =>
                  ref.read(gameProvider.notifier).toggleCombo(combo.id),
            ),
          ),
        const SizedBox(height: 28),

        // ── Stadtweite Marketing ──────────────────────────────────────────
        _buildSectionHeader(
            Icons.location_city_rounded, 'STADTWEITE MARKETING'),
        const SizedBox(height: 10),
        if (citiesWithShops.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'Eröffne zuerst eine Filiale, um stadtweite Kampagnen zu buchen.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          )
        else
          for (final cityId in citiesWithShops) ...[
            _CityMarketingSection(
              cityId: cityId,
              activeCityCampaigns: activeCityCampaigns[cityId] ?? const [],
              cash: cash,
              currentDay: currentDay,
            ),
            const SizedBox(height: 10),
          ],
        const SizedBox(height: 16),

        // ── Konzernweites Marketing ────────────────────────────────────────
        _buildSectionHeader(Icons.public_rounded, 'KONZERNWEITES MARKETING'),
        const SizedBox(height: 10),
        for (final campaign in kGlobalMarketingCampaigns)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _MarketingCampaignCard(
              campaign: campaign,
              activeCampaign:
                  _findActive(activeGlobalCampaigns, campaign.id, currentDay),
              cash: cash,
              currentDay: currentDay,
              onBook: () =>
                  ref.read(gameProvider.notifier).bookGlobalCampaign(campaign),
            ),
          ),
        const SizedBox(height: 20),
      ],
    );
  }

  ActiveCampaign? _findActive(List<ActiveCampaign> list, String id, int day) {
    try {
      return list.firstWhere((c) => c.campaignId == id && c.isActive(day));
    } catch (_) {
      return null;
    }
  }

  Widget _buildSectionHeader(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textMuted,
            letterSpacing: 2,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _QualityRow extends StatelessWidget {
  final ProductData product;
  final IngredientQuality quality;
  final ValueChanged<IngredientQuality> onChanged;

  const _QualityRow({
    required this.product,
    required this.quality,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(product.emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.bg.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: AppColors.border),
            ),
            padding: const EdgeInsets.all(2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final q in IngredientQuality.values)
                  GestureDetector(
                    onTap: () => onChanged(q),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: q == quality
                            ? AppColors.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        q.emoji,
                        style: TextStyle(
                          fontSize: 13,
                          color: q == quality
                              ? Colors.white
                              : AppColors.textMuted,
                        ),
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

class _ComboCard extends StatelessWidget {
  final MenuCombo combo;
  final bool active;
  final int supportingShops;
  final int totalShops;
  final VoidCallback onToggle;

  const _ComboCard({
    required this.combo,
    required this.active,
    required this.supportingShops,
    required this.totalShops,
    required this.onToggle,
  });

  String _productNames() {
    return combo.productIds.map((id) {
      final p = kAllProducts.where((x) => x.id == id);
      return p.isEmpty ? id : '${p.first.emoji} ${p.first.name}';
    }).join(' + ');
  }

  @override
  Widget build(BuildContext context) {
    final noShopSupports = totalShops > 0 && supportingShops == 0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: active ? AppColors.primary.withAlpha(15) : AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: active ? AppColors.primary.withAlpha(110) : AppColors.border,
          width: active ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(combo.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      combo.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      combo.description,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textMuted, height: 1.3),
                    ),
                  ],
                ),
              ),
              Switch(
                value: active,
                activeThumbColor: AppColors.primary,
                onChanged: (_) => onToggle(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _productNames(),
            style: const TextStyle(
              fontSize: 11.5,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _Chip('+${(combo.customerBoost * 100).round()}% Kunden',
                  AppColors.accent),
              _Chip('+${(combo.avgOrderBoost * 100).round()}% Bestellwert',
                  AppColors.success),
              _Chip('${_fmt.format(combo.dailyCost)} €/Tag', AppColors.warning),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                noShopSupports
                    ? Icons.warning_amber_rounded
                    : Icons.storefront_rounded,
                size: 14,
                color: noShopSupports ? AppColors.warning : AppColors.textMuted,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  noShopSupports
                      ? 'Keine Filiale führt alle Produkte — wirkt noch nicht.'
                      : 'Wirkt in $supportingShops/$totalShops Filialen',
                  style: TextStyle(
                    fontSize: 10.5,
                    color:
                        noShopSupports ? AppColors.warning : AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HrDepartmentCard extends ConsumerWidget {
  final GameState game;
  const _HrDepartmentCard({required this.game});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hrManager = game.hrManager;
    if (hrManager == null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Noch kein Personalchef eingestellt.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Ein guter HR-Manager verbessert Kandidatenqualität, Besetzungstempo und Training konzernweit.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            if (game.hrCandidates.isEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton.icon(
                  onPressed: () =>
                      ref.read(gameProvider.notifier).refreshHrCandidates(),
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('3 Kandidaten laden'),
                ),
              )
            else ...[
              for (final candidate in game.hrCandidates) ...[
                _HrCandidateTile(manager: candidate),
                const SizedBox(height: 8),
              ],
            ],
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hrManager.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      hrManager.archetype.label,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hrManager.archetype.shortDescription,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${_fmt.format(hrManager.salaryPerDay)} € / Tag',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.gold,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Level ${hrManager.level} • XP ${hrManager.xp}',
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          const SizedBox(height: 10),
          _HrStatRow(label: 'Talentblick', value: hrManager.talentSense),
          _HrStatRow(label: 'Netzwerk', value: hrManager.network),
          _HrStatRow(label: 'Verhandlung', value: hrManager.negotiation),
          _HrStatRow(label: 'Tempo', value: hrManager.speed),
          _HrStatRow(label: 'Training', value: hrManager.training),
          const SizedBox(height: 10),
          Text(
            'Aktive Strategie: ${game.hrStrategy.label}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final strategy in HrStrategy.values)
                ChoiceChip(
                  label: Text(
                    strategy.label,
                    style: const TextStyle(fontSize: 11),
                  ),
                  selected: game.hrStrategy == strategy,
                  onSelected: (_) =>
                      ref.read(gameProvider.notifier).setHrStrategy(strategy),
                  selectedColor: AppColors.primary.withAlpha(35),
                  labelStyle: TextStyle(
                    color: game.hrStrategy == strategy
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                  side: BorderSide(
                    color: game.hrStrategy == strategy
                        ? AppColors.primary
                        : AppColors.border,
                  ),
                  backgroundColor: AppColors.bgSurface,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            HrEngine.currentEffectSummary(game),
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      ref.read(gameProvider.notifier).fireHrManager(),
                  icon: const Icon(Icons.person_remove_alt_1_rounded, size: 16),
                  label: const Text('Entlassen'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    final notifier = ref.read(gameProvider.notifier);
                    notifier.fireHrManager();
                    notifier.refreshHrCandidates();
                  },
                  icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                  label: const Text('Ersetzen'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HrCandidateTile extends ConsumerWidget {
  final HrManager manager;
  const _HrCandidateTile({required this.manager});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      manager.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      manager.archetype.label,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${_fmt.format(manager.salaryPerDay)} € / Tag',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.gold,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            manager.archetype.shortDescription,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _HrMiniStat('Talent', manager.talentSense),
              _HrMiniStat('Netz', manager.network),
              _HrMiniStat('Verh', manager.negotiation),
              _HrMiniStat('Tempo', manager.speed),
              _HrMiniStat('Train', manager.training),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () =>
                  ref.read(gameProvider.notifier).hireHrManager(manager.id),
              child: const Text('Einstellen'),
            ),
          ),
        ],
      ),
    );
  }
}

class _HrMiniStat extends StatelessWidget {
  final String label;
  final int value;
  const _HrMiniStat(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        '$label $value',
        style: const TextStyle(
          fontSize: 10,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _HrStatRow extends StatelessWidget {
  final String label;
  final int value;
  const _HrStatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (value / 10).clamp(0.0, 1.0),
                minHeight: 7,
                backgroundColor: AppColors.border,
                valueColor: const AlwaysStoppedAnimation(AppColors.secondary),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 20,
            child: Text(
              '$value',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Preisstrategie-Sektion ─────────────────────────────────────────────────────

class _PriceStrategySection extends ConsumerWidget {
  final Map<String, double> globalPrices;
  const _PriceStrategySection({required this.globalPrices});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _StrategyButton(
              label: 'Günstig',
              subtitle: '-15 %',
              onTap: () =>
                  ref.read(gameProvider.notifier).applyPriceStrategy('cheap'),
            ),
            const SizedBox(width: 8),
            _StrategyButton(
              label: 'Normal',
              subtitle: 'Basispreis',
              onTap: () =>
                  ref.read(gameProvider.notifier).applyPriceStrategy('normal'),
            ),
            const SizedBox(width: 8),
            _StrategyButton(
              label: 'Premium',
              subtitle: '+20 %',
              onTap: () =>
                  ref.read(gameProvider.notifier).applyPriceStrategy('premium'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () =>
                ref.read(gameProvider.notifier).applyRecommendedPrices(),
            icon: const Icon(Icons.lightbulb_outline_rounded, size: 16),
            label: const Text('Empfohlene Preise (umsatzoptimal)'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.gold,
              side: BorderSide(color: AppColors.gold.withValues(alpha: 0.5)),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'EINZELNE PRODUKTPREISE GLOBAL',
          style: TextStyle(
            fontSize: 10,
            color: AppColors.textMuted,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        for (final p in kAllProducts)
          _GlobalPriceRow(
            product: p,
            currentPrice: globalPrices[p.id] ?? p.basePrice,
            onMinus: () {
              final cur = globalPrices[p.id] ?? p.basePrice;
              ref
                  .read(gameProvider.notifier)
                  .setGlobalPrice(p.id, (cur - 0.25).clamp(0.5, 99.0));
            },
            onPlus: () {
              final cur = globalPrices[p.id] ?? p.basePrice;
              ref
                  .read(gameProvider.notifier)
                  .setGlobalPrice(p.id, (cur + 0.25).clamp(0.5, 99.0));
            },
          ),
      ],
    );
  }
}

class _StrategyButton extends StatelessWidget {
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  const _StrategyButton(
      {required this.label, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style:
                    const TextStyle(fontSize: 10, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlobalPriceRow extends StatelessWidget {
  final ProductData product;
  final double currentPrice;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  const _GlobalPriceRow({
    required this.product,
    required this.currentPrice,
    required this.onMinus,
    required this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    final isAtBase = (currentPrice - product.basePrice).abs() < 0.005;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(product.emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              product.name,
              style:
                  const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove, size: 16),
            onPressed: currentPrice > 0.5 ? onMinus : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            color: AppColors.textMuted,
          ),
          SizedBox(
            width: 68,
            child: Text(
              '${_fmtPrice.format(currentPrice)} €',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: isAtBase ? AppColors.textSecondary : AppColors.primary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 16),
            onPressed: currentPrice < 50.0 ? onPlus : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

// ── Stadtweite Marketing-Sektion ───────────────────────────────────────────────

class _CityMarketingSection extends ConsumerWidget {
  final String cityId;
  final List<ActiveCampaign> activeCityCampaigns;
  final double cash;
  final int currentDay;
  const _CityMarketingSection({
    required this.cityId,
    required this.activeCityCampaigns,
    required this.cash,
    required this.currentDay,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final city = kAllCities.firstWhere(
      (c) => c.id == cityId,
      orElse: () => kAllCities.first,
    );
    final activeCount =
        activeCityCampaigns.where((c) => c.isActive(currentDay)).length;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: ExpansionTile(
        initiallyExpanded: activeCount > 0,
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        title: Row(
          children: [
            const Icon(Icons.location_city_rounded,
                size: 18, color: AppColors.textPrimary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                city.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (activeCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$activeCount aktiv',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        children: [
          for (final campaign in kCityMarketingCampaigns)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _MarketingCampaignCard(
                campaign: campaign,
                activeCampaign:
                    _findActive(activeCityCampaigns, campaign.id, currentDay),
                cash: cash,
                currentDay: currentDay,
                onBook: () => ref
                    .read(gameProvider.notifier)
                    .bookCityCampaign(cityId, campaign),
              ),
            ),
        ],
      ),
    );
  }

  ActiveCampaign? _findActive(List<ActiveCampaign> list, String id, int day) {
    try {
      return list.firstWhere((c) => c.campaignId == id && c.isActive(day));
    } catch (_) {
      return null;
    }
  }
}

// ── Marketing-Kampagnen-Karte ──────────────────────────────────────────────────

class _MarketingCampaignCard extends StatelessWidget {
  final MarketingCampaign campaign;
  final ActiveCampaign? activeCampaign;
  final double cash;
  final int currentDay;
  final VoidCallback onBook;
  const _MarketingCampaignCard({
    required this.campaign,
    required this.activeCampaign,
    required this.cash,
    required this.currentDay,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = activeCampaign != null;
    final canAfford = cash >= campaign.cost;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary.withAlpha(15) : AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? AppColors.primary.withAlpha(100) : AppColors.border,
          width: isActive ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(_marketingCampaignIcon(campaign.id),
                  size: 22, color: AppColors.textPrimary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      campaign.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      campaign.description,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              if (campaign.customerBoost > 0)
                _Chip(
                  '+${(campaign.customerBoost * 100).round()}% Kunden',
                  AppColors.accent,
                ),
              if (campaign.reputationBoostPerDay > 0)
                const _Chip('+Rep/Tag', AppColors.gold),
              if (campaign.brandAwarenessDelta > 0)
                _Chip(
                  '+${campaign.brandAwarenessDelta.toStringAsFixed(1)} Marke/Tag',
                  AppColors.secondary,
                ),
              _Chip('${campaign.durationDays} Tage', AppColors.textMuted),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '${_fmt.format(campaign.cost)} €',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              if (isActive)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'noch ${activeCampaign!.remainingDays(currentDay)} Tage',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else
                ElevatedButton(
                  onPressed: canAfford ? onBook : null,
                  style: ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                  child: const Text('Buchen'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
