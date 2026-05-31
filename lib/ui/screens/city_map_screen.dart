import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/city_model.dart';
import '../../models/time_profile_model.dart';
import '../../providers/game_provider.dart';
import '../../services/game_engine.dart';

final _fmt = NumberFormat('#,##0', 'de_DE');

class CityMapScreen extends ConsumerStatefulWidget {
  final String cityId;

  const CityMapScreen({super.key, required this.cityId});

  @override
  ConsumerState<CityMapScreen> createState() => _CityMapScreenState();
}

class _CityMapScreenState extends ConsumerState<CityMapScreen> {
  int _selectedIndex = 0;

  CityData get city =>
      kAllCities.firstWhere((entry) => entry.id == widget.cityId);

  List<LocationTemplate> get locations =>
      kLocationTemplates[city.tier] ?? kLocationTemplates[CityTier.klein]!;

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(gameProvider)!;
    final cityShops =
        game.shops.where((shop) => shop.cityId == city.id).toList();
    final selected = locations[_selectedIndex.clamp(0, locations.length - 1)];

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text('${city.name} Karte'),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          children: [
            _CityMapTopStrip(
              shopCount: cityShops.length,
              totalFootTraffic: cityShops.fold<int>(
                0,
                (sum, shop) => sum + shop.footTraffic,
              ),
              weeklyRent: cityShops.fold<double>(
                0,
                (sum, shop) => sum + shop.weeklyRent,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _CityMapStage(
                city: city,
                locations: locations,
                selectedIndex: _selectedIndex,
                shopCountsByLocation: {
                  for (final location in locations)
                    location.name: cityShops
                        .where((shop) => shop.locationName == location.name)
                        .length,
                },
                onSelect: (index) => setState(() => _selectedIndex = index),
              )
                  .animate()
                  .fadeIn(duration: 260.ms)
                  .slideY(begin: 0.03, end: 0, curve: Curves.easeOutCubic),
            ),
            const SizedBox(height: 12),
            _LocationDecisionSheet(
              city: city,
              location: selected,
              ownShopCount: cityShops
                  .where((shop) => shop.locationName == selected.name)
                  .length,
              cash: game.cash,
              onOpenShop: () => context.push(
                '/open-shop/${city.id}?location=${Uri.encodeComponent(selected.name)}',
              ),
            ),
            if (cityShops.isNotEmpty) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Deine Filialen',
                  style: AppText.label(color: AppColors.secondary),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 96,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (_, index) {
                    final shop = cityShops[index];
                    final dailyRevenue = GameEngine.calculateDailyRevenue(
                      shop,
                      day: game.currentDay,
                      state: game,
                    );
                    return _OwnedShopChip(
                      title: shop.displayName,
                      subtitle: shop.locationName,
                      revenue: dailyRevenue,
                      onTap: () => context.push('/shop/${shop.id}'),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemCount: cityShops.length,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CityMapTopStrip extends StatelessWidget {
  final int shopCount;
  final int totalFootTraffic;
  final double weeklyRent;

  const _CityMapTopStrip({
    required this.shopCount,
    required this.totalFootTraffic,
    required this.weeklyRent,
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
              label: 'Filialen',
              value: '$shopCount',
              color: AppColors.primary,
            ),
          ),
          Expanded(
            child: _TopMetric(
              label: 'Traffic gesamt',
              value: _fmt.format(totalFootTraffic),
              color: AppColors.accent,
            ),
          ),
          Expanded(
            child: _TopMetric(
              label: 'Miete / Woche',
              value: '${_fmt.format(weeklyRent)} EUR',
              color: AppColors.warning,
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
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
        ),
      ],
    );
  }
}

class _CityMapStage extends StatelessWidget {
  final CityData city;
  final List<LocationTemplate> locations;
  final int selectedIndex;
  final Map<String, int> shopCountsByLocation;
  final ValueChanged<int> onSelect;

  const _CityMapStage({
    required this.city,
    required this.locations,
    required this.selectedIndex,
    required this.shopCountsByLocation,
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
                const Positioned.fill(child: _MapBackdrop()),
                for (int i = 0; i < locations.length; i++)
                  _MapLocationMarker(
                    location: locations[i],
                    isSelected: i == selectedIndex,
                    ownShopCount: shopCountsByLocation[locations[i].name] ?? 0,
                    mapPosition: _locationPosition(i, locations.length),
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
                    child: Text(
                      '${city.name} · Hotspots',
                      style: const TextStyle(
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

  Offset _locationPosition(int index, int total) {
    if (total <= 1) {
      return const Offset(0.5, 0.5);
    }
    const predefined = [
      Offset(0.20, 0.32),
      Offset(0.46, 0.22),
      Offset(0.70, 0.40),
      Offset(0.55, 0.68),
      Offset(0.30, 0.62),
      Offset(0.78, 0.66),
    ];
    return index < predefined.length
        ? predefined[index]
        : const Offset(0.5, 0.5);
  }
}

class _MapBackdrop extends StatelessWidget {
  const _MapBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF15261D), Color(0xFF221911), Color(0xFF332317)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: CustomPaint(
        painter: _RoadPainter(),
      ),
    );
  }
}

class _RoadPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadShadow = Paint()
      ..color = Colors.black.withAlpha(85)
      ..strokeWidth = 22
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final road = Paint()
      ..color = const Color(0xFF5B4636)
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final roadLine = Paint()
      ..color = AppColors.cream.withAlpha(120)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final pathA = Path()
      ..moveTo(-0.1 * size.width, 0.72 * size.height)
      ..lineTo(0.30 * size.width, 0.52 * size.height)
      ..lineTo(0.64 * size.width, 0.60 * size.height)
      ..lineTo(1.05 * size.width, 0.36 * size.height);

    final pathB = Path()
      ..moveTo(0.16 * size.width, -0.06 * size.height)
      ..lineTo(0.36 * size.width, 0.34 * size.height)
      ..lineTo(0.44 * size.width, 1.06 * size.height);

    canvas.drawPath(pathA.shift(const Offset(0, 4)), roadShadow);
    canvas.drawPath(pathA, road);
    canvas.drawPath(pathA, roadLine);

    canvas.drawPath(pathB.shift(const Offset(0, 4)), roadShadow);
    canvas.drawPath(pathB, road);
    canvas.drawPath(pathB, roadLine);

    final glow = Paint()
      ..color = AppColors.primary.withAlpha(26)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22);
    canvas.drawCircle(
      Offset(size.width * 0.72, size.height * 0.24),
      math.min(size.width, size.height) * 0.18,
      glow,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MapLocationMarker extends StatelessWidget {
  final LocationTemplate location;
  final bool isSelected;
  final int ownShopCount;
  final Offset mapPosition;
  final Size size;
  final VoidCallback onTap;

  const _MapLocationMarker({
    required this.location,
    required this.isSelected,
    required this.ownShopCount,
    required this.mapPosition,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final left = mapPosition.dx * size.width;
    final top = mapPosition.dy * size.height;
    final color = ownShopCount > 0
        ? AppColors.accent
        : (isSelected ? AppColors.secondary : AppColors.primary);

    return Positioned(
      left: left - 34,
      top: top - 42,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedScale(
          scale: isSelected ? 1.08 : 1,
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
                  border: Border.all(color: color, width: isSelected ? 2 : 1),
                  boxShadow: [
                    BoxShadow(
                      color: color.withAlpha(60),
                      blurRadius: 16,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(location.personality.emoji,
                        style: const TextStyle(fontSize: 20)),
                    Text(
                      ownShopCount > 0 ? 'x$ownShopCount' : 'spot',
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
                  color: isSelected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationDecisionSheet extends StatelessWidget {
  final CityData city;
  final LocationTemplate location;
  final int ownShopCount;
  final double cash;
  final VoidCallback onOpenShop;

  const _LocationDecisionSheet({
    required this.city,
    required this.location,
    required this.ownShopCount,
    required this.cash,
    required this.onOpenShop,
  });

  @override
  Widget build(BuildContext context) {
    final footTraffic =
        (city.footTrafficBase * location.footTrafficFactor).round();
    final weeklyRent = city.rentBase * location.rentFactor;
    final deposit = weeklyRent * 2;
    final canAfford = cash >= deposit;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withAlpha(100)),
      ),
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
                    Text(location.name,
                        style:
                            AppText.display(size: 20, weight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(
                      location.personality.label,
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
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _DecisionMetric(
                  label: 'Traffic',
                  value: _fmt.format(footTraffic),
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
              Expanded(
                child: _DecisionMetric(
                  label: 'Kaution',
                  value: '${_fmt.format(deposit)} EUR',
                  color: AppColors.danger,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _decisionLine(location),
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
              onPressed: canAfford ? onOpenShop : null,
              child: Text(
                canAfford
                    ? 'Filiale eroeffnen'
                    : 'Zu wenig Kapital fuer ${_fmt.format(deposit)} EUR Kaution',
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _decisionLine(LocationTemplate location) {
    switch (location.personality) {
      case LocationPersonality.business:
        return 'Mittagsgeschaeft stark: Tempo und schnelle Ausgabe priorisieren.';
      case LocationPersonality.university:
        return 'Preis sensibel: guenstige Kombos bringen hier mehr Volumen.';
      case LocationPersonality.touristic:
        return 'Konstant hoher Strom: stabile Qualitaet haelt die Bewertung oben.';
      case LocationPersonality.residential:
        return 'Abendspitzen erwarten: Personal fuer Familienzeit einplanen.';
      case LocationPersonality.nightlife:
        return 'Spaetgeschaeft dominant: Verfuegbarkeit bis spaet abends sichern.';
      case LocationPersonality.transit:
        return 'Durchlauf-Standort: kurze Wartezeiten schlagen Premium-Menues.';
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
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _OwnedShopChip extends StatelessWidget {
  final String title;
  final String subtitle;
  final double revenue;
  final VoidCallback onTap;

  const _OwnedShopChip({
    required this.title,
    required this.subtitle,
    required this.revenue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        width: 188,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
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
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
              ),
            ),
            const Spacer(),
            Text(
              '${_fmt.format(revenue)} EUR / Tag',
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
