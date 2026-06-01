part of '../shop_detail_screen.dart';

// ── Marketing-Tab ─────────────────────────────────────────────────────────

class _MarketingTab extends ConsumerWidget {
  final Shop shop;
  final double cash;
  final int currentDay;
  const _MarketingTab({
    required this.shop,
    required this.cash,
    required this.currentDay,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active =
        shop.activeCampaigns.where((c) => c.isActive(currentDay)).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Aktive Kampagnen
        if (active.isNotEmpty) ...[
          const PremiumSectionLabel(text: 'LAUFENDE KAMPAGNEN'),
          const SizedBox(height: 8),
          for (final ac in active) ...[
            _ActiveCampaignCard(active: ac, currentDay: currentDay),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 16),
        ],

        const PremiumSectionLabel(text: 'VERFÜGBARE KAMPAGNEN'),
        const SizedBox(height: 8),
        for (final c in kAllCampaigns) ...[
          _CampaignCard(
            campaign: c,
            canAfford: cash >= c.cost,
            alreadyActive: active.any((a) => a.campaignId == c.id),
            onBook: () {
              if (cash < c.cost) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nicht genug Kapital')),
                );
                return;
              }
              ref.read(gameProvider.notifier).bookCampaign(shop.id, c);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${c.name} läuft jetzt ${c.emoji}'),
                  duration: const Duration(milliseconds: 1500),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _ActiveCampaignCard extends StatelessWidget {
  final ActiveCampaign active;
  final int currentDay;
  const _ActiveCampaignCard({required this.active, required this.currentDay});

  @override
  Widget build(BuildContext context) {
    final campaign = kAllCampaigns.firstWhere(
      (c) => c.id == active.campaignId,
      orElse: () => kAllCampaigns.first,
    );
    final remaining = active.remainingDays(currentDay);
    final progress = active.progress(currentDay);

    return PremiumDecisionSheet(
      borderColor: AppColors.accent.withAlpha(130),
      child: Column(
        children: [
          Row(
            children: [
              Text(campaign.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(campaign.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        )),
                    Text(
                      '+${(campaign.customerBoost * 100).round()}% Kunden  ·  Noch $remaining Tag${remaining == 1 ? "" : "e"}',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.accent),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.bgSurface,
              valueColor: const AlwaysStoppedAnimation(AppColors.accent),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }
}

class _CampaignCard extends StatelessWidget {
  final MarketingCampaign campaign;
  final bool canAfford;
  final bool alreadyActive;
  final VoidCallback onBook;
  const _CampaignCard({
    required this.campaign,
    required this.canAfford,
    required this.alreadyActive,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    final riskColor = switch (campaign.risk) {
      MarketingRisk.low => AppColors.success,
      MarketingRisk.medium => AppColors.warning,
      MarketingRisk.high => AppColors.danger,
    };
    final riskLabel = switch (campaign.risk) {
      MarketingRisk.low => 'sicher',
      MarketingRisk.medium => 'mittel',
      MarketingRisk.high => 'riskant',
    };

    return PremiumDecisionSheet(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(campaign.emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(campaign.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            )),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: riskColor.withAlpha(35),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            riskLabel,
                            style: TextStyle(
                                fontSize: 9,
                                color: riskColor,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5),
                          ),
                        ),
                      ],
                    ),
                    Text(campaign.description,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _CampaignStat(
                label: '+${(campaign.customerBoost * 100).round()}%',
                sub: 'Kunden',
                color: AppColors.accent,
              ),
              const SizedBox(width: 14),
              _CampaignStat(
                label: '${campaign.durationDays}d',
                sub: 'Laufzeit',
                color: AppColors.secondary,
              ),
              const SizedBox(width: 14),
              if (campaign.avgOrderValueMod != 0)
                _CampaignStat(
                  label:
                      '${campaign.avgOrderValueMod > 0 ? "+" : ""}${(campaign.avgOrderValueMod * 100).round()}%',
                  sub: 'Marge',
                  color: campaign.avgOrderValueMod > 0
                      ? AppColors.success
                      : AppColors.danger,
                ),
              const Spacer(),
              if (alreadyActive)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withAlpha(35),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Läuft',
                      style: TextStyle(
                          fontSize: 11,
                          color: AppColors.accent,
                          fontWeight: FontWeight.w800)),
                )
              else
                ElevatedButton(
                  onPressed: canAfford ? onBook : null,
                  style: ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                  child: Text('${_fmtInt.format(campaign.cost)} €'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CampaignStat extends StatelessWidget {
  final String label;
  final String sub;
  final Color color;
  const _CampaignStat({
    required this.label,
    required this.sub,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color,
            )),
        Text(sub,
            style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
      ],
    );
  }
}

