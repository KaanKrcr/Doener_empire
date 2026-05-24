import 'dart:math';

import '../models/shop_model.dart';
import '../models/game_state.dart';
import '../models/product_model.dart';
import '../models/equipment_model.dart';
import '../models/employee_model.dart';
import '../models/city_model.dart';
import '../core/constants.dart';

/// Zentrale Spiellogik. Reine statische Methoden ohne Seiteneffekte —
/// alles, was den Spielstand verändert, gibt ein neues [GameState] zurück.
///
/// **Wichtig:** [calculateDailyRevenue] ist *deterministisch* für einen
/// gegebenen [Shop] + [day]. Damit bleibt die Anzeige im UI stabil
/// (kein "Umsatz/Tag flackert"), aber jeder Tag liefert ein anderes
/// Ergebnis — abhängig von Wochentag-Faktor + pseudo-zufälligem Daily-Noise.
class GameEngine {
  // ──────────────────────────────────────────────────────────────────────────
  // ── Tageseinnahmen für einen Shop berechnen ──────────────────────────────
  // ──────────────────────────────────────────────────────────────────────────

  static double calculateDailyRevenue(Shop shop, {int? day}) {
    final stats = calculateShopStats(shop, day: day);
    return stats.actualRevenue;
  }

  /// Vollständige Tages-Statistik in einem Rutsch: actual + potential + capacity.
  /// "Potenzial" = was ohne Kapazitäts-Engpass möglich wäre.
  static ShopDayStats calculateShopStats(Shop shop, {int? day}) {
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

    double totalDemand = 0;
    double totalRevenue = 0;
    for (final sp in activeMenu) {
      final pd = _productData(sp.productId);
      if (pd == null) continue;
      final demand = priceDemandFactor(price: sp.price, basePrice: pd.basePrice);
      totalDemand += demand;
      totalRevenue += demand * sp.price;
    }
    final avgDemand = totalDemand / activeMenu.length;
    final avgOrderValue = totalDemand > 0 ? totalRevenue / totalDemand : 0;

    final rawCustomers =
        baseCustomers * eqQuality * staffMult * variation * avgDemand;
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

  /// Maximale Mitarbeiter-Anzahl pro Filiale, abhängig vom Stadt-Tier.
  /// Verhindert "35 Mitarbeiter mit ewig steigendem Umsatz".
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

  /// Ist der Shop personal-mäßig am Anschlag?
  static bool isCapacityLimited(Shop shop, {int? day}) {
    final stats = calculateShopStats(shop, day: day);
    return stats.potentialRevenue > stats.actualRevenue * 1.05;
  }

  /// Empfohlene zusätzliche Mitarbeiter-Anzahl um Engpass zu beseitigen.
  /// Returns 0 wenn kein Engpass oder Cap erreicht.
  static int recommendedExtraEmployees(Shop shop, {int? day}) {
    final stats = calculateShopStats(shop, day: day);
    if (!isCapacityLimited(shop, day: day)) return 0;
    final maxEmp = maxEmployeesForShop(shop);
    final canAddMax = (maxEmp - shop.employees.length).clamp(0, 10);
    if (canAddMax == 0) return 0;
    // Ein durchschnittlicher Mitarbeiter bringt ~80 Kapazität
    final missingCapacity = stats.potentialCustomers - stats.capacity;
    final needed = (missingCapacity / 80).ceil().clamp(1, canAddMax);
    return needed;
  }

  static int calculateDailyCustomers(Shop shop, {int? day}) {
    if (!shop.isOpen || shop.menu.isEmpty) return 0;
    final activeMenu = shop.menu.where((p) => p.isActive).toList();
    if (activeMenu.isEmpty) return 0;

    final effectiveDay = day ?? shop.dayOpened;
    final reputationFactor = _reputationFactor(shop.reputation);
    final baseCustomers = shop.footTraffic * 0.06 * reputationFactor;
    final eqQuality = _equipmentQualityScore(shop);
    final staffMult = _staffQualityScore(shop);
    final capacity = _capacityLimit(shop);
    final variation = _dailyVariation(shop, effectiveDay);

    double totalDemand = 0;
    for (final sp in activeMenu) {
      final pd = _productData(sp.productId);
      if (pd == null) continue;
      totalDemand += priceDemandFactor(price: sp.price, basePrice: pd.basePrice);
    }
    final avgDemand = totalDemand / activeMenu.length;

    final raw = baseCustomers * eqQuality * staffMult * variation * avgDemand;
    return raw.clamp(0.0, capacity.toDouble()).round();
  }

  /// Wie viele Kunden über ALLE Filialen heute?
  static int totalCustomersToday(GameState state) {
    return state.shops.fold(
        0, (s, shop) => s + calculateDailyCustomers(shop, day: state.currentDay));
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

  static double calculateDailyCosts(Shop shop, {int? day}) {
    if (shop.menu.isEmpty) return shop.dailyRent;

    final breakdown = calculateDailyCostsBreakdown(shop, day: day);
    return breakdown.rent + breakdown.salaries + breakdown.ingredients;
  }

  static ShopCostBreakdown calculateDailyCostsBreakdown(Shop shop,
      {int? day}) {
    final rent = shop.dailyRent;
    final salaries = shop.employees.fold(0.0, (s, e) => s + e.salaryPerDay);

    if (shop.menu.isEmpty) {
      return ShopCostBreakdown(rent: rent, salaries: salaries, ingredients: 0);
    }

    final revenue = calculateDailyRevenue(shop, day: day);
    final ingredientSaving = _ingredientSavingBonus(shop);
    final activeMenu = shop.menu.where((p) => p.isActive).toList();
    final ingredientRatio = _weightedIngredientRatio(activeMenu);
    final ingredients = revenue * ingredientRatio * (1 - ingredientSaving);

    return ShopCostBreakdown(
        rent: rent, salaries: salaries, ingredients: ingredients);
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

    final updatedShops = state.shops.map((shop) {
      final revenue = calculateDailyRevenue(shop, day: today);
      final br = calculateDailyCostsBreakdown(shop, day: today);
      final customers = calculateDailyCustomers(shop, day: today);

      totalRevenue += revenue;
      totalRent += br.rent;
      totalSalaries += br.salaries;
      totalIngredients += br.ingredients;
      totalCustomers += customers;

      final newRep = _updateReputation(shop);
      return shop.copyWith(reputation: newRep);
    }).toList();

    final totalCosts = totalRent + totalSalaries + totalIngredients;

    // Kreditraten abziehen
    double loanPayments = 0;
    final updatedLoans = state.loans.map((loan) {
      if (!loan.isPaidOff) {
        final payment = loan.dailyPayment;
        loan.amountPaid += payment;
        loanPayments += payment;
      }
      return loan;
    }).toList();
    final activeLoans = updatedLoans.where((l) => !l.isPaidOff).toList();

    final netCash = totalRevenue - totalCosts - loanPayments;
    final newCash = state.cash + netCash;

    final newRecord = DailyRecord(
      day: state.currentDay,
      revenue: totalRevenue,
      costs: totalCosts,
      customers: totalCustomers,
      rentCosts: totalRent,
      salaryCosts: totalSalaries,
      ingredientCosts: totalIngredients,
      loanPayments: loanPayments,
      investments: 0, // wird beim Kauf/Aktion separat hochgezählt
    );
    final history = [...state.history, newRecord];
    // 60 Tage Verlauf halten (genug für 2-Monats-Trends)
    final trimmedHistory = history.length > 60
        ? history.sublist(history.length - 60)
        : history;

    final newTotalRevenue = state.totalRevenue + totalRevenue;
    final newUnlocked =
        _checkCityUnlocks(state.unlockedCityIds, newTotalRevenue);

    return state.copyWith(
      cash: newCash,
      currentDay: state.currentDay + 1,
      shops: updatedShops,
      loans: activeLoans,
      totalRevenue: newTotalRevenue,
      totalProfit: state.totalProfit + netCash,
      history: trimmedHistory,
      unlockedCityIds: newUnlocked,
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // ── Stündlicher Tick ─────────────────────────────────────────────────────
  // ──────────────────────────────────────────────────────────────────────────

  static double calculateHourlyRevenue(GameState state) {
    return state.shops.fold(0.0, (sum, shop) {
      return sum +
          calculateDailyRevenue(shop, day: state.currentDay) / kDailyOpenHours;
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
    return _trackInvestment(state, cost).copyWith(
      cash: state.cash - cost,
      shops: [...state.shops, newShop],
    );
  }

  static GameState takeLoan(GameState state, Loan loan) {
    return state.copyWith(
      cash: state.cash + loan.amount,
      loans: [...state.loans, loan],
    );
  }

  /// Sondertilgung — `amount` wird vom Cash abgezogen und auf [loanId]
  /// angerechnet. Wenn die Restschuld dadurch ≤ 0 ist, ist der Kredit getilgt.
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

  /// Vollständige Ablösung mit Zinsrabatt (siehe Loan.earlyPayoffAmount).
  static GameState payOffLoan(GameState state, String loanId) {
    final loan = state.loans.firstWhere((l) => l.id == loanId);
    if (loan.isPaidOff) return state;
    final payoff = loan.earlyPayoffAmount(state.currentDay);
    if (state.cash < payoff) return state;

    final updated = state.loans.map((l) {
      if (l.id != loanId) return l;
      l.amountPaid = l.totalRepayment; // markiert als komplett bezahlt
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

      List<ShopProduct> updatedMenu = shop.menu;
      if (equipment.unlocksProductId != null) {
        final alreadyHas =
            shop.menu.any((p) => p.productId == equipment.unlocksProductId);
        if (!alreadyHas) {
          final productData = kAllProducts
              .firstWhere((p) => p.id == equipment.unlocksProductId);
          updatedMenu = [
            ...shop.menu,
            ShopProduct(productId: productData.id, price: productData.basePrice)
          ];
        }
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
      // Cap-Check: nicht über Maximum
      if (shop.employees.length >= maxEmployeesForShop(shop)) {
        return shop; // Stillschweigend ignorieren — UI muss vorher prüfen
      }
      return shop.copyWith(employees: [...shop.employees, employee]);
    }).toList();
    return state.copyWith(shops: updatedShops);
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

  /// Helper: schreibt eine Investition in den heutigen DailyRecord
  /// (oder erzeugt einen, wenn der Tag noch keinen hat).
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

  /// Personal-Multiplikator basierend auf den neuen Traits.
  /// Speed → mehr Durchsatz, Experience → Qualität, Friendliness → Kunden mögen es
  static double _staffQualityScore(Shop shop) {
    if (shop.employees.isEmpty) return 0.55;
    double score = 0.7;
    for (final emp in shop.employees) {
      // Erfahrung treibt Qualität, Freundlichkeit bringt Sympathie-Bonus
      score += 0.18 * emp.qualityFactor;
      score += 0.08 * emp.friendlinessFactor;
    }
    return score.clamp(0.55, 2.4);
  }

  /// Kapazität: Personal + Equipment bestimmen wie viele Kunden bedient werden können.
  /// Speed-Trait wirkt direkt auf die Kapazität pro Mitarbeiter.
  static int _capacityLimit(Shop shop) {
    int cap = 40; // Besitzer-Basis
    for (final emp in shop.employees) {
      // Schnelle Mitarbeiter bedienen mehr Kunden
      cap += (40 + 80 * emp.speedFactor).round();
      // Zuverlässigkeit verhindert Kapazitäts-Einbußen durch "Pausen"
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

  /// Tages-Variation: Wochentag + Random-Noise.
  /// Zuverlässige Mitarbeiter REDUZIEREN die Schwankung (weniger Pannen-Tage).
  static double _dailyVariation(Shop shop, int day) {
    final weekday = day % 7;
    const weekdayFactors = <double>[
      0.85, 0.85, 0.95, 1.00, 1.20, 1.30, 1.05,
    ];
    final base = weekdayFactors[weekday];

    final seed = shop.id.hashCode ^ (day * 2654435761);
    final rng = Random(seed);

    // Average Reliability über alle Mitarbeiter (0..1)
    double avgReliability = 0.5; // ohne Personal: standard
    if (shop.employees.isNotEmpty) {
      final sum = shop.employees.fold(0.0, (s, e) => s + e.reliabilityFactor);
      avgReliability = sum / shop.employees.length;
    }
    // Reliability 0.5 → ±0.15  (Standard), Reliability 1.0 → ±0.05
    final spread = 0.20 - avgReliability * 0.15;
    final noise = (1.0 - spread) + rng.nextDouble() * (2 * spread);

    return base * noise;
  }

  /// Reputations-Update pro Tag basierend auf Preisniveau UND Personal-Freundlichkeit.
  static double _updateReputation(Shop shop) {
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

    // Freundlichkeits-Bonus: Mitarbeiter mit hoher Friendliness pushen Rep
    if (shop.employees.isNotEmpty) {
      final avgFriend =
          shop.employees.fold(0.0, (s, e) => s + e.friendlinessFactor) /
              shop.employees.length;
      // 0..0.08 zusätzlich pro Tag
      sumScore += (avgFriend - 0.3) * 0.10;
    } else {
      // Niemand da → Service leidet
      sumScore -= 0.03;
    }

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
  final double actualRevenue;       // Was wirklich rauskommt (Kapazitäts-limitiert)
  final double potentialRevenue;    // Was möglich wäre ohne Limit
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

  /// Verlorener Umsatz durch Kapazitäts-Engpass
  double get lostRevenue => potentialRevenue - actualRevenue;

  /// Auslastungs-Quote (0..1+) — > 0.95 = Engpass
  double get utilization =>
      potentialCustomers == 0 ? 0 : actualCustomers / potentialCustomers;

  bool get isCapacityLimited => potentialRevenue > actualRevenue * 1.05;
}

/// Hilfs-Struktur für die Kostenaufschlüsselung pro Shop.
class ShopCostBreakdown {
  final double rent;
  final double salaries;
  final double ingredients;
  const ShopCostBreakdown({
    required this.rent,
    required this.salaries,
    required this.ingredients,
  });
  double get total => rent + salaries + ingredients;
}
