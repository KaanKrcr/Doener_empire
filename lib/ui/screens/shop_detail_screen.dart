import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../models/shop_model.dart';
import '../../models/product_model.dart';
import '../../models/equipment_model.dart';
import '../../models/employee_model.dart';
import '../../models/marketing_model.dart';
import '../../models/upgrade_model.dart';
import '../../models/customer_segment_model.dart';
import '../../models/time_profile_model.dart';
import '../../providers/game_provider.dart';
import '../../services/game_engine.dart';
import '../../services/hr_engine.dart';
import '../widgets/premium_mobile_ui.dart';

part 'shop_detail/products_tab.dart';
part 'shop_detail/equipment_tab.dart';
part 'shop_detail/employees_tab.dart';
part 'shop_detail/marketing_tab.dart';
part 'shop_detail/upgrades_tab.dart';
part 'shop_detail/shared_widgets.dart';

final _fmt = NumberFormat('#,##0.00', 'de_DE');
final _fmtInt = NumberFormat('#,##0', 'de_DE');

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
    _tabs = TabController(length: 5, vsync: this);
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
    if (game == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
    final stats =
        GameEngine.calculateShopStats(currentShop, day: today, state: game);
    final revenue = stats.actualRevenue;
    final costs =
        GameEngine.calculateDailyCosts(currentShop, day: today, state: game);
    final profit = revenue - costs;
    final customers = stats.actualCustomers;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(currentShop.displayName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () {
            // Falls Stack vorhanden (z.B. von Dashboard via push), poppen.
            // Sonst sauber zurÃ¼ck zum MainScaffold.
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
          // â”€â”€ Auslastungs-Banner â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          if (stats.actualCustomers > 0)
            _CapacityBanner(
              stats: stats,
              shop: currentShop,
            ),
          if (currentShop.wasAcquired && currentShop.acquiredHint != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.secondary.withAlpha(70)),
                ),
                child: Text(
                  'Ãœbernommen Â· ${currentShop.acquiredHint}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          // â”€â”€ Shop-Stats Header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PremiumSectionLabel(text: 'FILIALE HEUTE'),
                const SizedBox(height: 6),
                PremiumMetricStrip(
                  items: [
                    PremiumMetricData(
                      label: 'UMSATZ/TAG',
                      value: '+${_fmt.format(revenue)} €',
                      color: AppColors.success,
                    ),
                    PremiumMetricData(
                      label: 'KOSTEN/TAG',
                      value: '-${_fmt.format(costs)} €',
                      color: AppColors.danger,
                    ),
                    PremiumMetricData(
                      label: 'PROFIT/TAG',
                      value:
                          '${profit >= 0 ? '+' : ''}${_fmt.format(profit)} €',
                      color: profit >= 0 ? AppColors.success : AppColors.danger,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                PremiumMetricStrip(
                  dense: true,
                  items: [
                    PremiumMetricData(
                      label: 'KUNDEN',
                      value: _fmtInt.format(customers),
                      color: AppColors.accent,
                    ),
                    PremiumMetricData(
                      label: 'RUF',
                      value: '${currentShop.reputation.toStringAsFixed(1)} / 5',
                      color: AppColors.gold,
                    ),
                    PremiumMetricData(
                      label: 'TAG',
                      value: _weekdayLabel(today),
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Tabs ───────────────────────────────────────────────────────
          _ShopExpansionCard(
            shop: currentShop,
            cash: game.cash,
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PremiumSectionLabel(text: 'BEREICHE'),
                const SizedBox(height: 6),
                Container(
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
                    isScrollable: true,
                    tabs: const [
                      Tab(text: 'Sortiment'),
                      Tab(text: 'Equipment'),
                      Tab(text: 'Personal'),
                      Tab(text: 'Marketing'),
                      Tab(text: 'Ausstattung'),
                    ],
                  ),
                ),
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
                _MarketingTab(
                    shop: currentShop, cash: game.cash, currentDay: today),
                _UpgradesTab(shop: currentShop, cash: game.cash),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
