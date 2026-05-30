import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_state.dart';
import '../models/shop_model.dart';
import '../models/employee_model.dart';
import '../models/equipment_model.dart';
import '../models/mission_model.dart';
import '../models/campaign_model.dart';
import '../models/quality_model.dart';
import '../models/event_model.dart';
import '../models/marketing_model.dart';
import '../models/achievement_model.dart';
import '../models/city_model.dart';
import '../models/upgrade_model.dart';
import '../models/competitor_model.dart';
import '../models/production_model.dart';
import '../models/stock_model.dart';
import '../models/difficulty_model.dart';
import '../models/hr_manager_model.dart';
import '../models/tutorial_model.dart';
import '../services/game_engine.dart';
import '../services/hr_engine.dart';
import '../services/mission_engine.dart';
import '../services/campaign_engine.dart';
import '../services/sound_service.dart';
import '../services/save_service.dart';
import '../services/corporate_engine.dart';
import '../core/constants.dart';

/// Resultat-Container für UI-Notifications nach Tag-Ende.
class DayEndResult {
  final int day;
  final double revenue;
  final double costs;
  final double profit;
  final int customers;
  final GameEvent? event;
  final Mission? missionCompleted;
  final List<Achievement> newAchievements;
  final QuarterlyReport? quarterlyReport;
  final CampaignChapter? chapterCompleted;
  final WeeklyReport? weeklyReport;
  final double taxPaid;
  final bool challengeMet;
  final double challengeReward;

  DayEndResult({
    required this.day,
    required this.revenue,
    required this.costs,
    required this.profit,
    required this.customers,
    this.event,
    this.missionCompleted,
    this.newAchievements = const [],
    this.quarterlyReport,
    this.chapterCompleted,
    this.weeklyReport,
    this.taxPaid = 0,
    this.challengeMet = false,
    this.challengeReward = 0,
  });
}

class GameNotifier extends Notifier<GameState?> {
  static const double _tutorialCompletionReward = 25000;
  Timer? _tickTimer;

  /// Last day-end result für Dialog-Anzeige.
  DayEndResult? lastDayResult;

  @override
  GameState? build() => null;

  // ── Spiel starten / laden ────────────────────────────────────────────────

  Future<void> startNewGame(
    String companyName,
    String founderName, {
    GameDifficulty difficulty = GameDifficulty.normal,
    bool tutorialEnabled = true,
    double? startCash,
    double startingLoanAmount = 0,
  }) async {
    state = GameState.initial(
      companyName: companyName,
      founderName: founderName,
      startCash: startCash ?? kStartingCash,
      difficulty: difficulty,
      tutorialEnabled: tutorialEnabled,
    );
    final hrCandidates = HrEngine.generateHrCandidates(daySeed: 1);
    // Initial Bewerber-Pool
    state = state!.copyWith(
      hrCandidates: hrCandidates,
      employeePool: _generateEmployeePool(state!),
      lastEmployeePoolDay: 1,
    );
    // Szenario-Startkredit (z.B. „Schuldenstart")
    if (startingLoanAmount > 0) {
      final loan = Loan(
        id: 'start_loan',
        amount: startingLoanAmount,
        interestRate: 0.08,
        durationDays: 180,
        dayTaken: 1,
      );
      state = state!.copyWith(loans: [loan]);
    }
    await SaveService.save(state!);
    _startTickTimer();
  }

  Future<bool> loadGame() async {
    final saved = await SaveService.load();
    if (saved == null) return false;
    state = saved;
    _startTickTimer();
    return true;
  }

  Future<bool> hasSavedGame() => SaveService.hasSave();

  // ── Stündliche Echtzeit-Einnahmen ────────────────────────────────────

  void _startTickTimer() {
    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(
      Duration(milliseconds: (kTickIntervalSeconds * 1000).toInt()),
      (_) => _onHourTick(),
    );
  }

  void _onHourTick() {
    if (state == null) return;
    if (state!.shops.isEmpty) return;
    // Tagesgrenze: 14 Geschäftsstunden. Danach wartet das Spiel auf manuelles
    // Tag-Ende — verhindert "stundenlang Tag 1 stehen lassen = Millionär".
    if (state!.currentHour >= kDailyOpenHours.toInt()) return;

    final hourlyRevenue = GameEngine.calculateHourlyRevenue(state!);
    final hourlyCosts = GameEngine.calculateHourlyCosts(state!);
    final netHour = hourlyRevenue - hourlyCosts;

    state = state!.copyWith(
      cash: state!.cash + netHour,
      currentHour: state!.currentHour + 1,
    );

    // Live-Mission-Check: Cash-basierte Aufträge können sofort triggern.
    _checkMissions();
  }

  void stopTimers() {
    _tickTimer?.cancel();
  }

  // ── Manueller Tag-Ende ──────────────────────────────────────────────────

  void endDay() {
    if (state == null) return;
    final oldState = state!;
    final today = oldState.currentDay;

    final preview = _previewToday(oldState);

    var newState = GameEngine.processDay(oldState);

    // Ticks haben bereits einen Anteil von (Revenue - Kosten) zum Cash
    // hinzugefügt. processDay rechnet jetzt aber den vollen Tag (inkl. Loans).
    // Korrektur: den Tick-Anteil herausnehmen, damit nichts doppelt verbucht ist.
    final hoursElapsed = oldState.currentHour.clamp(0, kDailyOpenHours.toInt());
    final tickShare = hoursElapsed / kDailyOpenHours;
    final liveNetAlreadyAdded = (preview.revenue - preview.costs) * tickShare;
    newState = newState.copyWith(
      cash: newState.cash - liveNetAlreadyAdded,
      currentHour: 0, // Neuer Tag → Hour-Counter zurücksetzen
    );

    newState = newState.copyWith(
      customersServedTotal: oldState.customersServedTotal + preview.customers,
    );

    // Mitarbeiter-Pool difficulty-basiert rotieren
    final refreshIntervalDays = _employeePoolRefreshIntervalDays(newState);
    if (newState.currentDay - newState.lastEmployeePoolDay >=
        refreshIntervalDays) {
      newState = newState.copyWith(
        employeePool: _generateEmployeePool(newState),
        lastEmployeePoolDay: newState.currentDay,
      );
    }

    // Lucky-Trinkgeld: pro Lucky-Mitarbeiter 5% Chance auf Bonus
    double luckyBonus = 0;
    for (final shop in newState.shops) {
      for (final emp in shop.employees) {
        if (emp.hasTrait(PersonalityTrait.lucky) &&
            Random().nextDouble() < 0.05) {
          luckyBonus += 50 + Random().nextInt(150).toDouble();
        }
      }
    }
    if (luckyBonus > 0) {
      newState = newState.copyWith(cash: newState.cash + luckyBonus);
    }

    // Mission-Check
    final missionResult =
        MissionEngine.checkAndApply(newState, newState.missions);
    newState = missionResult.state;

    // Story-Kampagne: abgeschlossene Kapitel verbuchen (ggf. mehrere)
    CampaignChapter? chapterCompleted;
    for (int i = 0; i < kCampaignChapters.length; i++) {
      final r = CampaignEngine.checkAndApply(newState);
      if (r.justCompleted == null) break;
      newState = r.state;
      chapterCompleted ??= r.justCompleted;
    }

    // Achievement-Check
    final newAchievs = _checkAchievements(newState);
    if (newAchievs.isNotEmpty) {
      newState = newState.copyWith(
        achievementIds: [
          ...newState.achievementIds,
          ...newAchievs.map((a) => a.id),
        ],
      );
    }

    // Event ziehen (gewichtet)
    GameEvent? rolledEvent;
    final eventChance = (oldState.shops.length * 0.10).clamp(0.0, 0.45);
    if (Random().nextDouble() < eventChance && oldState.shops.isNotEmpty) {
      rolledEvent = _rollEvent(oldState);
    }

    // Quartalsbericht prüfen
    QuarterlyReport? quarterlyReport;
    if (CorporateEngine.isQuarterDue(newState)) {
      final (newStocks, report) =
          CorporateEngine.generateQuarterlyReport(newState);
      newState = newState.copyWith(stocks: newStocks);
      quarterlyReport = report;
    }

    // Wochen-Report alle 7 Tage (zu Beginn einer neuen Woche)
    WeeklyReport? weeklyReport;
    if (newState.currentDay > 7 && newState.currentDay % 7 == 1) {
      weeklyReport = GameEngine.buildWeeklyReport(newState);
    }

    // Steuer alle 30 Tage auf den Monatsgewinn
    double taxPaid = 0;
    if (newState.currentDay > 30 && (newState.currentDay - 1) % 30 == 0) {
      taxPaid = GameEngine.monthlyTaxDue(newState);
      if (taxPaid > 0) {
        newState = newState.copyWith(cash: newState.cash - taxPaid);
      }
    }

    // Daily Challenge auswerten
    bool challengeMet = false;
    double challengeReward = 0;
    if (oldState.shops.isNotEmpty) {
      final challenge = GameEngine.dailyChallenge(today);
      final yesterday =
          oldState.history.isNotEmpty ? oldState.history.last : null;
      final anyLoss = oldState.shops.any((s) {
        final r = GameEngine.calculateDailyRevenue(s,
            day: today, state: oldState);
        final c =
            GameEngine.calculateDailyCosts(s, day: today, state: oldState);
        return r - c < 0;
      });
      challengeMet = GameEngine.isChallengeMet(
        challenge,
        customersToday: preview.customers,
        revenueToday: preview.revenue,
        profitToday: preview.revenue - preview.costs,
        yesterday: yesterday,
        anyShopLoss: anyLoss,
      );
      if (challengeMet) {
        challengeReward = challenge.reward;
        newState = newState.copyWith(cash: newState.cash + challengeReward);
      }
    }

    state = newState;
    lastDayResult = DayEndResult(
      day: today,
      revenue: preview.revenue,
      costs: preview.costs,
      profit: preview.revenue - preview.costs - preview.loanPayments,
      customers: preview.customers,
      event: rolledEvent,
      missionCompleted: missionResult.justCompleted,
      newAchievements: newAchievs,
      quarterlyReport: quarterlyReport,
      chapterCompleted: chapterCompleted,
      weeklyReport: weeklyReport,
      taxPaid: taxPaid,
      challengeMet: challengeMet,
      challengeReward: challengeReward,
    );
    _completeTutorialStep(TutorialStep.endFirstDay, saveAfterUpdate: false);
    _save();
  }

  /// Spieler wählt eine Event-Option
  void applyEventChoice(GameEvent event, EventChoice choice) {
    if (state == null) return;
    final s = state!;
    final newCash = s.cash + choice.effect.cashDelta;

    final newShops = s.shops.map((shop) {
      final newRep =
          (shop.reputation + choice.effect.reputationDelta).clamp(0.5, 5.0);
      return shop.copyWith(reputation: newRep);
    }).toList();

    final newBrand = s.brand.copyWith(
      brandAwareness:
          (s.brand.brandAwareness + choice.effect.brandAwarenessDelta)
              .clamp(0.0, 100.0),
    );

    state = s.copyWith(
      cash: newCash,
      shops: newShops,
      brand: newBrand,
      seenEventIds: [...s.seenEventIds, event.id],
    );
    _save();
  }

  _DayPreview _previewToday(GameState s) {
    double revenue = 0;
    double costs = 0;
    int customers = 0;
    for (final shop in s.shops) {
      revenue +=
          GameEngine.calculateDailyRevenue(shop, day: s.currentDay, state: s);
      costs +=
          GameEngine.calculateDailyCosts(shop, day: s.currentDay, state: s);
      customers +=
          GameEngine.calculateDailyCustomers(shop, day: s.currentDay, state: s);
    }
    final loanPayments = s.loans
        .where((l) => !l.isPaidOff)
        .fold(0.0, (sum, l) => sum + l.dailyPayment);
    return _DayPreview(
      revenue: revenue,
      costs: costs,
      loanPayments: loanPayments,
      customers: customers,
    );
  }

  /// Event ziehen mit Anforderungs-Check und Gewichtung.
  GameEvent? _rollEvent(GameState state) {
    final hasMetro = state.shops.any((s) {
      final c = kAllCities.firstWhere(
        (c) => c.id == s.cityId,
        orElse: () => kAllCities.first,
      );
      return c.tier == CityTier.metropole;
    });

    // Filter: Anforderungen erfüllt?
    final eligible = kAllEvents.where((e) {
      if (e.requirements.minShops > state.shops.length) return false;
      if (e.requirements.minDay > state.currentDay) return false;
      if (e.requirements.minCash > state.cash) return false;
      if (e.requirements.needsMetropolitanShop && !hasMetro) return false;
      return true;
    }).toList();

    if (eligible.isEmpty) return null;

    // Bevorzuge ungesehene
    final unseen =
        eligible.where((e) => !state.seenEventIds.contains(e.id)).toList();
    final pool = unseen.isNotEmpty ? unseen : eligible;

    // Gewichtung
    final weights = pool.map((e) {
      switch (e.weight) {
        case EventWeight.rare:
          return 1;
        case EventWeight.normal:
          return 3;
        case EventWeight.common:
          return 6;
      }
    }).toList();
    final total = weights.fold(0, (s, w) => s + w);
    var pick = Random().nextInt(total);
    for (var i = 0; i < pool.length; i++) {
      pick -= weights[i];
      if (pick < 0) return pool[i];
    }
    return pool.first;
  }

  /// Achievements prüfen — returnt NEUE freigeschaltete.
  List<Achievement> _checkAchievements(GameState state) {
    final newOnes = <Achievement>[];
    final shopCount = state.shops.length;
    final empCount = state.employeeCount;
    final cash = state.cash;
    final day = state.currentDay;
    final customers = state.customersServedTotal;
    final maxRep = state.shops.isEmpty
        ? 0.0
        : state.shops.fold(0.0, (m, s) => s.reputation > m ? s.reputation : m);
    final brand = state.brand.brandAwareness;

    for (final a in kAllAchievements) {
      if (state.achievementIds.contains(a.id)) continue;
      if (a.check(shopCount, empCount, state.totalRevenue, cash, day, customers,
          maxRep, brand, 0)) {
        newOnes.add(a);
      }
    }
    return newOnes;
  }

  /// Mitarbeiter-Pool generieren (8-10 zufällige Kandidaten)
  List<Employee> _generateEmployeePool(GameState sourceState) {
    return HrEngine.generateCandidatePool(sourceState);
  }

  void markTutorialDone() {
    if (state == null) return;
    _finishTutorial();
  }

  void clearLastDayResult() {
    lastDayResult = null;
    _completeTutorialStep(TutorialStep.readDayReport);
  }

  // ── Spielaktionen ────────────────────────────────────────────────────────

  void openShop(Shop shop) {
    if (state == null) return;
    state = GameEngine.openShop(state!, shop);
    SoundService.play(Sfx.purchase);
    _completeTutorialStep(TutorialStep.openFirstShop, saveAfterUpdate: false);
    _checkMissions();
    _save();
  }

  void buyEquipment(String shopId, EquipmentData equipment) {
    if (state == null) return;
    state = GameEngine.buyEquipment(state!, shopId, equipment);
    SoundService.play(Sfx.purchase);
    _checkMissions();
    _save();
  }

  void hireEmployee(String shopId, Employee employee) {
    if (state == null) return;
    state = GameEngine.hireEmployee(state!, shopId, employee);
    SoundService.play(Sfx.purchase);
    _completeTutorialStep(TutorialStep.hireFirstEmployee,
        saveAfterUpdate: false);
    _checkMissions();
    _save();
  }

  void fireEmployee(String shopId, String employeeId) {
    if (state == null) return;
    state = GameEngine.fireEmployee(state!, shopId, employeeId);
    _save();
  }

  /// Filiale schließen (z.B. bei Insolvenz oder freiwillig). Spieler bekommt
  /// die Mietkaution (2 Wochen) zurück, alle Mitarbeiter werden entlassen.
  void closeShop(String shopId) {
    if (state == null) return;
    final s = state!;
    final shop = s.shops.firstWhere(
      (sh) => sh.id == shopId,
      orElse: () => s.shops.first,
    );
    final kaution = shop.weeklyRent * 2;
    final newShops = s.shops.where((sh) => sh.id != shopId).toList();
    state = s.copyWith(
      cash: s.cash + kaution,
      shops: newShops,
    );
    _save();
  }

  /// Insolvenz-Status: Cash unter Schwelle?
  bool get isBankrupt {
    final s = state;
    if (s == null) return false;
    return s.cash < 0;
  }

  void updateProductPrice(String shopId, String productId, double newPrice) {
    if (state == null) return;
    state = GameEngine.updateProductPrice(state!, shopId, productId, newPrice);
    _completeTutorialStep(TutorialStep.changeProductPrice,
        saveAfterUpdate: false);
    _checkMissions();
    _save();
  }

  bool get hasActiveTutorial {
    final s = state;
    if (s == null) return false;
    return s.tutorialEnabled && !s.tutorialDone;
  }

  TutorialStep? get currentTutorialStep {
    final s = state;
    if (s == null || !s.tutorialEnabled || s.tutorialDone) return null;
    return tutorialStepFromIndex(s.tutorialStep);
  }

  void skipTutorial() {
    if (state == null) return;
    state = state!.copyWith(tutorialEnabled: false);
    _save();
  }

  void resumeTutorial({bool restart = false}) {
    if (state == null) return;
    final s = state!;
    final nextStep =
        restart ? 0 : s.tutorialStep.clamp(0, kTutorialStepCount - 1);
    state = s.copyWith(
      tutorialEnabled: true,
      tutorialDone: false,
      tutorialStep: nextStep,
    );
    _save();
  }

  void acknowledgeTutorialStep() {
    final current = currentTutorialStep;
    if (current == null) return;
    switch (current) {
      case TutorialStep.understandLocationValues:
      case TutorialStep.viewDashboardMetrics:
      case TutorialStep.understandHrCompetitionGrowth:
        _completeTutorialStep(current);
        break;
      case TutorialStep.finishTutorial:
        _finishTutorial();
        break;
      default:
        break;
    }
  }

  void onTutorialTabOpened(int tabIndex) {
    final current = currentTutorialStep;
    if (current == null) return;
    if (current == TutorialStep.openEmpireMenu && tabIndex == 2) {
      _completeTutorialStep(TutorialStep.openEmpireMenu);
      return;
    }
    if (current == TutorialStep.understandLocationValues && tabIndex == 1) {
      _completeTutorialStep(TutorialStep.understandLocationValues);
      return;
    }
  }

  void takeLoan(Loan loan) {
    if (state == null) return;
    state = GameEngine.takeLoan(state!, loan);
    _save();
  }

  void payOffLoan(String loanId) {
    if (state == null) return;
    state = GameEngine.payOffLoan(state!, loanId);
    _save();
  }

  void extraLoanPayment(String loanId, double amount) {
    if (state == null) return;
    state = GameEngine.extraLoanPayment(state!, loanId, amount);
    _save();
  }

  void unlockCity(String cityId) {
    if (state == null) return;
    state = GameEngine.unlockCity(state!, cityId);
    _checkMissions();
    _save();
  }

  /// Marketing-Kampagne buchen
  void bookCampaign(String shopId, MarketingCampaign campaign) {
    if (state == null) return;
    state = GameEngine.bookCampaign(state!, shopId, campaign);
    _save();
  }

  /// Stadtweite Marketing-Kampagne buchen
  void bookCityCampaign(String cityId, MarketingCampaign campaign) {
    if (state == null) return;
    state = GameEngine.bookCityCampaign(state!, cityId, campaign);
    _save();
  }

  /// Konzernweite Marketing-Kampagne buchen
  void bookGlobalCampaign(MarketingCampaign campaign) {
    if (state == null) return;
    state = GameEngine.bookGlobalCampaign(state!, campaign);
    _save();
  }

  /// Globalen Preis für ein Produkt setzen (wirkt auf alle Filialen ohne Stadtpreis-Override)
  void setGlobalPrice(String productId, double price) {
    if (state == null) return;
    state = GameEngine.setGlobalPrice(state!, productId, price);
    _save();
  }

  /// Stadtweisen Preis für ein Produkt setzen
  void setCityPrice(String cityId, String productId, double price) {
    if (state == null) return;
    state = GameEngine.setCityPrice(state!, cityId, productId, price);
    _save();
  }

  /// Preisstrategie konzernweit anwenden: 'cheap' / 'normal' / 'premium'
  void applyPriceStrategy(String strategy) {
    if (state == null) return;
    state = GameEngine.applyPriceStrategy(state!, strategy);
    _save();
  }

  /// Setzt alle globalen Preise auf den umsatzoptimalen Vorschlag.
  void applyRecommendedPrices() {
    if (state == null) return;
    var s = state!;
    for (final p in kAllProducts) {
      final opt = GameEngine.revenueOptimalPrice(p.basePrice, s.difficulty);
      s = GameEngine.setGlobalPrice(s, p.id, opt);
    }
    state = s;
    SoundService.play(Sfx.purchase);
    _save();
  }

  /// Permanenten Shop-Upgrade kaufen (WLAN, Musik, Klima, etc.)
  void buyUpgrade(String shopId, UpgradeData upgrade) {
    if (state == null) return;
    state = GameEngine.buyUpgrade(state!, shopId, upgrade);
    SoundService.play(Sfx.purchase);
    _save();
  }

  /// Kosmetisches Marken-Thema (Skin) aktivieren.
  void setActiveTheme(String themeId) {
    if (state == null) return;
    if (state!.activeThemeId == themeId) return;
    state = state!.copyWith(activeThemeId: themeId);
    SoundService.play(Sfx.tap);
    _save();
  }

  /// Konzernweite Zutaten-Qualität eines Produkts setzen.
  void setProductQuality(String productId, IngredientQuality quality) {
    if (state == null) return;
    final map = Map<String, String>.from(state!.productQuality);
    map[productId] = quality.name;
    state = state!.copyWith(productQuality: map);
    SoundService.play(Sfx.tap);
    _save();
  }

  /// Menü-Angebot/Kombo konzernweit an-/abschalten.
  void toggleCombo(String comboId) {
    if (state == null) return;
    final s = state!;
    final active = List<String>.from(s.activeComboIds);
    if (active.contains(comboId)) {
      active.remove(comboId);
    } else {
      active.add(comboId);
      SoundService.play(Sfx.purchase);
    }
    state = s.copyWith(activeComboIds: active);
    _save();
  }

  // ── Corporate: IPO / Facilities / M&A / Manager ─────────────────────────

  /// IPO durchführen — Spieler gibt Anteile ab für großen Cash-Schub.
  void performIPO(double percentToFloat) {
    if (state == null) return;
    state = CorporateEngine.performIPO(state!, percentToFloat);
    _save();
  }

  /// Produktions-Anlage bauen
  void buildFacility(FacilityTemplate template) {
    if (state == null) return;
    state = CorporateEngine.buildFacility(state!, template);
    _save();
  }

  /// Konkurrenten aufkaufen
  void acquireCompetitor(Competitor c) {
    if (state == null) return;
    state = CorporateEngine.acquireCompetitor(state!, c);
    _save();
  }

  /// Auto-Hire pro Filiale togglen — HR-Manager stellt automatisch ein
  /// wenn Engpass + Cash vorhanden.
  void toggleAutoHire(String shopId) {
    if (state == null) return;
    final s = state!;
    final newShops = s.shops.map((shop) {
      if (shop.id != shopId) return shop;
      return shop.copyWith(autoHire: !shop.autoHire);
    }).toList();
    state = s.copyWith(shops: newShops);
    _save();
  }

  /// Mitarbeiter zum Manager machen
  void toggleManager(String employeeId) {
    if (state == null) return;
    final s = state!;
    if (s.managerEmployeeIds.contains(employeeId)) {
      state = CorporateEngine.unassignManager(s, employeeId);
    } else {
      state = CorporateEngine.assignManager(s, employeeId);
    }
    _save();
  }

  /// Pool manuell refreshen — kostet 500 € (Anti-Spam)
  void refreshEmployeePool() {
    if (state == null) return;
    final cost = employeePoolRefreshCostForCurrentDifficulty();
    if (state!.cash < cost) return;
    state = state!.copyWith(
      cash: state!.cash - cost,
      employeePool: _generateEmployeePool(state!),
      lastEmployeePoolDay: state!.currentDay,
    );
    _save();
  }

  double employeePoolRefreshCostForCurrentDifficulty() {
    final s = state;
    if (s == null) return 500.0;
    return _employeePoolRefreshCost(s);
  }

  static int _employeePoolRefreshIntervalDays(GameState state) {
    return HrEngine.poolRefreshIntervalDays(state);
  }

  static double _employeePoolRefreshCost(GameState state) {
    return HrEngine.poolRefreshCost(state);
  }

  void hireHrManager(String hrManagerId) {
    if (state == null) return;
    final s = state!;
    HrManager? picked;
    for (final candidate in s.hrCandidates) {
      if (candidate.id == hrManagerId) {
        picked = candidate;
        break;
      }
    }
    if (picked == null) return;
    state = s.copyWith(
      hrManager: picked,
      hrCandidates: const [],
    );
    _save();
  }

  void fireHrManager() {
    if (state == null) return;
    final s = state!;
    state = s.copyWith(clearHrManager: true);
    _save();
  }

  void setHrStrategy(HrStrategy strategy) {
    if (state == null) return;
    state = state!.copyWith(hrStrategy: strategy);
    _save();
  }

  void refreshHrCandidates() {
    if (state == null) return;
    final s = state!;
    state = s.copyWith(
      hrCandidates: HrEngine.generateHrCandidates(daySeed: s.currentDay),
    );
    _save();
  }

  Future<void> deleteGame() async {
    stopTimers();
    await SaveService.deleteSave();
    state = null;
  }

  Mission? _checkMissions() {
    if (state == null) return null;
    Mission? firstCompleted;
    for (int i = 0; i < 5; i++) {
      final r = MissionEngine.checkAndApply(state!, state!.missions);
      state = r.state;
      if (r.justCompleted == null) break;
      firstCompleted ??= r.justCompleted;
      ref.read(instantMissionProvider.notifier).state = r.justCompleted;
    }
    _checkCampaign();
    return firstCompleted;
  }

  /// Live-Prüfung der Story-Kampagne (z.B. direkt nach Filial-Eröffnung).
  void _checkCampaign() {
    if (state == null) return;
    for (int i = 0; i < kCampaignChapters.length; i++) {
      final r = CampaignEngine.checkAndApply(state!);
      if (r.justCompleted == null) break;
      state = r.state;
      ref.read(instantChapterProvider.notifier).state = r.justCompleted;
    }
  }

  void _save() => SaveService.save(state!);

  void _completeTutorialStep(
    TutorialStep expectedStep, {
    bool saveAfterUpdate = true,
  }) {
    final s = state;
    if (s == null || !s.tutorialEnabled || s.tutorialDone) return;
    final current = tutorialStepFromIndex(s.tutorialStep);
    if (current != expectedStep) return;
    if (current == TutorialStep.finishTutorial) {
      _finishTutorial(saveAfterUpdate: saveAfterUpdate);
      return;
    }

    final nextStep = (s.tutorialStep + 1).clamp(0, kTutorialStepCount - 1);
    state = s.copyWith(tutorialStep: nextStep);
    if (saveAfterUpdate) {
      _save();
    }
  }

  void _finishTutorial({bool saveAfterUpdate = true}) {
    final s = state;
    if (s == null || s.tutorialDone) return;

    state = s.copyWith(
      tutorialDone: true,
      tutorialEnabled: false,
      tutorialStep: kTutorialStepCount - 1,
      cash: s.cash + _tutorialCompletionReward,
    );
    if (saveAfterUpdate) {
      _save();
    }
  }
}

class _DayPreview {
  final double revenue;
  final double costs;
  final double loanPayments;
  final int customers;
  _DayPreview({
    required this.revenue,
    required this.costs,
    required this.loanPayments,
    required this.customers,
  });
}

final gameProvider =
    NotifierProvider<GameNotifier, GameState?>(GameNotifier.new);

// ── Berechnete Providers ──────────────────────────────────────────────────

final dailyRevenueProvider = Provider<double>((ref) {
  final game = ref.watch(gameProvider);
  if (game == null) return 0;
  return game.shops.fold(
      0.0,
      (sum, s) =>
          sum +
          GameEngine.calculateDailyRevenue(s,
              day: game.currentDay, state: game));
});

final dailyCostsProvider = Provider<double>((ref) {
  final game = ref.watch(gameProvider);
  if (game == null) return 0;
  return game.shops.fold(
      0.0,
      (sum, s) =>
          sum +
          GameEngine.calculateDailyCosts(s, day: game.currentDay, state: game));
});

final dailyProfitProvider = Provider<double>((ref) {
  return ref.watch(dailyRevenueProvider) - ref.watch(dailyCostsProvider);
});

final activeMissionProvider = Provider<Mission?>((ref) {
  final game = ref.watch(gameProvider);
  if (game == null) return null;
  return MissionEngine.activeMission(game.missions);
});

final activeMissionProgressProvider = Provider<double>((ref) {
  final game = ref.watch(gameProvider);
  if (game == null) return 0;
  return MissionEngine.activeProgress(game, game.missions);
});

final instantMissionProvider = StateProvider<Mission?>((_) => null);

// ── Story-Kampagne ─────────────────────────────────────────────────────────

/// Aktuelles Kampagnen-Kapitel (null, wenn durchgespielt).
final activeChapterProvider = Provider<CampaignChapter?>((ref) {
  final game = ref.watch(gameProvider);
  if (game == null) return null;
  return CampaignEngine.activeChapter(game);
});

/// Fortschritt (0..1) des aktuellen Kapitels.
final activeChapterProgressProvider = Provider<double>((ref) {
  final game = ref.watch(gameProvider);
  if (game == null) return 0;
  final chapter = CampaignEngine.activeChapter(game);
  if (chapter == null) return 1.0;
  return CampaignEngine.chapterProgress(chapter, game);
});

/// Für die Live-Feier eines frisch abgeschlossenen Kapitels.
final instantChapterProvider = StateProvider<CampaignChapter?>((_) => null);
