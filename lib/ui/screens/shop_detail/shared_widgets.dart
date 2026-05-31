part of '../shop_detail_screen.dart';

class _ShopStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ShopStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppText.display(size: 16, weight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
      ],
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
          'Auslastung ${util.toStringAsFixed(0)}% — Potenzial ${_fmt.format(stats.lostRevenue)} € liegt brach. Größere Filiale (Stadt-Upgrade) hilft.';
    } else if (isLimited) {
      color = AppColors.primary;
      icon = Icons.bolt_rounded;
      final extra = GameEngine.recommendedExtraEmployees(shop);
      color = AppColors.primary;
      label = 'Personal-Engpass!';
      detail =
          '${util.toStringAsFixed(0)}% Auslastung — du verlierst ${_fmt.format(stats.lostRevenue)} €/Tag. Stelle ~$extra weitere Mitarbeiter ein.';
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
          'Aktuell ${util.toStringAsFixed(0)}% Auslastung — Personal reicht.';
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
