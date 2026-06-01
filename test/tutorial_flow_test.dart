import 'package:doener_empire/models/game_state.dart';
import 'package:doener_empire/models/shop_model.dart';
import 'package:doener_empire/models/tutorial_model.dart';
import 'package:doener_empire/providers/game_provider.dart';
import 'package:doener_empire/services/sound_service.dart';
import 'package:doener_empire/ui/main_scaffold.dart';
import 'package:doener_empire/ui/tutorial_navigation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Shop _shop() {
  return const Shop(
    id: 'tutorial_shop_1',
    name: 'Tutorial Döner',
    cityId: 'fulda',
    locationName: 'Marktplatz',
    footTraffic: 1800,
    weeklyRent: 500,
    menu: [],
    equipment: [],
    employees: [],
    dayOpened: 1,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SoundService.setEnabled(false);
  });

  test('Neues Spiel startet mit tutorialEnabled == true', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(gameProvider.notifier);
    await notifier.startNewGame('Tutorial GmbH', 'Tester');
    notifier.stopTimers();

    final state = container.read(gameProvider)!;
    expect(state.tutorialEnabled, isTrue);
    expect(state.tutorialDone, isFalse);
  });

  test('Tutorial-Card ist standardmäßig nicht eingeklappt', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(tutorialCardCollapsedProvider), isFalse);
  });

  test('CTA für openFirstShop führt zur Stadtkarte oder zum Städte-Tab', () {
    final state = GameState.initial(
      companyName: 'Tutorial GmbH',
      founderName: 'Tester',
      startCash: 15000,
    );

    final target = tutorialJumpTarget(state, TutorialStep.openFirstShop);

    expect(target.tabIndex, TutorialStep.openFirstShop.targetTabIndex);
    expect(target.route, startsWith('/city-map/'));
  });

  test('Preis-CTA fällt ohne Filiale auf Stadtkarte zurück', () {
    final state = GameState.initial(
      companyName: 'Tutorial GmbH',
      founderName: 'Tester',
      startCash: 15000,
    );

    final target = tutorialJumpTarget(state, TutorialStep.changeProductPrice);

    expect(target.route, startsWith('/city-map/'));
  });

  test('Nach Filialeröffnung wird openFirstShop abgeschlossen', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(gameProvider.notifier);
    await notifier.startNewGame('Tutorial GmbH', 'Tester');
    notifier.stopTimers();

    notifier.openShop(_shop());

    expect(notifier.currentTutorialStep, TutorialStep.understandLocationValues);
  });

  test('Nach Preisänderung wird changeProductPrice abgeschlossen', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(gameProvider.notifier);
    await notifier.startNewGame('Tutorial GmbH', 'Tester');
    notifier.stopTimers();

    notifier.openShop(_shop());
    notifier.acknowledgeTutorialStep(); // understandLocationValues -> changeProductPrice

    final state = container.read(gameProvider)!;
    final shop = state.shops.first;
    final product = shop.menu.first;

    notifier.updateProductPrice(shop.id, product.productId, product.price + 0.5);

    expect(notifier.currentTutorialStep, TutorialStep.endFirstDay);
  });

  test('Nach endDay() wird endFirstDay abgeschlossen', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(gameProvider.notifier);
    await notifier.startNewGame('Tutorial GmbH', 'Tester');
    notifier.stopTimers();

    notifier.openShop(_shop());
    notifier.acknowledgeTutorialStep();

    var state = container.read(gameProvider)!;
    final shop = state.shops.first;
    final product = shop.menu.first;
    notifier.updateProductPrice(shop.id, product.productId, product.price + 0.5);

    expect(notifier.currentTutorialStep, TutorialStep.endFirstDay);

    notifier.endDay();

    expect(notifier.currentTutorialStep, TutorialStep.readDayReport);
  });

  test('Skip ist vor dem ersten Tagesabschluss nicht verfügbar', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(gameProvider.notifier);
    await notifier.startNewGame('Tutorial GmbH', 'Tester');
    notifier.stopTimers();

    notifier.openShop(_shop());

    final before = container.read(gameProvider)!;
    expect(notifier.canSkipTutorial, isFalse);

    notifier.skipTutorial();

    final after = container.read(gameProvider)!;
    expect(after.tutorialEnabled, before.tutorialEnabled);
    expect(after.tutorialDone, before.tutorialDone);
  });

  test('Skip nach readDayReport beendet Tutorial sauber', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(gameProvider.notifier);
    await notifier.startNewGame('Tutorial GmbH', 'Tester');
    notifier.stopTimers();

    notifier.openShop(_shop());
    notifier.acknowledgeTutorialStep();

    var state = container.read(gameProvider)!;
    final shop = state.shops.first;
    final product = shop.menu.first;
    notifier.updateProductPrice(shop.id, product.productId, product.price + 0.5);
    notifier.endDay();

    state = container.read(gameProvider)!;
    expect(notifier.currentTutorialStep, TutorialStep.readDayReport);
    expect(notifier.canSkipTutorial, isTrue);

    final cashBefore = state.cash;
    notifier.skipTutorial();

    final after = container.read(gameProvider)!;
    expect(after.tutorialDone, isTrue);
    expect(after.tutorialEnabled, isFalse);
    expect(after.tutorialStep, kTutorialStepCount - 1);
    expect(after.cash, cashBefore);
  });
}
