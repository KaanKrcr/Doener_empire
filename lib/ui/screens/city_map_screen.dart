import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/city_map_model.dart';
import '../../models/city_model.dart';
import '../../models/game_state.dart';
import '../../models/shop_model.dart';
import '../../models/time_profile_model.dart';
import '../../providers/game_provider.dart';
import '../../services/game_engine.dart';
import '../../services/location_engine.dart';
import '../widgets/city_map_view.dart';
import '../widgets/premium_mobile_ui.dart';

final _fmt = NumberFormat('#,##0', 'de_DE');

class CityMapScreen extends ConsumerStatefulWidget {
  final String cityId;

  const CityMapScreen({super.key, required this.cityId});

  @override
  ConsumerState<CityMapScreen> createState() => _CityMapScreenState();
}

class _CityMapScreenState extends ConsumerState<CityMapScreen> {
  String? _selectedLocationId;

  CityData get city =>
      kAllCities.firstWhere((entry) => entry.id == widget.cityId);

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(gameProvider)!;
    final cityShops =
        game.shops.where((shop) => shop.cityId == city.id).toList();
    final cityCompetitors = game.competitorsIn(city.id);
    final cityCompetitionPressure = cityCompetitors
        .fold<double>(0, (sum, competitor) => sum + competitor.marketShare)
        .clamp(0.0, 0.95);

    final locations = LocationEngine.locationsFor(city);
    if (locations.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: PremiumDecisionSheet(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const PremiumStatusHint(
                    text:
                        'Keine Standorte verfügbar. Wechsle in eine andere Stadt oder schalte mehr Standorte frei.',
                    tone: PremiumStatusTone.warning,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context.go('/cities'),
                    child: const Text('Zu den Städten'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final selected = _resolveSelectedLocation(locations);
    final ownShopCount = cityShops
        .where((shop) => shop.locationName == selected.template.name)
        .length;
    final priorityShop = _priorityShop(cityShops, game);
    final priorityShopRevenue = priorityShop == null
        ? 0.0
        : GameEngine.calculateDailyRevenue(
            priorityShop,
            day: game.currentDay,
            state: game,
          );

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text('${city.name} Stadtkarte'),
        toolbarHeight: 52,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          children: [
            PremiumMetricStrip(
              dense: true,
              items: [
                PremiumMetricData(
                  label: 'Filialen',
                  value: '${cityShops.length}',
                  color: AppColors.primary,
                ),
                PremiumMetricData(
                  label: 'Konkurrenten',
                  value: '${cityCompetitors.length}',
                  color: AppColors.danger,
                ),
                PremiumMetricData(
                  label: 'Druck',
                  value: _pressurePct(cityCompetitionPressure),
                  color: _pressureColor(cityCompetitionPressure),
                ),
                PremiumMetricData(
                  label: 'Traffic',
                  value: _fmt.format(
                    cityShops.fold<int>(
                        0, (sum, shop) => sum + shop.footTraffic),
                  ),
                  color: AppColors.accent,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: CityMapView(
                    city: city,
                    locations: locations,
                    shops: cityShops,
                    selected: selected,
                    fillParent: true,
                    showDetailChips: true,
                    onSelect: (location) => setState(
                      () => _selectedLocationId = location.id,
                    ),
                  ),
                ),
              )
                  .animate()
                  .fadeIn(duration: 260.ms)
                  .slideY(begin: 0.03, end: 0, curve: Curves.easeOutCubic),
            ),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.03),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: _LocationDecisionSheet(
                key: ValueKey(selected.id),
                city: city,
                location: selected,
                ownShopCount: ownShopCount,
                cash: game.cash,
                competitionPressure: cityCompetitionPressure,
                onOpenShop: () => context.push(
                  '/open-shop/${city.id}?location=${Uri.encodeComponent(selected.label)}',
                ),
              ),
            ),
            if (priorityShop != null) ...[
              const SizedBox(height: 10),
              _CityOpsBar(
                shopName: priorityShop.displayName,
                locationName: priorityShop.locationName,
                dailyRevenue: priorityShopRevenue,
                onOpenShop: () => context.push('/shop/${priorityShop.id}'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  CityMapLocation _resolveSelectedLocation(List<CityMapLocation> locations) {
    final fallback = locations.first;
    final selectedId = _selectedLocationId;
    if (selectedId == null) {
      _selectedLocationId = fallback.id;
      return fallback;
    }
    return locations.firstWhere(
      (entry) => entry.id == selectedId,
      orElse: () {
        _selectedLocationId = fallback.id;
        return fallback;
      },
    );
  }

  String _pressurePct(double pressure) => '${(pressure * 100).round()}%';

  Color _pressureColor(double pressure) {
    if (pressure >= 0.50) return AppColors.danger;
    if (pressure >= 0.30) return AppColors.warning;
    return AppColors.accent;
  }

  Shop? _priorityShop(List<Shop> cityShops, GameState game) {
    if (cityShops.isEmpty) return null;
    var weakest = cityShops.first;
    var weakestRevenue = GameEngine.calculateDailyRevenue(
      weakest,
      day: game.currentDay,
      state: game,
    );
    for (final shop in cityShops.skip(1)) {
      final revenue = GameEngine.calculateDailyRevenue(
        shop,
        day: game.currentDay,
        state: game,
      );
      if (revenue < weakestRevenue) {
        weakest = shop;
        weakestRevenue = revenue;
      }
    }
    return weakest;
  }
}

class _LocationDecisionSheet extends StatelessWidget {
  final CityData city;
  final CityMapLocation location;
  final int ownShopCount;
  final double cash;
  final double competitionPressure;
  final VoidCallback onOpenShop;

  const _LocationDecisionSheet({
    super.key,
    required this.city,
    required this.location,
    required this.ownShopCount,
    required this.cash,
    required this.competitionPressure,
    required this.onOpenShop,
  });

  @override
  Widget build(BuildContext context) {
    final footTraffic = location.footTrafficFor(city);
    final weeklyRent = location.weeklyRentFor(city);
    final deposit = location.depositFor(city);
    final canAfford = cash >= deposit;

    return PremiumDecisionSheet(
      borderColor: AppColors.primary.withAlpha(100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      location.label,
                      style: AppText.display(size: 20, weight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      location.template.personality.label,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (ownShopCount > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.accent),
                  ),
                  child: Text(
                    '$ownShopCount Filiale${ownShopCount > 1 ? 'n' : ''}',
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          const PremiumSectionLabel(text: 'KERN-KPIS'),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: PremiumInlineMetric(
                  data: PremiumMetricData(
                    label: 'Traffic',
                    value: _fmt.format(footTraffic),
                    color: AppColors.accent,
                  ),
                ),
              ),
              Expanded(
                child: PremiumInlineMetric(
                  data: PremiumMetricData(
                    label: 'Miete',
                    value: '${_fmt.format(weeklyRent)} EUR',
                    color: AppColors.warning,
                  ),
                ),
              ),
              Expanded(
                child: PremiumInlineMetric(
                  data: PremiumMetricData(
                    label: 'Kaution',
                    value: '${_fmt.format(deposit)} EUR',
                    color: AppColors.danger,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const PremiumSectionLabel(text: 'RISIKO & FIT'),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: PremiumInlineMetric(
                  data: PremiumMetricData(
                    label: 'Konkurrenzdruck',
                    value: _pressureLabel(competitionPressure),
                    color: _pressureColor(competitionPressure),
                  ),
                ),
              ),
              Expanded(
                child: PremiumInlineMetric(
                  data: PremiumMetricData(
                    label: 'Standortfit',
                    value: _fitLabel(footTraffic, weeklyRent),
                    color: _fitColor(footTraffic, weeklyRent),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          PremiumStatusHint(
            tone: canAfford
                ? PremiumStatusTone.success
                : PremiumStatusTone.danger,
            text: canAfford
                ? 'Kaution gedeckt: Standort kann sofort geöffnet werden.'
                : 'Kaution fehlt: ${_fmt.format(deposit - cash)} EUR zusätzlich einplanen.',
          ),
          const SizedBox(height: 8),
          const PremiumSectionLabel(text: 'PRIORITÄT JETZT'),
          const SizedBox(height: 6),
          PremiumStatusHint(
            tone: _priorityTone(footTraffic, weeklyRent, competitionPressure),
            text: _priorityLine(footTraffic, weeklyRent, competitionPressure),
          ),
          const SizedBox(height: 8),
          const PremiumSectionLabel(text: 'KONTEXT'),
          const SizedBox(height: 4),
          PremiumDecisionLine(
            text: _decisionLine(
                location.template.personality, competitionPressure),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: canAfford ? onOpenShop : null,
              child: Text(
                canAfford
                    ? 'Filiale eröffnen'
                    : 'Zu wenig Kapital für ${_fmt.format(deposit)} EUR Kaution',
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _pressureLabel(double pressure) {
    final pct = (pressure * 100).round();
    if (pressure >= 0.50) return 'Hoch ($pct%)';
    if (pressure >= 0.30) return 'Mittel ($pct%)';
    return 'Niedrig ($pct%)';
  }

  Color _pressureColor(double pressure) {
    if (pressure >= 0.50) return AppColors.danger;
    if (pressure >= 0.30) return AppColors.warning;
    return AppColors.accent;
  }

  String _fitLabel(int footTraffic, double weeklyRent) {
    final ratio = footTraffic / weeklyRent;
    if (ratio >= 1.9) return 'Sehr stark';
    if (ratio >= 1.4) return 'Stark';
    if (ratio >= 1.0) return 'Solide';
    return 'Riskant';
  }

  Color _fitColor(int footTraffic, double weeklyRent) {
    final ratio = footTraffic / weeklyRent;
    if (ratio >= 1.4) return AppColors.accent;
    if (ratio >= 1.0) return AppColors.warning;
    return AppColors.danger;
  }

  PremiumStatusTone _priorityTone(
    int footTraffic,
    double weeklyRent,
    double competitionPressure,
  ) {
    final ratio = footTraffic / weeklyRent;
    if (ratio < 1.0) return PremiumStatusTone.danger;
    if (competitionPressure >= 0.50) return PremiumStatusTone.warning;
    return PremiumStatusTone.success;
  }

  String _priorityLine(
    int footTraffic,
    double weeklyRent,
    double competitionPressure,
  ) {
    final ratio = footTraffic / weeklyRent;
    if (ratio < 1.0) {
      return 'Priorität jetzt: nur mit klarer Preisstrategie und hoher Geschwindigkeit eröffnen.';
    }
    if (competitionPressure >= 0.50) {
      return 'Priorität jetzt: Wettbewerb hoch - mit schlankem Menü und Tempo starten.';
    }
    return 'Priorität jetzt: guter Entry-Punkt - Standort schnell sichern und Ruf aufbauen.';
  }

  String _decisionLine(
    LocationPersonality personality,
    double competitionPressure,
  ) {
    switch (personality) {
      case LocationPersonality.business:
        return competitionPressure >= 0.45
            ? 'Mittag stark, aber umkämpft: Tempo plus klares Preisprofil setzen.'
            : 'Mittagsgeschäft stark: Tempo und schnelle Ausgabe priorisieren.';
      case LocationPersonality.university:
        return 'Preis sensibel: günstige Kombos bringen hier mehr Volumen.';
      case LocationPersonality.touristic:
        return 'Konstant hoher Strom: stabile Qualität hält die Bewertung oben.';
      case LocationPersonality.residential:
        return 'Abendspitzen erwarten: Personal für Familienzeit einplanen.';
      case LocationPersonality.nightlife:
        return 'Spätgeschäft dominant: Verfügbarkeit bis spät abends sichern.';
      case LocationPersonality.transit:
        return 'Durchlauf-Standort: kurze Wartezeiten schlagen Premium-Menüs.';
    }
  }
}

class _CityOpsBar extends StatelessWidget {
  final String shopName;
  final String locationName;
  final double dailyRevenue;
  final VoidCallback onOpenShop;

  const _CityOpsBar({
    required this.shopName,
    required this.locationName,
    required this.dailyRevenue,
    required this.onOpenShop,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumDecisionSheet(
      borderColor: AppColors.border,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PremiumSectionLabel(text: 'FILIALE MIT PRIORITÄT'),
                const SizedBox(height: 4),
                Text(
                  shopName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$locationName - ${_fmt.format(dailyRevenue)} EUR / Tag',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton(
            onPressed: onOpenShop,
            child: const Text('Öffnen'),
          ),
        ],
      ),
    );
  }
}
