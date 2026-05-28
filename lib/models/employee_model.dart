import 'dart:math';

class EmployeeTypeData {
  final String id;
  final String title;
  final String emoji;
  final String description;
  final double baseSalaryPerDay;
  final double qualityContribution;
  final double speedContribution;

  const EmployeeTypeData({
    required this.id,
    required this.title,
    required this.emoji,
    required this.description,
    required this.baseSalaryPerDay,
    required this.qualityContribution,
    required this.speedContribution,
  });
}

enum CandidateOrigin {
  regular,
  hiddenGem,
  topTalent,
  juniorPotential,
  exCompetitor,
  teamContact,
}

extension CandidateOriginX on CandidateOrigin {
  String get label {
    switch (this) {
      case CandidateOrigin.regular:
        return 'Standard';
      case CandidateOrigin.hiddenGem:
        return 'Geheimtipp';
      case CandidateOrigin.topTalent:
        return 'Top-Talent';
      case CandidateOrigin.juniorPotential:
        return 'Azubi mit Potenzial';
      case CandidateOrigin.exCompetitor:
        return 'Ex-Konkurrenz';
      case CandidateOrigin.teamContact:
        return 'Stammteam-Kontakt';
    }
  }

  String get description {
    switch (this) {
      case CandidateOrigin.regular:
        return 'Normale Bewerbung ohne Sonderbonus.';
      case CandidateOrigin.hiddenGem:
        return 'Überraschend stark und oft günstiger als erwartet.';
      case CandidateOrigin.topTalent:
        return 'Sehr hohe Werte, aber entsprechend teuer.';
      case CandidateOrigin.juniorPotential:
        return 'Günstiger Einstieg mit starkem Lernpotenzial.';
      case CandidateOrigin.exCompetitor:
        return 'Erfahren, aber mit höherem Gehaltsanspruch.';
      case CandidateOrigin.teamContact:
        return 'Zuverlässig und solide über persönliche Kontakte.';
    }
  }
}

/// Persönlichkeitseigenschaften verleihen jedem Mitarbeiter Charakter.
/// Maximal 2 Traits pro Person.
enum PersonalityTrait {
  /// +20% Friendliness-Wirkung, +0.02 Rep/Tag Bonus.
  charmer,

  /// +25% Speed-Wirkung, aber -1 Reliability (manchmal hektisch).
  workaholic,

  /// Macht andere Mitarbeiter besser (+5% pro Tag wenn anwesend).
  mentor,

  /// Sehr loyal, -30% Risiko zu kündigen, aber kein Bonus.
  loyal,

  /// +0.05 Rep einmalig beim Einstellen (Star-Image).
  influencer,

  /// -10% Gehalt-Forderung (zufrieden mit weniger).
  modest,

  /// Streitet sich oft -> +10% Risiko anderer Trait-Effekte zu reduzieren.
  hothead,

  /// 5% Chance täglich auf Bonus-Trinkgeld (Cash-Pop).
  lucky,
}

extension PersonalityTraitLabel on PersonalityTrait {
  String get label {
    switch (this) {
      case PersonalityTrait.charmer:
        return 'Charmant';
      case PersonalityTrait.workaholic:
        return 'Arbeitstier';
      case PersonalityTrait.mentor:
        return 'Mentor';
      case PersonalityTrait.loyal:
        return 'Loyal';
      case PersonalityTrait.influencer:
        return 'Influencer';
      case PersonalityTrait.modest:
        return 'Bescheiden';
      case PersonalityTrait.hothead:
        return 'Hitzkopf';
      case PersonalityTrait.lucky:
        return 'Glückspilz';
    }
  }

  String get emoji {
    switch (this) {
      case PersonalityTrait.charmer:
        return '😊';
      case PersonalityTrait.workaholic:
        return '⚡';
      case PersonalityTrait.mentor:
        return '🎓';
      case PersonalityTrait.loyal:
        return '🤝';
      case PersonalityTrait.influencer:
        return '⭐';
      case PersonalityTrait.modest:
        return '💰';
      case PersonalityTrait.hothead:
        return '🔥';
      case PersonalityTrait.lucky:
        return '🍀';
    }
  }

  String get description {
    switch (this) {
      case PersonalityTrait.charmer:
        return '+20% Freundlichkeits-Wirkung, baut Stammkunden auf';
      case PersonalityTrait.workaholic:
        return '+25% Tempo, aber etwas weniger zuverlässig';
      case PersonalityTrait.mentor:
        return 'Andere Mitarbeiter im selben Laden +5% Performance';
      case PersonalityTrait.loyal:
        return 'Wird niemals von selbst kündigen';
      case PersonalityTrait.influencer:
        return 'Bringt eine Reputations-Spritze beim Einstellen';
      case PersonalityTrait.modest:
        return 'Akzeptiert -10% Gehalt';
      case PersonalityTrait.hothead:
        return 'Erhöhtes Streit-Risiko, weniger Team-Bonus';
      case PersonalityTrait.lucky:
        return '5% Chance täglich auf Trinkgeld-Bonus';
    }
  }

  bool get isPositive {
    switch (this) {
      case PersonalityTrait.hothead:
        return false;
      default:
        return true;
    }
  }
}

/// Mitarbeiter mit individuellen Charakter-Traits.
///
/// Werte 1-10, jeweils mit konkreten Effekten im Spiel:
/// * [speed]        -> erhöht Kapazitäts-Limit (mehr Kunden bedient)
/// * [friendliness] -> steigert Reputation langsam, mehr Stammkunden
/// * [reliability]  -> reduziert Tagesschwankung (Krankheits-/Pannen-Risiko)
/// * [experience]   -> Qualitäts-Multiplikator für Umsatz
class Employee {
  final String id;
  final String typeId;
  final String name;
  final int speed; // 1..10
  final int friendliness; // 1..10
  final int reliability; // 1..10
  final int experience; // 1..10
  final double salaryPerDay;
  final List<PersonalityTrait> traits;
  final int daysEmployed; // Tracks loyalty & experience growth.
  final CandidateOrigin origin;
  final double growthPotential;

  const Employee({
    required this.id,
    required this.typeId,
    required this.name,
    required this.speed,
    required this.friendliness,
    required this.reliability,
    required this.experience,
    required this.salaryPerDay,
    this.traits = const [],
    this.daysEmployed = 0,
    this.origin = CandidateOrigin.regular,
    this.growthPotential = 0.0,
  });

  /// Durchschnitt aller Stats, 0.1..1.0
  double get overallScore =>
      ((speed + friendliness + reliability + experience) / 4.0) / 10.0;

  int get starRating => (overallScore * 5).round().clamp(1, 5);

  int get skillLevel => starRating;

  double get qualityFactor => experience / 10.0;

  bool get isSpecialCandidate => origin != CandidateOrigin.regular;

  double get speedFactor {
    final base = speed / 10.0;
    if (traits.contains(PersonalityTrait.workaholic)) {
      return (base * 1.25).clamp(0.0, 1.5);
    }
    return base;
  }

  double get friendlinessFactor {
    final base = friendliness / 10.0;
    if (traits.contains(PersonalityTrait.charmer)) {
      return (base * 1.20).clamp(0.0, 1.5);
    }
    return base;
  }

  double get reliabilityFactor {
    var base = reliability / 10.0;
    if (traits.contains(PersonalityTrait.workaholic)) {
      base = (base - 0.10).clamp(0.0, 1.0);
    }
    return base;
  }

  bool hasTrait(PersonalityTrait t) => traits.contains(t);

  Employee copyWith({
    int? speed,
    int? friendliness,
    int? reliability,
    int? experience,
    double? salaryPerDay,
    List<PersonalityTrait>? traits,
    int? daysEmployed,
    CandidateOrigin? origin,
    double? growthPotential,
  }) {
    return Employee(
      id: id,
      typeId: typeId,
      name: name,
      speed: speed ?? this.speed,
      friendliness: friendliness ?? this.friendliness,
      reliability: reliability ?? this.reliability,
      experience: experience ?? this.experience,
      salaryPerDay: salaryPerDay ?? this.salaryPerDay,
      traits: traits ?? this.traits,
      daysEmployed: daysEmployed ?? this.daysEmployed,
      origin: origin ?? this.origin,
      growthPotential: growthPotential ?? this.growthPotential,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'typeId': typeId,
        'name': name,
        'speed': speed,
        'friendliness': friendliness,
        'reliability': reliability,
        'experience': experience,
        'salaryPerDay': salaryPerDay,
        'traits': traits.map((t) => t.name).toList(),
        'daysEmployed': daysEmployed,
        'origin': origin.name,
        'growthPotential': growthPotential,
      };

  factory Employee.fromJson(Map<String, dynamic> j) {
    // Migration: alter Spielstand mit "skillLevel"
    if (j.containsKey('skillLevel') && !j.containsKey('speed')) {
      final skill = (j['skillLevel'] as num).toInt();
      return Employee(
        id: j['id'] as String,
        typeId: j['typeId'] as String,
        name: j['name'] as String,
        speed: skill * 2,
        friendliness: skill * 2,
        reliability: skill * 2,
        experience: skill * 2,
        salaryPerDay: (j['salaryPerDay'] as num).toDouble(),
      );
    }
    final rawTraits = (j['traits'] as List?) ?? const [];
    final traits = rawTraits
        .map((t) {
          try {
            return PersonalityTrait.values.firstWhere((e) => e.name == t);
          } catch (_) {
            return null;
          }
        })
        .whereType<PersonalityTrait>()
        .toList();

    return Employee(
      id: j['id'] as String,
      typeId: j['typeId'] as String,
      name: j['name'] as String,
      speed: (j['speed'] as num).toInt(),
      friendliness: (j['friendliness'] as num).toInt(),
      reliability: (j['reliability'] as num).toInt(),
      experience: (j['experience'] as num).toInt(),
      salaryPerDay: (j['salaryPerDay'] as num).toDouble(),
      traits: traits,
      daysEmployed: (j['daysEmployed'] as num?)?.toInt() ?? 0,
      origin: CandidateOrigin.values.firstWhere(
        (v) => v.name == (j['origin'] as String?),
        orElse: () => CandidateOrigin.regular,
      ),
      growthPotential: (j['growthPotential'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Erzeugt einen zufälligen Mitarbeiter-Kandidaten für eine gegebene Rolle.
class EmployeeFactory {
  static final _rng = Random();

  static Employee createCandidate({
    required String id,
    required EmployeeTypeData type,
    required String name,
    String? archetype,
    double qualityMultiplier = 1.0,
    double salaryMultiplier = 1.0,
    CandidateOrigin origin = CandidateOrigin.regular,
    double growthPotential = 0.0,
  }) {
    final pick = archetype ??
        ['rookie', 'balanced', 'balanced', 'veteran'][_rng.nextInt(4)];

    int s, f, r, e;
    switch (pick) {
      case 'rookie':
        s = 2 + _rng.nextInt(5);
        f = 2 + _rng.nextInt(5);
        r = 2 + _rng.nextInt(5);
        e = 1 + _rng.nextInt(4);
        break;
      case 'veteran':
        s = 6 + _rng.nextInt(5);
        f = 6 + _rng.nextInt(5);
        r = 6 + _rng.nextInt(5);
        e = 6 + _rng.nextInt(5);
        break;
      case 'balanced':
      default:
        s = 3 + _rng.nextInt(6);
        f = 3 + _rng.nextInt(6);
        r = 3 + _rng.nextInt(6);
        e = 3 + _rng.nextInt(6);
    }

    // Spezialisierung
    final spec = _rng.nextInt(4);
    switch (spec) {
      case 0:
        s = (s + 2).clamp(1, 10);
        break;
      case 1:
        f = (f + 2).clamp(1, 10);
        break;
      case 2:
        r = (r + 2).clamp(1, 10);
        break;
      case 3:
        e = (e + 2).clamp(1, 10);
        break;
    }

    int scaleStat(int stat) {
      final scaled = 1 + ((stat - 1) * qualityMultiplier);
      return scaled.round().clamp(1, 10);
    }

    s = scaleStat(s);
    f = scaleStat(f);
    r = scaleStat(r);
    e = scaleStat(e);

    // Persönlichkeitstraits: 40% Chance auf 1 Trait, 12% auf 2
    final traits = <PersonalityTrait>[];
    if (_rng.nextDouble() < 0.40) {
      traits.add(_rollTrait(null));
    }
    if (traits.isNotEmpty && _rng.nextDouble() < 0.12) {
      final second = _rollTrait(traits.first);
      if (!traits.contains(second)) traits.add(second);
    }

    final overall = (s + f + r + e) / 40.0;
    double salary = type.baseSalaryPerDay * (0.6 + overall * 1.2);
    if (traits.contains(PersonalityTrait.modest)) salary *= 0.9;
    if (traits.contains(PersonalityTrait.influencer)) salary *= 1.15;
    if (traits.contains(PersonalityTrait.workaholic)) salary *= 1.05;
    salary *= salaryMultiplier;

    return Employee(
      id: id,
      typeId: type.id,
      name: name,
      speed: s,
      friendliness: f,
      reliability: r,
      experience: e,
      salaryPerDay: double.parse(salary.toStringAsFixed(2)),
      traits: traits,
      daysEmployed: 0,
      origin: origin,
      growthPotential: growthPotential.clamp(0.0, 1.0),
    );
  }

  static PersonalityTrait _rollTrait(PersonalityTrait? exclude) {
    final pool = PersonalityTrait.values.where((t) => t != exclude).toList();
    return pool[_rng.nextInt(pool.length)];
  }
}

// Zufällige Mitarbeiter-Namen
const List<String> kMaleNames = [
  'Ali',
  'Mehmet',
  'Mustafa',
  'Kemal',
  'Ahmet',
  'Yusuf',
  'Hasan',
  'Ibrahim',
  'Lukas',
  'Noah',
  'Leon',
  'Maximilian',
  'Jonas',
  'Elias',
];

const List<String> kFemaleNames = [
  'Fatma',
  'Ayşe',
  'Emine',
  'Hatice',
  'Zeynep',
  'Laura',
  'Jana',
  'Sarah',
  'Emma',
  'Lena',
  'Anna',
];
