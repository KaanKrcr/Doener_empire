part of '../shop_detail_screen.dart';

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

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: PremiumDecisionSheet(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PremiumSectionLabel(text: 'FILIALAUSBAU'),
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
            const PremiumDecisionLine(
              text: 'Mehr Platz erlaubt mehr Personal, erhöht aber Fixkosten.',
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: PremiumInlineMetric(
                    data: PremiumMetricData(
                      label: 'MITARBEITER-CAP',
                      value: '$currentCap -> $nextCap',
                      color: AppColors.accent,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: PremiumInlineMetric(
                    data: PremiumMetricData(
                      label: 'KAPAZITÄT',
                      value:
                          '${currentService.toStringAsFixed(2)}x -> ${nextService.toStringAsFixed(2)}x',
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: PremiumInlineMetric(
                    data: PremiumMetricData(
                      label: 'MIETE/WOCHE',
                      value:
                          '${_fmtInt.format(currentRent)} € -> ${_fmtInt.format(nextRent)} €',
                      color: AppColors.warning,
                    ),
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
            if (!canLevelUp) ...[
              const SizedBox(height: 8),
              const PremiumStatusHint(
                text: 'Maximale Filialgröße erreicht.',
                tone: PremiumStatusTone.success,
              ),
            ] else if (!canAfford) ...[
              const SizedBox(height: 8),
              PremiumStatusHint(
                text:
                    'Nicht genug Kapital: es fehlen ${_fmtInt.format(expansionCost - cash)} €.',
                tone: PremiumStatusTone.warning,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Banner über dem Shop-Header: zeigt Auslastung + Potenzial + verlorenen Umsatz.
/// Spieler sieht sofort: wo Kapazität verloren geht.
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
    PremiumStatusTone tone;

    if (isLimited && atMaxEmployees) {
      color = AppColors.warning;
      icon = Icons.warning_amber_rounded;
      label = 'Personal-Cap erreicht';
      tone = PremiumStatusTone.warning;
      detail =
          'Du bedienst nur ${util.toStringAsFixed(0)}% der Nachfrage. Geschätztes Umsatzpotenzial: ${_fmt.format(stats.lostRevenue)} €/Tag. Mehr Personal ist erst nach einem Filialausbau möglich.';
    } else if (isLimited) {
      color = AppColors.primary;
      icon = Icons.bolt_rounded;
      final extra = GameEngine.recommendedExtraEmployees(shop);
      tone = PremiumStatusTone.warning;
      label = 'Nachfrage nicht vollständig gedeckt';
      detail =
          'Du bedienst nur ${util.toStringAsFixed(0)}% der Nachfrage. Geschätztes Umsatzpotenzial: ${_fmt.format(stats.lostRevenue)} €/Tag. Stelle ~$extra weitere Mitarbeiter ein.';
    } else if (util > 80) {
      color = AppColors.gold;
      icon = Icons.local_fire_department_rounded;
      tone = PremiumStatusTone.success;
      label = 'Volle Auslastung';
      detail =
          'Läuft optimal (${util.toStringAsFixed(0)}%). Bald wird mehr Personal nötig.';
    } else {
      color = AppColors.success;
      icon = Icons.check_circle_outline_rounded;
      tone = PremiumStatusTone.success;
      label = 'Alles im grünen Bereich';
      detail =
          'Aktuell ${util.toStringAsFixed(0)}% der Nachfrage bedient. Personal reicht.';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: PremiumDecisionSheet(
        borderColor: color.withAlpha(130),
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
                  const SizedBox(height: 6),
                  PremiumStatusHint(text: detail, tone: tone),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
