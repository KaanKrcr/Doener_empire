import 'game_state.dart';

/// Achievements / Trophies — anders als Missions, die linear sind,
/// sind diese ungeordnet und triggern bei Erfüllung einmalig.
///
/// Funktion: Long-Term-Engagement, "noch eine Runde"-Effekt, Sammeltrieb.
class Achievement {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final AchievementTier tier;
  final AchievementCheck check;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.tier,
    required this.check,
  });
}

enum AchievementTier { bronze, silber, gold, platin }

extension AchievementTierLabel on AchievementTier {
  String get label {
    switch (this) {
      case AchievementTier.bronze:
        return 'Bronze';
      case AchievementTier.silber:
        return 'Silber';
      case AchievementTier.gold:
        return 'Gold';
      case AchievementTier.platin:
        return 'Platin';
    }
  }

  int get points {
    switch (this) {
      case AchievementTier.bronze:
        return 10;
      case AchievementTier.silber:
        return 25;
      case AchievementTier.gold:
        return 50;
      case AchievementTier.platin:
        return 100;
    }
  }
}

/// Funktion-Signatur für Achievement-Prüfung.
/// Erhält den vollständigen [GameState] und prüft, ob das Achievement erfüllt
/// ist. (Früher positionsbasiert — jetzt zustandsbasiert, damit auch neue
/// Felder wie Prestige oder Einkaufsverträge abgefragt werden können.)
typedef AchievementCheck = bool Function(GameState state);

/// Höchste Filial-Reputation im aktuellen Stand (0, wenn keine Filiale).
double _maxRep(GameState s) => s.shops.isEmpty
    ? 0.0
    : s.shops.fold(0.0, (m, sh) => sh.reputation > m ? sh.reputation : m);

/// Anzahl verschiedener Städte mit eigener Filiale.
int _distinctCities(GameState s) =>
    s.shops.map((sh) => sh.cityId).toSet().length;

/// Achievement-Pool. Wird in MainScaffold + Engine geprüft.
final List<Achievement> kAllAchievements = [
  // Bronze
  Achievement(
    id: 'first_shop',
    title: 'Tag 1 als Boss',
    description: 'Eröffne deine erste Filiale.',
    emoji: '🥙',
    tier: AchievementTier.bronze,
    check: (s) => s.shops.isNotEmpty,
  ),
  Achievement(
    id: 'first_week',
    title: 'Eine Woche überstanden',
    description: 'Erreiche Tag 7 ohne Pleite.',
    emoji: '📅',
    tier: AchievementTier.bronze,
    check: (s) => s.currentDay >= 7,
  ),
  Achievement(
    id: 'first_5_employees',
    title: 'Kleines Team',
    description: 'Stelle insgesamt 5 Mitarbeiter ein.',
    emoji: '👥',
    tier: AchievementTier.bronze,
    check: (s) => s.employeeCount >= 5,
  ),
  Achievement(
    id: 'thousand_customers',
    title: '1.000 Kunden',
    description: 'Bediene insgesamt 1.000 Kunden.',
    emoji: '👥',
    tier: AchievementTier.bronze,
    check: (s) => s.customersServedTotal >= 1000,
  ),

  // Silber
  Achievement(
    id: 'three_cities',
    title: 'Regional aufgestellt',
    description: 'Filialen in 3 verschiedenen Städten.',
    emoji: '🗺️',
    tier: AchievementTier.silber,
    check: (s) => _distinctCities(s) >= 3,
  ),
  Achievement(
    id: 'rep_45',
    title: 'Premium-Adresse',
    description: 'Erreiche 4,5 Reputation in einer Filiale.',
    emoji: '⭐',
    tier: AchievementTier.silber,
    check: (s) => _maxRep(s) >= 4.5,
  ),
  Achievement(
    id: 'cash_50k',
    title: 'Fünfstellig',
    description: 'Erreiche 50.000 € Konto.',
    emoji: '💵',
    tier: AchievementTier.silber,
    check: (s) => s.cash >= 50000,
  ),
  Achievement(
    id: 'thirty_days',
    title: 'Ein Monat im Geschäft',
    description: 'Überlebe 30 Tage.',
    emoji: '📆',
    tier: AchievementTier.silber,
    check: (s) => s.currentDay >= 30,
  ),

  // Gold
  Achievement(
    id: 'ten_shops',
    title: 'Kettenbetreiber',
    description: 'Eröffne 10 Filialen.',
    emoji: '🏬',
    tier: AchievementTier.gold,
    check: (s) => s.shops.length >= 10,
  ),
  Achievement(
    id: 'cash_250k',
    title: 'Viertelmillionär',
    description: 'Erreiche 250.000 € Konto.',
    emoji: '💎',
    tier: AchievementTier.gold,
    check: (s) => s.cash >= 250000,
  ),
  Achievement(
    id: 'brand_40',
    title: 'Etablierte Marke',
    description: 'Markenbekanntheit 40+.',
    emoji: '📢',
    tier: AchievementTier.gold,
    check: (s) => s.brand.brandAwareness >= 40,
  ),
  Achievement(
    id: 'ten_thousand_customers',
    title: '10.000 Kunden bedient',
    description: 'Bediene 10.000 Kunden insgesamt.',
    emoji: '🥳',
    tier: AchievementTier.gold,
    check: (s) => s.customersServedTotal >= 10000,
  ),

  // Platin
  Achievement(
    id: 'million_revenue',
    title: 'Million-Euro-Boss',
    description: '1.000.000 € Gesamtumsatz.',
    emoji: '👑',
    tier: AchievementTier.platin,
    check: (s) => s.totalRevenue >= 1000000,
  ),
  Achievement(
    id: 'brand_80',
    title: 'Legendäre Marke',
    description: 'Markenbekanntheit 80+.',
    emoji: '🌟',
    tier: AchievementTier.platin,
    check: (s) => s.brand.brandAwareness >= 80,
  ),
  Achievement(
    id: 'twenty_shops',
    title: 'Imperium-Modus',
    description: '20 Filialen aktiv.',
    emoji: '🏰',
    tier: AchievementTier.platin,
    check: (s) => s.shops.length >= 20,
  ),

  // Zusätzliche Langzeit-Ziele
  Achievement(
    id: 'five_star_shop',
    title: 'Perfekte Filiale',
    description: 'Erreiche die volle 5,0 Reputation in einer Filiale.',
    emoji: '🌟',
    tier: AchievementTier.gold,
    check: (s) => _maxRep(s) >= 5.0,
  ),
  Achievement(
    id: 'fifty_employees',
    title: 'Großer Arbeitgeber',
    description: 'Beschäftige insgesamt 50 Mitarbeiter.',
    emoji: '👔',
    tier: AchievementTier.gold,
    check: (s) => s.employeeCount >= 50,
  ),
  Achievement(
    id: 'hundred_days',
    title: '100 Tage am Spieß',
    description: 'Überlebe 100 Tage im Geschäft.',
    emoji: '🗓️',
    tier: AchievementTier.gold,
    check: (s) => s.currentDay >= 100,
  ),
  Achievement(
    id: 'cash_500k',
    title: 'Halbe Million',
    description: 'Erreiche 500.000 € auf dem Konto.',
    emoji: '🤑',
    tier: AchievementTier.platin,
    check: (s) => s.cash >= 500000,
  ),

  // Neue Systeme: Prestige & Einkaufsverträge
  Achievement(
    id: 'hedge_master',
    title: 'Preis-Stratege',
    description: 'Schließe deinen ersten Einkaufsvertrag ab.',
    emoji: '🤝',
    tier: AchievementTier.silber,
    check: (s) => s.supplyContractUntilDay > 0,
  ),
  Achievement(
    id: 'first_franchise',
    title: 'Franchise-Gründer',
    description: 'Gründe dein Imperium als Franchise neu (Prestige).',
    emoji: '🏅',
    tier: AchievementTier.gold,
    check: (s) => s.prestigePoints >= 1,
  ),
  Achievement(
    id: 'prestige_master',
    title: 'Prestige-Meister',
    description: 'Sammle 5 Prestige-Punkte über mehrere Franchises.',
    emoji: '👑',
    tier: AchievementTier.platin,
    check: (s) => s.prestigePoints >= 5,
  ),
];

/// Statisches Lookup
Achievement? achievementById(String id) {
  try {
    return kAllAchievements.firstWhere((a) => a.id == id);
  } catch (_) {
    return null;
  }
}
