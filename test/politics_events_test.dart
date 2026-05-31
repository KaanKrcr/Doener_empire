import 'package:flutter_test/flutter_test.dart';
import 'package:doener_empire/models/event_model.dart';

void main() {
  group('Event-Pool – Wohlgeformtheit', () {
    test('Alle Event-IDs sind eindeutig', () {
      final ids = kAllEvents.map((e) => e.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('Jedes Event hat Titel, Beschreibung und mindestens eine Choice', () {
      for (final e in kAllEvents) {
        expect(e.title.trim(), isNotEmpty, reason: e.id);
        expect(e.description.trim(), isNotEmpty, reason: e.id);
        expect(e.choices, isNotEmpty, reason: e.id);
      }
    });

    test('Jede Choice hat Label + Ergebnis-Text und plausible Deltas', () {
      for (final e in kAllEvents) {
        for (final c in e.choices) {
          expect(c.label.trim(), isNotEmpty, reason: e.id);
          expect(c.effect.resultMessage.trim(), isNotEmpty, reason: e.id);
          expect(c.effect.reputationDelta, inInclusiveRange(-1.0, 1.0),
              reason: e.id);
          expect(c.effect.brandAwarenessDelta, inInclusiveRange(-10.0, 10.0),
              reason: e.id);
        }
      }
    });
  });

  group('Politik-/News-Events', () {
    const expectedIds = {
      'doener_price_cap',
      'mwst_debate',
      'energy_cost_spike',
      'min_wage_hike',
      'doener_index_media',
      'tiktok_doener_challenge',
      'best_doener_voting',
    };

    test('Alle neuen Politik-Events sind im Pool', () {
      final ids = kAllEvents.map((e) => e.id).toSet();
      for (final id in expectedIds) {
        expect(ids.contains(id), isTrue, reason: 'fehlt: $id');
      }
    });

    test('Dönerpreisbremse bietet eine echte Entscheidung (mehrere Optionen)',
        () {
      final e = kAllEvents.firstWhere((e) => e.id == 'doener_price_cap');
      expect(e.choices.length, greaterThanOrEqualTo(2));
      // Die Solidaritäts-Option kostet Marge, bringt aber Marke.
      final solidarity = e.choices.first;
      expect(solidarity.effect.cashDelta, lessThan(0));
      expect(solidarity.effect.brandAwarenessDelta, greaterThan(0));
    });
  });
}
