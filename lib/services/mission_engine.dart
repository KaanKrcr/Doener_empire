import '../models/mission_model.dart';
import '../models/game_state.dart';
import '../models/difficulty_model.dart';
import '../core/constants.dart';
import '../models/city_model.dart';

/// Prüft den GameState gegen alle Missions, returned die Liste mit
/// frisch erfüllten Missions (Belohnung bereits angewendet).
class MissionEngine {
  /// Aktuelle aktive Mission = erste die nicht done ist.
  /// Returns null wenn alle erledigt sind.
  static Mission? activeMission(List<Mission> missions) {
    for (final m in missions) {
      if (!m.isDone) return m;
    }
    return null;
  }

  /// Anzahl erledigter Missions
  static int doneCount(List<Mission> missions) =>
      missions.where((m) => m.isDone).length;

  /// Progress (0..1) der aktiven Mission gegen ihr Target.
  /// Returns 1.0 wenn die aktive Mission erfüllt ist (wird im nächsten
  /// `checkAndApply` als done markiert).
  static double activeProgress(GameState state, List<Mission> missions) {
    final m = activeMission(missions);
    if (m == null) return 1.0;
    final cur = _progressAdjustedValue(m, state);
    return (cur / m.target).clamp(0.0, 1.0);
  }

  /// Aktuelle Zahl für eine bestimmte Mission (z.B. "wie viele Mitarbeiter").
  static double currentValueFor(Mission m, GameState state) =>
      _currentValue(m, state);

  /// Hauptmethode: prüft die aktuell aktive Mission und gibt sie zurück
  /// wenn sie *jetzt* fertig wurde (für Confetti-Animation).
  /// Wendet die Belohnung an = neuer State.
  static MissionCheckResult checkAndApply(
      GameState state, List<Mission> missions) {
    final m = activeMission(missions);
    if (m == null) return MissionCheckResult(state: state, justCompleted: null);

    final cur = _progressAdjustedValue(m, state);
    if (cur >= m.target) {
      m.isDone = true;
      final newState = state.copyWith(
        cash: state.cash + m.cashReward,
      );
      return MissionCheckResult(state: newState, justCompleted: m);
    }
    return MissionCheckResult(state: state, justCompleted: null);
  }

  // ── Helper: aktuelles Mess-Ergebnis pro Mission-Typ ────────────────────

  static double _progressAdjustedValue(Mission m, GameState state) {
    final current = _currentValue(m, state);
    final speed = state.difficulty.modifiers.progressSpeedMultiplier;
    switch (m.type) {
      case MissionType.totalRevenue:
      case MissionType.reachCash:
      case MissionType.unlockCity:
        return current * speed;
      default:
        return current;
    }
  }

  static double _currentValue(Mission m, GameState state) {
    switch (m.type) {
      case MissionType.openFirstShop:
        return state.shops.length.toDouble();
      case MissionType.totalRevenue:
        return state.totalRevenue;
      case MissionType.hireEmployees:
        return state.employeeCount.toDouble();
      case MissionType.buyEquipment:
        return state.shops
            .fold<int>(0, (s, sh) => s + sh.equipment.length)
            .toDouble();
      case MissionType.unlockProduct:
        // Wie viele Equipment-Items haben Produkte freigeschaltet?
        // Wir prüfen: gibt es ein gekauftes Equipment mit unlocksProductId?
        for (final shop in state.shops) {
          for (final se in shop.equipment) {
            final eq = kAllEquipment.firstWhere((e) => e.id == se.equipmentId);
            if (eq.unlocksProductId != null) return 1;
          }
        }
        return 0;
      case MissionType.reachCash:
        return state.cash;
      case MissionType.shopCount:
        // Sonderfall metropole: nur Metropolen-Shops zählen
        if (m.id == 'metropole') {
          return state.shops
              .where((s) {
                final city = kAllCities.firstWhere((c) => c.id == s.cityId);
                return city.tier == CityTier.metropole;
              })
              .length
              .toDouble();
        }
        return state.shops.length.toDouble();
      case MissionType.unlockCity:
        // 3 Start-Städte sind frei, erst ab 4. zählt
        return (state.unlockedCityIds.length - 3).clamp(0, 1000).toDouble();
      case MissionType.daysSurvived:
        return state.currentDay.toDouble();
      case MissionType.reputationLevel:
        if (state.shops.isEmpty) return 0;
        return state.shops.fold<double>(
            0, (max, s) => s.reputation > max ? s.reputation : max);
      case MissionType.companyPublic:
        return state.stocks.isPublic ? 1 : 0;
      case MissionType.brandAwareness:
        return state.brand.brandAwareness;
      case MissionType.acquiredShops:
        return state.shops.where((s) => s.wasAcquired).length.toDouble();
    }
  }
}

class MissionCheckResult {
  final GameState state;
  final Mission? justCompleted;
  MissionCheckResult({required this.state, required this.justCompleted});
}
