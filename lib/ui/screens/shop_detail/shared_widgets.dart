part of '../shop_detail_screen.dart';

class _ShopStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ShopStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppText.display(
            size: 16,
            weight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class _ShopExpansionCard extends ConsumerWidget {
  final Shop shop;
  final double cash;

  const _ShopExpansionCard({
    required this.shop,
    required this.cash,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTier = shop.sizeTier;
    final nextTier = currentTier.nextTier;
    final canLevelUp = nextTier != null;

    final currentCfg = kShopSizeTierConfig[currentTier] ??
        kShopSizeTierConfig[ShopSizeTier.klein]!;
    final nextCfg = nextTier == null
        ? currentCfg
        : (kShopSizeTierConfig[nextTier] ?? currentCfg);

    final expansionCost = canLevelUp ? GameEngine.shopExpansionCost(shop) : 0.0;
    final canAfford = cash >= expansionCost;

    final currentCap = GameEngine.maxEmployeesForShop(shop);
    final nextCap = nextTier == null
        ? currentCap
        : GameEngine.employeeCapForTier(shop, nextTier);
    final currentService = currentCfg.capacityMultiplier;
    final nextService = nextCfg.capacityMultiplier;
    final currentRent = shop.weeklyRent;
    final nextRent = canLevelUp
        ? shop.weeklyRent * (nextCfg.rentMultiplier / currentCfg.rentMultiplier)
        : shop.weeklyRent;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
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
            'FILIALE AUSBAUEN',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
              letterSpacing: 1.8,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            canLevelUp
                ? '${currentTier.label} -> ${nextTier.label}'
                : '${currentTier.label} (Maximalstufe)',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            canLevelUp
                ? 'Mehr Platz erlaubt mehr Personal, erhöht aber Fixkosten.'
                : 'Maximale Filialgröße erreicht.',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ShopStat(
                  label: 'Mitarbeiter-Cap',
                  value: '$currentCap -> $nextCap',
                  color: AppColors.accent,
                ),
              ),
              Expanded(
                child: _ShopStat(
                  label: 'Kapazität',
                  value:
                      '${currentService.toStringAsFixed(2)}x -> ${nextService.toStringAsFixed(2)}x',
                  color: AppColors.primary,
                ),
              ),
              Expanded(
                child: _ShopStat(
                  label: 'Miete/Woche',
                  value:
                      '${_fmtInt.format(currentRent)} € -> ${_fmtInt.format(nextRent)} €',
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: canLevelUp && canAfford
                  ? () {
                      ref.read(gameProvider.notifier).expandShop(shop.id);
                    }
                  : null,
              icon: const Icon(Icons.store_mall_directory_outlined, size: 18),
              label: Text(
                canLevelUp
                    ? 'Filiale ausbauen (${_fmtInt.format(expansionCost)} €)'
                    : 'Maximale Filialgröße erreicht',
              ),
            ),
          ),
          if (canLevelUp && !canAfford) ...[
            const SizedBox(height: 6),
            Text(
              'Nicht genug Kapital: es fehlen ${_fmtInt.format(expansionCost - cash)} €.',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.warning,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Banner über dem Shop-Header: zeigt Auslastung + Potenzial + verlorenen Umsatz.
/// Spieler sieht sofort: "ich bin am Anschlag, brauche mehr Personal".
class _CapacityBanner extends StatelessWidget {
  final ShopDayStats stats;
  final Shop shop;
  const _CapacityBanner({required this.stats, required this.shop});

  @override
  Widget build(BuildContext context) {
    final util = (stats.utilization * 100).clamp(0, 100);
    final isLimited = stats.isCapacityLimited;
    final maxEmp = GameEngine.maxEmployeesForShop(shop);
    final empCount = shop.employees.length;
    final atMaxEmployees = empCount >= maxEmp;

    Color color;
    IconData icon;
    String label;
    String detail;

    if (isLimited && atMaxEmployees) {
      color = AppColors.warning;
      icon = Icons.warning_amber_rounded;
      label = 'Maximale Personalstärke erreicht';
      detail =
          'Auslastung ${util.toStringAsFixed(0)}% - Potenzial ${_fmt.format(stats.lostRevenue)} € liegt brach. Filiale ausbauen hilft jetzt direkt.';
    } else if (isLimited) {
      color = AppColors.primary;
      icon = Icons.bolt_rounded;
      final extra = GameEngine.recommendedExtraEmployees(shop);
      color = AppColors.primary;
      label = 'Personal-Engpass!';
      detail =
          '${util.toStringAsFixed(0)}% Auslastung - du verlierst ${_fmt.format(stats.lostRevenue)} €/Tag. Stelle ~$extra weitere Mitarbeiter ein.';
    } else if (util > 80) {
      color = AppColors.gold;
      icon = Icons.local_fire_department_rounded;
      label = 'Volle Auslastung';
      detail =
          'Läuft optimal (${util.toStringAsFixed(0)}%). Bald wird mehr Personal nötig.';
    } else {
      color = AppColors.success;
      icon = Icons.check_circle_outline_rounded;
      label = 'Alles im grünen Bereich';
      detail =
          'Aktuell ${util.toStringAsFixed(0)}% Auslastung - Personal reicht.';
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(90)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                    ),
                    Text(
                      '$empCount/$maxEmp 👥',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    height: 1.3,
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
