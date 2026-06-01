import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/city_map_model.dart';
import '../../models/city_model.dart';
import '../../models/shop_model.dart';
import '../../models/time_profile_model.dart';
import '../../providers/game_provider.dart';
import '../../services/location_engine.dart';
import '../main_scaffold.dart';
import '../widgets/city_map_view.dart';
import '../widgets/premium_mobile_ui.dart';

final _fmt = NumberFormat('#,##0', 'de_DE');
const _uuid = Uuid();

class OpenShopScreen extends ConsumerStatefulWidget {
  final String cityId;
  final String? initialLocationName;

  const OpenShopScreen({
    super.key,
    required this.cityId,
    this.initialLocationName,
  });

  @override
  ConsumerState<OpenShopScreen> createState() => _OpenShopScreenState();
}

class _OpenShopScreenState extends ConsumerState<OpenShopScreen> {
  final _nameCtrl = TextEditingController();
  String? _selectedLocationId;
  bool _loading = false;

  CityData get city =>
      kAllCities.firstWhere((entry) => entry.id == widget.cityId);

  @override
  void initState() {
    super.initState();
    final game = ref.read(gameProvider);
    if (game != null) {
      _nameCtrl.text = game.companyName;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _open(CityMapLocation location) {
    final game = ref.read(gameProvider)!;
    final deposit = location.depositFor(city);

    final typedName = _nameCtrl.text.trim();
    final resolvedBranchName = typedName.isEmpty ? game.companyName : typedName;
    final customName =
        resolvedBranchName == game.companyName ? null : resolvedBranchName;

    if (game.cash < deposit) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Nicht genug Kapital für die Kaution (${_fmt.format(deposit)} EUR)',
          ),
        ),
      );
      return;
    }

    setState(() => _loading = true);

    final shop = Shop(
      id: _uuid.v4(),
      name: game.companyName,
      customName: customName,
      cityId: widget.cityId,
      locationName: location.template.name,
      footTraffic: location.footTrafficFor(city),
      weeklyRent: location.weeklyRentFor(city),
      menu: const [],
      equipment: const [],
      employees: const [],
      dayOpened: game.currentDay,
      personality: location.template.personality,
    );

    ref.read(gameProvider.notifier).openShop(shop);
    context.pushReplacement('/shop/${shop.id}');
  }

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(gameProvider)!;
    final cityShops =
        game.shops.where((shop) => shop.cityId == city.id).toList();
    final cityCompetitionPressure = game
        .competitorsIn(city.id)
        .fold<double>(0, (sum, competitor) => sum + competitor.marketShare)
        .clamp(0.0, 0.95);

    final locations = LocationEngine.locationsFor(city);
    if (locations.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Keine Standorte verfügbar.')),
      );
    }

    final selected = _resolveSelectedLocation(locations);
    final footTraffic = selected.footTrafficFor(city);
    final weeklyRent = selected.weeklyRentFor(city);
    final deposit = selected.depositFor(city);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _goBackToCityMap();
      },
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          title: Text('Filiale in ${city.name}'),
          toolbarHeight: 52,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: _goBackToCityMap,
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: Column(
            children: [
              PremiumMetricStrip(
                dense: true,
                items: [
                  PremiumMetricData(
                    label: city.state,
                    value: city.name,
                    color: AppColors.textPrimary,
                  ),
                  PremiumMetricData(
                    label: 'Cash',
                    value: '${_fmt.format(game.cash)} EUR',
                    color: AppColors.primary,
                  ),
                  PremiumMetricData(
                    label: 'Druck',
                    value: _pressurePct(cityCompetitionPressure),
                    color: _pressureColor(cityCompetitionPressure),
                  ),
                  PremiumMetricData(
                    label: 'Filialen',
                    value: '${cityShops.length}',
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
                      onSelect: (location) =>
                          setState(() => _selectedLocationId = location.id),
                    ),
                  ),
                ),
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
                child: _OpenDecisionSheet(
                  key: ValueKey(selected.id),
                  city: city,
                  location: selected,
                  branchNameCtrl: _nameCtrl,
                  footTraffic: footTraffic,
                  weeklyRent: weeklyRent,
                  deposit: deposit,
                  cashAfter: game.cash - deposit,
                  competitionPressure: cityCompetitionPressure,
                  loading: _loading,
                  onOpen: () => _open(selected),
                  onBack: _goBackToCityMap,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  CityMapLocation _resolveSelectedLocation(List<CityMapLocation> locations) {
    final fallback = locations.first;
    final selectedId = _selectedLocationId;
    if (selectedId != null) {
      return locations.firstWhere(
        (entry) => entry.id == selectedId,
        orElse: () => fallback,
      );
    }

    final initialName = widget.initialLocationName;
    if (initialName != null) {
      final match = locations.where((entry) {
        return entry.label.toLowerCase() == initialName.toLowerCase() ||
            entry.template.name.toLowerCase() == initialName.toLowerCase();
      });
      if (match.isNotEmpty) {
        final resolved = match.first;
        _selectedLocationId = resolved.id;
        return resolved;
      }
    }

    _selectedLocationId = fallback.id;
    return fallback;
  }

  void _goBackToCityMap() {
    ref.read(navIndexProvider.notifier).state = kTabCities;
    context.go('/city-map/${widget.cityId}');
  }

  String _pressurePct(double pressure) => '${(pressure * 100).round()}%';

  Color _pressureColor(double pressure) {
    if (pressure >= 0.50) return AppColors.danger;
    if (pressure >= 0.30) return AppColors.warning;
    return AppColors.accent;
  }
}

class _OpenDecisionSheet extends StatelessWidget {
  final CityData city;
  final CityMapLocation location;
  final TextEditingController branchNameCtrl;
  final int footTraffic;
  final double weeklyRent;
  final double deposit;
  final double cashAfter;
  final double competitionPressure;
  final bool loading;
  final VoidCallback onOpen;
  final VoidCallback onBack;

  const _OpenDecisionSheet({
    super.key,
    required this.city,
    required this.location,
    required this.branchNameCtrl,
    required this.footTraffic,
    required this.weeklyRent,
    required this.deposit,
    required this.cashAfter,
    required this.competitionPressure,
    required this.loading,
    required this.onOpen,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final canAfford = cashAfter >= 0;

    return PremiumDecisionSheet(
      borderColor: AppColors.primary.withAlpha(92),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            location.label,
            style: AppText.display(size: 20, weight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            '${location.template.personality.label} - ${city.name}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          const PremiumSectionLabel(text: 'SETUP'),
          const SizedBox(height: 6),
          TextFormField(
            controller: branchNameCtrl,
            decoration: const InputDecoration(
              hintText: 'Optionaler Filialname (leer = Konzernname)',
              prefixIcon:
                  Icon(Icons.storefront_outlined, color: AppColors.textMuted),
            ),
            textCapitalization: TextCapitalization.words,
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
                    value: '${_fmt.format(footTraffic)} / Tag',
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
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: PremiumInlineMetric(
                  data: PremiumMetricData(
                    label: 'Kaution',
                    value: '${_fmt.format(deposit)} EUR',
                    color: AppColors.danger,
                  ),
                ),
              ),
              Expanded(
                child: PremiumInlineMetric(
                  data: PremiumMetricData(
                    label: 'Cash danach',
                    value: '${_fmt.format(cashAfter)} EUR',
                    color:
                        cashAfter >= 0 ? AppColors.success : AppColors.danger,
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
                ? 'Kaution gedeckt: Eröffnung sofort möglich.'
                : 'Kaution fehlt: ${_fmt.format(-cashAfter)} EUR.',
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
            text: _recommendation(
                location.template.personality, competitionPressure),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: loading || !canAfford ? null : onOpen,
              child: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      canAfford
                          ? 'Filiale eröffnen'
                          : 'Zu wenig Kapital für Kaution',
                    ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onBack,
              child: const Text('Zurück zur Karte'),
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
      return 'Priorität jetzt: nur mit Effizienz-Fokus und diszipliniertem Preislevel starten.';
    }
    if (competitionPressure >= 0.50) {
      return 'Priorität jetzt: hoher Druck - mit klarer Positionierung und Tempo eröffnen.';
    }
    return 'Priorität jetzt: Lage passt - jetzt schnell eröffnen und Bewertungen sichern.';
  }

  String _recommendation(
    LocationPersonality personality,
    double competitionPressure,
  ) {
    switch (personality) {
      case LocationPersonality.business:
        return competitionPressure >= 0.45
            ? 'Mittag umkämpft: Speed plus preisliche Klarheit zuerst stabilisieren.'
            : 'Mittag dominiert: Ausgabe-Takt priorisieren, Premium nur selektiv.';
      case LocationPersonality.university:
        return 'Preis wirkt schnell hoch: Kombi-Angebote halten den Durchlauf stabil.';
      case LocationPersonality.touristic:
        return 'Konstanter Strom: Qualität und Sichtbarkeit liefern stabile Bewertung.';
      case LocationPersonality.residential:
        return 'Abenddruck einplanen: Personal für Peak-Zeiten zuerst absichern.';
      case LocationPersonality.nightlife:
        return 'Spätgeschäft treibt Umsatz: Öffnungszeiten und Speed entscheiden.';
      case LocationPersonality.transit:
        return 'Transit braucht Tempo: kurze Wartezeit ist wichtiger als Produktbreite.';
    }
  }
}
