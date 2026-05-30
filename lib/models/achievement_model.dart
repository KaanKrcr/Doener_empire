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
/// Erhält den GameState und prüft ob das Achievement erfüllt ist.
typedef AchievementCheck = bool Function(
  int totalShops,
  int totalEmployees,
  double totalRevenue,
  double cash,
  int currentDay,
  int customersTotal,
  double maxShopRep,
  double brandAwareness,
  int competitorsBeat,
);

/// Achievement-Pool. Wird in MainScaffold + Engine geprüft.
final List<Achievement> kAllAchievements = [
  // Bronze
  Achievement(
    id: 'first_shop',
    title: 'Tag 1 als Boss',
    description: 'Eröffne deine erste Filiale.',
    emoji: '🥙',
    tier: AchievementTier.bronze,
    check: (shops, emp, rev, cash, day, cust, rep, brand, comp) => shops >= 1,
  ),
  Achievement(
    id: 'first_week',
    title: 'Eine Woche überstanden',
    description: 'Erreiche Tag 7 ohne Pleite.',
    emoji: '📅',
    tier: AchievementTier.bronze,
    check: (shops, emp, rev, cash, day, cust, rep, brand, comp) => day >= 7,
  ),
  Achievement(
    id: 'first_5_employees',
    title: 'Kleines Team',
    description: 'Stelle insgesamt 5 Mitarbeiter ein.',
    emoji: '👥',
    tier: AchievementTier.bronze,
    check: (shops, emp, rev, cash, day, cust, rep, brand, comp) => emp >= 5,
  ),
  Achievement(
    id: 'thousand_customers',
    title: '1.000 Kunden',
    description: 'Bediene insgesamt 1.000 Kunden.',
    emoji: '👥',
    tier: AchievementTier.bronze,
    check: (shops, emp, rev, cash, day, cust, rep, brand, comp) => cust >= 1000,
  ),

  // Silber
  Achievement(
    id: 'three_cities',
    title: 'Regional aufgestellt',
    description: 'Filialen in 3 verschiedenen Städten.',
    emoji: '🗺️',
    tier: AchievementTier.silber,
    // Workaround: nutze Stadt-Count über Repräsentation in checkAchievements
    check: (shops, emp, rev, cash, day, cust, rep, brand, comp) => shops >= 3,
  ),
  Achievement(
    id: 'rep_45',
    title: 'Premium-Adresse',
    description: 'Erreiche 4,5 Reputation in einer Filiale.',
    emoji: '⭐',
    tier: AchievementTier.silber,
    check: (shops, emp, rev, cash, day, cust, rep, brand, comp) => rep >= 4.5,
  ),
  Achievement(
    id: 'cash_50k',
    title: 'Fünfstellig',
    description: 'Erreiche 50.000 € Konto.',
    emoji: '💵',
    tier: AchievementTier.silber,
    check: (shops, emp, rev, cash, day, cust, rep, brand, comp) =>
        cash >= 50000,
  ),
  Achievement(
    id: 'thirty_days',
    title: 'Ein Monat im Geschäft',
    description: 'Überlebe 30 Tage.',
    emoji: '📆',
    tier: AchievementTier.silber,
    check: (shops, emp, rev, cash, day, cust, rep, brand, comp) => day >= 30,
  ),

  // Gold
  Achievement(
    id: 'ten_shops',
    title: 'Kettenbetreiber',
    description: 'Eröffne 10 Filialen.',
    emoji: '🏬',
    tier: AchievementTier.gold,
    check: (shops, emp, rev, cash, day, cust, rep, brand, comp) => shops >= 10,
  ),
  Achievement(
    id: 'cash_250k',
    title: 'Viertelmillionär',
    description: 'Erreiche 250.000 € Konto.',
    emoji: '💎',
    tier: AchievementTier.gold,
    check: (shops, emp, rev, cash, day, cust, rep, brand, comp) =>
        cash >= 250000,
  ),
  Achievement(
    id: 'brand_40',
    title: 'Etablierte Marke',
    description: 'Markenbekanntheit 40+.',
    emoji: '📢',
    tier: AchievementTier.gold,
    check: (shops, emp, rev, cash, day, cust, rep, brand, comp) => brand >= 40,
  ),
  Achievement(
    id: 'ten_thousand_customers',
    title: '10.000 Kunden bedient',
    description: 'Bediene 10.000 Kunden insgesamt.',
    emoji: '🥳',
    tier: AchievementTier.gold,
    check: (shops, emp, rev, cash, day, cust, rep, brand, comp) =>
        cust >= 10000,
  ),

  // Platin
  Achievement(
    id: 'million_revenue',
    title: 'Million-Euro-Boss',
    description: '1.000.000 € Gesamtumsatz.',
    emoji: '👑',
    tier: AchievementTier.platin,
    check: (shops, emp, rev, cash, day, cust, rep, brand, comp) =>
        rev >= 1000000,
  ),
  Achievement(
    id: 'brand_80',
    title: 'Legendäre Marke',
    description: 'Markenbekanntheit 80+.',
    emoji: '🌟',
    tier: AchievementTier.platin,
    check: (shops, emp, rev, cash, day, cust, rep, brand, comp) => brand >= 80,
  ),
  Achievement(
    id: 'twenty_shops',
    title: 'Imperium-Modus',
    description: '20 Filialen aktiv.',
    emoji: '🏰',
    tier: AchievementTier.platin,
    check: (shops, emp, rev, cash, day, cust, rep, brand, comp) => shops >= 20,
  ),

  // Zusätzliche Langzeit-Ziele
  Achievement(
    id: 'five_star_shop',
    title: 'Perfekte Filiale',
    description: 'Erreiche die volle 5,0 Reputation in einer Filiale.',
    emoji: '🌟',
    tier: AchievementTier.gold,
    check: (shops, emp, rev, cash, day, cust, rep, brand, comp) => rep >= 5.0,
  ),
  Achievement(
    id: 'fifty_employees',
    title: 'Großer Arbeitgeber',
    description: 'Beschäftige insgesamt 50 Mitarbeiter.',
    emoji: '👔',
    tier: AchievementTier.gold,
    check: (shops, emp, rev, cash, day, cust, rep, brand, comp) => emp >= 50,
  ),
  Achievement(
    id: 'hundred_days',
    title: '100 Tage am Spieß',
    description: 'Überlebe 100 Tage im Geschäft.',
    emoji: '🗓️',
    tier: AchievementTier.gold,
    check: (shops, emp, rev, cash, day, cust, rep, brand, comp) => day >= 100,
  ),
  Achievement(
    id: 'cash_500k',
    title: 'Halbe Million',
    description: 'Erreiche 500.000 € auf dem Konto.',
    emoji: '🤑',
    tier: AchievementTier.platin,
    check: (shops, emp, rev, cash, day, cust, rep, brand, comp) =>
        cash >= 500000,
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
