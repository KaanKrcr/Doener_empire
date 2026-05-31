import 'dart:math';

import '../models/competitor_model.dart';
import '../models/difficulty_model.dart';
import '../models/game_state.dart';
import '../models/product_model.dart';
import '../core/constants.dart';
import '../models/city_model.dart';

/// Steuert das Verhalten der KI-Konkurrenten.
///
/// - Beim ersten Eröffnen einer Filiale in einer Stadt werden 1–3 Konkurrenten gespawnt.
/// - Täglich (oder alle paar Tage) reagieren die Konkurrenten:
///     * Aggressive eröffnen neue Filialen
///     * Premium passen Preise nach oben
///     * Günstige passen Preise nach unten
/// - Marktanteile werden täglich auf Basis von Reputation + Preisniveau neu verteilt.
class CompetitorEngine {
  static final _rng = Random();

  /// Liefert Konkurrenten für eine Stadt — spawnt sie wenn noch keine da sind.
  /// Sollte beim ersten Eröffnen einer Filiale in der Stadt aufgerufen werden.
  static List<Competitor> ensureCompetitorsForCity(
    List<Competitor> existing,
    String cityId,
    GameDifficulty difficulty,
  ) {
    final existingInCity = existing.where((c) => c.cityId == cityId).toList();
    if (existingInCity.isNotEmpty) return existing;

    final city = kAllCities.firstWhere(
      (c) => c.id == cityId,
      orElse: () => kAllCities.first,
    );

    // Wie viele Konkurrenten je nach Stadtgröße?
    int count;
    switch (city.tier) {
      case CityTier.klein:
        count = 1;
        break;
      case CityTier.mittel:
        count = 2;
        break;
      case CityTier.gross:
        count = 3;
        break;
      case CityTier.metropole:
        count = 3 + _rng.nextInt(2);
        break;
    }
    final spawnBonus = difficulty.modifiers.competitorAggressivenessMultiplier;
    final extra = ((spawnBonus - 1.0) * 2).round().clamp(0, 2);
    count += extra;

    final newCompetitors = <Competitor>[];
    for (var i = 0; i < count; i++) {
      newCompetitors.add(CompetitorFactory.create(
        id: 'comp_${cityId}_${DateTime.now().microsecondsSinceEpoch}_$i',
        cityId: cityId,
      ));
    }

    return [...existing, ...newCompetitors];
  }

  /// Tägliches Update aller Konkurrenten + Marktanteils-Berechnung.
  /// Wird in [GameEngine.processDay] aufgerufen.
  static List<Competitor> processDay(GameState state) {
    final aggressiveness =
        state.difficulty.modifiers.competitorAggressivenessMultiplier;
    final updated = state.competitors.map((c) {
      c.daysSinceLastAction += 1;
      _maybeAct(c, state, aggressiveness);
      return c;
    }).toList();

    // Marktaustritt: dauerhaft schwache Konkurrenten schrumpfen und verlassen
    // ggf. den Markt. Der letzte Wettbewerber einer Stadt bleibt erhalten,
    // damit kein Markt komplett verödet.
    final cityCounts = <String, int>{};
    for (final c in updated) {
      cityCounts.update(c.cityId, (v) => v + 1, ifAbsent: () => 1);
    }
    final survivors = <Competitor>[];
    for (final c in updated) {
      final lastInCity = (cityCounts[c.cityId] ?? 1) <= 1;
      if (_maybeDeclineOrExit(c, aggressiveness, lastInCity)) {
        cityCounts[c.cityId] = (cityCounts[c.cityId] ?? 1) - 1;
        continue; // hat den Markt verlassen
      }
      survivors.add(c);
    }

    // Marktanteile neu berechnen pro Stadt
    final byCity = <String, List<Competitor>>{};
    for (final c in survivors) {
      byCity.putIfAbsent(c.cityId, () => []).add(c);
    }
    byCity.forEach((cityId, list) {
      _recomputeMarketShares(list, state, cityId);
    });

    return survivors;
  }

  /// Schwache Konkurrenten (niedrige Reputation UND Marktanteil) schrumpfen
  /// nach und nach: Erst verlieren sie Filialen, dann verlassen sie den Markt.
  /// Liefert `true`, wenn der Konkurrent ausgeschieden ist.
  /// Difficulty-skaliert (aggressivere Märkte = zähere Konkurrenz) und der
  /// letzte Wettbewerber einer Stadt scheidet nie durch Schwäche aus.
  /// Ein Konkurrent gilt als strauchelnd, wenn Reputation UND Marktanteil
  /// dauerhaft niedrig sind. Solche Ketten expandieren nicht und können
  /// schrumpfen/ausscheiden.
  static bool _isStruggling(Competitor c) =>
      c.reputation < 2.6 && c.marketShare < 0.06;

  static bool _maybeDeclineOrExit(
    Competitor c,
    double aggressiveness,
    bool lastInCity,
  ) {
    if (!_isStruggling(c)) return false;
    final chance = (0.06 / aggressiveness).clamp(0.02, 0.12);
    if (_rng.nextDouble() > chance) return false;
    if (c.shopCount > 1) {
      c.shopCount -= 1; // Kontraktion statt sofortigem Aus
      c.reputation = (c.reputation - 0.05).clamp(1.0, 5.0);
      return false;
    }
    if (lastInCity) return false; // letzten Wettbewerber nicht entfernen
    return true; // Marktaustritt
  }

  /// Wie stark drückt die Konkurrenz auf eine Spieler-Filiale in dieser Stadt?
  /// Liefert 0.6..1.05 — kleiner = mehr Druck.
  static double competitionPressure(
      GameState state, String cityId, double playerShopRep) {
    final inCity = state.competitorsIn(cityId);
    if (inCity.isEmpty) return 1.0;
    final aggressiveness =
        state.difficulty.modifiers.competitorAggressivenessMultiplier;

    // Wenn der Spieler im Vergleich schlechte Rep hat → Druck.
    double avgRivalRep =
        inCity.fold(0.0, (s, c) => s + c.reputation) / inCity.length;
    final repDelta = playerShopRep - avgRivalRep; // positiv = Spieler besser

    // Konkurrenz-Anzahl × Stärke
    final density = inCity.fold(0, (s, c) => s + c.shopCount) / 3.0;

    // Basis-Druck steigt mit Density
    double pressure = 1.0 - (density * 0.05 * aggressiveness);
    // Reputations-Bonus / Malus
    final defenseFactor = (1 / aggressiveness).clamp(0.6, 1.4);
    pressure += repDelta * 0.04 * defenseFactor;

    return pressure.clamp(0.55, 1.10);
  }

  // ── Private ──────────────────────────────────────────────────────────────

  /// Konkurrent macht ggf. eine Aktion (Preiskampf, Expansion, Rep-Update).
  static void _maybeAct(
    Competitor c,
    GameState state,
    double aggressiveness,
  ) {
    final minDays = (5 / aggressiveness).round().clamp(2, 9);
    if (c.daysSinceLastAction < minDays) return;

    final baseActionChance = switch (c.personality) {
      CompetitorPersonality.aggressive => 0.40,
      CompetitorPersonality.cheapMass => 0.25,
      CompetitorPersonality.balanced => 0.18,
      CompetitorPersonality.premium => 0.15,
      CompetitorPersonality.traditional => 0.10,
    };
    final actionChance = (baseActionChance * aggressiveness).clamp(0.05, 0.90);
    if (_rng.nextDouble() > actionChance) return;

    c.daysSinceLastAction = 0;

    // Welche Aktion?
    final r = _rng.nextDouble();
    final expansionChance = (0.30 * aggressiveness).clamp(0.15, 0.55);
    final priceChance =
        (0.30 + (aggressiveness - 1.0) * 0.10).clamp(0.20, 0.50);
    if (r < expansionChance && c.shopCount < 5 && !_isStruggling(c)) {
      // Expansion (strauchelnde Ketten expandieren nicht)
      c.shopCount = (c.shopCount + 1).clamp(1, 5);
      c.reputation = (c.reputation - 0.05).clamp(1.0, 5.0); // dilution
    } else if (r < expansionChance + priceChance) {
      // Preis-Anpassung: Reaktion auf das Spieler-Preisniveau in der Stadt.
      _reactToPlayerPrice(c, state);
    } else {
      // Reputations-Pflege oder -Schwächung
      final delta = (_rng.nextDouble() - 0.45) * 0.20;
      c.reputation = (c.reputation + delta).clamp(1.0, 5.0);
    }
  }

  /// Durchschnittliches Preisniveau des Spielers in einer Stadt — Preis geteilt
  /// durch Basispreis, gemittelt über die aktiven Menüs aller Spieler-Filialen.
  /// `null`, wenn der Spieler dort (noch) keine Filiale betreibt.
  static double? _playerPriceLevel(GameState state, String cityId) {
    double sum = 0;
    int n = 0;
    for (final shop in state.shops.where((s) => s.cityId == cityId)) {
      for (final sp in shop.menu.where((p) => p.isActive)) {
        ProductData? pd;
        for (final p in kAllProducts) {
          if (p.id == sp.productId) {
            pd = p;
            break;
          }
        }
        if (pd == null || pd.basePrice <= 0) continue;
        sum += sp.price / pd.basePrice;
        n++;
      }
    }
    if (n == 0) return null;
    return sum / n;
  }

  /// Konkurrent passt sein Preisniveau an das des Spielers an. Je nach
  /// Persönlichkeit unterbietet er ihn, setzt sich bewusst darüber oder zieht
  /// nach. Ohne Spieler-Filiale in der Stadt nur sanfte Eigendrift.
  static void _reactToPlayerPrice(Competitor c, GameState state) {
    final playerLevel = _playerPriceLevel(state, c.cityId);
    if (playerLevel == null) {
      final drift = switch (c.personality) {
        CompetitorPersonality.premium => 0.03,
        CompetitorPersonality.cheapMass => -0.03,
        CompetitorPersonality.aggressive => -0.02,
        _ => (_rng.nextDouble() - 0.5) * 0.04,
      };
      c.priceLevel = (c.priceLevel + drift).clamp(0.65, 1.4);
      return;
    }

    // (Offset zum Spieler-Niveau, Reaktionsgeschwindigkeit) je Persönlichkeit.
    final (offset, step) = switch (c.personality) {
      CompetitorPersonality.aggressive => (-0.12, 0.50),
      CompetitorPersonality.cheapMass => (-0.18, 0.35),
      CompetitorPersonality.balanced => (0.0, 0.40),
      CompetitorPersonality.premium => (0.15, 0.35),
      CompetitorPersonality.traditional => (0.05, 0.15),
    };
    final target = (playerLevel + offset).clamp(0.65, 1.4);
    c.priceLevel =
        (c.priceLevel + (target - c.priceLevel) * step).clamp(0.65, 1.4);
  }

  /// Verteilt die Marktanteile auf Konkurrenten + Spieler-Anteil basierend auf
  /// Reputation × Preisniveau × Filialdichte. Spieler ist separat — die
  /// Konkurrenten-Anteile addieren sich nicht auf 1.0, sondern auf 1.0 - playerShare.
  static void _recomputeMarketShares(
    List<Competitor> competitors,
    GameState state,
    String cityId,
  ) {
    if (competitors.isEmpty) return;
    final aggressiveness =
        state.difficulty.modifiers.competitorAggressivenessMultiplier;

    // Spieler-Power in dieser Stadt
    final playerShops = state.shops.where((s) => s.cityId == cityId).toList();
    final playerPower = playerShops.fold(0.0, (sum, s) {
      final repScore = s.reputation / 5.0; // 0..1
      const priceScore = 1.0; // im einfachen Modell neutral
      return sum + repScore * priceScore;
    });

    // Konkurrenten-Power
    final compPower = competitors.fold(0.0, (sum, c) {
      // niedrigerer Preis = etwas mehr Power
      final priceScore = (2.0 - c.priceLevel).clamp(0.5, 1.5);
      return sum +
          (c.reputation / 5.0) * priceScore * c.shopCount * aggressiveness;
    });

    final totalPower = playerPower + compPower;
    if (totalPower <= 0) return;

    for (final c in competitors) {
      final priceScore = (2.0 - c.priceLevel).clamp(0.5, 1.5);
      final p =
          (c.reputation / 5.0) * priceScore * c.shopCount * aggressiveness;
      c.marketShare = (p / totalPower).clamp(0.0, 1.0);
    }
  }
}
