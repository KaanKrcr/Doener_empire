import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/city_model.dart';
import '../../models/game_state.dart';
import '../../providers/game_provider.dart';
import '../widgets/premium_mobile_ui.dart';

final _fmt = NumberFormat('#,##0', 'de_DE');

class CitiesScreen extends ConsumerStatefulWidget {
  const CitiesScreen({super.key});

  @override
  ConsumerState<CitiesScreen> createState() => _CitiesScreenState();
}

class _CitiesScreenState extends ConsumerState<CitiesScreen> {
  String? _selectedCityId;

  @override
  void initState() {
    super.initState();
    final game = ref.read(gameProvider);
    _selectedCityId = game?.unlockedCityIds.isNotEmpty == true
        ? game!.unlockedCityIds.first
        : kAllCities.first.id;
  }

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(gameProvider)!;
    final selectedCity = _resolveSelectedCity(game);
    final unlockedCount = kAllCities
        .where((city) => game.unlockedCityIds.contains(city.id))
        .length;
    final selectedCityPressure = game
        .competitorsIn(selectedCity.id)
        .fold<double>(0, (sum, competitor) => sum + competitor.marketShare)
        .clamp(0.0, 0.95);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Staedtekarte'),
        automaticallyImplyLeading: false,
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
                  label: 'Cash',
                  value: '${_fmt.format(game.cash)} EUR',
                  color: AppColors.primary,
                ),
                PremiumMetricData(
                  label: 'Gesamtumsatz',
                  value: '${_fmt.format(game.totalRevenue)} EUR',
                  color: AppColors.accent,
                ),
                PremiumMetricData(
                  label: 'Staedte offen',
                  value: '$unlockedCount / ${kAllCities.length}',
                  color: AppColors.secondary,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _CityStage(
                selectedCityId: selectedCity.id,
                onSelect: (cityId) => setState(() => _selectedCityId = cityId),
                cityStatus: {
                  for (final city in kAllCities)
                    city.id: _CityStatus(
                      isUnlocked: game.unlockedCityIds.contains(city.id),
                      canUnlock: game.totalRevenue >= city.unlockCost,
                      hasShop: game.shops.any((shop) => shop.cityId == city.id),
                    ),
                },
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
              child: _CityDecisionSheet(
                key: ValueKey(selectedCity.id),
                city: selectedCity,
                status: _CityStatus(
                  isUnlocked: game.unlockedCityIds.contains(selectedCity.id),
                  canUnlock: game.totalRevenue >= selectedCity.unlockCost,
                  hasShop:
                      game.shops.any((shop) => shop.cityId == selectedCity.id),
                ),
                shopCount: game.shops
                    .where((shop) => shop.cityId == selectedCity.id)
                    .length,
                availableCash: game.cash,
                totalRevenue: game.totalRevenue,
                competitionPressure: selectedCityPressure,
                onUnlock: () =>
                    _unlockCity(context, ref, selectedCity, game.cash),
                onOpen: () => context.push('/city-map/${selectedCity.id}'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  CityData _resolveSelectedCity(GameState game) {
    final hasSelected = kAllCities.any((city) => city.id == _selectedCityId);
    if (!hasSelected) {
      _selectedCityId = game.unlockedCityIds.isNotEmpty
          ? game.unlockedCityIds.first
          : kAllCities.first.id;
    }
    return kAllCities.firstWhere((city) => city.id == _selectedCityId);
  }

  void _unlockCity(
    BuildContext context,
    WidgetRef ref,
    CityData city,
    double cash,
  ) {
    if (cash < city.unlockCost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Nicht genug Kapital. Benoetigt: ${_fmt.format(city.unlockCost)} EUR',
          ),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: Text('${city.name} freischalten?'),
        content: Text(
          'Kosten: ${_fmt.format(city.unlockCost)} EUR\n\n'
          'Marktzugang in ${city.name} (${city.state}) mit '
          '${_fmt.format(city.population)} Einwohnern.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              ref.read(gameProvider.notifier).unlockCity(city.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${city.name} ist jetzt aktiv.')),
              );
            },
            child: const Text('Freischalten'),
          ),
        ],
      ),
    );
  }
}

class _CityStatus {
  final bool isUnlocked;
  final bool canUnlock;
  final bool hasShop;

  const _CityStatus({
    required this.isUnlocked,
    required this.canUnlock,
    required this.hasShop,
  });
}

class _CityStage extends StatelessWidget {
  final String selectedCityId;
  final ValueChanged<String> onSelect;
  final Map<String, _CityStatus> cityStatus;

  const _CityStage({
    required this.selectedCityId,
    required this.onSelect,
    required this.cityStatus,
  });

  static const Map<String, Offset> _positions = {
    'hamburg': Offset(0.42, 0.14),
    'berlin': Offset(0.72, 0.20),
    'braunschweig': Offset(0.57, 0.31),
    'muenster': Offset(0.31, 0.34),
    'duesseldorf': Offset(0.27, 0.43),
    'koeln': Offset(0.24, 0.48),
    'goettingen': Offset(0.51, 0.44),
    'frankfurt': Offset(0.45, 0.57),
    'fulda': Offset(0.53, 0.61),
    'bayreuth': Offset(0.69, 0.61),
    'stuttgart': Offset(0.45, 0.74),
    'augsburg': Offset(0.58, 0.80),
    'muenchen': Offset(0.65, 0.88),
  };

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
                const Positioned.fill(child: _CityStageBackdrop()),
                for (final city in kAllCities)
                  _CityMarker(
                    city: city,
                    status: cityStatus[city.id] ??
                        const _CityStatus(
                          isUnlocked: false,
                          canUnlock: false,
                          hasShop: false,
                        ),
                    isSelected: city.id == selectedCityId,
                    position: _positions[city.id] ?? const Offset(0.5, 0.5),
                    canvasSize: size,
                    onTap: () => onSelect(city.id),
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
                      'Deutschlandkarte - Expansion',
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
}

class _CityStageBackdrop extends StatelessWidget {
  const _CityStageBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF171310), Color(0xFF231912), Color(0xFF2D1E15)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: -40,
            top: 40,
            right: -40,
            bottom: 20,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.24,
                child: CustomPaint(painter: _GridPainter()),
              ),
            ),
          ),
          Positioned(
            right: -30,
            top: -10,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withAlpha(20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.borderLight.withAlpha(120)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const step = 26.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(
          Offset(x, 0), Offset(x + size.height * 0.5, size.height), paint);
    }
    for (double y = -size.height; y < size.height * 1.5; y += step) {
      canvas.drawLine(
          Offset(0, y), Offset(size.width, y + size.width * 0.25), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CityMarker extends StatelessWidget {
  final CityData city;
  final _CityStatus status;
  final bool isSelected;
  final Offset position;
  final Size canvasSize;
  final VoidCallback onTap;

  const _CityMarker({
    required this.city,
    required this.status,
    required this.isSelected,
    required this.position,
    required this.canvasSize,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dx =
        (position.dx * canvasSize.width).clamp(24, canvasSize.width - 24);
    final dy =
        (position.dy * canvasSize.height).clamp(24, canvasSize.height - 24);

    final Color markerColor;
    if (status.hasShop) {
      markerColor = AppColors.accent;
    } else if (status.isUnlocked) {
      markerColor = AppColors.primary;
    } else if (status.canUnlock) {
      markerColor = AppColors.secondary;
    } else {
      markerColor = AppColors.textMuted;
    }

    return Positioned(
      left: dx - 34,
      top: dy - 34,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 170),
          scale: isSelected ? 1.08 : 1,
          curve: Curves.easeOutCubic,
          child: SizedBox(
            width: 68,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 170),
                  width: isSelected ? 38 : 34,
                  height: isSelected ? 38 : 34,
                  decoration: BoxDecoration(
                    color: AppColors.bgCard.withAlpha(236),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: markerColor,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: markerColor.withAlpha(isSelected ? 110 : 56),
                        blurRadius: isSelected ? 14 : 8,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.location_on_rounded,
                    size: isSelected ? 21 : 18,
                    color: markerColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  city.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: isSelected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CityDecisionSheet extends StatelessWidget {
  final CityData city;
  final _CityStatus status;
  final int shopCount;
  final double availableCash;
  final double totalRevenue;
  final double competitionPressure;
  final VoidCallback onUnlock;
  final VoidCallback onOpen;

  const _CityDecisionSheet({
    super.key,
    required this.city,
    required this.status,
    required this.shopCount,
    required this.availableCash,
    required this.totalRevenue,
    required this.competitionPressure,
    required this.onUnlock,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final remainingRevenue =
        (city.unlockCost - totalRevenue).clamp(0, double.infinity).toDouble();
    final missingCash =
        (city.unlockCost - availableCash).clamp(0, double.infinity).toDouble();
    final canAffordUnlock =
        city.unlockCost == 0 || availableCash >= city.unlockCost;
    final unlockProgress = city.unlockCost <= 0
        ? 1.0
        : (totalRevenue / city.unlockCost).clamp(0.0, 1.0);

    return PremiumDecisionSheet(
      borderColor: status.isUnlocked
          ? AppColors.border
          : (status.canUnlock ? AppColors.secondary : AppColors.border),
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
                    Text(city.name,
                        style:
                            AppText.display(size: 20, weight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(
                      '${city.state} - ${city.tier.label}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (status.isUnlocked && shopCount > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.accent),
                  ),
                  child: Text(
                    '$shopCount Filiale${shopCount > 1 ? 'n' : ''}',
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
                    label: 'Einwohner',
                    value: _fmt.format(city.population),
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Expanded(
                child: PremiumInlineMetric(
                  data: PremiumMetricData(
                    label: 'Traffic-Base',
                    value: _fmt.format(city.footTrafficBase),
                    color: AppColors.accent,
                  ),
                ),
              ),
              Expanded(
                child: PremiumInlineMetric(
                  data: PremiumMetricData(
                    label: 'Miete-Base',
                    value: '${_fmt.format(city.rentBase)} EUR',
                    color: AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const PremiumSectionLabel(text: 'RISIKO & STATUS'),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: PremiumInlineMetric(
                  data: PremiumMetricData(
                    label: 'Konkurrenzdruck',
                    value: _pressureLabel(competitionPressure),
                    color: competitionPressure >= 0.50
                        ? AppColors.danger
                        : (competitionPressure >= 0.30
                            ? AppColors.warning
                            : AppColors.accent),
                  ),
                ),
              ),
              Expanded(
                child: PremiumInlineMetric(
                  data: PremiumMetricData(
                    label: 'Freischaltung',
                    value: status.isUnlocked
                        ? 'Aktiv'
                        : '${(unlockProgress * 100).round()}%',
                    color: status.isUnlocked
                        ? AppColors.accent
                        : (status.canUnlock
                            ? AppColors.secondary
                            : AppColors.textSecondary),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const PremiumSectionLabel(text: 'PRIORITAET JETZT'),
          const SizedBox(height: 6),
          PremiumStatusHint(
            tone: _priorityTone(canAffordUnlock, remainingRevenue),
            text: _priorityLine(canAffordUnlock, remainingRevenue),
          ),
          const SizedBox(height: 8),
          const PremiumSectionLabel(text: 'KONTEXT'),
          const SizedBox(height: 4),
          PremiumDecisionLine(text: _recommendationLine(remainingRevenue)),
          if (!status.isUnlocked && status.canUnlock) ...[
            const SizedBox(height: 10),
            PremiumStatusHint(
              tone: canAffordUnlock
                  ? PremiumStatusTone.success
                  : PremiumStatusTone.danger,
              text: canAffordUnlock
                  ? 'Kapital gedeckt: Freischaltung sofort moeglich.'
                  : 'Kapital fehlt: ${_fmt.format(missingCash)} EUR.',
            ),
          ],
          if (!status.isUnlocked) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                minHeight: 8,
                value: unlockProgress,
                backgroundColor: AppColors.bgCard,
                valueColor: AlwaysStoppedAnimation<Color>(
                  status.canUnlock ? AppColors.secondary : AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Freischaltfortschritt: ${(unlockProgress * 100).round()}%',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: status.isUnlocked
                  ? onOpen
                  : (status.canUnlock ? onUnlock : null),
              child: Text(_primaryActionLabel(remainingRevenue)),
            ),
          ),
        ],
      ),
    );
  }

  String _primaryActionLabel(double remainingRevenue) {
    if (status.isUnlocked) {
      return 'Standorte pruefen';
    }
    if (city.unlockCost == 0 || status.canUnlock) {
      return city.unlockCost == 0
          ? 'Stadt aktivieren'
          : 'Stadt freischalten - ${_fmt.format(city.unlockCost)} EUR';
    }
    return 'Noch ${_fmt.format(remainingRevenue)} EUR Umsatz noetig';
  }

  String _recommendationLine(double remainingRevenue) {
    if (status.isUnlocked && shopCount == 0) {
      return competitionPressure >= 0.45
          ? 'Markt offen, aber umkaempft: jetzt frueh guten Standort sichern.'
          : 'Markt ist offen: jetzt ersten Standort sichern und Tagesgewinn starten.';
    }
    if (status.isUnlocked) {
      return competitionPressure >= 0.45
          ? 'Druck steigt: starke Lage halten oder zweite Filiale defensiv platzieren.'
          : 'Naechster Schritt: schwache Lage optimieren oder zweite Filiale planen.';
    }
    if (status.canUnlock) {
      return competitionPressure >= 0.45
          ? 'Finanziell bereit: Expansion jetzt verhindert spaeteren Preiskampf.'
          : 'Finanziell bereit: Expansion jetzt sichert fruehen Marktanteil.';
    }
    return 'Umsatzziel fuer Expansion: noch ${_fmt.format(remainingRevenue)} EUR bis Freischaltung.';
  }

  String _pressureLabel(double pressure) {
    final pct = (pressure * 100).round();
    if (pressure >= 0.50) return 'Hoch ($pct%)';
    if (pressure >= 0.30) return 'Mittel ($pct%)';
    return 'Niedrig ($pct%)';
  }

  PremiumStatusTone _priorityTone(
      bool canAffordUnlock, double remainingRevenue) {
    if (status.isUnlocked) {
      return competitionPressure >= 0.50
          ? PremiumStatusTone.warning
          : PremiumStatusTone.success;
    }
    if (status.canUnlock && canAffordUnlock) return PremiumStatusTone.success;
    if (status.canUnlock && !canAffordUnlock) return PremiumStatusTone.warning;
    return remainingRevenue <= city.unlockCost * 0.20
        ? PremiumStatusTone.warning
        : PremiumStatusTone.danger;
  }

  String _priorityLine(bool canAffordUnlock, double remainingRevenue) {
    if (status.isUnlocked) {
      return competitionPressure >= 0.50
          ? 'Prioritaet jetzt: in dieser Stadt Wettbewerbsdruck aktiv managen.'
          : 'Prioritaet jetzt: Standortwahl fuer naechste Filiale vorbereiten.';
    }
    if (status.canUnlock && canAffordUnlock) {
      return 'Prioritaet jetzt: Stadt freischalten und ersten Standort sichern.';
    }
    if (status.canUnlock && !canAffordUnlock) {
      return 'Prioritaet jetzt: Cash-Luecke schliessen, dann sofort freischalten.';
    }
    return 'Prioritaet jetzt: noch ${_fmt.format(remainingRevenue)} EUR Umsatz bis Freischaltung.';
  }
}
