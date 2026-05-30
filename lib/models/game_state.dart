import 'shop_model.dart';
import 'product_model.dart';
import 'mission_model.dart';
import 'brand_model.dart';
import 'competitor_model.dart';
import 'employee_model.dart';
import 'marketing_model.dart';
import 'stock_model.dart';
import 'production_model.dart';
import 'upgrade_model.dart';
import 'difficulty_model.dart';
import 'hr_manager_model.dart';
import 'tutorial_model.dart';
import '../core/constants.dart';

class Loan {
  final String id;
  final double amount;
  final double interestRate; // z.B. 0.05 = 5% pro Jahr
  final int durationDays;
  final int dayTaken;
  double amountPaid;

  Loan({
    required this.id,
    required this.amount,
    required this.interestRate,
    required this.durationDays,
    required this.dayTaken,
    this.amountPaid = 0,
  });

  /// Gesamtsumme (Kredit + Zinsen) die ursprünglich zurückgezahlt werden muss.
  double get totalRepayment =>
      amount * (1 + interestRate * (durationDays / 365));

  double get dailyPayment => totalRepayment / durationDays;

  double get remainingDebt =>
      (totalRepayment - amountPaid).clamp(0.0, double.infinity);

  /// Bei Sondertilgung wird der bereits gezahlte Zins-Anteil rabattiert:
  /// Wer früher tilgt, zahlt weniger Zinsen.
  /// Liefert den Betrag, der für eine *vollständige* Ablösung *heute* nötig wäre.
  /// Formel: Restschuld minus 50% der noch nicht angefallenen Zinsen.
  double earlyPayoffAmount(int currentDay) {
    final daysElapsed = (currentDay - dayTaken).clamp(0, durationDays);
    final totalInterest = amount * interestRate * (durationDays / 365);
    final paidInterestShare = (daysElapsed / durationDays) * totalInterest;
    final futureInterest = totalInterest - paidInterestShare;
    // 50% der zukünftigen Zinsen werden erlassen (Standard-Bank-Praxis)
    final discount = futureInterest * 0.5;
    final remaining = totalRepayment - amountPaid - discount;
    return remaining.clamp(0.0, double.infinity);
  }

  /// Verbleibende Tage bis Laufzeit-Ende
  int remainingDays(int currentDay) {
    final daysElapsed = (currentDay - dayTaken).clamp(0, durationDays);
    return durationDays - daysElapsed;
  }

  /// Progress-Anteil (0..1)
  double get progress => (amountPaid / totalRepayment).clamp(0.0, 1.0);

  bool get isPaidOff => remainingDebt <= 0.01;

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'interestRate': interestRate,
        'durationDays': durationDays,
        'dayTaken': dayTaken,
        'amountPaid': amountPaid,
      };

  factory Loan.fromJson(Map<String, dynamic> j) => Loan(
        id: j['id'] as String,
        amount: (j['amount'] as num).toDouble(),
        interestRate: (j['interestRate'] as num).toDouble(),
        durationDays: j['durationDays'] as int,
        dayTaken: j['dayTaken'] as int,
        amountPaid: (j['amountPaid'] as num).toDouble(),
      );
}

/// Tagesabschluss-Datensatz mit voller Kosten-Aufschlüsselung.
/// Die einzelnen `costX` Felder werden im Finanzverlauf-Chart visualisiert
/// und sollten zusammen ungefähr `costs` ergeben (Investitionen
/// kommen aber zusätzlich oben drauf — siehe `investments`).
class DailyRecord {
  final int day;
  final double revenue;
  final double costs; // operative Tageskosten gesamt
  final int customers; // Kunden gesamt über alle Filialen
  final double rentCosts;
  final double salaryCosts;
  final double ingredientCosts;
  final double deliveryCommissionCosts;
  final double loanPayments;
  final double investments; // einmalige Ausgaben (Equipment, Kaution, Stadt)

  const DailyRecord({
    required this.day,
    required this.revenue,
    required this.costs,
    this.customers = 0,
    this.rentCosts = 0,
    this.salaryCosts = 0,
    this.ingredientCosts = 0,
    this.deliveryCommissionCosts = 0,
    this.loanPayments = 0,
    this.investments = 0,
  });

  double get profit => revenue - costs - loanPayments - investments;
  double get operatingProfit => revenue - costs;

  Map<String, dynamic> toJson() => {
        'day': day,
        'revenue': revenue,
        'costs': costs,
        'customers': customers,
        'rentCosts': rentCosts,
        'salaryCosts': salaryCosts,
        'ingredientCosts': ingredientCosts,
        'deliveryCommissionCosts': deliveryCommissionCosts,
        'loanPayments': loanPayments,
        'investments': investments,
      };

  factory DailyRecord.fromJson(Map<String, dynamic> j) => DailyRecord(
        day: j['day'] as int,
        revenue: (j['revenue'] as num).toDouble(),
        costs: (j['costs'] as num).toDouble(),
        customers: (j['customers'] as num?)?.toInt() ?? 0,
        rentCosts: (j['rentCosts'] as num?)?.toDouble() ?? 0,
        salaryCosts: (j['salaryCosts'] as num?)?.toDouble() ?? 0,
        ingredientCosts: (j['ingredientCosts'] as num?)?.toDouble() ?? 0,
        deliveryCommissionCosts:
            (j['deliveryCommissionCosts'] as num?)?.toDouble() ?? 0,
        loanPayments: (j['loanPayments'] as num?)?.toDouble() ?? 0,
        investments: (j['investments'] as num?)?.toDouble() ?? 0,
      );
}

class GameState {
  final String companyName;
  final String founderName;
  final double cash;
  final int currentDay;
  final List<Shop> shops;
  final List<String> unlockedCityIds;
  final List<Loan> loans;
  final double totalRevenue;
  final double totalProfit;
  final List<DailyRecord> history;
  final List<Mission> missions;
  final int customersServedTotal;
  final List<String> seenEventIds;
  final bool tutorialDone;
  final bool tutorialEnabled;
  final int tutorialStep;
  final BrandStats brand; // Markenbekanntheit + City-Rep
  final List<Competitor> competitors; // KI-Konkurrenz
  final List<String> achievementIds; // freigeschaltete Achievements
  final List<Employee> employeePool; // Bewerber-Pool (rotiert wöchentlich)
  final int lastEmployeePoolDay; // wann wurde Pool zuletzt rotiert?
  final int currentHour; // 0..14 — Tag-Tick-Counter, stoppt bei 14
  final StockState stocks; // Börse / Aktienkurs
  final List<ProductionFacility> facilities; // Produktions-Anlagen
  final List<String> managerEmployeeIds; // Mitarbeiter-IDs, die Manager sind
  final List<String> globalUpgradeIds; // Konzern-Upgrades (scope = global)
  final GameDifficulty difficulty; // Schwierigkeitsstufe
  final HrManager? hrManager; // Konzernweiter HR-Manager
  final HrStrategy hrStrategy; // HR-Strategie
  final List<HrManager> hrCandidates; // Auswahlpool für HR-Neubesetzung

  // ── Globale und stadtweite Preissteuerung ─────────────────────────────────
  /// Globale Standardpreise: productId → Preis.
  /// Neue Filialen erben diese Preise; bestehende werden bei
  /// `setGlobalPrice` / `applyPriceStrategy` sofort aktualisiert.
  final Map<String, double> globalPrices;

  /// Stadtweite Preisübersteuerungen: cityId → productId → Preis.
  /// Stadtpreise haben Vorrang vor globalPrices.
  final Map<String, Map<String, double>> cityPrices;

  // ── Globale und stadtweite Marketing-Kampagnen ────────────────────────────
  /// Stadtweite aktive Kampagnen: cityId → Liste aktiver Kampagnen.
  final Map<String, List<ActiveCampaign>> activeCityCampaigns;

  /// Konzernweit aktive Kampagnen (wirken auf alle Filialen + Brand).
  final List<ActiveCampaign> activeGlobalCampaigns;

  /// Abgeschlossene Story-Kampagnen-Kapitel (Kapitel-IDs).
  final List<String> completedChapterIds;

  /// Konzernweit aktive Menü-Angebote/Kombos (Kombo-IDs).
  final List<String> activeComboIds;

  /// Aktives kosmetisches Marken-Thema (Branding-Skin).
  final String activeThemeId;

  /// Konzernweite Zutaten-Qualität je Produkt (productId → Qualitätsname).
  /// Fehlt ein Eintrag → Standard.
  final Map<String, String> productQuality;

  const GameState({
    required this.companyName,
    required this.founderName,
    required this.cash,
    required this.currentDay,
    required this.shops,
    required this.unlockedCityIds,
    required this.loans,
    required this.totalRevenue,
    required this.totalProfit,
    required this.history,
    required this.missions,
    this.customersServedTotal = 0,
    this.seenEventIds = const [],
    this.tutorialDone = false,
    this.tutorialEnabled = false,
    this.tutorialStep = 0,
    this.brand = const BrandStats(),
    this.competitors = const [],
    this.achievementIds = const [],
    this.employeePool = const [],
    this.lastEmployeePoolDay = 0,
    this.currentHour = 0,
    this.stocks = const StockState(),
    this.facilities = const [],
    this.managerEmployeeIds = const [],
    this.globalUpgradeIds = const [],
    this.difficulty = GameDifficulty.normal,
    this.hrManager,
    this.hrStrategy = HrStrategy.balanced,
    this.hrCandidates = const [],
    this.globalPrices = const {},
    this.cityPrices = const {},
    this.activeCityCampaigns = const {},
    this.activeGlobalCampaigns = const [],
    this.completedChapterIds = const [],
    this.activeComboIds = const [],
    this.activeThemeId = 'klassik',
    this.productQuality = const {},
  });

  factory GameState.initial({
    required String companyName,
    required String founderName,
    required double startCash,
    GameDifficulty difficulty = GameDifficulty.normal,
    bool tutorialEnabled = true,
  }) {
    return GameState(
      companyName: companyName,
      founderName: founderName,
      cash: startCash,
      currentDay: 1,
      shops: const [],
      unlockedCityIds: const ['fulda', 'bayreuth', 'goettingen'],
      loans: const [],
      totalRevenue: 0,
      totalProfit: 0,
      history: const [],
      missions: buildMissionsTemplate(),
      customersServedTotal: 0,
      seenEventIds: const [],
      tutorialDone: false,
      tutorialEnabled: tutorialEnabled,
      tutorialStep: 0,
      brand: const BrandStats(brandAwareness: 5.0, cityReputation: {}),
      competitors: const [],
      achievementIds: const [],
      employeePool: const [],
      lastEmployeePoolDay: 0,
      currentHour: 0,
      stocks: const StockState(),
      facilities: const [],
      managerEmployeeIds: const [],
      globalUpgradeIds: const [],
      difficulty: difficulty,
      hrManager: null,
      hrStrategy: HrStrategy.balanced,
      hrCandidates: const [],
      globalPrices: const {},
      cityPrices: const {},
      activeCityCampaigns: const {},
      activeGlobalCampaigns: const [],
      completedChapterIds: const [],
      activeComboIds: const [],
      activeThemeId: 'klassik',
      productQuality: const {},
    );
  }

  int get shopCount => shops.length;
  int get employeeCount => shops.fold(0, (sum, s) => sum + s.employees.length);

  double get activeLoansTotal =>
      loans.where((l) => !l.isPaidOff).fold(0.0, (s, l) => s + l.remainingDebt);

  /// Konkurrenten in einer bestimmten Stadt
  List<Competitor> competitorsIn(String cityId) =>
      competitors.where((c) => c.cityId == cityId).toList();

  /// Markttreiber: hat der Spieler in dieser Stadt eine Filiale?
  bool hasShopIn(String cityId) => shops.any((s) => s.cityId == cityId);

  GameState copyWith({
    String? companyName,
    double? cash,
    int? currentDay,
    List<Shop>? shops,
    List<String>? unlockedCityIds,
    List<Loan>? loans,
    double? totalRevenue,
    double? totalProfit,
    List<DailyRecord>? history,
    List<Mission>? missions,
    int? customersServedTotal,
    List<String>? seenEventIds,
    bool? tutorialDone,
    bool? tutorialEnabled,
    int? tutorialStep,
    BrandStats? brand,
    List<Competitor>? competitors,
    List<String>? achievementIds,
    List<Employee>? employeePool,
    int? lastEmployeePoolDay,
    int? currentHour,
    StockState? stocks,
    List<ProductionFacility>? facilities,
    List<String>? managerEmployeeIds,
    List<String>? globalUpgradeIds,
    GameDifficulty? difficulty,
    HrManager? hrManager,
    bool clearHrManager = false,
    HrStrategy? hrStrategy,
    List<HrManager>? hrCandidates,
    Map<String, double>? globalPrices,
    Map<String, Map<String, double>>? cityPrices,
    Map<String, List<ActiveCampaign>>? activeCityCampaigns,
    List<ActiveCampaign>? activeGlobalCampaigns,
    List<String>? completedChapterIds,
    List<String>? activeComboIds,
    String? activeThemeId,
    Map<String, String>? productQuality,
  }) {
    return GameState(
      companyName: companyName ?? this.companyName,
      founderName: founderName,
      cash: cash ?? this.cash,
      currentDay: currentDay ?? this.currentDay,
      shops: shops ?? this.shops,
      unlockedCityIds: unlockedCityIds ?? this.unlockedCityIds,
      loans: loans ?? this.loans,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      totalProfit: totalProfit ?? this.totalProfit,
      history: history ?? this.history,
      missions: missions ?? this.missions,
      customersServedTotal: customersServedTotal ?? this.customersServedTotal,
      seenEventIds: seenEventIds ?? this.seenEventIds,
      tutorialDone: tutorialDone ?? this.tutorialDone,
      tutorialEnabled: tutorialEnabled ?? this.tutorialEnabled,
      tutorialStep: tutorialStep ?? this.tutorialStep,
      brand: brand ?? this.brand,
      competitors: competitors ?? this.competitors,
      achievementIds: achievementIds ?? this.achievementIds,
      employeePool: employeePool ?? this.employeePool,
      lastEmployeePoolDay: lastEmployeePoolDay ?? this.lastEmployeePoolDay,
      currentHour: currentHour ?? this.currentHour,
      stocks: stocks ?? this.stocks,
      facilities: facilities ?? this.facilities,
      managerEmployeeIds: managerEmployeeIds ?? this.managerEmployeeIds,
      globalUpgradeIds: globalUpgradeIds ?? this.globalUpgradeIds,
      difficulty: difficulty ?? this.difficulty,
      hrManager: clearHrManager ? null : (hrManager ?? this.hrManager),
      hrStrategy: hrStrategy ?? this.hrStrategy,
      hrCandidates: hrCandidates ?? this.hrCandidates,
      globalPrices: globalPrices ?? this.globalPrices,
      cityPrices: cityPrices ?? this.cityPrices,
      activeCityCampaigns: activeCityCampaigns ?? this.activeCityCampaigns,
      activeGlobalCampaigns:
          activeGlobalCampaigns ?? this.activeGlobalCampaigns,
      completedChapterIds: completedChapterIds ?? this.completedChapterIds,
      activeComboIds: activeComboIds ?? this.activeComboIds,
      activeThemeId: activeThemeId ?? this.activeThemeId,
      productQuality: productQuality ?? this.productQuality,
    );
  }

  Map<String, dynamic> toJson() => {
        'companyName': companyName,
        'founderName': founderName,
        'cash': cash,
        'currentDay': currentDay,
        'shops': shops.map((s) => s.toJson()).toList(),
        'unlockedCityIds': unlockedCityIds,
        'loans': loans.map((l) => l.toJson()).toList(),
        'totalRevenue': totalRevenue,
        'totalProfit': totalProfit,
        'history': history.map((r) => r.toJson()).toList(),
        'missions': missions.map((m) => m.toJson()).toList(),
        'customersServedTotal': customersServedTotal,
        'seenEventIds': seenEventIds,
        'tutorialDone': tutorialDone,
        'tutorialEnabled': tutorialEnabled,
        'tutorialStep': tutorialStep,
        'brand': brand.toJson(),
        'competitors': competitors.map((c) => c.toJson()).toList(),
        'achievementIds': achievementIds,
        'employeePool': employeePool.map((e) => e.toJson()).toList(),
        'lastEmployeePoolDay': lastEmployeePoolDay,
        'currentHour': currentHour,
        'stocks': stocks.toJson(),
        'facilities': facilities.map((f) => f.toJson()).toList(),
        'managerEmployeeIds': managerEmployeeIds,
        'globalUpgradeIds': globalUpgradeIds,
        'difficulty': difficulty.name,
        'hrManager': hrManager?.toJson(),
        'hrStrategy': hrStrategy.name,
        'hrCandidates': hrCandidates.map((m) => m.toJson()).toList(),
        'globalPrices': globalPrices,
        'cityPrices': cityPrices.map((k, v) => MapEntry(k, v)),
        'activeCityCampaigns': activeCityCampaigns
            .map((k, v) => MapEntry(k, v.map((c) => c.toJson()).toList())),
        'activeGlobalCampaigns':
            activeGlobalCampaigns.map((c) => c.toJson()).toList(),
        'completedChapterIds': completedChapterIds,
        'activeComboIds': activeComboIds,
        'activeThemeId': activeThemeId,
        'productQuality': productQuality,
      };

  factory GameState.fromJson(Map<String, dynamic> j) {
    List<dynamic> asList(dynamic v) => v is List ? v : const [];
    Map<String, dynamic> asMap(dynamic v) =>
        v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};
    double asDouble(dynamic v, [double fallback = 0.0]) {
      if (v is num) return v.toDouble();
      if (v is String) {
        final parsed = double.tryParse(v.replaceAll(',', '.'));
        if (parsed != null) return parsed;
      }
      return fallback;
    }

    int asInt(dynamic v, [int fallback = 0]) {
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? fallback;
      return fallback;
    }

    bool asBool(dynamic v, [bool fallback = false]) {
      if (v is bool) return v;
      if (v is num) return v != 0;
      if (v is String) {
        final s = v.toLowerCase();
        if (s == 'true' || s == '1') return true;
        if (s == 'false' || s == '0') return false;
      }
      return fallback;
    }

    final companyName = (j['companyName'] ?? '') as String;

    // Missions: Templates laden, dann Status aus Save anwenden
    final missionsTemplate = buildMissionsTemplate();
    final savedMissions = asList(j['missions']);
    for (final saved in savedMissions) {
      if (saved is! Map) continue;
      final map = Map<String, dynamic>.from(saved);
      final id = map['id'];
      if (id is! String) continue;
      final m = missionsTemplate.firstWhere(
        (m) => m.id == id,
        orElse: () => missionsTemplate.first,
      );
      if (m.id == id) m.applyJson(map);
    }

    final globalPrices =
        asMap(j['globalPrices']).map((k, v) => MapEntry(k, asDouble(v)));
    final cityPrices = asMap(j['cityPrices']).map((cityId, priceMap) {
      final mapped =
          asMap(priceMap).map((pid, price) => MapEntry(pid, asDouble(price)));
      return MapEntry(cityId, mapped);
    });

    var shops = asList(j['shops'])
        .whereType<Map>()
        .map((e) => Shop.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    // Filialnamen-Migration:
    // Alte Saves hatten oft individuelle Namen direkt in `shop.name`.
    // Neues Modell: `name` = Konzernname, optional individueller Name in
    // `customName`.
    if (companyName.trim().isNotEmpty) {
      shops = shops.map((shop) {
        final legacyName = shop.name.trim();
        if (legacyName.isEmpty) {
          return shop.copyWith(name: companyName);
        }
        final alreadyBranded = legacyName == companyName;
        if (alreadyBranded) {
          return shop;
        }
        // Nur migrieren, wenn bisher kein customName gesetzt war.
        if (!shop.hasCustomName) {
          return shop.copyWith(
            name: companyName,
            customName: legacyName,
          );
        }
        return shop.copyWith(name: companyName);
      }).toList();
    }
    final globalUpgradeIds = List<String>.from(asList(j['globalUpgradeIds']));

    // Legacy-Migration: alter filialbasierter Döner-Spieß (Equipment) wird auf
    // konzernweiten Upgrade-Stand vereinheitlicht.
    const legacySpiessIds = ['spiess_klein', 'spiess_standard', 'spiess_profi'];
    var legacySpiessLevel = -1;
    for (final shop in shops) {
      for (final se in shop.equipment) {
        final idx = legacySpiessIds.indexOf(se.equipmentId);
        if (idx > legacySpiessLevel) legacySpiessLevel = idx;
      }
    }
    if (legacySpiessLevel >= 0) {
      shops = shops
          .map(
            (s) => s.copyWith(
              equipment: s.equipment
                  .where((e) => !legacySpiessIds.contains(e.equipmentId))
                  .toList(),
            ),
          )
          .toList();
      final mappedId = switch (legacySpiessLevel) {
        0 => kGlobalSpiessBasicId,
        1 => kGlobalSpiessStandardId,
        _ => kGlobalSpiessProfiId,
      };
      final existingGlobalSpiess = globalUpgradeIds
          .where((id) => kGlobalSpiessUpgradeOrder.contains(id))
          .toList();
      if (existingGlobalSpiess.isEmpty) {
        globalUpgradeIds.add(mappedId);
      } else {
        final existingBestIndex = existingGlobalSpiess
            .map((id) => kGlobalSpiessUpgradeOrder.indexOf(id))
            .fold<int>(-1, (best, idx) => idx > best ? idx : best);
        if (legacySpiessLevel > existingBestIndex) {
          globalUpgradeIds
              .removeWhere((id) => kGlobalSpiessUpgradeOrder.contains(id));
          globalUpgradeIds.add(mappedId);
        }
      }
    }

    // Legacy-Migration: früher war `lieferdienst` ein Filial-Upgrade.
    // Jetzt ist es global. Alte Save-Stände werden daher einmalig
    // auf globale Aktivierung vereinheitlicht.
    final hadLegacyDelivery =
        shops.any((s) => s.upgradeIds.contains('lieferdienst'));
    if (hadLegacyDelivery) {
      shops = shops
          .map(
            (s) => s.copyWith(
              upgradeIds:
                  s.upgradeIds.where((id) => id != 'lieferdienst').toList(),
            ),
          )
          .toList();
      if (!globalUpgradeIds.contains('lieferdienst')) {
        globalUpgradeIds.add('lieferdienst');
      }
    }

    // Legacy-/Forward-Migration: fehlende Default-Produkte in bestehenden
    // Filial-Menüs ergänzen (z.B. veg_doener in älteren Save-Ständen).
    final defaultProducts = kAllProducts.where((p) => p.isDefault).toList();
    shops = shops.map((shop) {
      final existing = shop.menu.map((sp) => sp.productId).toSet();
      final cityPriceMap = cityPrices[shop.cityId] ?? const <String, double>{};
      final missingDefaults = defaultProducts
          .where((p) => !existing.contains(p.id))
          .map(
            (p) => ShopProduct(
              productId: p.id,
              price: cityPriceMap[p.id] ?? globalPrices[p.id] ?? p.basePrice,
            ),
          )
          .toList();
      if (missingDefaults.isEmpty) return shop;
      return shop.copyWith(menu: [...shop.menu, ...missingDefaults]);
    }).toList();

    final unlockedCityIds = List<String>.from(asList(j['unlockedCityIds']));
    final freeCityIds = kAllCities
        .where((city) => city.unlockCost <= 0)
        .map((city) => city.id);
    for (final freeCityId in freeCityIds) {
      if (!unlockedCityIds.contains(freeCityId)) {
        unlockedCityIds.add(freeCityId);
      }
    }

    return GameState(
      companyName: companyName,
      founderName: (j['founderName'] ?? '') as String,
      cash: asDouble(j['cash']),
      currentDay: asInt(j['currentDay'], 1),
      shops: shops,
      unlockedCityIds: unlockedCityIds,
      loans: asList(j['loans'])
          .whereType<Map>()
          .map((e) => Loan.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      totalRevenue: asDouble(j['totalRevenue']),
      totalProfit: asDouble(j['totalProfit']),
      history: asList(j['history'])
          .whereType<Map>()
          .map((e) => DailyRecord.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      missions: missionsTemplate,
      customersServedTotal: asInt(j['customersServedTotal']),
      seenEventIds: List<String>.from(asList(j['seenEventIds'])),
      tutorialDone: asBool(j['tutorialDone']),
      tutorialEnabled: asBool(j['tutorialEnabled']),
      tutorialStep: asInt(j['tutorialStep']).clamp(0, kTutorialStepCount - 1),
      brand: j['brand'] != null
          ? BrandStats.fromJson(asMap(j['brand']))
          : const BrandStats(),
      competitors: asList(j['competitors'])
          .whereType<Map>()
          .map((e) => Competitor.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      achievementIds: List<String>.from(asList(j['achievementIds'])),
      employeePool: asList(j['employeePool'])
          .whereType<Map>()
          .map((e) => Employee.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      lastEmployeePoolDay: asInt(j['lastEmployeePoolDay']),
      currentHour: asInt(j['currentHour']),
      stocks: j['stocks'] != null
          ? StockState.fromJson(asMap(j['stocks']))
          : const StockState(),
      facilities: asList(j['facilities'])
          .whereType<Map>()
          .map((e) => ProductionFacility.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      managerEmployeeIds: List<String>.from(asList(j['managerEmployeeIds'])),
      globalUpgradeIds: globalUpgradeIds,
      difficulty: gameDifficultyFromName(j['difficulty'] as String?),
      hrManager: j['hrManager'] is Map
          ? HrManager.fromJson(asMap(j['hrManager']))
          : null,
      hrStrategy: hrStrategyFromName(j['hrStrategy'] as String?),
      hrCandidates: asList(j['hrCandidates'])
          .whereType<Map>()
          .map((e) => HrManager.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      globalPrices: globalPrices,
      cityPrices: cityPrices,
      activeCityCampaigns: asMap(j['activeCityCampaigns']).map((cityId, list) {
        final campaigns = asList(list)
            .whereType<Map>()
            .map((e) => ActiveCampaign.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        return MapEntry(cityId, campaigns);
      }),
      activeGlobalCampaigns: asList(j['activeGlobalCampaigns'])
          .whereType<Map>()
          .map((e) => ActiveCampaign.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      completedChapterIds:
          List<String>.from(asList(j['completedChapterIds'])),
      activeComboIds: List<String>.from(asList(j['activeComboIds'])),
      activeThemeId: (j['activeThemeId'] as String?) ?? 'klassik',
      productQuality: asMap(j['productQuality'])
          .map((k, v) => MapEntry(k, v.toString())),
    );
  }
}
