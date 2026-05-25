import 'shop_model.dart';
import 'mission_model.dart';
import 'brand_model.dart';
import 'competitor_model.dart';
import 'employee_model.dart';
import 'stock_model.dart';
import 'production_model.dart';

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

  double get remainingDebt => (totalRepayment - amountPaid).clamp(0.0, double.infinity);

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
  double get progress =>
      (amountPaid / totalRepayment).clamp(0.0, 1.0);

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
  final double costs;        // operative Tageskosten gesamt (Miete+Gehalt+Zutaten)
  final int customers;       // Kunden gesamt über alle Filialen
  final double rentCosts;
  final double salaryCosts;
  final double ingredientCosts;
  final double loanPayments;
  final double investments;  // einmalige Ausgaben (Equipment, Kaution, Stadt)

  const DailyRecord({
    required this.day,
    required this.revenue,
    required this.costs,
    this.customers = 0,
    this.rentCosts = 0,
    this.salaryCosts = 0,
    this.ingredientCosts = 0,
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
  final BrandStats brand;                  // Markenbekanntheit + City-Rep
  final List<Competitor> competitors;      // KI-Konkurrenz
  final List<String> achievementIds;       // freigeschaltete Achievements
  final List<Employee> employeePool;       // Bewerber-Pool (rotiert wöchentlich)
  final int lastEmployeePoolDay;           // wann wurde Pool zuletzt rotiert?
  final int currentHour;                   // 0..14 — Tag-Tick-Counter, stoppt bei 14
  final StockState stocks;                 // Börse / Aktienkurs
  final List<ProductionFacility> facilities; // Produktions-Anlagen
  final List<String> managerEmployeeIds;   // Mitarbeiter-IDs, die Manager sind
  final List<String> globalUpgradeIds;    // Konzern-Upgrades (scope = global)

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
  });

  factory GameState.initial({
    required String companyName,
    required String founderName,
    required double startCash,
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
  bool hasShopIn(String cityId) =>
      shops.any((s) => s.cityId == cityId);

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
      customersServedTotal:
          customersServedTotal ?? this.customersServedTotal,
      seenEventIds: seenEventIds ?? this.seenEventIds,
      tutorialDone: tutorialDone ?? this.tutorialDone,
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
      };

  factory GameState.fromJson(Map<String, dynamic> j) {
    // Missions: Templates laden, dann Status aus Save anwenden
    final missionsTemplate = buildMissionsTemplate();
    final savedMissions = j['missions'] as List? ?? [];
    for (final saved in savedMissions) {
      final map = saved as Map<String, dynamic>;
      final id = map['id'] as String;
      final m = missionsTemplate.firstWhere(
        (m) => m.id == id,
        orElse: () => missionsTemplate.first,
      );
      if (m.id == id) m.applyJson(map);
    }

    return GameState(
      companyName: j['companyName'] as String,
      founderName: j['founderName'] as String,
      cash: (j['cash'] as num).toDouble(),
      currentDay: j['currentDay'] as int,
      shops: (j['shops'] as List)
          .map((e) => Shop.fromJson(e as Map<String, dynamic>))
          .toList(),
      unlockedCityIds: List<String>.from(j['unlockedCityIds'] as List),
      loans: (j['loans'] as List)
          .map((e) => Loan.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalRevenue: (j['totalRevenue'] as num).toDouble(),
      totalProfit: (j['totalProfit'] as num).toDouble(),
      history: (j['history'] as List)
          .map((e) => DailyRecord.fromJson(e as Map<String, dynamic>))
          .toList(),
      missions: missionsTemplate,
      customersServedTotal:
          (j['customersServedTotal'] as num?)?.toInt() ?? 0,
      seenEventIds:
          List<String>.from(j['seenEventIds'] as List? ?? const []),
      tutorialDone: j['tutorialDone'] as bool? ?? false,
      brand: j['brand'] != null
          ? BrandStats.fromJson(j['brand'] as Map<String, dynamic>)
          : const BrandStats(),
      competitors: (j['competitors'] as List?)
              ?.map((e) =>
                  Competitor.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      achievementIds:
          List<String>.from(j['achievementIds'] as List? ?? const []),
      employeePool: (j['employeePool'] as List?)
              ?.map((e) => Employee.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      lastEmployeePoolDay:
          (j['lastEmployeePoolDay'] as num?)?.toInt() ?? 0,
      currentHour:
          (j['currentHour'] as num?)?.toInt() ?? 0,
      stocks: j['stocks'] != null
          ? StockState.fromJson(j['stocks'] as Map<String, dynamic>)
          : const StockState(),
      facilities: (j['facilities'] as List?)
              ?.map((e) =>
                  ProductionFacility.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      managerEmployeeIds: List<String>.from(
          j['managerEmployeeIds'] as List? ?? const []),
      globalUpgradeIds: List<String>.from(
          j['globalUpgradeIds'] as List? ?? const []),
    );
  }
}
