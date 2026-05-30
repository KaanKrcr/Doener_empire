import 'dart:math';

import '../models/shop_model.dart';
import '../models/game_state.dart';
import '../models/product_model.dart';
import '../models/equipment_model.dart';
import '../models/employee_model.dart';
import '../models/city_model.dart';
import '../models/brand_model.dart';
import '../models/marketing_model.dart';
import '../models/upgrade_model.dart';
import '../models/difficulty_model.dart';
import '../models/hr_manager_model.dart';
import '../models/campaign_model.dart';
import '../models/combo_model.dart';
import '../models/quality_model.dart';
import '../core/constants.dart';
import 'competitor_engine.dart';
import 'corporate_engine.dart';
import 'hr_engine.dart';

/// Zentrale Spiellogik. Reine statische Methoden ohne Seiteneffekte —
/// alles, was den Spielstand verändert, gibt ein neues [GameState] zurück.
class GameEngine {
  static const Map<String, double> _globalSpiessQualityBonus = {
    kGlobalSpiessBasicId: 0.15,
    kGlobalSpiessStandardId: 0.40,
    kGlobalSpiessProfiId: 0.80,
  };

  static const Map<String, int> _globalSpiessCapacityBonus = {
    kGlobalSpiessBasicId: 40,
    kGlobalSpiessStandardId: 100,
    kGlobalSpiessProfiId: 200,
  };

  // ──────────────────────────────────────────────────────────────────────────
  // ── Tageseinnahmen für einen Shop berechnen ──────────────────────────────
  // ──────────────────────────────────────────────────────────────────────────

  static double calculateDailyRevenue(Shop shop, {int? day, GameState? state}) {
    final stats = calculateShopStats(shop, day: day, state: state);
    return stats.actualRevenue;
  }

  /// Vollständige Tages-Statistik in einem Rutsch: actual + potential + capacity.
  static ShopDayStats calculateShopStats(Shop shop,
      {int? day, GameState? state}) {
    if (!shop.isOpen || shop.menu.isEmpty) {
      return ShopDayStats.zero();
    }
    final activeMenu = shop.menu.where((p) => p.isActive).toList();
    if (activeMenu.isEmpty) return ShopDayStats.zero();

    final effectiveDay = day ?? shop.dayOpened;

    final reputationFactor = _reputationFactor(shop.reputation);
    final baseCustomers = shop.footTraffic * 0.06 * reputationFactor;
    final eqQuality = _equipmentQualityScore(shop, state);
    final staffMult = _staffQualityScore(shop);
    final capacity = _capacityLimit(shop, state);
    final variation = _dailyVariation(shop, effectiveDay);

    // Tageszeit-Profil (Mittelwert über den Öffnungszeiten + Wochentag)
    final timeProfile = shop.timeProfile;
    final weekday = effectiveDay % 7;
    final timeMult = timeProfile.dailyAverage(weekday);

    // Brand & City-Reputation (wenn State verfügbar)
    final brandMult = state?.brand.customerMultiplier(shop.cityId) ?? 1.0;
    // Konkurrenz-Druck
    final compPressure = state == null
        ? 1.0
        : CompetitorEngine.competitionPressure(
            state, shop.cityId, shop.reputation);

    // Aktive Marketing-Kampagnen (Shop + Stadt + Konzern)
    final campaignBoost = _activeCampaignBoost(shop, effectiveDay) +
        _activeCityCampaignBoost(shop, effectiveDay, state) +
        _activeGlobalCampaignBoost(effectiveDay, state);
    final campaignAOV = _activeCampaignAvgOrderMod(shop, effectiveDay);

    // Permanente Upgrades (WLAN, Musik, etc.) — inkl. aktiver globaler Upgrades
    final upgradeBoost = _upgradeCustomerBoost(shop, state);
    final upgradeAOV = _upgradeAvgOrderBoost(shop, state);

    // Dauerhafte Story-Kampagnen-Perks (konzernweit)
    final perks = aggregateCampaignPerks(state?.completedChapterIds ?? const []);

    // Menü-Angebote/Kombos (nur wenn die Filiale die Produkte führt)
    final comboBoost = _comboCustomerBoost(shop, state);
    final comboAOV = _comboAvgOrderBoost(shop, state);

    // Tagesspecial: ein Produkt pro Tag mit erhöhter Nachfrage
    final specialId = dailySpecialProductId(effectiveDay);
    // Jahreszeit: kategorieabhängige Nachfrage
    final season = seasonForDay(effectiveDay);

    double totalDemand = 0;
    double totalRevenue = 0;
    for (final sp in activeMenu) {
      final pd = _productData(sp.productId);
      if (pd == null) continue;
      var demand = priceDemandFactor(
        price: sp.price,
        basePrice: pd.basePrice,
        difficulty: state?.difficulty ?? GameDifficulty.normal,
      );
      if (sp.productId == specialId) demand *= kDailySpecialBoost;
      demand *= seasonCategoryMultiplier(season, pd.category);
      totalDemand += demand;
      totalRevenue += demand *
          sp.price *
          (1.0 + campaignAOV + upgradeAOV + perks.avgOrderBoost + comboAOV);
    }
    final avgDemand = totalDemand / activeMenu.length;
    final avgOrderValue = totalDemand > 0 ? totalRevenue / totalDemand : 0;

    final rawCustomers = baseCustomers *
        eqQuality *
        staffMult *
        variation *
        avgDemand *
        timeMult *
        brandMult *
        compPressure *
        (1.0 + campaignBoost + upgradeBoost + perks.customerBoost + comboBoost);
    final actualCustomers = rawCustomers.clamp(0.0, capacity.toDouble());

    final actualRevenue =
        (actualCustomers * avgOrderValue).clamp(0.0, double.infinity);
    final potentialRevenue =
        (rawCustomers * avgOrderValue).clamp(0.0, double.infinity);

    return ShopDayStats(
      actualRevenue: actualRevenue,
      potentialRevenue: potentialRevenue,
      actualCustomers: actualCustomers.round(),
      potentialCustomers: rawCustomers.round(),
      capacity: capacity,
      avgOrderValue: avgOrderValue.toDouble(),
    );
  }

  /// Stunden-Verteilung über den Tag (14 Werte, je Stunde 10..23 Uhr).
  /// Wird vom Charts-Screen genutzt um die Tages-Heatmap zu zeichnen.
  static List<double> hourlyCustomerCurve(Shop shop, int day) {
    if (!shop.isOpen) return List<double>.filled(14, 0);
    final stats = calculateShopStats(shop, day: day);
    if (stats.actualCustomers == 0) return List<double>.filled(14, 0);

    final profile = shop.timeProfile;
    final weekday = day % 7;

    final hours = <double>[];
    double sum = 0;
    for (var h = 0; h < profile.hourlyFactors.length; h++) {
      final f = profile.factor(weekday: weekday, hourSlot: h);
      hours.add(f);
      sum += f;
    }
    // Skalieren: Summe ≙ actualCustomers
    final total = stats.actualCustomers;
    if (sum <= 0) return List<double>.filled(profile.hourlyFactors.length, 0);
    return hours.map((f) => f / sum * total).toList();
  }

  static int maxEmployeesForShop(Shop shop) {
    final city = kAllCities.firstWhere(
      (c) => c.id == shop.cityId,
      orElse: () => kAllCities.first,
    );
    switch (city.tier) {
      case CityTier.klein:
        return 3;
      case CityTier.mittel:
        return 5;
      case CityTier.gross:
        return 7;
      case CityTier.metropole:
        return 10;
    }
  }

  static bool isCapacityLimited(Shop shop, {int? day, GameState? state}) {
    final stats = calculateShopStats(shop, day: day, state: state);
    return stats.potentialRevenue > stats.actualRevenue * 1.05;
  }

  static int recommendedExtraEmployees(Shop shop,
      {int? day, GameState? state}) {
    final stats = calculateShopStats(shop, day: day, state: state);
    if (!isCapacityLimited(shop, day: day, state: state)) return 0;
    final maxEmp = maxEmployeesForShop(shop);
    final canAddMax = (maxEmp - shop.employees.length).clamp(0, 10);
    if (canAddMax == 0) return 0;
    final missingCapacity = stats.potentialCustomers - stats.capacity;
    final needed = (missingCapacity / 80).ceil().clamp(1, canAddMax);
    return needed;
  }

  static int calculateDailyCustomers(Shop shop, {int? day, GameState? state}) {
    final stats = calculateShopStats(shop, day: day, state: state);
    return stats.actualCustomers;
  }

  static int totalCustomersToday(GameState state) {
    return state.shops.fold(
        0,
        (s, shop) =>
            s +
            calculateDailyCustomers(shop, day: state.currentDay, state: state));
  }

  /// Konzernweite Produkt-Profitabilität (Schätzung auf Basis des aktuellen
  /// Nachfrage-Modells). Verteilt die Tageskunden je Shop anteilig nach der
  /// Preis-Nachfrage-Gewichtung auf die aktiven Produkte und summiert über
  /// alle Filialen. Zutaten-Ersparnisse wirken gleichmäßig und ändern das
  /// Ranking nicht, daher hier mit Brutto-Zutatenkosten gerechnet.
  static List<ProductProfit> productProfitBreakdown(GameState state) {
    final agg = <String, ProductProfit>{};
    for (final shop in state.shops) {
      final stats =
          calculateShopStats(shop, day: state.currentDay, state: state);
      final customers = stats.actualCustomers;
      if (customers <= 0) continue;

      final activeMenu = shop.menu.where((p) => p.isActive).toList();
      final weights = <String, double>{};
      double totalW = 0;
      for (final sp in activeMenu) {
        final pd = _productData(sp.productId);
        if (pd == null) continue;
        final w = priceDemandFactor(
          price: sp.price,
          basePrice: pd.basePrice,
          difficulty: state.difficulty,
        );
        weights[sp.productId] = w;
        totalW += w;
      }
      if (totalW <= 0) continue;

      for (final sp in activeMenu) {
        final pd = _productData(sp.productId);
        if (pd == null) continue;
        final w = weights[sp.productId] ?? 0;
        final units = customers * (w / totalW);
        final revenue = units * sp.price;
        final ingredientCost = units * pd.ingredientCostPerUnit;
        final entry = agg.putIfAbsent(
            sp.productId, () => ProductProfit(productId: sp.productId));
        entry.units += units;
        entry.revenue += revenue;
        entry.ingredientCost += ingredientCost;
      }
    }
    final list = agg.values.toList();
    list.sort((a, b) => b.profit.compareTo(a.profit));
    return list;
  }

  /// Das Produkt, das an einem bestimmten Tag „Tagesspecial" ist (rotiert
  /// deterministisch). Filialen, die es im Menü führen, profitieren von
  /// erhöhter Nachfrage auf dieses Gericht.
  static String dailySpecialProductId(int day) {
    if (kAllProducts.isEmpty) return '';
    return kAllProducts[day % kAllProducts.length].id;
  }

  /// Nachfrage-Multiplikator für das Tagesspecial.
  static const double kDailySpecialBoost = 1.6;

  // ── Jahreszeiten ──────────────────────────────────────────────────────────

  /// Aktuelle Jahreszeit (wechselt alle 30 Tage).
  static Season seasonForDay(int day) {
    final idx = ((day - 1) ~/ 30) % 4;
    return Season.values[idx.clamp(0, 3)];
  }

  /// Saisonaler Nachfrage-Multiplikator je Produktkategorie.
  static double seasonCategoryMultiplier(Season s, ProductCategory cat) {
    switch (s) {
      case Season.sommer:
        if (cat == ProductCategory.getraenk) return 1.25;
        if (cat == ProductCategory.doener) return 0.95;
        return 1.0;
      case Season.winter:
        if (cat == ProductCategory.doener) return 1.12;
        if (cat == ProductCategory.box) return 1.12;
        if (cat == ProductCategory.getraenk) return 0.85;
        return 1.0;
      case Season.fruehling:
        if (cat == ProductCategory.beilage) return 1.08;
        return 1.0;
      case Season.herbst:
        if (cat == ProductCategory.box) return 1.08;
        if (cat == ProductCategory.getraenk) return 1.05;
        return 1.0;
    }
  }

  /// Steuersatz auf den Monatsgewinn (alle 30 Tage fällig).
  static const double kMonthlyTaxRate = 0.12;

  // ── Daily Challenges ──────────────────────────────────────────────────────

  /// Die Tagesaufgabe für einen Tag (deterministisch, rotiert).
  static DailyChallenge dailyChallenge(int day) {
    const types = ChallengeType.values;
    final type = types[day % types.length];
    final reward = 500.0 + (day % 4) * 250.0; // 500..1250
    return DailyChallenge(type: type, reward: reward);
  }

  /// Prüft, ob die Tagesaufgabe erfüllt wurde.
  static bool isChallengeMet(
    DailyChallenge c, {
    required int customersToday,
    required double revenueToday,
    required double profitToday,
    required DailyRecord? yesterday,
    required bool anyShopLoss,
  }) {
    switch (c.type) {
      case ChallengeType.moreCustomers:
        return yesterday != null && customersToday > yesterday.customers;
      case ChallengeType.moreRevenue:
        return yesterday != null && revenueToday > yesterday.revenue;
      case ChallengeType.moreProfit:
        return yesterday != null && profitToday > yesterday.operatingProfit;
      case ChallengeType.allProfitable:
        return !anyShopLoss;
    }
  }

  /// Fällige Steuer auf den operativen Gewinn der letzten ~30 Tage.
  /// Nur auf positiven Gewinn — bei Verlust 0. Rein aus der History abgeleitet.
  static double monthlyTaxDue(GameState state) {
    final h = state.history;
    if (h.isEmpty) return 0;
    final window = h.length >= 30 ? h.sublist(h.length - 30) : h;
    final profit = window.fold<double>(0, (s, r) => s + r.operatingProfit);
    return profit > 0 ? profit * kMonthlyTaxRate : 0;
  }

  /// Wochenbilanz der letzten 7 abgeschlossenen Tage (inkl. Wachstum ggü.
  /// der Vorwoche). null, wenn noch keine volle Woche vorliegt.
  static WeeklyReport? buildWeeklyReport(GameState state) {
    final h = state.history;
    if (h.length < 7) return null;
    final last7 = h.sublist(h.length - 7);
    final prev7 = h.length >= 14 ? h.sublist(h.length - 14, h.length - 7) : const <DailyRecord>[];

    final revenue = last7.fold<double>(0, (s, r) => s + r.revenue);
    final profit = last7.fold<double>(0, (s, r) => s + r.operatingProfit);
    final customers = last7.fold<int>(0, (s, r) => s + r.customers);
    final best = last7.reduce((a, b) => a.revenue > b.revenue ? a : b);

    final prevProfit = prev7.fold<double>(0, (s, r) => s + r.operatingProfit);
    final growth = prevProfit.abs() > 0.01
        ? (profit - prevProfit) / prevProfit.abs() * 100
        : 0.0;

    return WeeklyReport(
      weekNumber: ((state.currentDay - 1) / 7).floor().clamp(1, 9999),
      revenue: revenue,
      profit: profit,
      customers: customers,
      bestDay: best.day,
      bestDayRevenue: best.revenue,
      profitGrowthPct: growth,
    );
  }

  /// Filialen nach geschätztem Tagesgewinn (Umsatz − Kosten), absteigend.
  static List<({Shop shop, double profit})> shopsByProfit(GameState state) {
    final list = state.shops.map((s) {
      final rev =
          calculateDailyRevenue(s, day: state.currentDay, state: state);
      final cost = calculateDailyCosts(s, day: state.currentDay, state: state);
      return (shop: s, profit: rev - cost);
    }).toList();
    list.sort((a, b) => b.profit.compareTo(a.profit));
    return list;
  }

  /// Geschätzter Marktanteil des Spielers in einer Stadt (0..1).
  /// = 1 − Summe der Konkurrenz-Marktanteile, sofern der Spieler dort vertreten
  /// ist. Ohne eigene Filiale 0.
  static double playerMarketShareIn(GameState state, String cityId) {
    if (!state.hasShopIn(cityId)) return 0;
    final compSum = state
        .competitorsIn(cityId)
        .fold<double>(0, (s, c) => s + c.marketShare);
    return (1 - compSum).clamp(0.0, 1.0);
  }

  /// Unternehmens-Gesundheit (0..100) aus Liquidität, Profitabilität,
  /// Verschuldung und Reputation. Rein abgeleitet.
  static HealthScore healthScore(GameState state) {
    if (state.shops.isEmpty) {
      return const HealthScore(score: 50, label: 'Neu gegründet');
    }
    double dailyCost = 0, dailyRev = 0;
    for (final shop in state.shops) {
      dailyRev +=
          calculateDailyRevenue(shop, day: state.currentDay, state: state);
      dailyCost +=
          calculateDailyCosts(shop, day: state.currentDay, state: state);
    }
    final dailyProfit = dailyRev - dailyCost;

    // Liquidität: Reichweite der Kasse in Tagen (0..14 → 0..1)
    final runway = dailyCost > 0 ? state.cash / dailyCost : 30.0;
    final liq = (runway / 14).clamp(0.0, 1.0);

    // Profitabilität: Tagesmarge (−10 % → 0, +30 % → 1)
    final margin = dailyRev > 0 ? dailyProfit / dailyRev : 0.0;
    final profScore = ((margin + 0.10) / 0.40).clamp(0.0, 1.0);

    // Verschuldung: Schulden im Verhältnis zur Kasse (weniger = besser)
    final debt = state.activeLoansTotal;
    final debtScore = state.cash > 0
        ? (1 - (debt / (state.cash + debt)).clamp(0.0, 1.0))
        : 0.0;

    // Reputation
    final avgRep = state.shops.fold<double>(0, (s, sh) => s + sh.reputation) /
        state.shops.length;
    final repScore = (avgRep / 5).clamp(0.0, 1.0);

    final score =
        (liq * 0.30 + profScore * 0.35 + debtScore * 0.15 + repScore * 0.20) *
            100;

    final label = score >= 80
        ? 'Exzellent'
        : score >= 62
            ? 'Stark'
            : score >= 45
                ? 'Solide'
                : score >= 28
                    ? 'Angeschlagen'
                    : 'Kritisch';
    return HealthScore(score: score.clamp(0, 100), label: label);
  }

  /// Aktuelle Hinweise/Warnungen für den Spieler (verlustreiche Filialen,
  /// schlechter Ruf, niedrige Liquidität). Rein abgeleitet — keine Seiteneffekte.
  static List<ShopAlert> shopAlerts(GameState state) {
    final alerts = <ShopAlert>[];
    double dailyCostTotal = 0;
    for (final shop in state.shops) {
      final rev =
          calculateDailyRevenue(shop, day: state.currentDay, state: state);
      final cost =
          calculateDailyCosts(shop, day: state.currentDay, state: state);
      dailyCostTotal += cost;
      if (rev - cost < 0) {
        alerts.add(ShopAlert(
          level: AlertLevel.danger,
          message:
              '${shop.displayName} macht Verlust (${(rev - cost).round()} €/Tag)',
          shopId: shop.id,
        ));
      } else if (shop.reputation < 2.0) {
        alerts.add(ShopAlert(
          level: AlertLevel.warn,
          message:
              '${shop.displayName}: schlechter Ruf (${shop.reputation.toStringAsFixed(1)} ⭐)',
          shopId: shop.id,
        ));
      }
    }
    if (state.cash >= 0 && dailyCostTotal > 0 && state.cash < dailyCostTotal * 2) {
      alerts.add(const ShopAlert(
        level: AlertLevel.warn,
        message: 'Liquidität niedrig — die Kasse reicht nur wenige Tage.',
      ));
    }
    return alerts;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // ── Preiselastizität ─────────────────────────────────────────────────────
  // ──────────────────────────────────────────────────────────────────────────

  static double priceDemandFactor({
    required double price,
    required double basePrice,
    GameDifficulty difficulty = GameDifficulty.normal,
  }) {
    if (price <= 0) return 0;
    final sensitivity = difficulty.modifiers.customerPriceSensitivityMultiplier;
    final ratio = price / basePrice;

    if (ratio <= 1.0) {
      final discountBoost = 0.4 / sensitivity;
      return (1.0 + (1.0 - ratio) * discountBoost).clamp(0.6, 1.25);
    } else {
      final overshoot = ratio - 1.0;
      final demand = exp(-pow(overshoot * 1.6 * sensitivity, 2));
      return demand.clamp(0.0, 1.0);
    }
  }

  /// Umsatzoptimaler Preis für ein Produkt: maximiert Nachfrage × Preis
  /// (numerischer Scan). Hilft dem Spieler bei der Preisfindung.
  static double revenueOptimalPrice(double basePrice,
      [GameDifficulty difficulty = GameDifficulty.normal]) {
    if (basePrice <= 0) return basePrice;
    double bestPrice = basePrice;
    double bestRev = -1;
    final step = basePrice * 0.02;
    for (double p = basePrice * 0.5; p <= basePrice * 2.0; p += step) {
      final d = priceDemandFactor(
          price: p, basePrice: basePrice, difficulty: difficulty);
      final rev = d * p;
      if (rev > bestRev) {
        bestRev = rev;
        bestPrice = p;
      }
    }
    return double.parse(bestPrice.clamp(0.5, 99.0).toStringAsFixed(2));
  }

  // ──────────────────────────────────────────────────────────────────────────
  // ── Tageskosten für einen Shop ───────────────────────────────────────────
  // ──────────────────────────────────────────────────────────────────────────

  static double calculateDailyCosts(Shop shop, {int? day, GameState? state}) {
    if (shop.menu.isEmpty) return shop.dailyRent + _upgradeDailyCost(shop);
    final breakdown =
        calculateDailyCostsBreakdown(shop, day: day, state: state);
    return breakdown.total;
  }

  static ShopCostBreakdown calculateDailyCostsBreakdown(Shop shop,
      {int? day, GameState? state}) {
    final pressure =
        state?.difficulty.modifiers.economicPressureMultiplier ?? 1.0;
    final perks = aggregateCampaignPerks(state?.completedChapterIds ?? const []);
    final rent = shop.dailyRent * pressure * (1 - perks.rentSaving);
    final salaries =
        shop.employees.fold(0.0, (s, e) => s + e.salaryPerDay) * pressure;
    final upgrades = _upgradeDailyCost(shop) * pressure;

    if (shop.menu.isEmpty) {
      return ShopCostBreakdown(
          rent: rent, salaries: salaries, ingredients: 0, upgrades: upgrades);
    }

    final revenue = calculateDailyRevenue(shop, day: day, state: state);
    final equipmentSaving = _ingredientSavingBonus(shop);
    // Eigene Lieferkette (Produktions-Anlagen) reduziert Zutatenkosten weiter
    final facilitySaving = state == null
        ? 0.0
        : CorporateEngine.facilitySavingForShop(state, shop);
    final ingredientSaving =
        (equipmentSaving + facilitySaving + perks.ingredientSaving)
            .clamp(0.0, 0.85);
    final activeMenu = shop.menu.where((p) => p.isActive).toList();
    final ingredientRatio = _weightedIngredientRatio(activeMenu);
    final qualityMult = _menuIngredientQualityMult(shop, state);
    final ingredients = revenue *
        ingredientRatio *
        (1 - ingredientSaving) *
        qualityMult *
        pressure;

    // Liefer-Provision (Lieferando etc.) — nie negativ, immer <= Umsatz
    final deliveryCommission = _deliveryCommissionCost(shop, revenue, state)
        .clamp(0.0, revenue * pressure);

    return ShopCostBreakdown(
        rent: rent,
        salaries: salaries,
        ingredients: ingredients,
        upgrades: upgrades,
        deliveryCommission: deliveryCommission);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // ── Tages-Abschluss ──────────────────────────────────────────────────────
  // ──────────────────────────────────────────────────────────────────────────

  static GameState processDay(GameState state) {
    final today = state.currentDay;
    final difficultyMods = state.difficulty.modifiers;
    double totalRevenue = 0;
    double totalRent = 0;
    double totalSalaries = 0;
    double totalIngredients = 0;
    double totalDeliveryCommission = 0;
    int totalCustomers = 0;

    // Konkurrenz updaten
    final updatedCompetitors = CompetitorEngine.processDay(state);
    final stateWithComp = state.copyWith(competitors: updatedCompetitors);

    // Mitarbeiter altern + Erfahrung wachsen
    final trainingGrowth = HrEngine.trainingGrowthMultiplier(stateWithComp);
    final updatedShops = stateWithComp.shops.map((shop) {
      final revenue =
          calculateDailyRevenue(shop, day: today, state: stateWithComp);
      final br =
          calculateDailyCostsBreakdown(shop, day: today, state: stateWithComp);
      final customers =
          calculateDailyCustomers(shop, day: today, state: stateWithComp);

      totalRevenue += revenue;
      totalRent += br.rent;
      totalSalaries += br.salaries;
      totalIngredients += br.ingredients;
      totalDeliveryCommission += br.deliveryCommission;
      totalCustomers += customers;

      final newRep = _updateReputation(shop, stateWithComp);
      final updatedEmployees = shop.employees.map((emp) {
        final newDays = emp.daysEmployed + 1;
        // Erfahrungs-Wachstum: difficulty-basiertes Intervall.
        final expInterval = HrEngine.xpIntervalDays(
          difficulty: stateWithComp.difficulty,
          trainingGrowthMultiplier: trainingGrowth,
          growthPotential: emp.growthPotential,
        );
        final newExp = (newDays % expInterval == 0 && emp.experience < 10)
            ? emp.experience + 1
            : emp.experience;
        return emp.copyWith(daysEmployed: newDays, experience: newExp);
      }).toList();

      // Abgelaufene Marketing-Kampagnen entfernen
      final activeNow =
          shop.activeCampaigns.where((c) => c.isActive(today + 1)).toList();

      return shop.copyWith(
        reputation: newRep,
        employees: updatedEmployees,
        activeCampaigns: activeNow,
      );
    }).toList();

    // Abgelaufene Stadt/Konzern-Kampagnen entfernen
    final cleanedCityCampaigns = stateWithComp.activeCityCampaigns.map(
      (cityId, list) => MapEntry(
        cityId,
        list.where((c) => c.isActive(today + 1)).toList(),
      ),
    );
    final cleanedGlobalCampaigns = stateWithComp.activeGlobalCampaigns
        .where((c) => c.isActive(today + 1))
        .toList();

    // Laufende Kosten globaler Konzern-Upgrades (einmal pro Tag, nicht pro Shop)
    final economicPressure = difficultyMods.economicPressureMultiplier;
    final hrDailySalary =
        (stateWithComp.hrManager?.salaryPerDay ?? 0) * economicPressure;
    final globalUpgradeCost =
        globalUpgradeDailyCost(stateWithComp) * economicPressure;
    final comboCost = activeComboDailyCost(stateWithComp) * economicPressure;
    final totalCosts = totalRent +
        totalSalaries +
        hrDailySalary +
        totalIngredients +
        totalDeliveryCommission +
        globalUpgradeCost +
        comboCost;

    // Kreditraten abziehen
    double loanPayments = 0;
    final updatedLoans = stateWithComp.loans.map((loan) {
      if (!loan.isPaidOff) {
        final payment = loan.dailyPayment;
        loan.amountPaid += payment;
        loanPayments += payment;
      }
      return loan;
    }).toList();
    final activeLoans = updatedLoans.where((l) => !l.isPaidOff).toList();

    final netCash = totalRevenue - totalCosts - loanPayments;
    final newCash = stateWithComp.cash + netCash;

    final newRecord = DailyRecord(
      day: stateWithComp.currentDay,
      revenue: totalRevenue,
      costs: totalCosts,
      customers: totalCustomers,
      rentCosts: totalRent,
      salaryCosts: totalSalaries + hrDailySalary,
      ingredientCosts: totalIngredients,
      deliveryCommissionCosts: totalDeliveryCommission,
      loanPayments: loanPayments,
      investments: 0,
    );
    final history = [...stateWithComp.history, newRecord];
    final trimmedHistory =
        history.length > 60 ? history.sublist(history.length - 60) : history;

    // Corporate: Facilities verursachen Kosten + B2B-Umsatz
    final facilityCost = CorporateEngine.facilityDailyCosts(stateWithComp);
    final facilityRevenue = CorporateEngine.facilityB2BRevenue(stateWithComp);
    final facilityNet = facilityRevenue - facilityCost;

    final progressRevenue = (totalRevenue + facilityRevenue) *
        difficultyMods.progressSpeedMultiplier;
    final newTotalRevenue = stateWithComp.totalRevenue + progressRevenue;
    final newUnlocked =
        _checkCityUnlocks(stateWithComp.unlockedCityIds, newTotalRevenue);

    // Brand & City-Reputation updaten
    final newBrand =
        _updateBrand(stateWithComp, totalRevenue, totalCustomers, updatedShops);

    // Stocks: Aktienkurs täglich updaten
    final updatedStocks = CorporateEngine.updateDailyPrice(stateWithComp);
    final updatedHrManager = _updateHrManagerProgress(
      stateWithComp,
      totalCustomers: totalCustomers,
    );

    // Manager: Auto-Pricing + Auto-Hire
    var managerState = stateWithComp.copyWith(
      cash: newCash + facilityNet,
      currentDay: stateWithComp.currentDay + 1,
      shops: updatedShops,
      loans: activeLoans,
      totalRevenue: newTotalRevenue,
      totalProfit: stateWithComp.totalProfit + netCash + facilityNet,
      history: trimmedHistory,
      unlockedCityIds: newUnlocked,
      brand: newBrand,
      stocks: updatedStocks,
      hrManager: updatedHrManager,
      activeCityCampaigns: cleanedCityCampaigns,
      activeGlobalCampaigns: cleanedGlobalCampaigns,
    );
    managerState = CorporateEngine.applyManagerAutoPricing(managerState);
    managerState = CorporateEngine.applyAutoHire(managerState);

    return managerState;
  }

  /// Brand-Update: Awareness wächst langsam mit Gesamt-Aktivität,
  /// City-Reputation wächst pro aktiver Filiale in der jeweiligen Stadt.
  static BrandStats _updateBrand(
    GameState state,
    double dailyRevenue,
    int dailyCustomers,
    List<Shop> shops,
  ) {
    final brand = state.brand;
    final progressSpeed = state.difficulty.modifiers.progressSpeedMultiplier;

    // Awareness: +0.02 pro 100 Kunden/Tag + 0.005 pro 1000€ Umsatz
    var newAwareness = brand.brandAwareness +
        ((dailyCustomers / 100) * 0.02 + (dailyRevenue / 1000) * 0.005) *
            progressSpeed;
    // Plus Upgrade-Boost (Premium-Inneneinrichtung, Loyalty-App, globale Upgrades)
    for (final shop in shops) {
      newAwareness += _upgradeBrandPerDay(shop, state);
    }
    // Marketing-Kampagnen brandAwarenessDelta
    final processedCities = <String>{};
    for (final shop in shops) {
      if (!processedCities.add(shop.cityId)) continue; // bereits gezählt
      for (final ac
          in (state.activeCityCampaigns[shop.cityId] ?? <ActiveCampaign>[])) {
        if (!ac.isActive(state.currentDay)) continue;
        final campaign = kAllMarketingCampaigns.firstWhere(
          (c) => c.id == ac.campaignId,
          orElse: () => kAllMarketingCampaigns.first,
        );
        newAwareness += campaign.brandAwarenessDelta;
      }
    }
    for (final ac in state.activeGlobalCampaigns) {
      if (!ac.isActive(state.currentDay)) continue;
      final campaign = kAllMarketingCampaigns.firstWhere(
        (c) => c.id == ac.campaignId,
        orElse: () => kAllMarketingCampaigns.first,
      );
      newAwareness += campaign.brandAwarenessDelta;
    }
    // Plateaut: je höher, desto langsamer wächst es weiter
    if (newAwareness > 30) {
      final overshoot = newAwareness - 30;
      newAwareness = 30 + overshoot * 0.4;
    }
    newAwareness = newAwareness.clamp(0.0, 100.0);

    // City-Reputation
    final newCityRep = Map<String, double>.from(brand.cityReputation);
    final shopsByCity = <String, List<Shop>>{};
    for (final s in shops) {
      shopsByCity.putIfAbsent(s.cityId, () => []).add(s);
    }
    shopsByCity.forEach((cityId, list) {
      var current = newCityRep[cityId] ?? 0;
      final avgRep = list.fold(0.0, (s, sh) => s + sh.reputation) / list.length;
      // höhere lokale Reputation = schneller bekannt
      var delta = (avgRep - 2.5) * 0.5;
      // pro Filiale ein kleiner Bonus
      delta += list.length * 0.2;
      delta *= progressSpeed;
      current = (current + delta).clamp(0.0, 100.0);
      newCityRep[cityId] = current;
    });

    return brand.copyWith(
      brandAwareness: newAwareness,
      cityReputation: newCityRep,
    );
  }

  static HrManager? _updateHrManagerProgress(
    GameState state, {
    required int totalCustomers,
  }) {
    final manager = state.hrManager;
    if (manager == null) return null;
    final xpGain = (4 + (totalCustomers / 130)).round().clamp(4, 30);
    final newXp = manager.xp + xpGain;
    final newLevel = (1 + (newXp / 120).floor()).clamp(1, 50);
    return manager.copyWith(level: newLevel, xp: newXp);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // ── Stündlicher Tick ─────────────────────────────────────────────────────
  // ──────────────────────────────────────────────────────────────────────────

  static double calculateHourlyRevenue(GameState state) {
    return state.shops.fold(0.0, (sum, shop) {
      return sum +
          calculateDailyRevenue(shop, day: state.currentDay, state: state) /
              kDailyOpenHours;
    });
  }

  /// Stündliche Kosten = Tageskosten / Öffnungsstunden.
  /// Wird im Tick zusammen mit hourlyRevenue verrechnet, damit der Spieler
  /// auch laufend Kosten merkt (Realismus + verhindert Endlos-Cash-Farmen).
  static double calculateHourlyCosts(GameState state) {
    final shopCosts = state.shops.fold(0.0, (sum, shop) {
      return sum +
          calculateDailyCosts(shop, day: state.currentDay, state: state) /
              kDailyOpenHours;
    });
    // Globale Upgrade- + Kombo-Kosten anteilig über den Tag verteilen
    final pressure = state.difficulty.modifiers.economicPressureMultiplier;
    final globalCosts =
        globalUpgradeDailyCost(state) * pressure / kDailyOpenHours;
    final comboCosts = activeComboDailyCost(state) * pressure / kDailyOpenHours;
    return shopCosts + globalCosts + comboCosts;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // ── Spielaktionen ────────────────────────────────────────────────────────
  // ──────────────────────────────────────────────────────────────────────────

  static GameState openShop(GameState state, Shop shop) {
    final cost = shop.weeklyRent * 2;
    assert(state.cash >= cost, 'Nicht genug Geld für Kaution');

    final defaultProducts = kAllProducts.where((p) => p.isDefault).map((p) {
      final cityP = state.cityPrices[shop.cityId] ?? {};
      final price = cityP[p.id] ?? state.globalPrices[p.id] ?? p.basePrice;
      return ShopProduct(productId: p.id, price: price);
    }).toList();

    final newShop = shop.copyWith(menu: defaultProducts);
    // Konkurrenz für die Stadt sicherstellen
    final newCompetitors = CompetitorEngine.ensureCompetitorsForCity(
      state.competitors,
      shop.cityId,
      state.difficulty,
    );
    return _trackInvestment(state, cost).copyWith(
      cash: state.cash - cost,
      shops: [...state.shops, newShop],
      competitors: newCompetitors,
    );
  }

  static bool canUnlockOwnDeliveryApp(GameState state) {
    final shopsWithDelivery =
        state.shops.where((s) => _hasDeliveryChannel(s, state)).length;
    return shopsWithDelivery >= 3;
  }

  /// Permanenten Upgrade kaufen.
  ///
  /// • scope == shop   → nur diese Filiale; shopId muss übergeben werden.
  /// • scope == global → konzernweit; shopId wird ignoriert, aber zur
  ///   Konsistenz weiterhin akzeptiert.
  static GameState buyUpgrade(
      GameState state, String shopId, UpgradeData upgrade) {
    // Legacy-Guard: frühe Versionen konnten `lieferdienst` pro Filiale kaufen.
    // In neuen Ständen ist es global. Alte UI-/Call-Pfade werden hier abgefangen.
    if (!upgrade.isGlobal && upgrade.id == 'lieferdienst') {
      final globalDelivery = upgradeById('lieferdienst');
      if (globalDelivery != null && globalDelivery.isGlobal) {
        return buyUpgrade(state, '', globalDelivery);
      }
    }

    if (state.cash < upgrade.installCost) return state;

    if (upgrade.isGlobal) {
      // Bereits vorhanden?
      if (state.globalUpgradeIds.contains(upgrade.id)) return state;
      if (upgrade.id == 'eigen_lieferdienst' &&
          !canUnlockOwnDeliveryApp(state)) {
        return state;
      }
      var newGlobalIds = [...state.globalUpgradeIds];
      if (kGlobalSpiessUpgradeOrder.contains(upgrade.id)) {
        newGlobalIds = newGlobalIds
            .where((id) => !kGlobalSpiessUpgradeOrder.contains(id))
            .toList();
      }
      newGlobalIds.add(upgrade.id);

      return _trackInvestment(state, upgrade.installCost).copyWith(
        cash: state.cash - upgrade.installCost,
        globalUpgradeIds: newGlobalIds,
      );
    }

    // Shop-Upgrade
    final newShops = state.shops.map((shop) {
      if (shop.id != shopId) return shop;
      if (shop.hasUpgrade(upgrade.id)) return shop;
      return shop.copyWith(upgradeIds: [...shop.upgradeIds, upgrade.id]);
    }).toList();
    return _trackInvestment(state, upgrade.installCost).copyWith(
      cash: state.cash - upgrade.installCost,
      shops: newShops,
    );
  }

  /// Marketing-Kampagne buchen
  static GameState bookCampaign(
      GameState state, String shopId, MarketingCampaign campaign) {
    if (state.cash < campaign.cost) return state;
    final today = state.currentDay;
    final newShops = state.shops.map((shop) {
      if (shop.id != shopId) return shop;
      final active = ActiveCampaign(
        campaignId: campaign.id,
        startDay: today,
        endDay: today + campaign.durationDays,
      );
      // Reputations-Boost direkt anwenden
      final newRep =
          (shop.reputation + campaign.reputationBoostOnce).clamp(0.5, 5.0);
      return shop.copyWith(
        activeCampaigns: [...shop.activeCampaigns, active],
        reputation: newRep,
      );
    }).toList();
    return _trackInvestment(state, campaign.cost).copyWith(
      cash: state.cash - campaign.cost,
      shops: newShops,
    );
  }

  /// Stadtweite Marketing-Kampagne buchen
  static GameState bookCityCampaign(
      GameState state, String cityId, MarketingCampaign campaign) {
    if (state.cash < campaign.cost) return state;
    final today = state.currentDay;
    final active = ActiveCampaign(
      campaignId: campaign.id,
      startDay: today,
      endDay: today + (campaign.durationDays > 0 ? campaign.durationDays : 1),
    );
    // Reputations-Boost einmalig auf alle Filialen der Stadt anwenden
    final newShops = state.shops.map((shop) {
      if (shop.cityId != cityId) return shop;
      final newRep =
          (shop.reputation + campaign.reputationBoostOnce).clamp(0.5, 5.0);
      return shop.copyWith(reputation: newRep);
    }).toList();
    // Kampagne in cityId-Bucket eintragen
    final newCityCampaigns =
        Map<String, List<ActiveCampaign>>.from(state.activeCityCampaigns);
    final bucket = List<ActiveCampaign>.from(newCityCampaigns[cityId] ?? []);
    bucket.add(active);
    newCityCampaigns[cityId] = bucket;
    return _trackInvestment(state, campaign.cost).copyWith(
      cash: state.cash - campaign.cost,
      shops: newShops,
      activeCityCampaigns: newCityCampaigns,
    );
  }

  /// Konzernweite Marketing-Kampagne buchen
  static GameState bookGlobalCampaign(
      GameState state, MarketingCampaign campaign) {
    if (state.cash < campaign.cost) return state;
    final today = state.currentDay;
    final active = ActiveCampaign(
      campaignId: campaign.id,
      startDay: today,
      endDay: today + (campaign.durationDays > 0 ? campaign.durationDays : 1),
    );
    // Einmalige Reputation für alle Filialen
    final newShops = state.shops.map((shop) {
      final newRep =
          (shop.reputation + campaign.reputationBoostOnce).clamp(0.5, 5.0);
      return shop.copyWith(reputation: newRep);
    }).toList();
    return _trackInvestment(state, campaign.cost).copyWith(
      cash: state.cash - campaign.cost,
      shops: newShops,
      activeGlobalCampaigns: [...state.activeGlobalCampaigns, active],
    );
  }

  /// Globalen Preis für ein Produkt setzen.
  /// Wirkt sofort auf alle Filialen ohne Stadtpreis-Überschreibung.
  static GameState setGlobalPrice(
      GameState state, String productId, double price) {
    final newGlobalPrices = Map<String, double>.from(state.globalPrices);
    newGlobalPrices[productId] = price;
    final newShops = state.shops.map((shop) {
      final cityP = state.cityPrices[shop.cityId] ?? {};
      if (cityP.containsKey(productId)) return shop; // city-Preis bleibt
      final updatedMenu = shop.menu.map((sp) {
        if (sp.productId != productId) return sp;
        return sp.copyWith(price: price);
      }).toList();
      return shop.copyWith(menu: updatedMenu);
    }).toList();
    return state.copyWith(globalPrices: newGlobalPrices, shops: newShops);
  }

  /// Stadtweisen Preis für ein Produkt setzen.
  /// Überschreibt den globalen Preis für alle Filialen in dieser Stadt.
  static GameState setCityPrice(
      GameState state, String cityId, String productId, double price) {
    final newCityPrices =
        Map<String, Map<String, double>>.from(state.cityPrices);
    final cityMap = Map<String, double>.from(newCityPrices[cityId] ?? {});
    cityMap[productId] = price;
    newCityPrices[cityId] = cityMap;
    final newShops = state.shops.map((shop) {
      if (shop.cityId != cityId) return shop;
      final updatedMenu = shop.menu.map((sp) {
        if (sp.productId != productId) return sp;
        return sp.copyWith(price: price);
      }).toList();
      return shop.copyWith(menu: updatedMenu);
    }).toList();
    return state.copyWith(cityPrices: newCityPrices, shops: newShops);
  }

  /// Preisstrategie konzernweit anwenden.
  /// 'cheap' → −15 %, 'normal' → Basispreis, 'premium' → +20 %
  /// Stadtpreisüberschreibungen bleiben unverändert.
  static GameState applyPriceStrategy(GameState state, String strategy) {
    const multipliers = {'cheap': 0.85, 'normal': 1.0, 'premium': 1.20};
    final mult = multipliers[strategy] ?? 1.0;
    final newGlobalPrices = <String, double>{};
    for (final p in kAllProducts) {
      newGlobalPrices[p.id] = p.basePrice * mult;
    }
    final newShops = state.shops.map((shop) {
      final cityP = state.cityPrices[shop.cityId] ?? {};
      final updatedMenu = shop.menu.map((sp) {
        if (cityP.containsKey(sp.productId)) return sp; // city-Preis bleibt
        final newPrice = newGlobalPrices[sp.productId];
        if (newPrice == null) return sp;
        return sp.copyWith(price: newPrice);
      }).toList();
      return shop.copyWith(menu: updatedMenu);
    }).toList();
    return state.copyWith(globalPrices: newGlobalPrices, shops: newShops);
  }

  static GameState takeLoan(GameState state, Loan loan) {
    return state.copyWith(
      cash: state.cash + loan.amount,
      loans: [...state.loans, loan],
    );
  }

  static GameState extraLoanPayment(
      GameState state, String loanId, double amount) {
    if (amount <= 0 || state.cash < amount) return state;

    final updated = state.loans.map((loan) {
      if (loan.id != loanId || loan.isPaidOff) return loan;
      final newPaid = loan.amountPaid + amount;
      loan.amountPaid = newPaid;
      return loan;
    }).toList();

    return state.copyWith(
      cash: state.cash - amount,
      loans: updated,
    );
  }

  static GameState payOffLoan(GameState state, String loanId) {
    final loan = state.loans.firstWhere((l) => l.id == loanId);
    if (loan.isPaidOff) return state;
    final payoff = loan.earlyPayoffAmount(state.currentDay);
    if (state.cash < payoff) return state;

    final updated = state.loans.map((l) {
      if (l.id != loanId) return l;
      l.amountPaid = l.totalRepayment;
      return l;
    }).toList();

    return state.copyWith(
      cash: state.cash - payoff,
      loans: updated,
    );
  }

  static GameState buyEquipment(
    GameState state,
    String shopId,
    EquipmentData equipment,
  ) {
    // Döner-Spieß wird zentral über Konzern-Upgrades gesteuert.
    if (equipment.category == EquipmentCategory.spiess) return state;

    assert(state.cash >= equipment.price);

    final updatedShops = state.shops.map((shop) {
      if (shop.id != shopId) return shop;
      final filtered = shop.equipment.where((e) {
        final existing =
            kAllEquipment.firstWhere((eq) => eq.id == e.equipmentId);
        return existing.category != equipment.category ||
            equipment.category == EquipmentCategory.sonstiges;
      }).toList();

      final newEquipment = [
        ...filtered,
        ShopEquipment(equipmentId: equipment.id)
      ];

      List<ShopProduct> updatedMenu = List.from(shop.menu);
      for (final unlockId in equipment.allUnlockedProducts) {
        final alreadyHas = updatedMenu.any((p) => p.productId == unlockId);
        if (alreadyHas) continue;
        final productData = kAllProducts.firstWhere(
          (p) => p.id == unlockId,
          orElse: () => kAllProducts.first,
        );
        updatedMenu.add(
          ShopProduct(productId: productData.id, price: productData.basePrice),
        );
      }

      return shop.copyWith(equipment: newEquipment, menu: updatedMenu);
    }).toList();

    return _trackInvestment(state, equipment.price).copyWith(
      cash: state.cash - equipment.price,
      shops: updatedShops,
    );
  }

  static GameState hireEmployee(
      GameState state, String shopId, Employee employee) {
    final updatedShops = state.shops.map((shop) {
      if (shop.id != shopId) return shop;
      if (shop.employees.length >= maxEmployeesForShop(shop)) {
        return shop;
      }
      // Influencer-Trait: Rep-Boost
      double newRep = shop.reputation;
      if (employee.hasTrait(PersonalityTrait.influencer)) {
        newRep = (newRep + 0.20).clamp(0.5, 5.0);
      }
      return shop.copyWith(
        employees: [...shop.employees, employee],
        reputation: newRep,
      );
    }).toList();
    // Aus Bewerber-Pool entfernen
    final newPool =
        state.employeePool.where((e) => e.id != employee.id).toList();
    return state.copyWith(shops: updatedShops, employeePool: newPool);
  }

  static GameState fireEmployee(
      GameState state, String shopId, String employeeId) {
    final updatedShops = state.shops.map((shop) {
      if (shop.id != shopId) return shop;
      return shop.copyWith(
        employees: shop.employees.where((e) => e.id != employeeId).toList(),
      );
    }).toList();
    return state.copyWith(shops: updatedShops);
  }

  static GameState updateProductPrice(
    GameState state,
    String shopId,
    String productId,
    double newPrice,
  ) {
    final updatedShops = state.shops.map((shop) {
      if (shop.id != shopId) return shop;
      final updatedMenu = shop.menu.map((p) {
        if (p.productId != productId) return p;
        return p.copyWith(price: newPrice);
      }).toList();
      return shop.copyWith(menu: updatedMenu);
    }).toList();
    return state.copyWith(shops: updatedShops);
  }

  static GameState unlockCity(GameState state, String cityId) {
    final cityData = kAllCities.firstWhere((c) => c.id == cityId);
    assert(state.cash >= cityData.unlockCost);
    return _trackInvestment(state, cityData.unlockCost).copyWith(
      cash: state.cash - cityData.unlockCost,
      unlockedCityIds: [...state.unlockedCityIds, cityId],
    );
  }

  static GameState _trackInvestment(GameState state, double amount) {
    final today = state.currentDay;
    final history = List<DailyRecord>.from(state.history);
    final idx = history.indexWhere((r) => r.day == today);
    if (idx >= 0) {
      final old = history[idx];
      history[idx] = DailyRecord(
        day: old.day,
        revenue: old.revenue,
        costs: old.costs,
        customers: old.customers,
        rentCosts: old.rentCosts,
        salaryCosts: old.salaryCosts,
        ingredientCosts: old.ingredientCosts,
        deliveryCommissionCosts: old.deliveryCommissionCosts,
        loanPayments: old.loanPayments,
        investments: old.investments + amount,
      );
    } else {
      history.add(DailyRecord(
        day: today,
        revenue: 0,
        costs: 0,
        investments: amount,
      ));
    }
    return state.copyWith(history: history);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // ── Helpers ──────────────────────────────────────────────────────────────
  // ──────────────────────────────────────────────────────────────────────────

  static ProductData? _productData(String id) {
    try {
      return kAllProducts.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  static double _equipmentQualityScore(Shop shop, [GameState? state]) {
    double total = shop.equipment.isEmpty ? 0.5 : 1.0;
    for (final se in shop.equipment) {
      final eq = kAllEquipment.firstWhere((e) => e.id == se.equipmentId);
      total += eq.qualityBonus;
    }
    total += _globalSpiessQualityFor(state);
    return total.clamp(0.5, 2.5);
  }

  /// Personal-Multiplikator basierend auf Traits + Persönlichkeit.
  static double _staffQualityScore(Shop shop) {
    if (shop.employees.isEmpty) return 0.55;
    double score = 0.7;
    // Mentor-Bonus aktivieren wenn ein Mentor anwesend ist
    final hasMentor =
        shop.employees.any((e) => e.hasTrait(PersonalityTrait.mentor));
    final teamBonus = hasMentor ? 1.05 : 1.0;
    // Hothead reduziert team bonus
    final hothead =
        shop.employees.any((e) => e.hasTrait(PersonalityTrait.hothead));
    final adjustedTeam = hothead ? teamBonus * 0.95 : teamBonus;

    for (final emp in shop.employees) {
      score += 0.18 * emp.qualityFactor * adjustedTeam;
      score += 0.08 * emp.friendlinessFactor;
    }
    return score.clamp(0.55, 2.4);
  }

  /// Kapazität: Personal + Equipment.
  /// Owner-Base auf 20 reduziert (vorher 40), damit Personal echt nötig ist
  /// und ein Shop ohne Mitarbeiter wirklich Verlust macht.
  static int _capacityLimit(Shop shop, [GameState? state]) {
    int cap = 20;
    for (final emp in shop.employees) {
      cap += (40 + 80 * emp.speedFactor).round();
      cap += (20 * emp.reliabilityFactor).round();
    }
    for (final se in shop.equipment) {
      final eq = kAllEquipment.firstWhere((e) => e.id == se.equipmentId);
      cap += eq.capacityBonus;
    }
    cap += _globalSpiessCapacityFor(state);
    return cap;
  }

  static String? _activeGlobalSpiessUpgradeId(GameState? state) {
    if (state == null) return null;
    for (final id in kGlobalSpiessUpgradeOrder.reversed) {
      if (state.globalUpgradeIds.contains(id)) return id;
    }
    return null;
  }

  static double _globalSpiessQualityFor(GameState? state) {
    final id = _activeGlobalSpiessUpgradeId(state);
    if (id == null) return 0;
    return _globalSpiessQualityBonus[id] ?? 0;
  }

  static int _globalSpiessCapacityFor(GameState? state) {
    final id = _activeGlobalSpiessUpgradeId(state);
    if (id == null) return 0;
    return _globalSpiessCapacityBonus[id] ?? 0;
  }

  static double _ingredientSavingBonus(Shop shop) {
    return shop.equipment.fold(0.0, (sum, se) {
      final eq = kAllEquipment.firstWhere((e) => e.id == se.equipmentId);
      return sum + eq.ingredientSavingBonus;
    });
  }

  static double _weightedIngredientRatio(List<ShopProduct> active) {
    if (active.isEmpty) return 0.35;
    double total = 0;
    int n = 0;
    for (final sp in active) {
      final pd = _productData(sp.productId);
      if (pd == null) continue;
      if (sp.price <= 0) continue;
      total += (pd.ingredientCostPerUnit / sp.price).clamp(0.05, 0.9);
      n++;
    }
    return n == 0 ? 0.35 : total / n;
  }

  static double _reputationFactor(double rep) {
    return (0.4 + (rep / 5.0) * 1.0).clamp(0.4, 1.4);
  }

  // ── Upgrade-Helpers ──────────────────────────────────────────────────────

  /// Effektive Upgrade-IDs: Shop-eigene + aktive globale Konzern-Upgrades.
  /// Verhindert Doppelzählung bei Saves, die loyalty_app noch pro Shop hatten.
  static List<String> _effectiveUpgradeIds(Shop shop, GameState? state) {
    final ids = <String>{...shop.upgradeIds};
    if (state != null) {
      ids.addAll(state.globalUpgradeIds);
    }
    return ids.toList();
  }

  static double _upgradeCustomerBoost(Shop shop, [GameState? state]) {
    double boost = 0;
    for (final id in _effectiveUpgradeIds(shop, state)) {
      final u = upgradeById(id);
      if (u != null) boost += u.customerBoost;
    }
    return boost;
  }

  static double _upgradeAvgOrderBoost(Shop shop, [GameState? state]) {
    double boost = 0;
    for (final id in _effectiveUpgradeIds(shop, state)) {
      final u = upgradeById(id);
      if (u != null) boost += u.avgOrderValueBoost;
    }
    return boost;
  }

  /// Tägliche Laufkosten der Upgrades.
  /// Globale Upgrades werden nur EINMAL für den ganzen Konzern gezählt
  /// (in calculateHourlyCosts / processDay), nicht pro Filiale.
  static double _upgradeDailyCost(Shop shop) {
    double cost = 0;
    for (final id in shop.upgradeIds) {
      final u = upgradeById(id);
      if (u != null && !u.isGlobal) cost += u.dailyCost;
    }
    return cost;
  }

  /// Tägliche Laufkosten aller globalen Upgrades (einmalig, konzernweit).
  static double globalUpgradeDailyCost(GameState state) {
    double cost = 0;
    for (final id in state.globalUpgradeIds) {
      final u = upgradeById(id);
      if (u != null) cost += u.dailyCost;
    }
    return cost;
  }

  // ── Menü-Angebote / Kombos ────────────────────────────────────────────────

  /// Führt die Filiale alle Produkte eines Kombos (aktiv im Menü)?
  static bool shopSupportsCombo(Shop shop, MenuCombo combo) {
    final active =
        shop.menu.where((p) => p.isActive).map((p) => p.productId).toSet();
    return combo.productIds.every(active.contains);
  }

  /// Aktive Kombos, die in dieser Filiale auch wirklich greifen.
  static List<MenuCombo> _effectiveCombos(Shop shop, GameState? state) {
    if (state == null) return const [];
    final out = <MenuCombo>[];
    for (final id in state.activeComboIds) {
      final c = comboById(id);
      if (c != null && shopSupportsCombo(shop, c)) out.add(c);
    }
    return out;
  }

  static double _comboCustomerBoost(Shop shop, GameState? state) {
    double b = 0;
    for (final c in _effectiveCombos(shop, state)) {
      b += c.customerBoost;
    }
    return b;
  }

  static double _comboAvgOrderBoost(Shop shop, GameState? state) {
    double b = 0;
    for (final c in _effectiveCombos(shop, state)) {
      b += c.avgOrderBoost;
    }
    return b;
  }

  static double _comboReputationPerDay(Shop shop, GameState? state) {
    double v = 0;
    for (final c in _effectiveCombos(shop, state)) {
      v += c.reputationPerDay;
    }
    return v;
  }

  /// Konzernweite Tagespauschale aller aktiven Kombos (einmalig).
  static double activeComboDailyCost(GameState state) {
    double cost = 0;
    for (final id in state.activeComboIds) {
      final c = comboById(id);
      if (c != null) cost += c.dailyCost;
    }
    return cost;
  }

  // ── Zutaten-Qualität ──────────────────────────────────────────────────────

  static IngredientQuality productQualityOf(GameState? state, String productId) {
    if (state == null) return IngredientQuality.standard;
    return ingredientQualityFromName(state.productQuality[productId]);
  }

  /// Durchschnittlicher Zutatenkosten-Multiplikator über die aktiven Produkte.
  static double _menuIngredientQualityMult(Shop shop, GameState? state) {
    final active = shop.menu.where((p) => p.isActive).toList();
    if (active.isEmpty || state == null) return 1.0;
    double sum = 0;
    for (final sp in active) {
      sum += productQualityOf(state, sp.productId).ingredientMult;
    }
    return sum / active.length;
  }

  /// Durchschnittlicher Reputations-Beitrag der Qualitätsniveaus.
  static double _menuQualityReputation(Shop shop, GameState? state) {
    final active = shop.menu.where((p) => p.isActive).toList();
    if (active.isEmpty || state == null) return 0.0;
    double sum = 0;
    for (final sp in active) {
      sum += productQualityOf(state, sp.productId).reputationPerDay;
    }
    return sum / active.length;
  }

  static double _upgradeReputationPerDay(Shop shop, [GameState? state]) {
    double v = 0;
    for (final id in _effectiveUpgradeIds(shop, state)) {
      final u = upgradeById(id);
      if (u != null) v += u.reputationPerDay;
    }
    return v;
  }

  static double _upgradeBrandPerDay(Shop shop, [GameState? state]) {
    double v = 0;
    for (final id in _effectiveUpgradeIds(shop, state)) {
      final u = upgradeById(id);
      if (u != null) v += u.brandPerDay;
    }
    return v;
  }

  /// Tägliche Liefer-Provision für einen Shop.
  /// = revenue × deliveryRevenueFraction × effectiveCommissionRate
  ///
  /// Wenn das globale Upgrade [eigen_lieferdienst] aktiv ist, sinkt die
  /// Provision auf 8 % statt der Plattform-Rate.
  static double _deliveryCommissionCost(
      Shop shop, double revenue, GameState? state) {
    double cost = 0;
    final hasOwnApp =
        state?.globalUpgradeIds.contains('eigen_lieferdienst') ?? false;
    for (final id in _effectiveUpgradeIds(shop, state)) {
      final u = upgradeById(id);
      if (u == null || !u.isDelivery) continue;
      final rate = hasOwnApp ? 0.08 : u.deliveryCommissionRate;
      cost += revenue * u.deliveryRevenueFraction * rate;
    }
    return cost;
  }

  static bool _hasDeliveryChannel(Shop shop, GameState? state) {
    for (final id in _effectiveUpgradeIds(shop, state)) {
      final u = upgradeById(id);
      if (u != null && u.isDelivery) return true;
    }
    return false;
  }

  /// Aktive Kampagnen-Boost auf Kundenzahl (additiv).
  static double _activeCampaignBoost(Shop shop, int day) {
    double boost = 0;
    for (final ac in shop.activeCampaigns) {
      if (!ac.isActive(day)) continue;
      final campaign = kAllCampaigns.firstWhere(
        (c) => c.id == ac.campaignId,
        orElse: () => kAllCampaigns.first,
      );
      boost += campaign.customerBoost;
    }
    return boost;
  }

  /// Aktive Kampagnen-Mod auf Average Order Value (z.B. -0.40 für 2-für-1).
  static double _activeCampaignAvgOrderMod(Shop shop, int day) {
    double mod = 0;
    for (final ac in shop.activeCampaigns) {
      if (!ac.isActive(day)) continue;
      final campaign = kAllCampaigns.firstWhere(
        (c) => c.id == ac.campaignId,
        orElse: () => kAllCampaigns.first,
      );
      mod += campaign.avgOrderValueMod;
    }
    return mod;
  }

  /// Aktive Stadt-Kampagnen-Boost auf Kundenzahl für diesen Shop.
  static double _activeCityCampaignBoost(Shop shop, int day, GameState? state) {
    if (state == null) return 0;
    final cityCampaigns = state.activeCityCampaigns[shop.cityId] ?? [];
    double boost = 0;
    for (final ac in cityCampaigns) {
      if (!ac.isActive(day)) continue;
      final campaign = kAllMarketingCampaigns.firstWhere(
        (c) => c.id == ac.campaignId,
        orElse: () => kAllMarketingCampaigns.first,
      );
      boost += campaign.customerBoost;
    }
    return boost;
  }

  /// Aktive Konzern-Kampagnen-Boost auf Kundenzahl (gilt für alle Filialen).
  static double _activeGlobalCampaignBoost(int day, GameState? state) {
    if (state == null) return 0;
    double boost = 0;
    for (final ac in state.activeGlobalCampaigns) {
      if (!ac.isActive(day)) continue;
      final campaign = kAllMarketingCampaigns.firstWhere(
        (c) => c.id == ac.campaignId,
        orElse: () => kAllMarketingCampaigns.first,
      );
      boost += campaign.customerBoost;
    }
    return boost;
  }

  static double _dailyVariation(Shop shop, int day) {
    final seed = shop.id.hashCode ^ (day * 2654435761);
    final rng = Random(seed);

    double avgReliability = 0.5;
    if (shop.employees.isNotEmpty) {
      final sum = shop.employees.fold(0.0, (s, e) => s + e.reliabilityFactor);
      avgReliability = sum / shop.employees.length;
    }
    final spread = 0.20 - avgReliability * 0.15;
    final noise = (1.0 - spread) + rng.nextDouble() * (2 * spread);
    return noise;
  }

  /// Reputations-Update pro Tag.
  static double _updateReputation(Shop shop, GameState state) {
    if (shop.menu.isEmpty) return shop.reputation;

    final penaltyMultiplier =
        state.difficulty.modifiers.reputationPenaltyMultiplier;
    double sumScore = 0;
    int n = 0;
    for (final sp in shop.menu.where((p) => p.isActive)) {
      final pd = _productData(sp.productId);
      if (pd == null) continue;
      final ratio = sp.price / pd.basePrice;
      double s;
      if (ratio <= 0.9) {
        s = 0.05;
      } else if (ratio <= 1.1) {
        s = 0.02;
      } else if (ratio <= 1.3) {
        s = -0.04;
      } else if (ratio <= 1.6) {
        s = -0.12;
      } else {
        s = -0.25;
      }
      if (s < 0) {
        s *= penaltyMultiplier;
      } else if (penaltyMultiplier > 1.0) {
        s /= sqrt(penaltyMultiplier);
      }
      sumScore += s;
      n++;
    }

    if (shop.employees.isNotEmpty) {
      final avgFriend =
          shop.employees.fold(0.0, (s, e) => s + e.friendlinessFactor) /
              shop.employees.length;
      sumScore += (avgFriend - 0.3) * 0.10;

      // Charmer: bonus
      final charmers = shop.employees
          .where((e) => e.hasTrait(PersonalityTrait.charmer))
          .length;
      sumScore += charmers * 0.03;
    } else {
      sumScore -= 0.03 * penaltyMultiplier;
    }

    // Aktive Kampagnen-Reputations-Boost
    for (final ac in shop.activeCampaigns) {
      if (!ac.isActive(state.currentDay)) continue;
      final campaign = kAllCampaigns.firstWhere(
        (c) => c.id == ac.campaignId,
        orElse: () => kAllCampaigns.first,
      );
      sumScore += campaign.reputationBoostPerDay;
    }
    // Aktive Stadt-Kampagnen-Reputations-Boost
    for (final ac
        in (state.activeCityCampaigns[shop.cityId] ?? <ActiveCampaign>[])) {
      if (!ac.isActive(state.currentDay)) continue;
      final campaign = kAllMarketingCampaigns.firstWhere(
        (c) => c.id == ac.campaignId,
        orElse: () => kAllMarketingCampaigns.first,
      );
      sumScore += campaign.reputationBoostPerDay;
    }
    // Aktive Konzern-Kampagnen-Reputations-Boost
    for (final ac in state.activeGlobalCampaigns) {
      if (!ac.isActive(state.currentDay)) continue;
      final campaign = kAllMarketingCampaigns.firstWhere(
        (c) => c.id == ac.campaignId,
        orElse: () => kAllMarketingCampaigns.first,
      );
      sumScore += campaign.reputationBoostPerDay;
    }

    // Permanente Upgrades (WLAN, Musik, etc.) — inkl. globale Konzern-Upgrades
    sumScore += _upgradeReputationPerDay(shop, state);

    // Menü-Angebote/Kombos (nur wo unterstützt)
    sumScore += _comboReputationPerDay(shop, state);

    // Zutaten-Qualität (Premium hebt, Günstig senkt die Reputation)
    sumScore += _menuQualityReputation(shop, state);

    if (n == 0) return shop.reputation;
    final delta = sumScore / n;
    return (shop.reputation + delta).clamp(0.5, 5.0);
  }

  static List<String> _checkCityUnlocks(
    List<String> current,
    double totalRevenue,
  ) {
    final newList = List<String>.from(current);
    for (final city in kAllCities) {
      if (!newList.contains(city.id) &&
          totalRevenue >= city.unlockCost &&
          city.unlockCost > 0) {
        newList.add(city.id);
      }
    }
    return newList;
  }
}

/// Hilfs-Struktur für die volle Tages-Statistik (actual + potential)
class ShopDayStats {
  final double actualRevenue;
  final double potentialRevenue;
  final int actualCustomers;
  final int potentialCustomers;
  final int capacity;
  final double avgOrderValue;

  const ShopDayStats({
    required this.actualRevenue,
    required this.potentialRevenue,
    required this.actualCustomers,
    required this.potentialCustomers,
    required this.capacity,
    required this.avgOrderValue,
  });

  factory ShopDayStats.zero() => const ShopDayStats(
        actualRevenue: 0,
        potentialRevenue: 0,
        actualCustomers: 0,
        potentialCustomers: 0,
        capacity: 0,
        avgOrderValue: 0,
      );

  double get lostRevenue => potentialRevenue - actualRevenue;

  double get utilization =>
      potentialCustomers == 0 ? 0 : actualCustomers / potentialCustomers;

  bool get isCapacityLimited => potentialRevenue > actualRevenue * 1.05;
}

/// Hilfs-Struktur für die Kostenaufschlüsselung pro Shop.
class ShopCostBreakdown {
  final double rent;
  final double salaries;
  final double ingredients;
  final double upgrades;

  /// Liefer-Provision (Lieferando etc.) — wird separat ausgewiesen,
  /// damit Umsatz niemals durch diesen Posten negativ wird.
  final double deliveryCommission;

  const ShopCostBreakdown({
    required this.rent,
    required this.salaries,
    required this.ingredients,
    this.upgrades = 0,
    this.deliveryCommission = 0,
  });

  double get total =>
      rent + salaries + ingredients + upgrades + deliveryCommission;
}

/// Geschätzte Tages-Profitabilität eines Produkts über alle Filialen.
class ProductProfit {
  final String productId;
  double units;
  double revenue;
  double ingredientCost;

  ProductProfit({
    required this.productId,
    this.units = 0,
    this.revenue = 0,
    this.ingredientCost = 0,
  });

  double get profit => revenue - ingredientCost;
  double get margin => revenue > 0 ? profit / revenue : 0;
}

/// Wochenbilanz-Zusammenfassung für den Wochen-Report.
class WeeklyReport {
  final int weekNumber;
  final double revenue;
  final double profit;
  final int customers;
  final int bestDay;
  final double bestDayRevenue;
  final double profitGrowthPct;

  const WeeklyReport({
    required this.weekNumber,
    required this.revenue,
    required this.profit,
    required this.customers,
    required this.bestDay,
    required this.bestDayRevenue,
    required this.profitGrowthPct,
  });
}

enum Season { fruehling, sommer, herbst, winter }

extension SeasonX on Season {
  String get label => switch (this) {
        Season.fruehling => 'Frühling',
        Season.sommer => 'Sommer',
        Season.herbst => 'Herbst',
        Season.winter => 'Winter',
      };
  String get emoji => switch (this) {
        Season.fruehling => '🌸',
        Season.sommer => '☀️',
        Season.herbst => '🍂',
        Season.winter => '❄️',
      };
}

enum ChallengeType { moreCustomers, moreRevenue, moreProfit, allProfitable }

/// Eine Tagesaufgabe (Daily Challenge).
class DailyChallenge {
  final ChallengeType type;
  final double reward;
  const DailyChallenge({required this.type, required this.reward});

  String get emoji => switch (type) {
        ChallengeType.moreCustomers => '👥',
        ChallengeType.moreRevenue => '💰',
        ChallengeType.moreProfit => '📈',
        ChallengeType.allProfitable => '✅',
      };

  String get label => switch (type) {
        ChallengeType.moreCustomers => 'Bediene heute mehr Kunden als gestern',
        ChallengeType.moreRevenue => 'Mach heute mehr Umsatz als gestern',
        ChallengeType.moreProfit => 'Mach heute mehr Gewinn als gestern',
        ChallengeType.allProfitable => 'Halte heute alle Filialen profitabel',
      };
}

/// Unternehmens-Gesundheit (0..100) mit Kurz-Label.
class HealthScore {
  final double score;
  final String label;
  const HealthScore({required this.score, required this.label});
}

enum AlertLevel { warn, danger }

/// Ein Hinweis/Warnung für den Spieler (Dashboard).
class ShopAlert {
  final AlertLevel level;
  final String message;
  final String? shopId;
  const ShopAlert({
    required this.level,
    required this.message,
    this.shopId,
  });
}
