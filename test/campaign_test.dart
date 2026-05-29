import 'package:flutter_test/flutter_test.dart';
import 'package:doener_empire/models/game_state.dart';
import 'package:doener_empire/models/shop_model.dart';
import 'package:doener_empire/models/campaign_model.dart';
import 'package:doener_empire/services/campaign_engine.dart';

GameState _fresh() => GameState.initial(
      companyName: 'Test',
      founderName: 'Kaan',
      startCash: 15000,
    );

Shop _shop(String id) => Shop(
      id: id,
      name: 'Test',
      cityId: 'fulda',
      locationName: 'Marktplatz',
      footTraffic: 100,
      weeklyRent: 700,
      menu: const [],
      equipment: const [],
      employees: const [],
      dayOpened: 1,
    );

void main() {
  test('Frischer Stand: erstes Kapitel ist aktiv', () {
    final s = _fresh();
    final ch = CampaignEngine.activeChapter(s);
    expect(ch, isNotNull);
    expect(ch!.number, 1);
    expect(CampaignEngine.completedCount(s), 0);
  });

  test('Kapitel 1 wird durch erste Filiale abgeschlossen + Belohnung gutgeschrieben', () {
    var s = _fresh().copyWith(shops: [_shop('a')]);
    final reward = kCampaignChapters.first.cashReward;
    final cashBefore = s.cash;

    final r = CampaignEngine.checkAndApply(s);
    expect(r.justCompleted, isNotNull);
    expect(r.justCompleted!.id, 'ch1_traum');

    s = r.state;
    expect(s.completedChapterIds, contains('ch1_traum'));
    expect(s.cash, cashBefore + reward);
    // Nächstes aktives Kapitel ist nun Kapitel 2
    expect(CampaignEngine.activeChapter(s)!.number, 2);
  });

  test('Ohne erfülltes Ziel passiert nichts', () {
    final s = _fresh();
    final r = CampaignEngine.checkAndApply(s);
    expect(r.justCompleted, isNull);
    expect(r.state.cash, s.cash);
    expect(r.state.completedChapterIds, isEmpty);
  });

  test('Kapitel-Fortschritt liegt zwischen 0 und 1', () {
    final s = _fresh();
    final ch = CampaignEngine.activeChapter(s)!;
    final p = CampaignEngine.chapterProgress(ch, s);
    expect(p, inInclusiveRange(0.0, 1.0));
  });
}
