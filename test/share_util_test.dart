import 'package:flutter_test/flutter_test.dart';
import 'package:doener_empire/models/game_state.dart';
import 'package:doener_empire/services/share_util.dart';

void main() {
  test('empireSummaryText enthält Firmenname, Tag und Hashtag', () {
    final s = GameState.initial(
      companyName: 'Sultan Döner',
      founderName: 'Kaan',
      startCash: 15000,
    ).copyWith(currentDay: 12, totalRevenue: 99999);

    final text = empireSummaryText(s);
    expect(text, contains('Sultan Döner'));
    expect(text, contains('Tag 12'));
    expect(text, contains('#DönerEmpire'));
    expect(text, contains('Gesamtumsatz'));
  });
}
