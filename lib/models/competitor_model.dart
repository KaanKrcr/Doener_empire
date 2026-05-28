import 'dart:math';

/// KI-Konkurrenz-Ketten im Spiel.
///
/// Jede Stadt hat 1–3 Wettbewerber, die sich wie echte Imbissketten verhalten:
/// * Preisstrategien (günstig, mittel, premium)
/// * Aggressivität (expandiert, eröffnet neue Filialen)
/// * Marktanteil → frisst Kunden ab
///
/// Konkurrenten sind über das ganze Spiel persistent und haben Namen
/// + Persönlichkeit, damit sie als "Charaktere" wahrgenommen werden.

enum CompetitorPersonality {
  /// Günstig, niedrige Qualität, große Reichweite.
  cheapMass,

  /// Mittlere Preise, solide Marke.
  balanced,

  /// Premium-Konzept, teuer, kleine Stückzahlen.
  premium,

  /// Aggressiv, expandiert schnell, Preiskampf.
  aggressive,

  /// Familien-Tradition, fokus Reputation.
  traditional,
}

extension CompetitorPersonalityLabel on CompetitorPersonality {
  String get tagline {
    switch (this) {
      case CompetitorPersonality.cheapMass:
        return '"Döner für alle, billig & schnell"';
      case CompetitorPersonality.balanced:
        return '"Solide. Lecker. Bezahlbar."';
      case CompetitorPersonality.premium:
        return '"Premium-Döner. Bio. Authentisch."';
      case CompetitorPersonality.aggressive:
        return '"Wir wachsen wo andere sterben."';
      case CompetitorPersonality.traditional:
        return '"Seit 1985. Echtes Handwerk."';
    }
  }

  String get emoji {
    switch (this) {
      case CompetitorPersonality.cheapMass:
        return '💸';
      case CompetitorPersonality.balanced:
        return '⚖️';
      case CompetitorPersonality.premium:
        return '💎';
      case CompetitorPersonality.aggressive:
        return '⚔️';
      case CompetitorPersonality.traditional:
        return '🏛️';
    }
  }
}

/// Ein konkurrierender Imbiss in einer bestimmten Stadt.
class Competitor {
  final String id;
  final String name;
  final String cityId;
  final CompetitorPersonality personality;

  /// Anzahl Filialen in der Stadt (1-5). Bestimmt Marktanteil.
  int shopCount;

  /// Reputation 1..5 (wie bei Shop)
  double reputation;

  /// Preisniveau-Faktor (0.7..1.4 von der Marktnorm) — beeinflusst
  /// Kunden-Konkurrenz wenn Spieler ähnliche Preise hat.
  double priceLevel;

  /// Marktanteil in der Stadt (0..1). Wird in CompetitorEngine berechnet.
  double marketShare;

  /// Wie viele Tage seit letzter Aktion (Eröffnung/Preis-Update)
  int daysSinceLastAction;

  Competitor({
    required this.id,
    required this.name,
    required this.cityId,
    required this.personality,
    this.shopCount = 1,
    this.reputation = 3.0,
    this.priceLevel = 1.0,
    this.marketShare = 0.15,
    this.daysSinceLastAction = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'cityId': cityId,
        'personality': personality.name,
        'shopCount': shopCount,
        'reputation': reputation,
        'priceLevel': priceLevel,
        'marketShare': marketShare,
        'daysSinceLastAction': daysSinceLastAction,
      };

  factory Competitor.fromJson(Map<String, dynamic> j) => Competitor(
        id: j['id'] as String,
        name: j['name'] as String,
        cityId: j['cityId'] as String,
        personality: CompetitorPersonality.values.firstWhere(
          (p) => p.name == (j['personality'] as String),
          orElse: () => CompetitorPersonality.balanced,
        ),
        shopCount: j['shopCount'] as int,
        reputation: (j['reputation'] as num).toDouble(),
        priceLevel: (j['priceLevel'] as num).toDouble(),
        marketShare: (j['marketShare'] as num).toDouble(),
        daysSinceLastAction: j['daysSinceLastAction'] as int? ?? 0,
      );

  /// Lebendige Kurzbeschreibung für UI
  String shortStatus() {
    final repLabel = reputation >= 4.0
        ? 'starker Ruf'
        : reputation >= 3.0
            ? 'okayer Ruf'
            : 'schwächelt';
    final priceLabel = priceLevel >= 1.15
        ? 'teuer'
        : priceLevel <= 0.85
            ? 'günstig'
            : 'normal';
    return '$shopCount Filialen · $repLabel · $priceLabel';
  }
}

/// Namens-Pool für KI-Konkurrenten (deutsch-türkisch authentisch).
const List<String> kCompetitorNames = [
  'Mehmet\'s Grill',
  'Berlin Kebap Haus',
  'Anatolia Express',
  'Bosporus Imbiss',
  'King Döner',
  'Istanbul Grillhaus',
  'Sultan\'s Pide',
  'Goldener Spieß',
  'Marmara Snack',
  'Yilmaz Family Kebap',
  'Topkapi Imbiss',
  'Döner-Express 24',
  'Pasha Grill',
  'Efes Imbiss',
  'Kebap KralÄ±',
  'Mama Mehmet',
  'Bistro Anadolu',
  'Best Döner',
  'Döner Time',
  'Star Kebap',
];

/// Factory: erzeugt einen plausiblen Konkurrenten für eine Stadt.
class CompetitorFactory {
  static final _rng = Random();
  static final Set<String> _usedNames = {};

  static String _uniqueName() {
    final available =
        kCompetitorNames.where((n) => !_usedNames.contains(n)).toList();
    final pool = available.isEmpty ? kCompetitorNames : available;
    final pick = pool[_rng.nextInt(pool.length)];
    _usedNames.add(pick);
    return pick;
  }

  static Competitor create({
    required String id,
    required String cityId,
    CompetitorPersonality? personality,
    int? shopCount,
  }) {
    final pers = personality ??
        CompetitorPersonality
            .values[_rng.nextInt(CompetitorPersonality.values.length)];

    double price, rep;
    switch (pers) {
      case CompetitorPersonality.cheapMass:
        price = 0.75 + _rng.nextDouble() * 0.10;
        rep = 2.3 + _rng.nextDouble() * 0.7;
        break;
      case CompetitorPersonality.balanced:
        price = 0.95 + _rng.nextDouble() * 0.10;
        rep = 3.0 + _rng.nextDouble() * 0.7;
        break;
      case CompetitorPersonality.premium:
        price = 1.20 + _rng.nextDouble() * 0.15;
        rep = 3.8 + _rng.nextDouble() * 0.7;
        break;
      case CompetitorPersonality.aggressive:
        price = 0.85 + _rng.nextDouble() * 0.15;
        rep = 2.8 + _rng.nextDouble() * 0.7;
        break;
      case CompetitorPersonality.traditional:
        price = 1.00 + _rng.nextDouble() * 0.10;
        rep = 3.5 + _rng.nextDouble() * 0.8;
        break;
    }

    return Competitor(
      id: id,
      name: _uniqueName(),
      cityId: cityId,
      personality: pers,
      shopCount: shopCount ?? (1 + _rng.nextInt(2)),
      reputation: double.parse(rep.toStringAsFixed(2)),
      priceLevel: double.parse(price.toStringAsFixed(2)),
      marketShare: 0.15 + _rng.nextDouble() * 0.20,
    );
  }
}
