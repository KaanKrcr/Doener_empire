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
import '../core/constants.dart';
import 'competitor_engine.dart';
import 'corporate_engine.dart';

/// Zentrale Spiellogik. Reine statische Methoden ohne Seiteneffekte —
/// alles, was den Spielstand verändert, gibt ein neues [GameState] zurück.
class GameEngine {
  // ──────────────────────────────────────────────────────────────────────────
  // ── Tageseinnahmen für einen Shop berechnen ──────────────────────────────
  // ──────────────────────────────────────────────────────────────────────────

  static double calculateDailyRevenue(Shop shop, {int? day, GameState? state}) {
    final stats = calculateShopStats(shop, day: day, state: state);
    return stats.actualRevenue;
  }

  /// Vollständige Tages-Statistik in einem Rutsch: actual + potential + capacity.
  static ShopDayStats calculateShopStats(Shop shop, {int? day, GameState? state}) {
    if (!shop.isOpen || shop.menu.isEmpty) {
      return ShopDayStats.zero();
    }
    final activeMenu = shop.menu.where((p) => p.isActive).toList();
    if (activeMenu.isEmpty) return ShopDayStats.zero();

    final effectiveDay = day ?? shop.dayOpened;

    final reputationFactor = _reputationFactor(shop.reputation);
    final baseCustomers = shop.footTraffic * 0.06 * reputationFactor;
    final eqQuality = _equipmentQualityScore(shop);
    final staffMult = _staffQualityScore(shop);
    final capacity = _capacityLimit(shop);
    final variation = _dailyVariation(shop, effectiveDay);

    // Tageszeit-Profil (Mittelwert über den Öffnungszeiten + Wochentag)
    final timeProfile = shop.timeProfile;
    final weekday = effectiveDay % 7;
    final timeMult = timeProfile.dailyAverage(weekday);

    // Brand & City-Reputation (wenn State verfügbar)
    final brandMult = state?.brand.customerMultiplier(shop.cityId) ?? 1.0;
    // Konkurrenz-Druck
    final compPressure =
        state == null ? 1.0 : CompetitorEngine.competitionPressure(state, shop.cityId, shop.reputation);

    // Aktive Marketing-Kampagnen
    final campaignBoost = _activeCampaignBoost(shop, effectiveDay);
    final campaignAOV = _activeCampaignAvgOrderMod(shop, effectiveDay);

    // Permanente Upgrades (WLAN, Musik, etc.)
    final upgradeBoost = _upgradeCustomerBoost(shop);
    final upgradeAOV = _upgradeAvgOrderBoost(shop);

    double totalDemand = 0;
    double totalRevenue = 0;
    for (final sp in activeMenu) {
      final pd = _productData(sp.productId);
      if (pd == null) continue;
      final demand = priceDemandFactor(price: sp.price, basePrice: pd.basePrice);
      totalDemand += demand;
      totalRevenue += demand * sp.price * (1.0 + campaignAOV + upgradeAOV);
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
        (1.0 + campaignBoost + upgradeBoost);
    final actualCustomers = rawCustomers.clamp(0.0, capacity.toDouble());

    final actualRevenue = (actualCustomers * avgOrderValue).clamp(0.0, double.infinity);
    final potentialRevenue = (rawCustomers * avgOrderValue).clamp(0.0, double.infinity);

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

  static int recommendedExtraEmployees(Shop shop, {int? day, GameState? state}) {
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
        0, (s, shop) => s + calculateDailyCustomers(shop, day: state.currentDay, state: state));
  }

  // ──────────────────────────────────────────────────────────────────────────
  // ── Preiselastizität ─────────────────────────────────────────────────────
  // ──────────────────────────────────────────────────────────────────────────

  static double priceDemandFactor({
    required double price,
    required double basePrice,
  }) {
    if (price <= 0) return 0;
    final ratio = price / basePrice;

    if (ratio <= 1.0) {
      return (1.0 + (1.0 - ratio) * 0.4).clamp(0.6, 1.25);
    } else {
      final overshoot = ratio - 1.0;
      final demand = exp(-pow(overshoot * 1.6, 2));
      return demand.clamp(0.0, 1.0);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // ── Tageskosten für einen Shop ───────────────────────────────────────────
  // ──────────────────────────────────────────────────────────────────────────

  static double calculateDailyCosts(Shop shop, {int? day, GameState? state}) {
    if (shop.menu.isEmpty) return shop.dailyRent + _upgradeDailyCost(shop);
    final breakdown = calculateDailyCostsBreakdown(shop, day: day, state: state);
    return breakdown.total;
  }

  static ShopCostBreakdown calculateDailyCostsBreakdown(Shop shop,
      {int? day, GameState? state}) {
    final rent = shop.dailyRent;
    final salaries = shop.employees.fold(0.0, (s, e) => s + e.salaryPerDay);
    final upgrades = _upgradeDailyCost(shop);

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
    final ingredientSaving = (equipmentSaving + facilitySaving).clamp(0.0, 0.85);
    final activeMenu = shop.menu.where((p) => p.isActive).toList();
    final ingredientRatio = _weightedIngredientRatio(activeMenu);
    final ingredients = revenue * ingredientRatio * (1 - ingredientSaving);

    return ShopCostBreakdown(
        rent: rent,
        salaries: salaries,
        ingredients: ingredients,
        upgrades: upgrades);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // ── Tages-Abschluss ──────────────────────────────────────────────────────
  // ──────────────────────────────────────────────────────────────────────────

  static GameState processDay(GameState state) {
    final today = state.currentDay;
    double totalRevenue = 0;
    double totalRent = 0;
    double totalSalaries = 0;
    double totalIngredients = 0;
    int totalCustomers = 0;

    // Konkurrenz updaten
    final updatedCompetitors = CompetitorEngine.processDay(state);
    final stateWithComp = state.copyWith(competitors: updatedCompetitors);

    // Mitarbeiter altern + Erfahrung wachsen
    final updatedShops = stateWithComp.shops.map((shop) {
      final revenue = calculateDailyRevenue(shop, day: today, state: stateWithComp);
      final br = calculateDailyCostsBreakdown(shop, day: today, state: stateWithComp);
      final customers = calculateDailyCustomers(shop, day: today, state: stateWithComp);

      totalRevenue += revenue;
      totalRent += br.rent;
      totalSalaries += br.salaries;
      totalIngredients += br.ingredients;
      totalCustomers += customers;

      final newRep = _updateReputation(shop, stateWithComp);
      final updatedEmployees = shop.employees.map((emp) {
        final newDays = emp.daysEmployed + 1;
        // Erfahrungs-Wachstum: Alle 30 Tage +1 Erfahrung (max 10)
        final newExp = (newDays % 30 == 0 && emp.experience < 10)
            ? emp.experience + 1
            : emp.experience;
        return emp.copyWith(daysEmployed: newDays, experience: newExp);
      }).toList();

      // Abgelaufene Marketing-Kampagnen entfernen
      final activeNow = shop.activeCampaigns
          .where((c) => c.isActive(today + 1))
          .toList();

      return shop.copyWith(
        reputation: newRep,
        employees: updatedEmployees,
        activeCampaigns: activeNow,
      );
    }).toList();

    final totalCosts = totalRent + totalSalaries + totalIngredients;

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
      salaryCosts: totalSalaries,
      ingredientCosts: totalIngredients,
      loanPayments: loanPayments,
      investments: 0,
    );
    final history = [...stateWithComp.history, newRecord];
    final trimmedHistory = history.length > 60
        ? history.sublist(history.length - 60)
        : history;

    final newTotalRevenue = stateWithComp.totalRevenue + totalRevenue;
    final newUnlocked =
        _checkCityUnlocks(stateWithComp.unlockedCityIds, newTotalRevenue);

    // Brand & City-Reputation updaten
    final newBrand = _updateBrand(stateWithComp, totalRevenue, totalCustomers, updatedShops);

    // Corporate: Facilities verursachen Kosten + B2B-Umsatz
    final facilityCost = CorporateEngine.facilityDailyCosts(stateWithComp);
    final facilityRevenue =
        CorporateEngine.facilityB2BRevenue(stateWithComp);
    final facilityNet = facilityRevenue - facilityCost;

    // Stocks: Aktienkurs täglich updaten
    final updatedStocks = CorporateEngine.updateDailyPrice(stateWithComp);

    // Manager: Auto-Pricing + Auto-Hire
    var managerState = stateWithComp.copyWith(
      cash: newCash + facilityNet,
      currentDay: stateWithComp.currentDay + 1,
      shops: updatedShops,
      loans: activeLoans,
      totalRevenue: newTotalRevenue + facilityRevenue,
      totalProfit: stateWithComp.totalProfit + netCash + facilityNet,
      history: trimmedHistory,
      unlockedCityIds: newUnlocked,
      brand: newBrand,
      stocks: updatedStocks,
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

    // Awareness: +0.02 pro 100 Kunden/Tag + 0.005 pro 1000€ Umsatz
    var newAwareness = brand.brandAwareness +
        (dailyCustomers / 100) * 0.02 +
        (dailyRevenue / 1000) * 0.005;
    // Plus Upgrade-Boost (Premium-Inneneinrichtung, Loyalty-App)
    for (final shop in shops) {
      newAwareness += _upgradeBrandPerDay(shop);
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
      current = (current + delta).clamp(0.0, 100.0);
      newCityRep[cityId] = current;
    });

    return brand.copyWith(
      brandAwareness: newAwareness,
      cityReputation: newCityRep,
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // ── Stündlicher Tick ─────────────────────────────────────────────────────
  // ──────────────────────────────────────────────────────────────────────────

  static double calculateHourlyRevenue(GameState state) {
    return state.shops.fold(0.0, (sum, shop) {
      return sum +
          calculateDailyRevenue(shop, day: state.currentDay, state: state) / kDailyOpenHours;
    });
  }

  /// Stündliche Kosten = Tageskosten / Öffnungsstunden.
  /// Wird im Tick zusammen mit hourlyRevenue verrechnet, damit der Spieler
  /// auch laufend Kosten merkt (Realismus + verhindert Endlos-Cash-Farmen).
  static double calculateHourlyCosts(GameState state) {
    return state.shops.fold(0.0, (sum, shop) {
      return sum +
          calculateDailyCosts(shop, day: state.currentDay, state: state) / kDailyOpenHours;
    });
  }

  // ──────────────────────────────────────────────────────────────────────────
  // ── Spielaktionen ────────────────────────────────────────────────────────
  // ──────────────────────────────────────────────────────────────────────────

  static GameState openShop(GameState state, Shop shop) {
    final cost = shop.weeklyRent * 2;
    assert(state.cash >= cost, 'Nicht genug Geld für Kaution');

    final defaultProducts = kAllProducts
        .where((p) => p.isDefault)
        .map((p) => ShopProduct(productId: p.id, price: p.basePrice))
        .toList();

    final newShop = shop.copyWith(menu: defaultProducts);
    // Konkurrenz für die Stadt sicherstellen
    final newCompetitors = CompetitorEngine.ensureCompetitorsForCity(
      state.competitors,
      shop.cityId,
    );
    return _trackInvestment(state, cost).copyWith(
      cash: state.cash - cost,
      shops: [...state.shops, newShop],
      competitors: newCompetitors,
    );
  }

  /// Permanenten Upgrade kaufen (z.B. WLAN, Klimaanlage, Stammkunden-App)
  static GameState buyUpgrade(
      GameState state, String shopId, UpgradeData upgrade) {
    if (state.cash < upgrade.installCost) return state;
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
  static GameState bookCampaign(GameState state, String shopId, MarketingCampaign campaign) {
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
      final newRep = (shop.reputation + campaign.reputationBoostOnce).clamp(0.5, 5.0);
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
        final alreadyHas =
            updatedMenu.any((p) => p.productId == unlockId);
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
    final newPool = state.employeePool.where((e) => e.id != employee.id).toList();
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

  static double _equipmentQualityScore(Shop shop) {
    if (shop.equipment.isEmpty) return 0.5;
    double total = 1.0;
    for (final se in shop.equipment) {
      final eq = kAllEquipment.firstWhere((e) => e.id == se.equipmentId);
      total += eq.qualityBonus;
    }
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
    final hothead = shop.employees.any((e) => e.hasTrait(PersonalityTrait.hothead));
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
  static int _capacityLimit(Shop shop) {
    int cap = 20;
    for (final emp in shop.employees) {
      cap += (40 + 80 * emp.speedFactor).round();
      cap += (20 * emp.reliabilityFactor).round();
    }
    for (final se in shop.equipment) {
      final eq = kAllEquipment.firstWhere((e) => e.id == se.equipmentId);
      cap += eq.capacityBonus;
    }
    return cap;
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

  static double _upgradeCustomerBoost(Shop shop) {
    double boost = 0;
    for (final id in shop.upgradeIds) {
      final u = upgradeById(id);
      if (u != null) boost += u.customerBoost;
    }
    return boost;
  }

  static double _upgradeAvgOrderBoost(Shop shop) {
    double boost = 0;
    for (final id in shop.upgradeIds) {
      final u = upgradeById(id);
      if (u != null) boost += u.avgOrderValueBoost;
    }
    return boost;
  }

  static double _upgradeDailyCost(Shop shop) {
    double cost = 0;
    for (final id in shop.upgradeIds) {
      final u = upgradeById(id);
      if (u != null) cost += u.dailyCost;
    }
    return cost;
  }

  static double _upgradeReputationPerDay(Shop shop) {
    double v = 0;
    for (final id in shop.upgradeIds) {
      final u = upgradeById(id);
      if (u != null) v += u.reputationPerDay;
    }
    return v;
  }

  static double _upgradeBrandPerDay(Shop shop) {
    double v = 0;
    for (final id in shop.upgradeIds) {
      final u = upgradeById(id);
      if (u != null) v += u.brandPerDay;
    }
    return v;
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
      sumScore -= 0.03;
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

    // Permanente Upgrades (WLAN, Musik, etc.) — Reputations-Boost
    sumScore += _upgradeReputationPerDay(shop);

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
  const ShopCostBreakdown({
    required this.rent,
    required this.salaries,
    required this.ingredients,
    this.upgrades = 0,
  });
  double get total => rent + salaries + ingredients + upgrades;
}
