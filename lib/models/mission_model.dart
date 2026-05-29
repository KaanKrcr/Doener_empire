/// Mission/Quest die der Spieler erfüllt. Sequenzielle Goals führen durch das
/// erste Spiel (erste Stunde, erster Tag, erste Woche).
///
/// Jede Mission hat:
/// * eine Bedingung (wird in MissionEngine geprüft)
/// * eine Belohnung in Cash
/// * einen Status (locked, active, done)
class Mission {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final double cashReward;
  final MissionType type;
  final double target;
  bool isDone;

  Mission({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.cashReward,
    required this.type,
    required this.target,
    this.isDone = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'isDone': isDone,
      };

  /// Statisch aus kAllMissions (id) + persistiertem Status zusammenbauen
  void applyJson(Map<String, dynamic> j) {
    isDone = j['isDone'] as bool? ?? false;
  }
}

enum MissionType {
  openFirstShop,
  totalRevenue,
  hireEmployees,
  buyEquipment,
  unlockProduct,
  reachCash,
  shopCount,
  unlockCity,
  daysSurvived,
  reputationLevel,
  companyPublic, // Börsengang durchgeführt (stocks.isPublic)
  brandAwareness, // Markenbekanntheit (brand.brandAwareness, 0..100)
  acquiredShops, // übernommene Konkurrenz-Filialen (wasAcquired)
}

/// Reihenfolge bestimmt die "Story". Eine Mission ist erst aktiv,
/// wenn alle vorigen erfüllt sind.
List<Mission> buildMissionsTemplate() => [
      Mission(
        id: 'open_first_shop',
        title: 'Erster Imbiss',
        description: 'Eröffne deinen ersten Döner-Imbiss in einer Stadt.',
        emoji: '🏪',
        cashReward: 500,
        type: MissionType.openFirstShop,
        target: 1,
      ),
      Mission(
        id: 'first_1000',
        title: 'Erste 1.000 €',
        description: 'Erwirtschafte insgesamt 1.000 € Umsatz.',
        emoji: '💵',
        cashReward: 500,
        type: MissionType.totalRevenue,
        target: 1000,
      ),
      Mission(
        id: 'hire_first',
        title: 'Erster Mitarbeiter',
        description: 'Stelle deinen ersten Mitarbeiter ein.',
        emoji: '👨‍🍳',
        cashReward: 800,
        type: MissionType.hireEmployees,
        target: 1,
      ),
      Mission(
        id: 'first_equipment',
        title: 'Profi-Ausrüstung',
        description: 'Kaufe dein erstes Equipment für eine Filiale.',
        emoji: '🔥',
        cashReward: 1000,
        type: MissionType.buyEquipment,
        target: 1,
      ),
      Mission(
        id: 'first_product_unlock',
        title: 'Sortiment erweitern',
        description:
            'Schalte ein neues Produkt durch Equipment frei (z.B. Pommes).',
        emoji: '🍟',
        cashReward: 1500,
        type: MissionType.unlockProduct,
        target: 1,
      ),
      Mission(
        id: 'cash_10k',
        title: '10.000 € auf dem Konto',
        description: 'Erreiche einen Kontostand von 10.000 €.',
        emoji: '💰',
        cashReward: 2000,
        type: MissionType.reachCash,
        target: 10000,
      ),
      Mission(
        id: 'unlock_city',
        title: 'Stadt-Expansion',
        description: 'Schalte eine zweite Stadt frei.',
        emoji: '🏙️',
        cashReward: 3000,
        type: MissionType.unlockCity,
        target: 1,
      ),
      Mission(
        id: 'three_shops',
        title: 'Kleine Kette',
        description: 'Eröffne 3 Filialen.',
        emoji: '🏬',
        cashReward: 5000,
        type: MissionType.shopCount,
        target: 3,
      ),
      Mission(
        id: 'reputation_4',
        title: 'Stadt-Liebling',
        description: 'Erreiche 4.0 Reputation in mindestens einer Filiale.',
        emoji: '⭐',
        cashReward: 4000,
        type: MissionType.reputationLevel,
        target: 4.0,
      ),
      Mission(
        id: 'cash_100k',
        title: 'Sechsstelliger Boss',
        description: 'Erreiche 100.000 € auf dem Konto.',
        emoji: '💎',
        cashReward: 10000,
        type: MissionType.reachCash,
        target: 100000,
      ),
      Mission(
        id: 'survive_30',
        title: '30 Tage am Spieß',
        description: 'Überlebe 30 Tage im Geschäft.',
        emoji: '📅',
        cashReward: 5000,
        type: MissionType.daysSurvived,
        target: 30,
      ),
      Mission(
        id: 'metropole',
        title: 'Metropolen-Boss',
        description: 'Eröffne eine Filiale in Berlin, Hamburg oder München.',
        emoji: '👑',
        cashReward: 25000,
        type: MissionType.shopCount, // Spezial-Logik im Engine
        target: 1,
      ),
    ];
