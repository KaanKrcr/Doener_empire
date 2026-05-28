import 'dart:math';

import '../models/game_state.dart';
import '../models/stock_model.dart';
import '../models/production_model.dart';
import '../models/competitor_model.dart';
import '../models/shop_model.dart';
import '../models/product_model.dart';
import '../models/city_model.dart';
import '../models/employee_model.dart';
import '../models/difficulty_model.dart';
import '../core/constants.dart';
import 'game_engine.dart';
import 'hr_engine.dart';

/// Corporate-Level-Operationen: IPO, Aktienkurs, Produktions-Anlagen, M&A.
///
/// Ergänzt die normale GameEngine um die "Phase 4 / Coffee-Inc-Niveau"-Features.
class CorporateEngine {
  static final _rng = Random();

  // ── Stocks / IPO ────────────────────────────────────────────────────────

  /// Prüft ob IPO-Voraussetzungen erfüllt sind.
  static bool canDoIPO(GameState state) {
    if (state.stocks.isPublic) return false;
    return state.shops.length >= IPORequirements.minShops &&
        state.brand.brandAwareness >= IPORequirements.minBrandAwareness &&
        state.totalRevenue >= IPORequirements.minTotalRevenue;
  }

  /// Bewertung berechnen: Filialwert + Markenwert + Cashflow-Multiple
  static double estimateValuation(GameState state) {
    final shopValue = state.shops.length * 50000.0; // ~50k per Shop
    final brandValue = state.brand.brandAwareness * 2500.0;
    // Letztes Quartal extrapoliert als Cashflow
    final yearlyProfitEstimate = state.history.isEmpty
        ? 0.0
        : state.history.map((r) => r.profit).fold(0.0, (a, b) => a + b) *
            (365 / state.history.length);
    const pe = 10.0; // P/E ratio
    final cashflowValue =
        (yearlyProfitEstimate * pe).clamp(0.0, double.infinity);
    return shopValue + brandValue + cashflowValue;
  }

  /// Führt IPO durch.
  /// [percentToFloat] = wie viele % als Aktien ausgegeben werden (max 0.49)
  /// Returns neuer State + Cash-Erlös aus IPO.
  static GameState performIPO(GameState state, double percentToFloat) {
    if (!canDoIPO(state)) return state;
    final p = percentToFloat.clamp(0.10, 0.49);
    final valuation = estimateValuation(state);

    // Aktien-Stückelung: 1 Aktie = 10€ Initial-Wert (Standard)
    const initialSharePrice = 10.0;
    final totalShares = (valuation / initialSharePrice).round();
    final floatedShares = (totalShares * p).round();
    final playerShares = totalShares - floatedShares;

    // Cash-Erlös aus IPO = floatedShares * sharePrice (minus Bank-Gebühren 5%)
    final ipoProceeds = floatedShares * initialSharePrice * 0.95;

    return state.copyWith(
      cash: state.cash + ipoProceeds,
      stocks: state.stocks.copyWith(
        isPublic: true,
        ipoDay: state.currentDay,
        sharePrice: initialSharePrice,
        totalShares: totalShares,
        playerShares: playerShares,
        priceHistory: [initialSharePrice],
        lastQuarterDay: state.currentDay,
        analystExpectation: valuation * 0.02 / 4, // 2% Jahresgewinn-Erwartung
      ),
    );
  }

  /// Daily-Update für Aktienkurs (kleine Schwankungen).
  static StockState updateDailyPrice(GameState state) {
    final s = state.stocks;
    if (!s.isPublic) return s;

    // Basis: leichter Random-Walk
    final noise = (_rng.nextDouble() - 0.5) * 0.02;
    // Brand-Awareness als Faktor (stärkere Marke = Kursanstieg)
    final brandImpact = (state.brand.brandAwareness - 50) / 5000;
    // Shop-Count
    final shopImpact = (state.shops.length - 10) / 1000;

    final priceMove =
        (1.0 + noise + brandImpact + shopImpact).clamp(0.95, 1.05);
    final newPrice = (s.sharePrice * priceMove).clamp(0.01, double.infinity);

    final newHistory = [...s.priceHistory, newPrice];
    final trimmed = newHistory.length > 60
        ? newHistory.sublist(newHistory.length - 60)
        : newHistory;

    return s.copyWith(
      sharePrice: newPrice,
      priceHistory: trimmed,
    );
  }

  /// Ist es Zeit für einen Quartalsbericht?
  static bool isQuarterDue(GameState state) {
    if (!state.stocks.isPublic) return false;
    return state.currentDay - state.stocks.lastQuarterDay >= 90;
  }

  /// Erzeugt Quartalsbericht UND aktualisiert Aktienkurs basierend auf
  /// Performance vs. Erwartung.
  static (StockState, QuarterlyReport) generateQuarterlyReport(
      GameState state) {
    final s = state.stocks;
    final quarterStart = s.lastQuarterDay;
    final quarterDays =
        state.history.where((r) => r.day >= quarterStart).toList();

    final qRevenue = quarterDays.fold(0.0, (a, r) => a + r.revenue);
    final qProfit = quarterDays.fold(0.0, (a, r) => a + r.profit);
    final qCustomers = quarterDays.fold(0, (a, r) => a + r.customers);

    final delta = qProfit - s.analystExpectation;
    final deltaPercent = s.analystExpectation == 0
        ? 0.0
        : (delta / s.analystExpectation.abs()).clamp(-0.50, 0.50);

    // Aktienkurs reagiert auf Ergebnis ±30%
    final priceMove = 1.0 + deltaPercent * 0.6;
    final newPrice = (s.sharePrice * priceMove).clamp(0.5, double.infinity);

    // Neue Analysten-Erwartung
    final newExpectation = (qProfit * 0.9 + s.analystExpectation * 0.1)
        .clamp(0.0, double.infinity);

    String headline;
    if (deltaPercent > 0.20) {
      headline = 'SENSATION! Döner Empire übertrifft Erwartungen massiv';
    } else if (deltaPercent > 0.05) {
      headline = 'Gewinn schlägt Analysten-Prognose';
    } else if (deltaPercent > -0.05) {
      headline = 'Solides Quartal - im Rahmen der Erwartungen';
    } else if (deltaPercent > -0.20) {
      headline = 'Aktie unter Druck - Quartal enttäuschend';
    } else {
      headline = 'KURSEINBRUCH! Massive Gewinnwarnung';
    }

    final report = QuarterlyReport(
      day: state.currentDay,
      revenue: qRevenue,
      profit: qProfit,
      customers: qCustomers,
      shopsAtStart: state.shops.length, // Vereinfachung
      shopsAtEnd: state.shops.length,
      brandAwarenessChange: 0,
      expectation: s.analystExpectation,
      priceMovePercent: (priceMove - 1) * 100,
      headline: headline,
    );

    final updatedStocks = s.copyWith(
      sharePrice: newPrice,
      lastQuarterProfit: qProfit,
      analystExpectation: newExpectation,
      lastQuarterDay: state.currentDay,
    );

    return (updatedStocks, report);
  }

  // ── Production-Facilities ──────────────────────────────────────────────

  /// Baut eine Anlage. Returns neuer State.
  static GameState buildFacility(GameState state, FacilityTemplate template) {
    if (state.cash < template.buildCost) return state;
    final facility = ProductionFacility(
      id: 'fac_${DateTime.now().microsecondsSinceEpoch}',
      type: template.type,
      tier: template.tier,
      dayBuilt: state.currentDay,
    );
    return state.copyWith(
      cash: state.cash - template.buildCost,
      facilities: [...state.facilities, facility],
    );
  }

  /// Tageskosten der Anlagen (Betrieb)
  static double facilityDailyCosts(GameState state) {
    double total = 0;
    for (final f in state.facilities) {
      final template = kAllFacilityTemplates.firstWhere(
        (t) => t.type == f.type && t.tier == f.tier,
        orElse: () => kAllFacilityTemplates.first,
      );
      total += template.dailyOperatingCost;
    }
    return total;
  }

  /// Tagesumsatz aus B2B-Sales (an Konkurrenten verkauft)
  static double facilityB2BRevenue(GameState state) {
    double total = 0;
    for (final f in state.facilities) {
      final template = kAllFacilityTemplates.firstWhere(
        (t) => t.type == f.type && t.tier == f.tier,
        orElse: () => kAllFacilityTemplates.first,
      );
      // B2B-Effizienz hängt von Markt-Größe ab (Konkurrenz-Anzahl)
      final marketDemand = (state.competitors.length / 10.0).clamp(0.3, 1.5);
      total += template.b2bRevenuePerDay * marketDemand;
    }
    return total;
  }

  /// Zutaten-Saving für einen Shop durch die Facilities.
  /// Returns 0..0.7 (max 70% Zutaten-Ersparnis durch eigene Lieferkette).
  static double facilitySavingForShop(GameState state, Shop shop) {
    if (state.facilities.isEmpty) return 0;

    // Pro Type bester Tier
    final bestPerType = <ProductionType, FacilityTier>{};
    for (final f in state.facilities) {
      final cur = bestPerType[f.type];
      if (cur == null || f.tier.index > cur.index) {
        bestPerType[f.type] = f.tier;
      }
    }

    // Kann diese Anlage diesen Shop überhaupt versorgen? (Tier-Cap)
    double totalSaving = 0;
    bestPerType.forEach((type, tier) {
      if (state.shops.length <= tier.maxShops) {
        totalSaving += type.costShareCovered * tier.ingredientSaving;
      } else {
        // Anteilig — wenn 20 Shops aber Tier nur für 15, dann 15/20 abgedeckt
        final coverage = tier.maxShops / state.shops.length;
        totalSaving += type.costShareCovered * tier.ingredientSaving * coverage;
      }
    });

    return totalSaving.clamp(0.0, 0.7);
  }

  // ── M&A — Konkurrenten aufkaufen ───────────────────────────────────────

  /// Akquisitionspreis für einen Konkurrenten
  static double acquisitionPrice(Competitor c) {
    // Basis: 60.000€ × Filialen × Reputations-Faktor
    final repFactor = (c.reputation / 3.0).clamp(0.7, 1.6);
    return c.shopCount * 60000 * repFactor;
  }

  /// Konkurrenten aufkaufen. Übernommen werden seine Filialen als
  /// (vereinfacht) Player-Shops mit Default-Werten.
  static GameState acquireCompetitor(GameState state, Competitor c) {
    final price = acquisitionPrice(c);
    if (state.cash < price) return state;

    // Erzeuge Player-Shops aus dem Konkurrenten
    final newShops = <Shop>[];
    final city = kAllCities.firstWhere(
      (city) => city.id == c.cityId,
      orElse: () => kAllCities.first,
    );
    final locTemplates = kLocationTemplates[city.tier]!;

    for (var i = 0; i < c.shopCount; i++) {
      final loc = locTemplates[i % locTemplates.length];
      final ft = (city.footTrafficBase * loc.footTrafficFactor).round();
      final rent = city.rentBase * loc.rentFactor;

      newShops.add(Shop(
        id: 'aq_${c.id}_$i',
        name: state.companyName,
        customName: null,
        cityId: c.cityId,
        locationName: loc.name,
        footTraffic: ft,
        weeklyRent: rent,
        menu: kAllProducts
            .where((p) => p.isDefault)
            .map((p) => ShopProduct(productId: p.id, price: p.basePrice))
            .toList(),
        equipment: const [],
        employees: const [],
        reputation: c.reputation,
        dayOpened: state.currentDay,
        personality: loc.personality,
        originalCompetitorName: c.name,
        wasAcquired: true,
      ));
    }

    final newCompetitors =
        state.competitors.where((x) => x.id != c.id).toList();

    return state.copyWith(
      cash: state.cash - price,
      shops: [...state.shops, ...newShops],
      competitors: newCompetitors,
    );
  }

  // ── Manager / Auto-Pricing ─────────────────────────────────────────────

  /// Macht einen Mitarbeiter zum Manager (für Auto-Pricing seiner Filiale)
  static GameState assignManager(GameState state, String employeeId) {
    if (state.managerEmployeeIds.contains(employeeId)) return state;
    return state.copyWith(
      managerEmployeeIds: [...state.managerEmployeeIds, employeeId],
    );
  }

  /// Entfernt Manager-Status
  static GameState unassignManager(GameState state, String employeeId) {
    return state.copyWith(
      managerEmployeeIds:
          state.managerEmployeeIds.where((id) => id != employeeId).toList(),
    );
  }

  /// Auto-Hire: pro Filiale mit `autoHire=true` werden offene Stellen
  /// schrittweise aufgefüllt, ohne die Balance zu sprengen.
  ///
  /// Regeln:
  /// - Pro Tag maximal 2 Hires (ohne lokalen Manager) oder 3 (mit Manager)
  /// - Kein automatisches unbegrenztes Nachfüllen des Kandidatenpools
  /// - Cash-Reserve bleibt erhalten (mind. fixer Betrag ODER 15% Tageskosten)
  /// - Kandidatenauswahl aus Top-Fenster statt immer blind der Beste
  static const int _kMaxAutoHiresPerShopPerDay = 2;
  static const int _kMaxAutoHiresPerShopPerDayWithManager = 3;
  static const int _kTopCandidateWindow = 4;
  static const double _kReserveShareOfDailyCosts = 0.15;
  static const double _kMinCashReserve = 1500.0;
  static const double _kBaseHireFeeMultiplier = 1.25;
  static const double _kMinHireFeeMultiplier = 1.0;

  static const Map<GameDifficulty, double> _kAutoHireDifficultyReserve = {
    GameDifficulty.easy: 0.70,
    GameDifficulty.normal: 1.00,
    GameDifficulty.hard: 1.18,
    GameDifficulty.impossible: 1.35,
  };

  static GameState applyAutoHire(GameState state) {
    var workingState = state;
    final hrMods = HrEngine.recruitmentModifiers(state);

    for (final initialShop in state.shops) {
      if (!initialShop.autoHire) continue;

      final maxEmp = _maxEmployeesForCity(initialShop.cityId);
      int hiresThisShop = 0;

      while (true) {
        // Aktuellen Zustand dieser Filiale aus workingState holen
        final shop = workingState.shops.firstWhere(
          (s) => s.id == initialShop.id,
          orElse: () => initialShop,
        );

        final hasLocalManager = _shopHasActiveManager(shop, workingState);
        final baseMaxHires = hasLocalManager
            ? _kMaxAutoHiresPerShopPerDayWithManager
            : _kMaxAutoHiresPerShopPerDay;
        final maxHiresToday = (baseMaxHires * hrMods.autoHireAggressivenessMultiplier)
            .round()
            .clamp(1, 6);
        final neededByCapacity = GameEngine.recommendedExtraEmployees(
          shop,
          day: workingState.currentDay,
          state: workingState,
        );
        final mustFill = shop.employees.isEmpty;
        if (!mustFill && neededByCapacity <= 0) break;
        final targetHires = mustFill
            ? maxHiresToday
            : neededByCapacity.clamp(1, maxHiresToday).toInt();
        if (hiresThisShop >= targetHires) break;

        final freeSlots = maxEmp - shop.employees.length;
        if (freeSlots <= 0) break;

        // Kein unendliches Auto-Nachfüllen: bei leerem Pool stoppt Auto-Hire.
        if (workingState.employeePool.isEmpty) break;

        final pick = _pickCandidateForAutoHire(
          workingState,
          hasLocalManager: hasLocalManager,
          preferredTypeId: _targetRoleTypeId(shop),
        );
        if (pick == null) break;
        final (bestEmp, fee) = pick;

        final newPool =
            workingState.employeePool.where((e) => e.id != bestEmp.id).toList();
        final newShops = workingState.shops.map((s) {
          if (s.id != shop.id) return s;
          return s.copyWith(employees: [...s.employees, bestEmp]);
        }).toList();

        workingState = workingState.copyWith(
          cash: workingState.cash - fee,
          shops: newShops,
          employeePool: newPool,
        );
        hiresThisShop++;
      }
    }
    return workingState;
  }

  static (Employee, double)? _pickCandidateForAutoHire(
    GameState state, {
    required bool hasLocalManager,
    required String? preferredTypeId,
  }) {
    final reserve = _autoHireCashReserve(state);
    final sorted = List<Employee>.from(state.employeePool)
      ..sort((a, b) {
        final aScore = _autoHireCandidateScore(a, preferredTypeId);
        final bScore = _autoHireCandidateScore(b, preferredTypeId);
        return bScore.compareTo(aScore);
      });

    final topCount = sorted.length < _kTopCandidateWindow
        ? sorted.length
        : _kTopCandidateWindow;
    final topCandidates = sorted.take(topCount).toList();

    final affordableTop = <(Employee, double)>[];
    for (final cand in topCandidates) {
      final fee = cand.salaryPerDay * _hireFeeMultiplier(
            state,
            hasLocalManager: hasLocalManager,
            candidate: cand,
          );
      if ((state.cash - fee) >= reserve) {
        affordableTop.add((cand, fee));
      }
    }

    if (affordableTop.isNotEmpty) {
      return affordableTop[_rng.nextInt(affordableTop.length)];
    }

    for (final cand in sorted) {
      final fee = cand.salaryPerDay * _hireFeeMultiplier(
            state,
            hasLocalManager: hasLocalManager,
            candidate: cand,
          );
      if ((state.cash - fee) >= reserve) {
        return (cand, fee);
      }
    }
    return null;
  }

  static double _autoHireCashReserve(GameState state) {
    final hrMods = HrEngine.recruitmentModifiers(state);
    final dailyCosts = state.shops.fold<double>(
      0,
      (sum, shop) =>
          sum +
          GameEngine.calculateDailyCosts(shop,
              day: state.currentDay, state: state),
    );
    final percentReserve = dailyCosts * _kReserveShareOfDailyCosts;
    final reserve =
        percentReserve > _kMinCashReserve ? percentReserve : _kMinCashReserve;
    final difficultyMult =
        _kAutoHireDifficultyReserve[state.difficulty] ?? 1.0;
    return reserve *
        state.difficulty.modifiers.economicPressureMultiplier *
        difficultyMult *
        hrMods.autoHireReserveMultiplier;
  }

  static double _hireFeeMultiplier(
    GameState state, {
    required bool hasLocalManager,
    required Employee candidate,
  }) {
    final hrMods = HrEngine.recruitmentModifiers(state);
    final activeManagers = _activeManagerCount(state);
    final globalReduction = (activeManagers * 0.03).clamp(0.0, 0.25);
    final localReduction = hasLocalManager ? 0.15 : 0.0;
    final hrRecruitingEffect =
        (1 / hrMods.refreshSpeedMultiplier).clamp(0.70, 1.90);
    final salaryEffect = hrMods.candidateSalaryMultiplier;
    final candidatePremium = switch (candidate.origin) {
      CandidateOrigin.topTalent => 1.10,
      CandidateOrigin.exCompetitor => 1.08,
      CandidateOrigin.hiddenGem => 0.94,
      CandidateOrigin.juniorPotential => 0.90,
      CandidateOrigin.teamContact => 0.97,
      CandidateOrigin.regular => 1.00,
    };
    final base =
        _kBaseHireFeeMultiplier * hrRecruitingEffect * salaryEffect * candidatePremium;

    return (base - globalReduction - localReduction)
        .clamp(_kMinHireFeeMultiplier, 2.10);
  }

  static double _autoHireCandidateScore(Employee candidate, String? preferredTypeId) {
    final typeFit = preferredTypeId == null || candidate.typeId == preferredTypeId
        ? 1.0
        : 0.88;
    final growthBonus = 1.0 + candidate.growthPotential * 0.25;
    final originBonus = switch (candidate.origin) {
      CandidateOrigin.topTalent => 1.10,
      CandidateOrigin.hiddenGem => 1.08,
      CandidateOrigin.exCompetitor => 1.06,
      CandidateOrigin.teamContact => 1.03,
      CandidateOrigin.juniorPotential => 0.96,
      CandidateOrigin.regular => 1.00,
    };
    return candidate.overallScore * typeFit * growthBonus * originBonus;
  }

  static String? _targetRoleTypeId(Shop shop) {
    if (shop.employees.isEmpty) return null;
    final counts = <String, int>{};
    for (final type in kEmployeeTypes) {
      counts[type.id] = 0;
    }
    for (final emp in shop.employees) {
      counts[emp.typeId] = (counts[emp.typeId] ?? 0) + 1;
    }
    counts.removeWhere((_, value) => value < 0);
    final entries = counts.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    return entries.isEmpty ? null : entries.first.key;
  }

  static int _activeManagerCount(GameState state) {
    final activeEmployeeIds = <String>{};
    for (final shop in state.shops) {
      for (final emp in shop.employees) {
        activeEmployeeIds.add(emp.id);
      }
    }
    return state.managerEmployeeIds.where(activeEmployeeIds.contains).length;
  }

  static bool _shopHasActiveManager(Shop shop, GameState state) {
    return shop.employees.any((e) => state.managerEmployeeIds.contains(e.id));
  }

  static int _maxEmployeesForCity(String cityId) {
    final city = kAllCities.firstWhere(
      (c) => c.id == cityId,
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

  /// Auto-Preisanpassung pro Filiale wenn Manager vorhanden.
  /// Manager passt Preise leicht an: bei Verlust senken, bei zu wenig
  /// Auslastung erhöhen.
  static GameState applyManagerAutoPricing(GameState state) {
    final updatedShops = state.shops.map((shop) {
      final hasManager =
          shop.employees.any((e) => state.managerEmployeeIds.contains(e.id));
      if (!hasManager) return shop;

      // Strategie: Preise mit ±2% jiggle in Richtung der Reputation
      final newMenu = shop.menu.map((sp) {
        if (!sp.isActive) return sp;
        double adjust = 1.0;
        if (shop.reputation >= 4.0) {
          // Premium-Adresse → leicht teurer
          adjust = 1.01;
        } else if (shop.reputation < 2.5) {
          // Schwächere Filiale → leicht günstiger um Kunden zu halten
          adjust = 0.99;
        }
        final newPrice = (sp.price * adjust).clamp(1.0, 30.0);
        return sp.copyWith(price: newPrice);
      }).toList();

      return shop.copyWith(menu: newMenu);
    }).toList();

    return state.copyWith(shops: updatedShops);
  }
}
