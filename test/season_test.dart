import 'package:flutter_test/flutter_test.dart';
import 'package:doener_empire/models/product_model.dart';
import 'package:doener_empire/services/game_engine.dart';

void main() {
  test('Saison wechselt alle 30 Tage und rotiert', () {
    expect(GameEngine.seasonForDay(1), Season.fruehling);
    expect(GameEngine.seasonForDay(30), Season.fruehling);
    expect(GameEngine.seasonForDay(31), Season.sommer);
    expect(GameEngine.seasonForDay(61), Season.herbst);
    expect(GameEngine.seasonForDay(91), Season.winter);
    expect(GameEngine.seasonForDay(121), Season.fruehling); // neues Jahr
  });

  test('Sommer pusht Getränke, dämpft Döner', () {
    expect(
        GameEngine.seasonCategoryMultiplier(
            Season.sommer, ProductCategory.getraenk),
        greaterThan(1.0));
    expect(
        GameEngine.seasonCategoryMultiplier(
            Season.sommer, ProductCategory.doener),
        lessThan(1.0));
  });

  test('Winter pusht Döner, dämpft Getränke', () {
    expect(
        GameEngine.seasonCategoryMultiplier(
            Season.winter, ProductCategory.doener),
        greaterThan(1.0));
    expect(
        GameEngine.seasonCategoryMultiplier(
            Season.winter, ProductCategory.getraenk),
        lessThan(1.0));
  });
}
