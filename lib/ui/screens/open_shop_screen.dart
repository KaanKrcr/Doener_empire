import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/city_model.dart';
import '../../models/shop_model.dart';
import '../../models/time_profile_model.dart';
import '../../providers/game_provider.dart';
import '../main_scaffold.dart';

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
  int _selectedLocation = 0;
  bool _loading = false;

  CityData get city =>
      kAllCities.firstWhere((entry) => entry.id == widget.cityId);

  List<LocationTemplate> get locations =>
      kLocationTemplates[city.tier] ?? kLocationTemplates[CityTier.klein]!;

  LocationTemplate get selectedLocation => locations[_selectedLocation];

  int get footTraffic =>
      (city.footTrafficBase * selectedLocation.footTrafficFactor).round();

  double get weeklyRent => city.rentBase * selectedLocation.rentFactor;

  double get deposit => weeklyRent * 2;

  @override
  void initState() {
    super.initState();
    final game = ref.read(gameProvider);
    if (game != null) {
      _nameCtrl.text = game.companyName;
    }
    final initialLocationName = widget.initialLocationName;
    if (initialLocationName != null) {
      final index = locations.indexWhere(
        (location) =>
            location.name.toLowerCase() == initialLocationName.toLowerCase(),
      );
      if (index >= 0) {
        _selectedLocation = index;
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _open() {
    final game = ref.read(gameProvider)!;
    final typedName = _nameCtrl.text.trim();
    final resolvedBranchName = typedName.isEmpty ? game.companyName : typedName;
    final customName =
        resolvedBranchName == game.companyName ? null : resolvedBranchName;

    if (game.cash < deposit) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Nicht genug Kapital fuer die Kaution (${_fmt.format(deposit)} EUR)',
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
      locationName: selectedLocation.name,
      footTraffic: footTraffic,
      weeklyRent: weeklyRent,
      menu: const [],
      equipment: const [],
      employees: const [],
      dayOpened: game.currentDay,
      personality: selectedLocation.personality,
    );

    ref.read(gameProvider.notifier).openShop(shop);
    context.pushReplacement('/shop/${shop.id}');
  }

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(gameProvider)!;
    final cityShops =
        game.shops.where((shop) => shop.cityId == city.id).toList();

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
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: _goBackToCityMap,
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          child: Column(
            children: [
              _OpenShopTopStrip(
                city: city,
                cash: game.cash,
                cityShopCount: cityShops.length,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _OpenShopStage(
                  locations: locations,
                  selectedIndex: _selectedLocation,
                  ownShopCounts: {
                    for (final location in locations)
                      location.name: cityShops
                          .where((shop) => shop.locationName == location.name)
                          .length,
                  },
                  onSelect: (index) =>
                      setState(() => _selectedLocation = index),
                ),
              ),
              const SizedBox(height: 12),
              _OpenDecisionSheet(
                city: city,
                location: selectedLocation,
                branchNameCtrl: _nameCtrl,
                footTraffic: footTraffic,
                weeklyRent: weeklyRent,
                deposit: deposit,
                cashAfter: game.cash - deposit,
                loading: _loading,
                onOpen: _open,
                onBack: _goBackToCityMap,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _goBackToCityMap() {
    ref.read(navIndexProvider.notifier).state = kTabCities;
    context.go('/city-map/${widget.cityId}');
  }
}

class _OpenShopTopStrip extends StatelessWidget {
  final CityData city;
  final double cash;
  final int cityShopCount;

  const _OpenShopTopStrip({
    required this.city,
    required this.cash,
    required this.cityShopCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TopMetric(
              label: city.state,
              value: city.name,
              color: AppColors.textPrimary,
            ),
          ),
          Expanded(
            child: _TopMetric(
              label: 'Cash',
              value: '${_fmt.format(cash)} EUR',
              color: AppColors.primary,
            ),
          ),
          Expanded(
            child: _TopMetric(
              label: 'Filialen',
              value: '$cityShopCount',
              color: AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _TopMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style:
              AppText.display(size: 14, color: color, weight: FontWeight.w700),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _OpenShopStage extends StatelessWidget {
  final List<LocationTemplate> locations;
  final int selectedIndex;
  final Map<String, int> ownShopCounts;
  final ValueChanged<int> onSelect;

  const _OpenShopStage({
    required this.locations,
    required this.selectedIndex,
    required this.ownShopCounts,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            return Stack(
              children: [
                const Positioned.fill(child: _OpenMapBackdrop()),
                for (int i = 0; i < locations.length; i++)
                  _HotspotMarker(
                    location: locations[i],
                    selected: i == selectedIndex,
                    ownCount: ownShopCounts[locations[i].name] ?? 0,
                    position: _markerPosition(i, locations.length),
                    size: size,
                    onTap: () => onSelect(i),
                  ),
                Positioned(
                  left: 12,
                  top: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.bg.withAlpha(214),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: const Text(
                      'Standort waehlen',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Offset _markerPosition(int index, int total) {
    if (total <= 1) {
      return const Offset(0.5, 0.5);
    }
    const predefined = [
      Offset(0.20, 0.30),
      Offset(0.44, 0.24),
      Offset(0.70, 0.40),
      Offset(0.56, 0.70),
      Offset(0.30, 0.62),
      Offset(0.80, 0.64),
    ];
    return index < predefined.length
        ? predefined[index]
        : const Offset(0.5, 0.5);
  }
}

class _OpenMapBackdrop extends StatelessWidget {
  const _OpenMapBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF15120F), Color(0xFF221911), Color(0xFF302216)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: CustomPaint(painter: _OpenRoadPainter()),
    );
  }
}

class _OpenRoadPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadShadow = Paint()
      ..color = Colors.black.withAlpha(86)
      ..strokeWidth = 22
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final road = Paint()
      ..color = const Color(0xFF574331)
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final roadLine = Paint()
      ..color = AppColors.cream.withAlpha(118)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final pathA = Path()
      ..moveTo(-0.12 * size.width, 0.75 * size.height)
      ..lineTo(0.28 * size.width, 0.53 * size.height)
      ..lineTo(0.62 * size.width, 0.62 * size.height)
      ..lineTo(1.05 * size.width, 0.37 * size.height);

    final pathB = Path()
      ..moveTo(0.12 * size.width, -0.08 * size.height)
      ..lineTo(0.34 * size.width, 0.32 * size.height)
      ..lineTo(0.42 * size.width, 1.05 * size.height);

    canvas.drawPath(pathA.shift(const Offset(0, 4)), roadShadow);
    canvas.drawPath(pathA, road);
    canvas.drawPath(pathA, roadLine);

    canvas.drawPath(pathB.shift(const Offset(0, 4)), roadShadow);
    canvas.drawPath(pathB, road);
    canvas.drawPath(pathB, roadLine);

    final glow = Paint()
      ..color = AppColors.primary.withAlpha(30)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24);

    canvas.drawCircle(
      Offset(size.width * 0.76, size.height * 0.24),
      math.min(size.width, size.height) * 0.16,
      glow,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HotspotMarker extends StatelessWidget {
  final LocationTemplate location;
  final bool selected;
  final int ownCount;
  final Offset position;
  final Size size;
  final VoidCallback onTap;

  const _HotspotMarker({
    required this.location,
    required this.selected,
    required this.ownCount,
    required this.position,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final left = position.dx * size.width;
    final top = position.dy * size.height;
    final color = ownCount > 0
        ? AppColors.accent
        : (selected ? AppColors.secondary : AppColors.primary);

    return Positioned(
      left: left - 34,
      top: top - 42,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedScale(
          scale: selected ? 1.08 : 1,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.bgCard.withAlpha(236),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color, width: selected ? 2 : 1),
                  boxShadow: [
                    BoxShadow(
                      color: color.withAlpha(64),
                      blurRadius: 14,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(location.personality.emoji,
                        style: const TextStyle(fontSize: 20)),
                    Text(
                      ownCount > 0 ? 'x$ownCount' : 'spot',
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                location.name,
                style: TextStyle(
                  color: selected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OpenDecisionSheet extends StatelessWidget {
  final CityData city;
  final LocationTemplate location;
  final TextEditingController branchNameCtrl;
  final int footTraffic;
  final double weeklyRent;
  final double deposit;
  final double cashAfter;
  final bool loading;
  final VoidCallback onOpen;
  final VoidCallback onBack;

  const _OpenDecisionSheet({
    required this.city,
    required this.location,
    required this.branchNameCtrl,
    required this.footTraffic,
    required this.weeklyRent,
    required this.deposit,
    required this.cashAfter,
    required this.loading,
    required this.onOpen,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withAlpha(92)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            location.name,
            style: AppText.display(size: 20, weight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            '${location.personality.label} · ${city.name}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
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
          Row(
            children: [
              Expanded(
                child: _DecisionMetric(
                  label: 'Traffic',
                  value: '${_fmt.format(footTraffic)} / Tag',
                  color: AppColors.accent,
                ),
              ),
              Expanded(
                child: _DecisionMetric(
                  label: 'Miete',
                  value: '${_fmt.format(weeklyRent)} EUR',
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _DecisionMetric(
                  label: 'Kaution',
                  value: '${_fmt.format(deposit)} EUR',
                  color: AppColors.danger,
                ),
              ),
              Expanded(
                child: _DecisionMetric(
                  label: 'Cash danach',
                  value: '${_fmt.format(cashAfter)} EUR',
                  color: cashAfter >= 0 ? AppColors.success : AppColors.danger,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _recommendation(location.personality),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: loading ? null : onOpen,
              child: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Filiale eroeffnen'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onBack,
              child: const Text('Zurueck zur Karte'),
            ),
          ),
        ],
      ),
    );
  }

  String _recommendation(LocationPersonality personality) {
    switch (personality) {
      case LocationPersonality.business:
        return 'Mittag dominiert: Ausgabe-Takt priorisieren, Premium nur selektiv.';
      case LocationPersonality.university:
        return 'Preis wirkt schnell hoch: Kombi-Angebote halten den Durchlauf stabil.';
      case LocationPersonality.touristic:
        return 'Konstanter Strom: Qualitaet und Sichtbarkeit liefern stabile Bewertung.';
      case LocationPersonality.residential:
        return 'Abenddruck einplanen: Personal fuer Peak-Zeiten zuerst absichern.';
      case LocationPersonality.nightlife:
        return 'Spaetgeschaeft treibt Umsatz: Oeffnungszeiten und Speed entscheiden.';
      case LocationPersonality.transit:
        return 'Transit braucht Tempo: kurze Wartezeit ist wichtiger als Produktbreite.';
    }
  }
}

class _DecisionMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _DecisionMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 10,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
