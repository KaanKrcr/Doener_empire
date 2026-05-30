import 'package:flutter_test/flutter_test.dart';
import 'package:doener_empire/models/scenario_model.dart';
import 'package:doener_empire/models/difficulty_model.dart';

void main() {
  test('Klassisches Szenario ist das erste und neutral', () {
    final classic = kScenarios.first;
    expect(classic.id, 'classic');
    expect(classic.startCash, 15000);
    expect(classic.difficulty, GameDifficulty.normal);
    expect(classic.startingLoan, 0);
    expect(classic.tutorialEnabled, isTrue);
  });

  test('Schuldenstart hat einen Startkredit', () {
    final s = kScenarios.firstWhere((x) => x.id == 'schuldenstart');
    expect(s.startingLoan, greaterThan(0));
  });

  test('Alle Szenarien sind wohlgeformt', () {
    final ids = kScenarios.map((s) => s.id).toList();
    expect(ids.toSet().length, ids.length); // eindeutig
    for (final s in kScenarios) {
      expect(s.name.trim(), isNotEmpty);
      expect(s.startCash, greaterThan(0));
      expect(s.startingLoan, greaterThanOrEqualTo(0));
    }
  });
}
