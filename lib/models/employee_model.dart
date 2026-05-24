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

/// Mitarbeiter mit individuellen Charakter-Traits.
///
/// Werte 1–10, jeweils mit konkreten Effekten im Spiel:
/// * [speed]        → erhöht Kapazitäts-Limit (mehr Kunden bedient)
/// * [friendliness] → steigert Reputation langsam, mehr Stammkunden
/// * [reliability]  → reduziert Tagesschwankung (Krankheits-/Pannen-Risiko)
/// * [experience]   → Qualitäts-Multiplikator für Umsatz
class Employee {
  final String id;
  final String typeId;
  final String name;
  final int speed;          // 1..10
  final int friendliness;   // 1..10
  final int reliability;    // 1..10
  final int experience;     // 1..10
  final double salaryPerDay;

  const Employee({
    required this.id,
    required this.typeId,
    required this.name,
    required this.speed,
    required this.friendliness,
    required this.reliability,
    required this.experience,
    required this.salaryPerDay,
  });

  /// Durchschnitt aller Traits, 0.1..1.0 — zur Anzeige / Vergleich.
  double get overallScore =>
      ((speed + friendliness + reliability + experience) / 4.0) / 10.0;

  /// Sterne-Repräsentation (1..5)
  int get starRating => (overallScore * 5).round().clamp(1, 5);

  /// Kompatibilität: alter "skillLevel" Wert
  int get skillLevel => starRating;

  /// Kompatibilität: alter qualityFactor (0..1)
  double get qualityFactor => experience / 10.0;

  /// Wie schnell der Mitarbeiter arbeitet (0..1)
  double get speedFactor => speed / 10.0;

  /// Wie freundlich (0..1)
  double get friendlinessFactor => friendliness / 10.0;

  /// Zuverlässigkeit (0..1)
  double get reliabilityFactor => reliability / 10.0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'typeId': typeId,
        'name': name,
        'speed': speed,
        'friendliness': friendliness,
        'reliability': reliability,
        'experience': experience,
        'salaryPerDay': salaryPerDay,
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
    return Employee(
      id: j['id'] as String,
      typeId: j['typeId'] as String,
      name: j['name'] as String,
      speed: (j['speed'] as num).toInt(),
      friendliness: (j['friendliness'] as num).toInt(),
      reliability: (j['reliability'] as num).toInt(),
      experience: (j['experience'] as num).toInt(),
      salaryPerDay: (j['salaryPerDay'] as num).toDouble(),
    );
  }
}

/// Erzeugt einen zufälligen Mitarbeiter-Kandidaten für eine gegebene Rolle.
/// Salary skaliert mit dem overallScore — bessere Leute kosten mehr.
class EmployeeFactory {
  static final _rng = Random();

  /// Erstellt einen Kandidaten. [archetype] erlaubt einen leichten Bias:
  /// * "rookie" → niedrigere Erfahrung, günstiger
  /// * "veteran" → hohe Werte, teuer
  /// * "balanced" → mittel
  /// Wenn null, wird zufällig gewählt.
  static Employee createCandidate({
    required String id,
    required EmployeeTypeData type,
    required String name,
    String? archetype,
  }) {
    final pick = archetype ?? ['rookie', 'balanced', 'balanced', 'veteran'][_rng.nextInt(4)];

    int s, f, r, e;
    switch (pick) {
      case 'rookie':
        // 2..6
        s = 2 + _rng.nextInt(5);
        f = 2 + _rng.nextInt(5);
        r = 2 + _rng.nextInt(5);
        e = 1 + _rng.nextInt(4);
        break;
      case 'veteran':
        // 6..10
        s = 6 + _rng.nextInt(5);
        f = 6 + _rng.nextInt(5);
        r = 6 + _rng.nextInt(5);
        e = 6 + _rng.nextInt(5);
        break;
      case 'balanced':
      default:
        // 3..8
        s = 3 + _rng.nextInt(6);
        f = 3 + _rng.nextInt(6);
        r = 3 + _rng.nextInt(6);
        e = 3 + _rng.nextInt(6);
    }

    // Spezialisierung: einen Trait nach oben pushen (Persönlichkeit)
    final spec = _rng.nextInt(4);
    switch (spec) {
      case 0: s = (s + 2).clamp(1, 10); break;
      case 1: f = (f + 2).clamp(1, 10); break;
      case 2: r = (r + 2).clamp(1, 10); break;
      case 3: e = (e + 2).clamp(1, 10); break;
    }

    final overall = (s + f + r + e) / 40.0;
    // Gehalt: Basis × (0.6..1.8) je nach Gesamtscore
    final salary = type.baseSalaryPerDay * (0.6 + overall * 1.2);

    return Employee(
      id: id,
      typeId: type.id,
      name: name,
      speed: s,
      friendliness: f,
      reliability: r,
      experience: e,
      salaryPerDay: double.parse(salary.toStringAsFixed(2)),
    );
  }
}

// Zufällige Mitarbeiter-Namen
const List<String> kMaleNames = [
  'Ali', 'Mehmet', 'Mustafa', 'Kemal', 'Ahmet', 'Yusuf', 'Hasan', 'Ibrahim',
  'Lukas', 'Noah', 'Leon', 'Maximilian', 'Jonas', 'Elias',
];

const List<String> kFemaleNames = [
  'Fatma', 'Ayşe', 'Emine', 'Hatice', 'Zeynep',
  'Laura', 'Jana', 'Sarah', 'Emma', 'Lena', 'Anna',
];
