part of '../shop_detail_screen.dart';

// ── Ausstattung-/Upgrade-Tab ────────────────────────────────────────────────

class _UpgradesTab extends ConsumerWidget {
  final Shop shop;
  final double cash;
  const _UpgradesTab({required this.shop, required this.cash});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameProvider);
    final globalIds = game?.globalUpgradeIds ?? const [];

    // Nur Shop-Upgrades hier zeigen; globale → Konzern-Tab
    const shopOnlyUpgrades = kShopUpgrades;
    final byCategory = <UpgradeCategory, List<UpgradeData>>{};
    for (final u in shopOnlyUpgrades) {
      byCategory.putIfAbsent(u.category, () => []).add(u);
    }

    // Gekaufte Shop-Upgrades
    final ownedShop = shop.upgradeIds
        .map((id) => upgradeById(id))
        .whereType<UpgradeData>()
        .toList();
    // Aktive globale Upgrades die auch diese Filiale betreffen
    final activeGlobal = globalIds
        .map((id) => upgradeById(id))
        .whereType<UpgradeData>()
        .toList();

    final monthlyTotal = ownedShop.fold(0.0, (s, u) => s + u.monthlyCost);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ─ Aktive Shop-Upgrades ─────────────────────────────────────────
        if (ownedShop.isNotEmpty) ...[
          PremiumDecisionSheet(
            borderColor: AppColors.accent.withAlpha(130),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline,
                    color: AppColors.accent, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${ownedShop.length} aktive Ausstattung${ownedShop.length == 1 ? "" : "en"}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.accent,
                        ),
                      ),
                      Text(
                        '${_fmtInt.format(monthlyTotal)} €/Monat laufende Kosten',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],

        // ─ Aktive Konzern-Upgrades (Info-Banner) ─────────────────────────
        if (activeGlobal.isNotEmpty) ...[
          PremiumDecisionSheet(
            borderColor: AppColors.secondary.withAlpha(130),
            child: Row(
              children: [
                const Text('🏢', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Konzern-Upgrades aktiv: ${activeGlobal.map((u) => u.name).join(", ")}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],

        const SizedBox(height: 8),

        // ─ Kaufbare Shop-Upgrades ─────────────────────────────────────────
        for (final cat in UpgradeCategory.values) ...[
          if (byCategory[cat] != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: PremiumSectionLabel(text: cat.label.toUpperCase()),
            ),
            for (final u in byCategory[cat]!) ...[
              _UpgradeCard(
                upgrade: u,
                owned: shop.hasUpgrade(u.id),
                canAfford: cash >= u.installCost,
                onBuy: () {
                  if (cash < u.installCost) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Nicht genug Kapital')),
                    );
                    return;
                  }
                  ref.read(gameProvider.notifier).buyUpgrade(shop.id, u);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${u.name} installiert ${u.emoji}'),
                      duration: const Duration(milliseconds: 1500),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ],
        ],
      ],
    );
  }
}

class _UpgradeCard extends StatelessWidget {
  final UpgradeData upgrade;
  final bool owned;
  final bool canAfford;
  final VoidCallback onBuy;

  const _UpgradeCard({
    required this.upgrade,
    required this.owned,
    required this.canAfford,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumDecisionSheet(
      borderColor: owned ? AppColors.accent.withAlpha(130) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(upgrade.emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(upgrade.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        )),
                    Text(upgrade.description,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 6,
            children: [
              if (upgrade.customerBoost > 0)
                _UpgradeStatChip(
                  label: '+${(upgrade.customerBoost * 100).round()}% Kunden',
                  color: AppColors.accent,
                ),
              if (upgrade.avgOrderValueBoost != 0)
                _UpgradeStatChip(
                  label: upgrade.avgOrderValueBoost > 0
                      ? '+${(upgrade.avgOrderValueBoost * 100).round()}% Bestellwert'
                      : '${(upgrade.avgOrderValueBoost * 100).round()}% Bestellwert',
                  color: upgrade.avgOrderValueBoost > 0
                      ? AppColors.success
                      : AppColors.warning,
                ),
              if (upgrade.reputationPerDay > 0)
                _UpgradeStatChip(
                  label:
                      '+${(upgrade.reputationPerDay * 100).toStringAsFixed(1)} Rep/Tag',
                  color: AppColors.gold,
                ),
              if (upgrade.brandPerDay > 0)
                const _UpgradeStatChip(
                  label: '+Marke',
                  color: AppColors.secondary,
                ),
              if (upgrade.isDelivery)
                _UpgradeStatChip(
                  label:
                      '${(upgrade.deliveryCommissionRate * 100).round()}% Provision',
                  color: AppColors.warning,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      upgrade.installCost > 0
                          ? 'Einmalig ${_fmtInt.format(upgrade.installCost)} €'
                          : 'Keine Anschaffung',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '${_fmtInt.format(upgrade.monthlyCost)} €/Monat laufend',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.warning),
                    ),
                  ],
                ),
              ),
              if (owned)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withAlpha(35),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    '✓ Aktiv',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.accent,
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
                  child: Text(
                      upgrade.installCost > 0 ? 'Installieren' : 'Abonnieren'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UpgradeStatChip extends StatelessWidget {
  final String label;
  final Color color;
  const _UpgradeStatChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

