import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_state.dart';
import '../models/shop_model.dart';
import '../models/employee_model.dart';
import '../models/equipment_model.dart';
import '../models/mission_model.dart';
import '../models/event_model.dart';
import '../services/game_engine.dart';
import '../services/mission_engine.dart';
import '../services/save_service.dart';
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

  DayEndResult({
    required this.day,
    required this.revenue,
    required this.costs,
    required this.profit,
    required this.customers,
    this.event,
    this.missionCompleted,
  });
}

class GameNotifier extends Notifier<GameState?> {
  Timer? _tickTimer;

  /// Last day-end result für Dialog-Anzeige. Wird von Dashboard ge-watch'd.
  DayEndResult? lastDayResult;

  @override
  GameState? build() => null;

  // ── Spiel starten / laden ────────────────────────────────────────────────

  Future<void> startNewGame(String companyName, String founderName) async {
    state = GameState.initial(
      companyName: companyName,
      founderName: founderName,
      startCash: kStartingCash,
    );
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

  // ── Stündliche Echtzeit-Einnahmen (nur Kontostand-Tropfen) ────────────

  void _startTickTimer() {
    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(
      Duration(milliseconds: (kTickIntervalSeconds * 1000).toInt()),
      (_) => _onHourTick(),
    );
  }

  void _onHourTick() {
    if (state == null) return;
    final hourlyRevenue = GameEngine.calculateHourlyRevenue(state!);
    // Kein Day-Auto-End mehr! Spieler entscheidet manuell.
    state = state!.copyWith(cash: state!.cash + hourlyRevenue);
  }

  void stopTimers() {
    _tickTimer?.cancel();
  }

  // ── Manueller Tag-Ende ──────────────────────────────────────────────────

  /// Beendet den aktuellen Spieltag. Zieht Kosten/Kredite ab, ruft
  /// Mission-Check & Event-Auswahl. Speichert das Ergebnis in [lastDayResult]
  /// damit das UI einen Summary-Dialog zeigen kann.
  void endDay() {
    if (state == null) return;
    final oldState = state!;
    final today = oldState.currentDay;

    // Heutige Werte vor Tagesabschluss messen
    final preview = _previewToday(oldState);

    // GameEngine.processDay verändert Reputation, History, Loans, Cash...
    var newState = GameEngine.processDay(oldState);

    // Heutige Kosten/Loans wurden bereits im stündlichen Tick simuliert?
    // Nein — der hourly tick fügt nur Revenue zu. Day-End rechnet die Kosten ab.
    // Da processDay den vollen netCash anwendet (revenue - costs - loanPay) UND
    // wir aber bereits die Revenue über den ganzen Tag ausgezahlt haben,
    // müssen wir die doppelt gezahlte Revenue rückerstatten.
    final dailyRevenueDup = preview.revenue;
    newState = newState.copyWith(
      cash: newState.cash - dailyRevenueDup,
    );

    // Kunden-Counter
    newState = newState.copyWith(
      customersServedTotal: oldState.customersServedTotal + preview.customers,
    );

    // Mission-Check (kann Belohnung in Cash addieren)
    final missionResult =
        MissionEngine.checkAndApply(newState, newState.missions);
    newState = missionResult.state;

    // Event ziehen (20-30% Chance, je nach Filialen)
    GameEvent? rolledEvent;
    final eventChance = (oldState.shops.length * 0.10).clamp(0.0, 0.40);
    if (Random().nextDouble() < eventChance && oldState.shops.isNotEmpty) {
      rolledEvent = _rollEvent(oldState.seenEventIds);
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
    );
    _save();
  }

  /// Spieler wählt eine Event-Option (oder schließt ohne Wahl)
  void applyEventChoice(GameEvent event, EventChoice choice) {
    if (state == null) return;
    final s = state!;
    final newCash = s.cash + choice.effect.cashDelta;

    // Reputation auf alle Shops anwenden (vereinfacht)
    final newShops = s.shops.map((shop) {
      final newRep =
          (shop.reputation + choice.effect.reputationDelta).clamp(0.5, 5.0);
      return shop.copyWith(reputation: newRep);
    }).toList();

    state = s.copyWith(
      cash: newCash,
      shops: newShops,
      seenEventIds: [...s.seenEventIds, event.id],
    );
    _save();
  }

  _DayPreview _previewToday(GameState s) {
    double revenue = 0;
    double costs = 0;
    int customers = 0;
    for (final shop in s.shops) {
      revenue += GameEngine.calculateDailyRevenue(shop, day: s.currentDay);
      costs += GameEngine.calculateDailyCosts(shop, day: s.currentDay);
      customers += GameEngine.calculateDailyCustomers(shop, day: s.currentDay);
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

  GameEvent? _rollEvent(List<String> seenIds) {
    // Bevorzuge ungesehene Events, sonst random
    final unseen =
        kAllEvents.where((e) => !seenIds.contains(e.id)).toList();
    final pool = unseen.isNotEmpty ? unseen : kAllEvents;
    return pool[Random().nextInt(pool.length)];
  }

  void markTutorialDone() {
    if (state == null) return;
    state = state!.copyWith(tutorialDone: true);
    _save();
  }

  void clearLastDayResult() {
    lastDayResult = null;
  }

  // ── Spielaktionen ────────────────────────────────────────────────────────

  void openShop(Shop shop) {
    if (state == null) return;
    state = GameEngine.openShop(state!, shop);
    _checkMissions();
    _save();
  }

  void buyEquipment(String shopId, EquipmentData equipment) {
    if (state == null) return;
    state = GameEngine.buyEquipment(state!, shopId, equipment);
    _checkMissions();
    _save();
  }

  void hireEmployee(String shopId, Employee employee) {
    if (state == null) return;
    state = GameEngine.hireEmployee(state!, shopId, employee);
    _checkMissions();
    _save();
  }

  void fireEmployee(String shopId, String employeeId) {
    if (state == null) return;
    state = GameEngine.fireEmployee(state!, shopId, employeeId);
    _save();
  }

  void updateProductPrice(String shopId, String productId, double newPrice) {
    if (state == null) return;
    state = GameEngine.updateProductPrice(state!, shopId, productId, newPrice);
    _checkMissions();
    _save();
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

  Future<void> deleteGame() async {
    stopTimers();
    await SaveService.deleteSave();
    state = null;
  }

  /// Prüft nach jeder Spielaktion ob eine Mission gerade erfüllt wurde.
  /// Belohnung wird direkt auf den State angewendet.
  /// Schreibt die erfüllte Mission in [instantMissionProvider] damit das UI
  /// SOFORT (nicht erst am Tag-Ende) einen Glückwunsch-Dialog zeigt.
  /// Kettet mehrere Erledigungen: falls eine Mission durch die Belohnung
  /// (Cash) eine andere Mission triggert, wird auch die geprüft.
  Mission? _checkMissions() {
    if (state == null) return null;
    Mission? firstCompleted;
    // Maximal 5 Iterationen (Schutz vor Endlos-Schleife)
    for (int i = 0; i < 5; i++) {
      final r = MissionEngine.checkAndApply(state!, state!.missions);
      state = r.state;
      if (r.justCompleted == null) break;
      firstCompleted ??= r.justCompleted;
      // ins Stream-Provider schreiben
      ref.read(instantMissionProvider.notifier).state = r.justCompleted;
    }
    return firstCompleted;
  }

  void _save() => SaveService.save(state!);
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

final gameProvider = NotifierProvider<GameNotifier, GameState?>(GameNotifier.new);

// ── Berechnete Providers ──────────────────────────────────────────────────

final dailyRevenueProvider = Provider<double>((ref) {
  final game = ref.watch(gameProvider);
  if (game == null) return 0;
  return game.shops.fold(0.0, (sum, s) => sum + GameEngine.calculateDailyRevenue(s, day: game.currentDay));
});

final dailyCostsProvider = Provider<double>((ref) {
  final game = ref.watch(gameProvider);
  if (game == null) return 0;
  return game.shops.fold(0.0, (sum, s) => sum + GameEngine.calculateDailyCosts(s, day: game.currentDay));
});

final dailyProfitProvider = Provider<double>((ref) {
  return ref.watch(dailyRevenueProvider) - ref.watch(dailyCostsProvider);
});

/// Aktive Mission (nicht null bis alle erledigt sind)
final activeMissionProvider = Provider<Mission?>((ref) {
  final game = ref.watch(gameProvider);
  if (game == null) return null;
  return MissionEngine.activeMission(game.missions);
});

/// Progress (0..1) der aktiven Mission
final activeMissionProgressProvider = Provider<double>((ref) {
  final game = ref.watch(gameProvider);
  if (game == null) return 0;
  return MissionEngine.activeProgress(game, game.missions);
});

/// One-shot Stream-Provider: enthält die gerade soeben erfüllte Mission
/// (sofort, nicht erst am Tag-Ende). UI lauscht via ref.listen und zeigt
/// den Glückwunsch-Dialog. Nach dem Anzeigen setzt UI auf null zurück.
final instantMissionProvider = StateProvider<Mission?>((_) => null);
