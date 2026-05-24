import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../models/shop_model.dart';
import '../../models/product_model.dart';
import '../../models/equipment_model.dart';
import '../../models/employee_model.dart';
import '../../providers/game_provider.dart';
import '../../services/game_engine.dart';
import 'dart:math';

final _fmt = NumberFormat('#,##0.00', 'de_DE');
final _fmtInt = NumberFormat('#,##0', 'de_DE');
const _uuid = Uuid();
final _rng = Random();

const _kWeekdays = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
String _weekdayLabel(int day) => _kWeekdays[day % 7];

class ShopDetailScreen extends ConsumerStatefulWidget {
  final String shopId;
  const ShopDetailScreen({super.key, required this.shopId});

  @override
  ConsumerState<ShopDetailScreen> createState() => _ShopDetailScreenState();
}

class _ShopDetailScreenState extends ConsumerState<ShopDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Shop? get shop {
    final game = ref.read(gameProvider);
    if (game == null) return null;
    try {
      return game.shops.firstWhere((s) => s.id == widget.shopId);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(gameProvider);
    if (game == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    Shop? currentShop;
    try {
      currentShop = game.shops.firstWhere((s) => s.id == widget.shopId);
    } catch (_) {
      return Scaffold(
        appBar: AppBar(title: const Text('Filiale')),
        body: const Center(child: Text('Filiale nicht gefunden')),
      );
    }

    final today = game.currentDay;
    final stats = GameEngine.calculateShopStats(currentShop, day: today);
    final revenue = stats.actualRevenue;
    final costs = GameEngine.calculateDailyCosts(currentShop, day: today);
    final profit = revenue - costs;
    final customers = stats.actualCustomers;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(currentShop.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () {
            // Falls Stack vorhanden (z.B. von Dashboard via push), poppen.
            // Sonst sauber zurück zum MainScaffold.
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/game');
            }
          },
        ),
      ),
      body: Column(
        children: [
          // ── Auslastungs-Banner ───────────────────────────────────────
          if (stats.actualCustomers > 0)
            _CapacityBanner(
              stats: stats,
              shop: currentShop,
            ),
          // ── Shop-Stats Header ─────────────────────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _ShopStat(
                        label: 'Umsatz/Tag',
                        value: '+${_fmt.format(revenue)} €',
                        color: AppColors.success,
                      ),
                    ),
                    Expanded(
                      child: _ShopStat(
                        label: 'Kosten/Tag',
                        value: '-${_fmt.format(costs)} €',
                        color: AppColors.danger,
                      ),
                    ),
                    Expanded(
                      child: _ShopStat(
                        label: 'Profit/Tag',
                        value:
                            '${profit >= 0 ? "+" : ""}${_fmt.format(profit)} €',
                        color: profit >= 0
                            ? AppColors.success
                            : AppColors.danger,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ShopStat(
                        label: 'Kunden/Tag',
                        value: _fmtInt.format(customers),
                        color: AppColors.accent,
                      ),
                    ),
                    Expanded(
                      child: _ShopStat(
                        label: 'Reputation',
                        value:
                            '${currentShop.reputation.toStringAsFixed(1)} / 5',
                        color: AppColors.gold,
                      ),
                    ),
                    Expanded(
                      child: _ShopStat(
                        label: 'Wochentag',
                        value: _weekdayLabel(today),
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Tabs ───────────────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: TabBar(
              controller: _tabs,
              indicatorColor: AppColors.primary,
              dividerColor: Colors.transparent,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textMuted,
              tabs: const [
                Tab(text: 'Sortiment'),
                Tab(text: 'Equipment'),
                Tab(text: 'Personal'),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _ProductsTab(shop: currentShop),
                _EquipmentTab(shop: currentShop, cash: game.cash),
                _EmployeesTab(shop: currentShop, cash: game.cash),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sortiment-Tab ──────────────────────────────────────────────────────────

class _ProductsTab extends ConsumerWidget {
  final Shop shop;
  const _ProductsTab({required this.shop});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final sp in shop.menu) ...[
          _ProductTile(shopId: shop.id, shopProduct: sp),
          const SizedBox(height: 8),
        ],
        // Gesperrte Produkte (brauchen Equipment)
        const SizedBox(height: 8),
        const Text(
          'WEITERE PRODUKTE',
          style: TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
              letterSpacing: 2,
              fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        for (final pd in kAllProducts.where(
          (p) => !shop.menu.any((sp) => sp.productId == p.id),
        )) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Text(pd.emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pd.name,
                          style: const TextStyle(
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w600)),
                      Text(
                        pd.requiredEquipmentId != null
                            ? 'Benötigt: ${kAllEquipment.firstWhere((e) => e.id == pd.requiredEquipmentId).name}'
                            : 'Nicht im Sortiment',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.lock_outline,
                    size: 16, color: AppColors.textMuted),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _ProductTile extends ConsumerStatefulWidget {
  final String shopId;
  final ShopProduct shopProduct;
  const _ProductTile({required this.shopId, required this.shopProduct});

  @override
  ConsumerState<_ProductTile> createState() => _ProductTileState();
}

class _ProductTileState extends ConsumerState<_ProductTile> {
  late double _price;
  late TextEditingController _textCtrl;
  final FocusNode _focus = FocusNode();

  // Sinnvolle Grenzen für die Texteingabe & den Slider
  double get _minPrice => 0.50;
  double get _maxPrice => 30.0;

  @override
  void initState() {
    super.initState();
    _price = widget.shopProduct.price;
    _textCtrl = TextEditingController(
      text: _price.toStringAsFixed(2).replaceAll('.', ','),
    );
    _focus.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (!_focus.hasFocus) {
      // Beim Verlassen des Felds: Eingabe validieren + speichern
      _commitTextField();
    }
  }

  void _commitTextField() {
    final raw = _textCtrl.text.trim().replaceAll(',', '.').replaceAll('€', '').trim();
    final parsed = double.tryParse(raw);
    if (parsed == null) {
      // Zurück auf gespeicherten Preis
      _resetTextField();
      return;
    }
    final clamped = parsed.clamp(_minPrice, _maxPrice);
    setState(() => _price = clamped);
    _resetTextField();
    ref
        .read(gameProvider.notifier)
        .updateProductPrice(widget.shopId, widget.shopProduct.productId, clamped);
  }

  void _resetTextField() {
    _textCtrl.text = _price.toStringAsFixed(2).replaceAll('.', ',');
  }

  @override
  void dispose() {
    _focus.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pd = kAllProducts.firstWhere((p) => p.id == widget.shopProduct.productId);
    final margin = _price - pd.ingredientCostPerUnit;
    final marginPct = pd.ingredientCostPerUnit > 0
        ? (margin / pd.ingredientCostPerUnit) * 100
        : 0.0;
    final demand =
        GameEngine.priceDemandFactor(price: _price, basePrice: pd.basePrice);
    final priceRatio = _price / pd.basePrice;

    // Demand-Stufen für Anzeige
    final (demandLabel, demandColor) = _demandStatus(demand, priceRatio);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // ── Kopfzeile: Emoji + Name + Marge ─────────────────────────────
          Row(
            children: [
              Text(pd.emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pd.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    Text(
                      'Basispreis ${_fmt.format(pd.basePrice)} €  ·  '
                      'Zutaten ${_fmt.format(pd.ingredientCostPerUnit)} €',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Marge ${_fmt.format(margin)} € (${marginPct.toStringAsFixed(0)}%)',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: margin > 0
                              ? AppColors.success
                              : AppColors.danger),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Preis-Eingabe (Text + Slider) ────────────────────────────────
          Row(
            children: [
              // Texteingabe mit Euro-Symbol
              SizedBox(
                width: 110,
                child: TextField(
                  controller: _textCtrl,
                  focusNode: _focus,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true, signed: false),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.gold,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                    suffixText: '€',
                    suffixStyle: const TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                    filled: true,
                    fillColor: AppColors.bg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                  onSubmitted: (_) => _commitTextField(),
                  onTapOutside: (_) => _focus.unfocus(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Slider(
                  value: _price.clamp(_minPrice, _maxPrice),
                  min: _minPrice,
                  max: _maxPrice,
                  divisions: 59, // 0,50€-Schritte
                  activeColor: AppColors.primary,
                  inactiveColor: AppColors.border,
                  onChanged: (v) {
                    setState(() {
                      _price = v;
                      _resetTextField();
                    });
                  },
                  onChangeEnd: (v) {
                    ref
                        .read(gameProvider.notifier)
                        .updateProductPrice(widget.shopId, pd.id, v);
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── Nachfrage-Indikator ───────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: demandColor.withAlpha(30),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: demandColor.withAlpha(80)),
            ),
            child: Row(
              children: [
                Icon(
                  demand >= 1.0
                      ? Icons.trending_up
                      : (demand >= 0.5
                          ? Icons.trending_flat
                          : Icons.trending_down),
                  size: 16,
                  color: demandColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    demandLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: demandColor,
                    ),
                  ),
                ),
                Text(
                  '${(demand * 100).round()}% Nachfrage',
                  style: TextStyle(
                      fontSize: 11,
                      color: demandColor,
                      fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Liefert (Beschreibung, Farbe) für einen gegebenen Demand-Wert.
  (String, Color) _demandStatus(double demand, double priceRatio) {
    if (priceRatio < 0.7) {
      return ('Sehr günstig — Marge leidet', AppColors.warning);
    } else if (priceRatio < 0.9) {
      return ('Günstig — viele Kunden', AppColors.success);
    } else if (priceRatio <= 1.1) {
      return ('Fair — guter Mix aus Kunden & Marge', AppColors.success);
    } else if (priceRatio <= 1.3) {
      return ('Etwas teuer — Kundenzahl sinkt', AppColors.warning);
    } else if (priceRatio <= 1.6) {
      return ('Teuer — viele Kunden gehen woanders hin', AppColors.warning);
    } else {
      return ('Wucher — kaum noch Kunden, Ruf leidet', AppColors.danger);
    }
  }
}

// ── Equipment-Tab ──────────────────────────────────────────────────────────

class _EquipmentTab extends ConsumerWidget {
  final Shop shop;
  final double cash;
  const _EquipmentTab({required this.shop, required this.cash});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = EquipmentCategory.values;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final cat in categories) ...[
          _EquipCategoryHeader(cat),
          const SizedBox(height: 8),
          for (final eq in kAllEquipment.where((e) => e.category == cat)) ...[
            _EquipmentCard(
              eq: eq,
              isOwned: shop.hasEquipment(eq.id),
              canAfford: cash >= eq.price,
              onBuy: () {
                if (cash < eq.price) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Nicht genug Kapital')),
                  );
                  return;
                }
                ref.read(gameProvider.notifier).buyEquipment(shop.id, eq);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('${eq.name} gekauft! ${eq.emoji}')),
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

// ── Personal-Tab ──────────────────────────────────────────────────────────

class _EmployeesTab extends ConsumerWidget {
  final Shop shop;
  final double cash;
  const _EmployeesTab({required this.shop, required this.cash});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final maxEmp = GameEngine.maxEmployeesForShop(shop);
    final atMax = shop.employees.length >= maxEmp;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Personal-Kapazitäts-Indikator ───────────────────────────────
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: atMax
                  ? AppColors.warning.withAlpha(80)
                  : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Icon(
                atMax ? Icons.groups_rounded : Icons.group_add_rounded,
                color: atMax ? AppColors.warning : AppColors.accent,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      atMax
                          ? 'Personal-Cap erreicht'
                          : 'Mitarbeiter ${shop.employees.length}/$maxEmp',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: atMax ? AppColors.warning : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      atMax
                          ? 'Diese Filiale hat Platz für maximal $maxEmp Personen. Eröffne neue Filialen für mehr Personal.'
                          : 'Noch ${maxEmp - shop.employees.length} freie Stelle${maxEmp - shop.employees.length == 1 ? "" : "n"}.',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              // Progress-Balken
              SizedBox(
                width: 60,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: shop.employees.length / maxEmp,
                    minHeight: 6,
                    backgroundColor: AppColors.bg,
                    color: atMax ? AppColors.warning : AppColors.accent,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Aktuelle Mitarbeiter
        if (shop.employees.isNotEmpty) ...[
          const Text(
            'AKTUELLE MITARBEITER',
            style: TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
                letterSpacing: 2,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          for (final emp in shop.employees) ...[
            _EmployeeCard(
              employee: emp,
              onFire: () {
                ref.read(gameProvider.notifier).fireEmployee(shop.id, emp.id);
              },
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 16),
        ],

        // Stellen ausschreiben
        const Text(
          'STELLENAUSSCHREIBUNG',
          style: TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
              letterSpacing: 2,
              fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        for (final type in kEmployeeTypes) ...[
          _HireCard(
            type: type,
            disabled: atMax,
            onPostJob: () {
              if (atMax) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Filiale voll besetzt ($maxEmp/$maxEmp). Eröffne neue Filiale.'),
                    backgroundColor: AppColors.warning,
                  ),
                );
                return;
              }
              _openCandidates(context, ref, type);
            },
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  void _openCandidates(
      BuildContext context, WidgetRef ref, EmployeeTypeData type) {
    // 3 Kandidaten generieren
    final candidates = List.generate(3, (i) {
      final name = _randomName();
      return EmployeeFactory.createCandidate(
        id: _uuid.v4(),
        type: type,
        name: name,
      );
    });

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _CandidatePicker(
        type: type,
        candidates: candidates,
        onPick: (cand) {
          Navigator.pop(ctx);
          ref.read(gameProvider.notifier).hireEmployee(shop.id, cand);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('${cand.name} eingestellt! ${type.emoji}')),
          );
        },
      ),
    );
  }

  String _randomName() {
    final all = [...kMaleNames, ...kFemaleNames];
    return all[_rng.nextInt(all.length)];
  }
}

// ── Kandidaten-Auswahl Bottom Sheet ───────────────────────────────────────

class _CandidatePicker extends StatelessWidget {
  final EmployeeTypeData type;
  final List<Employee> candidates;
  final void Function(Employee) onPick;

  const _CandidatePicker({
    required this.type,
    required this.candidates,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag-handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(type.emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bewerber für ${type.title}',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        )),
                    const Text('3 Kandidaten haben sich beworben',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        )),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (final c in candidates) ...[
            _CandidateCard(
              candidate: c,
              onPick: () => onPick(c),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _CandidateCard extends StatelessWidget {
  final Employee candidate;
  final VoidCallback onPick;

  const _CandidateCard({required this.candidate, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kopf: Name, Sterne, Gehalt
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withAlpha(140),
                      AppColors.primaryDark.withAlpha(120)
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    candidate.name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(candidate.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          fontSize: 15,
                        )),
                    Row(
                      children: [
                        for (int i = 0; i < 5; i++)
                          Icon(
                            i < candidate.starRating
                                ? Icons.star
                                : Icons.star_outline,
                            size: 12,
                            color: AppColors.gold,
                          ),
                        const SizedBox(width: 8),
                        Text(
                          _archetypeLabel(candidate),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${_fmt.format(candidate.salaryPerDay)} €',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.gold,
                    ),
                  ),
                  const Text('pro Tag',
                      style: TextStyle(
                          fontSize: 10, color: AppColors.textMuted)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Traits (4 horizontale Bars)
          _TraitBar(
              label: 'Geschwindigkeit',
              value: candidate.speed,
              icon: Icons.bolt,
              color: AppColors.warning),
          const SizedBox(height: 6),
          _TraitBar(
              label: 'Freundlichkeit',
              value: candidate.friendliness,
              icon: Icons.sentiment_very_satisfied,
              color: AppColors.accent),
          const SizedBox(height: 6),
          _TraitBar(
              label: 'Zuverlässigkeit',
              value: candidate.reliability,
              icon: Icons.verified_outlined,
              color: AppColors.cream),
          const SizedBox(height: 6),
          _TraitBar(
              label: 'Erfahrung',
              value: candidate.experience,
              icon: Icons.workspace_premium_outlined,
              color: AppColors.gold),

          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onPick,
              icon: const Icon(Icons.handshake_outlined, size: 18),
              label: const Text('Einstellen'),
            ),
          ),
        ],
      ),
    );
  }

  String _archetypeLabel(Employee e) {
    final avg = e.overallScore;
    if (avg >= 0.75) return 'Profi';
    if (avg >= 0.55) return 'Erfahren';
    if (avg >= 0.4) return 'Solide';
    return 'Anfänger';
  }
}

class _TraitBar extends StatelessWidget {
  final String label;
  final int value; // 1..10
  final IconData icon;
  final Color color;

  const _TraitBar({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 8),
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
                fontSize: 11, color: AppColors.textSecondary),
          ),
        ),
        Expanded(
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (value / 10).clamp(0.05, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 22,
          child: Text(
            '$value',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmployeeCard extends StatelessWidget {
  final Employee employee;
  final VoidCallback onFire;

  const _EmployeeCard({required this.employee, required this.onFire});

  @override
  Widget build(BuildContext context) {
    final type = kEmployeeTypes.firstWhere((t) => t.id == employee.typeId);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(type.emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(employee.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    Text(type.title,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                    Row(
                      children: [
                        for (int i = 0; i < 5; i++)
                          Icon(
                            i < employee.starRating
                                ? Icons.star
                                : Icons.star_outline,
                            size: 12,
                            color: AppColors.gold,
                          ),
                        const SizedBox(width: 6),
                        Text(
                          '${_fmt.format(employee.salaryPerDay)} €/Tag',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.person_remove_outlined,
                    color: AppColors.danger, size: 20),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: AppColors.bgCard,
                      title: Text('${employee.name} entlassen?'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Abbrechen')),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.danger),
                          onPressed: () {
                            Navigator.pop(ctx);
                            onFire();
                          },
                          child: const Text('Entlassen'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          // Trait-Mini-Anzeige
          const SizedBox(height: 10),
          Row(
            children: [
              _MiniTrait(icon: Icons.bolt, value: employee.speed, color: AppColors.warning),
              const SizedBox(width: 8),
              _MiniTrait(icon: Icons.sentiment_very_satisfied, value: employee.friendliness, color: AppColors.accent),
              const SizedBox(width: 8),
              _MiniTrait(icon: Icons.verified_outlined, value: employee.reliability, color: AppColors.cream),
              const SizedBox(width: 8),
              _MiniTrait(icon: Icons.workspace_premium_outlined, value: employee.experience, color: AppColors.gold),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniTrait extends StatelessWidget {
  final IconData icon;
  final int value;
  final Color color;
  const _MiniTrait({required this.icon, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              '$value',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HireCard extends StatelessWidget {
  final EmployeeTypeData type;
  final VoidCallback onPostJob;
  final bool disabled;

  const _HireCard({
    required this.type,
    required this.onPostJob,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.45 : 1.0,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Text(type.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(type.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  Text(type.description,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textMuted)),
                  Text(
                    'ab ${_fmt.format(type.baseSalaryPerDay)} €/Tag',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.secondary),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: onPostJob,
              icon: Icon(disabled ? Icons.block : Icons.search, size: 16),
              label: Text(disabled ? 'Voll' : 'Bewerber'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                textStyle: const TextStyle(fontSize: 13),
                backgroundColor:
                    disabled ? AppColors.bgSurface : null,
                foregroundColor:
                    disabled ? AppColors.textMuted : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
        Text(value,
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w800, color: color)),
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
