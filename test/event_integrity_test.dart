import 'package:flutter_test/flutter_test.dart';
import 'package:doener_empire/models/event_model.dart';

void main() {
  test('Event-IDs sind eindeutig', () {
    final ids = kAllEvents.map((e) => e.id).toList();
    expect(ids.toSet().length, ids.length,
        reason: 'Doppelte Event-IDs gefunden');
  });

  test('Jedes Event hat mindestens eine Wahlmöglichkeit', () {
    for (final e in kAllEvents) {
      expect(e.choices, isNotEmpty, reason: 'Event ${e.id} ohne Choices');
    }
  });

  test('Jede Wahlmöglichkeit ist wohlgeformt', () {
    for (final e in kAllEvents) {
      for (final c in e.choices) {
        expect(c.label.trim(), isNotEmpty,
            reason: 'Leeres Label in ${e.id}');
        expect(c.effect.resultMessage.trim(), isNotEmpty,
            reason: 'Leere resultMessage in ${e.id}');
        if (c.cost != null) {
          expect(c.cost, greaterThan(0),
              reason: 'Nicht-positive Kosten in ${e.id}');
        }
      }
    }
  });

  test('Anforderungen sind sinnvoll', () {
    for (final e in kAllEvents) {
      expect(e.requirements.minShops, greaterThanOrEqualTo(0));
      expect(e.requirements.minDay, greaterThanOrEqualTo(0));
      expect(e.requirements.minCash, greaterThanOrEqualTo(0));
    }
  });

  test('Neue Krisen-Events sind vorhanden', () {
    final ids = kAllEvents.map((e) => e.id).toSet();
    for (final id in [
      'kitchen_fire',
      'social_scandal',
      'night_robbery',
      'power_outage',
      'food_poisoning_rumor',
      'employee_theft',
    ]) {
      expect(ids, contains(id));
    }
  });
}
