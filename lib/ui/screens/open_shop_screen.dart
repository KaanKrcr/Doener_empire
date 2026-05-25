import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../models/city_model.dart';
import '../../models/shop_model.dart';
import '../../models/time_profile_model.dart';
import '../../providers/game_provider.dart';
import '../main_scaffold.dart';

final _fmt = NumberFormat('#,##0', 'de_DE');
const _uuid = Uuid();

class OpenShopScreen extends ConsumerStatefulWidget {
  final String cityId;
  const OpenShopScreen({super.key, required this.cityId});

  @override
  ConsumerState<OpenShopScreen> createState() => _OpenShopScreenState();
}

class _OpenShopScreenState extends ConsumerState<OpenShopScreen> {
  final _nameCtrl = TextEditingController();
  int _selectedLocation = 0;
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  CityData get city => kAllCities.firstWhere((c) => c.id == widget.cityId);
  List<LocationTemplate> get locations =>
      kLocationTemplates[city.tier] ?? kLocationTemplates[CityTier.klein]!;

  int get footTraffic =>
      (city.footTrafficBase * locations[_selectedLocation].footTrafficFactor)
          .round();
  double get weeklyRent =>
      city.rentBase * locations[_selectedLocation].rentFactor;
  double get kaution => weeklyRent * 2;

  void _open() {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte einen Filial-Namen eingeben')),
      );
      return;
    }
    final game = ref.read(gameProvider)!;
    if (game.cash < kaution) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Nicht genug Kapital für die Kaution (${_fmt.format(kaution)} €)'),
        ),
      );
      return;
    }

    setState(() => _loading = true);
    final shop = Shop(
      id: _uuid.v4(),
      name: _nameCtrl.text.trim(),
      cityId: widget.cityId,
      locationName: locations[_selectedLocation].name,
      footTraffic: footTraffic,
      weeklyRent: weeklyRent,
      menu: const [],
      equipment: const [],
      employees: const [],
      dayOpened: game.currentDay,
      personality: locations[_selectedLocation].personality,
    );

    ref.read(gameProvider.notifier).openShop(shop);
    // Open-Shop-Route durch Shop-Detail ersetzen (kein "Filiale eröffnen"
    // mehr im Back-Stack), aber Back-Stack zu /game behalten.
    context.pushReplacement('/shop/${shop.id}');
  }

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(gameProvider)!;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _goBackToCities();
      },
      child: Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text('Filiale in ${city.name}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: _goBackToCities,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stadt-Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Text(city.emoji, style: const TextStyle(fontSize: 36)),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(city.name,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary)),
                      Text(
                        '${city.state}  ·  ${_fmt.format(city.population)} Einwohner',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textMuted),
                      ),
                      Text(
                        city.tier.label,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.secondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Filial-Name
            const _Label('Filial-Name'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                hintText: 'z.B. Sultan Döner Fulda',
                prefixIcon:
                    Icon(Icons.storefront_outlined, color: AppColors.textMuted),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 24),

            // Standort wählen
            const _Label('Standort wählen'),
            const SizedBox(height: 8),
            for (int i = 0; i < locations.length; i++)
              _LocationTile(
                template: locations[i],
                cityData: city,
                isSelected: _selectedLocation == i,
                onTap: () => setState(() => _selectedLocation = i),
              ),
            const SizedBox(height: 24),

            // Zusammenfassung
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withAlpha((0.3 * 255).round())),
              ),
              child: Column(
                children: [
                  _SummaryRow(
                    label: 'Laufkundschaft/Tag',
                    value: '${_fmt.format(footTraffic)} Personen',
                    icon: Icons.people_outline,
                    color: AppColors.accent,
                  ),
                  const Divider(height: 20, color: AppColors.border),
                  _SummaryRow(
                    label: 'Wochenmiete',
                    value: '${_fmt.format(weeklyRent)} €',
                    icon: Icons.home_outlined,
                    color: AppColors.warning,
                  ),
                  const Divider(height: 20, color: AppColors.border),
                  _SummaryRow(
                    label: 'Kaution (2 Wochen)',
                    value: '${_fmt.format(kaution)} €',
                    icon: Icons.lock_outlined,
                    color: AppColors.danger,
                  ),
                  const Divider(height: 20, color: AppColors.border),
                  _SummaryRow(
                    label: 'Dein Kapital danach',
                    value: '${_fmt.format(game.cash - kaution)} €',
                    icon: Icons.account_balance_wallet_outlined,
                    color: game.cash - kaution >= 0
                        ? AppColors.success
                        : AppColors.danger,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _open,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Filiale eröffnen  🥙'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    ),
    );
  }

  /// Zurück in den Städte-Tab des MainScaffold (statt nicht-existierender Route `/cities`).
  void _goBackToCities() {
    ref.read(navIndexProvider.notifier).state = kTabCities;
    context.go('/game');
  }
}

class _LocationTile extends StatelessWidget {
  final LocationTemplate template;
  final CityData cityData;
  final bool isSelected;
  final VoidCallback onTap;

  const _LocationTile({
    required this.template,
    required this.cityData,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ft = (cityData.footTrafficBase * template.footTrafficFactor).round();
    final rent = cityData.rentBase * template.rentFactor;
    final pers = template.personality;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withAlpha((0.15 * 255).round())
              : AppColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppColors.primary : AppColors.textMuted,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(template.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: isSelected
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          )),
                      const SizedBox(width: 8),
                      Text(pers.emoji, style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                  Text(
                    '${_fmt.format(ft)} Laufkundschaft  ·  ${_fmt.format(rent)} €/Woche',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${pers.label}: ${pers.description}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected
                          ? AppColors.secondary
                          : AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryRow(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
        ),
        Text(value,
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }
}
