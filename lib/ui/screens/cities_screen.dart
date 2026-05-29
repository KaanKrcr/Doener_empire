import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../models/city_model.dart';
import '../../providers/game_provider.dart';

final _fmt = NumberFormat('#,##0', 'de_DE');

class CitiesScreen extends ConsumerWidget {
  const CitiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameProvider)!;

    final tierOrder = [
      CityTier.klein,
      CityTier.mittel,
      CityTier.gross,
      CityTier.metropole
    ];

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Städte & Expansion'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Info-Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Text('💡', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Gesamtumsatz: ${_fmt.format(game.totalRevenue)} € · '
                    'Neue Städte werden durch Wachstum freigeschaltet.',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          for (final tier in tierOrder) ...[
            _TierHeader(tier: tier),
            const SizedBox(height: 8),
            for (final city in kAllCities.where((c) => c.tier == tier))
              _CityCard(
                city: city,
                isUnlocked: game.unlockedCityIds.contains(city.id),
                shopCount: game.shops.where((s) => s.cityId == city.id).length,
                totalRevenue: game.totalRevenue,
                onUnlock: () => _unlockCity(context, ref, city, game.cash),
                onOpen: () => context.push('/open-shop/${city.id}'),
              ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  void _unlockCity(
      BuildContext context, WidgetRef ref, CityData city, double cash) {
    if (cash < city.unlockCost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Nicht genug Kapital. Benötigt: ${_fmt.format(city.unlockCost)} €'),
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: Text('${city.emoji} ${city.name} freischalten?'),
        content: Text(
          'Kosten: ${_fmt.format(city.unlockCost)} €\n\n'
          'Du erhältst Zugang zum Markt in ${city.name} (${city.state}) '
          'mit ${_fmt.format(city.population)} Einwohnern.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Abbrechen')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(gameProvider.notifier).unlockCity(city.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${city.name} freigeschaltet! 🎉')),
              );
            },
            child: const Text('Freischalten'),
          ),
        ],
      ),
    );
  }
}

class _TierHeader extends StatelessWidget {
  final CityTier tier;
  const _TierHeader({required this.tier});

  @override
  Widget build(BuildContext context) {
    final colors = {
      CityTier.klein: AppColors.accent,
      CityTier.mittel: AppColors.secondary,
      CityTier.gross: AppColors.primary,
      CityTier.metropole: AppColors.gold,
    };
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: colors[tier],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          tier.label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: colors[tier],
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}

class _CityCard extends StatelessWidget {
  final CityData city;
  final bool isUnlocked;
  final int shopCount;
  final double totalRevenue;
  final VoidCallback onUnlock;
  final VoidCallback onOpen;

  const _CityCard({
    required this.city,
    required this.isUnlocked,
    required this.shopCount,
    required this.totalRevenue,
    required this.onUnlock,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final canUnlock = totalRevenue >= city.unlockCost;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUnlocked
                ? AppColors.border
                : (canUnlock
                    ? AppColors.secondary.withAlpha((0.4 * 255).round())
                    : AppColors.border),
          ),
        ),
        child: Row(
          children: [
            // Emoji
            Text(city.emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    city.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isUnlocked
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                    ),
                  ),
                  Text(
                    '${city.state}  ·  ${_fmt.format(city.population)} Einw.',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textMuted),
                  ),
                  if (isUnlocked && shopCount > 0)
                    Text(
                      '$shopCount Filiale${shopCount > 1 ? "n" : ""}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.accent),
                    ),
                ],
              ),
            ),

            // Aktion
            if (isUnlocked)
              ElevatedButton(
                onPressed: onOpen,
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  textStyle: const TextStyle(fontSize: 13),
                ),
                child: const Text('+ Filiale'),
              )
            else if (city.unlockCost == 0)
              OutlinedButton(
                onPressed: onUnlock,
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontSize: 12),
                  side: const BorderSide(color: AppColors.secondary),
                ),
                child: const Text(
                  'Kostenlos',
                  style: TextStyle(color: AppColors.secondary),
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: canUnlock ? onUnlock : null,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      textStyle: const TextStyle(fontSize: 12),
                      side: BorderSide(
                        color: canUnlock
                            ? AppColors.secondary
                            : AppColors.textMuted,
                      ),
                    ),
                    child: Text(
                      '${_fmt.format(city.unlockCost)} €',
                      style: TextStyle(
                          color: canUnlock
                              ? AppColors.secondary
                              : AppColors.textMuted),
                    ),
                  ),
                  if (!canUnlock)
                    Text(
                      'Noch ${_fmt.format(city.unlockCost - totalRevenue)} € Umsatz',
                      style: const TextStyle(
                          fontSize: 9, color: AppColors.textMuted),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
