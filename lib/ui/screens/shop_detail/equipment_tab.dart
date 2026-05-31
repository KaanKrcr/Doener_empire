part of '../shop_detail_screen.dart';

// ── Equipment-Tab ──────────────────────────────────────────────────────────

class _EquipmentTab extends ConsumerWidget {
  final Shop shop;
  final double cash;
  const _EquipmentTab({required this.shop, required this.cash});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visibleEquipment = kAllEquipment
        .where((e) => e.category != EquipmentCategory.spiess)
        .toList();
    final categories = visibleEquipment.map((e) => e.category).toSet().toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final cat in categories) ...[
          _EquipCategoryHeader(cat),
          const SizedBox(height: 8),
          for (final eq
              in visibleEquipment.where((e) => e.category == cat)) ...[
            _EquipmentCard(
              eq: eq,
              isOwned: shop.hasEquipment(eq.id),
              canAfford: cash >= eq.price,
              onBuy: () {
                if (cash < eq.price) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nicht genug Kapital')),
                  );
                  return;
                }
                ref.read(gameProvider.notifier).buyEquipment(shop.id, eq);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${eq.name} gekauft ${eq.emoji}'),
                    duration: const Duration(milliseconds: 1500),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _EquipCategoryHeader extends StatelessWidget {
  final EquipmentCategory cat;
  const _EquipCategoryHeader(this.cat);

  String get label {
    switch (cat) {
      case EquipmentCategory.spiess:
        return '🔥  DÖNER-SPIEß';
      case EquipmentCategory.kasse:
        return '💳  KASSE';
      case EquipmentCategory.sonstiges:
        return '🔧  WEITERES EQUIPMENT';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
          fontSize: 11,
          color: AppColors.textMuted,
          letterSpacing: 2,
          fontWeight: FontWeight.w600),
    );
  }
}

class _EquipmentCard extends StatelessWidget {
  final EquipmentData eq;
  final bool isOwned;
  final bool canAfford;
  final VoidCallback onBuy;

  const _EquipmentCard({
    required this.eq,
    required this.isOwned,
    required this.canAfford,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOwned
              ? AppColors.accent.withAlpha((0.5 * 255).round())
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Text(eq.emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(eq.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                Text(eq.description,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textMuted)),
                if (eq.qualityBonus > 0)
                  Text('+${(eq.qualityBonus * 100).round()}% Qualität',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.accent)),
                if (eq.unlocksProductId != null)
                  Text(
                    'Schaltet ${kAllProducts.firstWhere((p) => p.id == eq.unlocksProductId).name} frei',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.secondary),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isOwned)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.accent.withAlpha((0.15 * 255).round()),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('✓ Vorhanden',
                  style: TextStyle(
                      fontSize: 12,
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600)),
            )
          else
            ElevatedButton(
              onPressed: canAfford ? onBuy : null,
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                textStyle: const TextStyle(fontSize: 12),
              ),
              child: Text('${_fmtInt.format(eq.price)} €'),
            ),
        ],
      ),
    );
  }
}

