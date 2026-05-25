import 'dart:math';

import '../models/game_state.dart';
import '../models/stock_model.dart';
import '../models/production_model.dart';
import '../models/competitor_model.dart';
import '../models/shop_model.dart';
import '../models/product_model.dart';
import '../models/city_model.dart';
import '../core/constants.dart';

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
        : state.history
                .map((r) => r.profit)
                .fold(0.0, (a, b) => a + b) *
            (365 / state.history.length);
    final pe = 10.0; // P/E ratio
    final cashflowValue = (yearlyProfitEstimate * pe).clamp(0.0, double.infinity);
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

    final priceMove = (1.0 + noise + brandImpact + shopImpact).clamp(0.95, 1.05);
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
    final quarterDays = state.history.where((r) => r.day >= quarterStart).toList();

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
    final newExpectation =
        (qProfit * 0.9 + s.analystExpectation * 0.1).clamp(0.0, double.infinity);

    String headline;
    if (deltaPercent > 0.20) {
      headline = '🚀 SENSATION! Döner Empire übertrifft Erwartungen massiv';
    } else if (deltaPercent > 0.05) {
      headline = '📈 Gewinn schlägt Analysten-Prognose';
    } else if (deltaPercent > -0.05) {
      headline = 'Solides Quartal — im Rahmen der Erwartungen';
    } else if (deltaPercent > -0.20) {
      headline = '⚠️ Aktie unter Druck — Quartal enttäuschend';
    } else {
      headline = '🔻 KURSEINBRUCH! Massive Gewinnwarnung';
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
  static GameState buildFacility(
      GameState state, FacilityTemplate template) {
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
      final marketDemand =
          (state.competitors.length / 10.0).clamp(0.3, 1.5);
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
        name: '${c.name} ${i + 1}',
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
      managerEmployeeIds: state.managerEmployeeIds
          .where((id) => id != employeeId)
          .toList(),
    );
  }

  /// Auto-Hire: pro Filiale mit `autoHire=true` wird bei Engpass automatisch
  /// der beste passende Kandidat aus dem Bewerber-Pool eingestellt.
  /// Spieler zahlt dafür Recruiter-Pauschale (3-Tages-Gehalt).
  static GameState applyAutoHire(GameState state) {
    if (state.employeePool.isEmpty) return state;
    var workingState = state;

    for (final shop in List.from(state.shops)) {
      if (!shop.autoHire) continue;
      // Engpass-Check: rekommendiert mehr Mitarbeiter?
      final stats = _shopUtilization(workingState, shop);
      if (stats < 0.85) continue; // weniger als 85% ausgelastet → kein Hire

      // Max-Cap erreicht?
      final maxEmp = _maxEmployeesForCity(shop.cityId);
      if (shop.employees.length >= maxEmp) continue;

      // Besten Kandidaten finden
      if (workingState.employeePool.isEmpty) break;
      final sorted = List.from(workingState.employeePool);
      sorted.sort((a, b) =>
          (b.overallScore as double).compareTo(a.overallScore as double));
      final best = sorted.first;

      // Recruiter-Pauschale: 3 Tagesgehälter
      final fee = best.salaryPerDay * 3;
      if (workingState.cash < fee) continue;

      // Einstellen
      final newPool =
          workingState.employeePool.where((e) => e.id != best.id).toList();
      final newShops = workingState.shops.map((s) {
        if (s.id != shop.id) return s;
        return s.copyWith(employees: [...s.employees, best]);
      }).toList();
      workingState = workingState.copyWith(
        cash: workingState.cash - fee,
        shops: newShops,
        employeePool: newPool,
      );
    }
    return workingState;
  }

  /// Vereinfachter Auslastungs-Check für Auto-Hire
  static double _shopUtilization(GameState state, dynamic shop) {
    // Vereinfachung: nur "hat genug Mitarbeiter?" — wenn 1 oder weniger
    // pro 100 Foot-Traffic, dann Engpass.
    final ft = shop.footTraffic as int;
    final empCount = (shop.employees as List).length;
    final density = empCount / (ft / 1000.0);
    return density < 1.0 ? 1.0 : 0.5;
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
      final hasManager = shop.employees
          .any((e) => state.managerEmployeeIds.contains(e.id));
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
