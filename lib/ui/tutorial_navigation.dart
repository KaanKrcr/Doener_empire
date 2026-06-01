import '../core/constants.dart';
import '../models/game_state.dart';
import '../models/tutorial_model.dart';

class TutorialJumpTarget {
  final int? tabIndex;
  final String? route;

  const TutorialJumpTarget({this.tabIndex, this.route});
}

TutorialJumpTarget tutorialJumpTarget(GameState state, TutorialStep step) {
  final cityId = _firstUnlockedCityId(state);

  switch (step) {
    case TutorialStep.openFirstShop:
    case TutorialStep.understandLocationValues:
      return TutorialJumpTarget(
        tabIndex: step.targetTabIndex,
        route: '/city-map/$cityId',
      );
    case TutorialStep.changeProductPrice:
    case TutorialStep.hireFirstEmployee:
      final firstShop = state.shops.isNotEmpty ? state.shops.first : null;
      if (firstShop != null) {
        return TutorialJumpTarget(
          tabIndex: step.targetTabIndex,
          route: '/shop/${firstShop.id}',
        );
      }
      return TutorialJumpTarget(
        tabIndex: TutorialStep.openFirstShop.targetTabIndex,
        route: '/city-map/$cityId',
      );
    case TutorialStep.endFirstDay:
    case TutorialStep.readDayReport:
    case TutorialStep.viewDashboardMetrics:
    case TutorialStep.openEmpireMenu:
    case TutorialStep.understandHrCompetitionGrowth:
      return TutorialJumpTarget(tabIndex: step.targetTabIndex);
    case TutorialStep.finishTutorial:
      return const TutorialJumpTarget();
  }
}

String _firstUnlockedCityId(GameState state) {
  for (final cityId in state.unlockedCityIds) {
    final found = kAllCities.any((city) => city.id == cityId);
    if (found) return cityId;
  }
  return kAllCities.first.id;
}
