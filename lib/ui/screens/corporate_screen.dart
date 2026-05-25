import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../models/competitor_model.dart';
import '../../models/production_model.dart';
import '../../models/stock_model.dart';
import '../../providers/game_provider.dart';
import '../../services/corporate_engine.dart';

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
    _tabs = TabController(length: 3, vsync: this);
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
                  const Text(
                    'Konzern',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
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
  final dynamic game;
  const _StockTab({required this.game});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canIPO = CorporateEngine.canDoIPO(game);
    final isPublic = game.stocks.isPublic as bool;

    if (!isPublic) {
      // Exakt dieselben Werte wie in CorporateEngine.canDoIPO verwenden,
      // damit UI-grün und Button-aktiv übereinstimmen (kein Rundungs-Drift).
      final shopsOk = game.shops.length >= IPORequirements.minShops;
      final brandOk =
          game.brand.brandAwareness >= IPORequirements.minBrandAwareness;
      final revenueOk =
          game.totalRevenue >= IPORequirements.minTotalRevenue;

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
                  currentLabel:
                      game.brand.brandAwareness.toStringAsFixed(1),
                  requiredLabel: '${IPORequirements.minBrandAwareness}',
                ),
                _RequirementRow(
                  label: 'Gesamtumsatz',
                  met: revenueOk,
                  currentLabel:
                      '${_fmt.format(game.totalRevenue)} €',
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
    final history = (game.stocks.priceHistory as List<double>);
    final maxP = history.isEmpty ? 1.0 : history.reduce((a, b) => a > b ? a : b);
    final minP = history.isEmpty ? 0.0 : history.reduce((a, b) => a < b ? a : b);

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
                height: 80,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final p in history.length > 30
                        ? history.sublist(history.length - 30)
                        : history)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1),
                          child: Container(
                            height: maxP > minP
                                ? ((p - minP) / (maxP - minP) * 60)
                                    .clamp(2.0, 60.0)
                                : 2,
                            decoration: BoxDecoration(
                              color: AppColors.bg,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
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
          value:
              '${(game.stocks.playerShareRatio * 100).toStringAsFixed(1)}%',
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

  void _showIPODialog(BuildContext context, WidgetRef ref, dynamic game) {
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
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
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
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textPrimary),
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

// ── PRODUKTIONS-TAB ────────────────────────────────────────────────────

class _ProductionTab extends ConsumerWidget {
  final dynamic game;
  const _ProductionTab({required this.game});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final facilities = game.facilities as List<ProductionFacility>;
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
            _FacilityTemplateCard(template: t, cash: game.cash as double),
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
                  'Versorgt bis ${facility.tier.maxShops} Filialen  ·  -${(facility.tier.ingredientSaving * 100).round()}% Zutaten',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_fmt.format(t.b2bRevenuePerDay)} €/Tag B2B  ·  ${_fmt.format(t.dailyOperatingCost)} €/Tag Betrieb',
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
                ? () => ref
                    .read(gameProvider.notifier)
                    .buildFacility(template)
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
  final dynamic game;
  const _MATab({required this.game});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final competitors = (game.competitors as List<Competitor>);
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
          'Konkurrenten aufkaufen — übernimm Marktanteile und Filialen.',
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
            _AcquisitionCard(competitor: c, cash: game.cash as double),
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
                      '${competitor.shopCount} Filialen  ·  ${competitor.reputation.toStringAsFixed(1)}⭐  ·  ${(competitor.marketShare * 100).toStringAsFixed(0)}% Markt',
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

  void _confirmAcquisition(
      BuildContext context, WidgetRef ref, Competitor c) {
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
                SnackBar(content: Text('${c.name} übernommen! 🤝')),
              );
            },
            child: const Text('Übernehmen'),
          ),
        ],
      ),
    );
  }
}
