import 'package:flutter_test/flutter_test.dart';
import 'package:doener_empire/core/localization.dart';

void main() {
  group('Lokalisierung', () {
    test('Alle Sprachen liefern nicht-leere Kern-Labels', () {
      for (final lang in AppLanguage.values) {
        final t = AppStrings(lang);
        final samples = [
          t.navShop,
          t.navCities,
          t.navEmpire,
          t.navCorporate,
          t.navFinance,
          t.navBank,
          t.gameMenu,
          t.backToMainMenu,
          t.settings,
          t.brandDesign,
          t.myEmpire,
          t.soundEffects,
          t.language,
          t.on,
          t.off,
          t.cancel,
        ];
        for (final s in samples) {
          expect(s.trim(), isNotEmpty, reason: '$lang');
        }
      }
    });

    test('Übersetzungen unterscheiden sich je Sprache', () {
      expect(const AppStrings(AppLanguage.de).navCities, 'Städte');
      expect(const AppStrings(AppLanguage.tr).navCities, 'Şehirler');
      expect(const AppStrings(AppLanguage.en).navCities, 'Cities');
      // DE/TR/EN sind paarweise verschieden für ein typisches Label.
      final de = const AppStrings(AppLanguage.de).settings;
      final tr = const AppStrings(AppLanguage.tr).settings;
      final en = const AppStrings(AppLanguage.en).settings;
      expect({de, tr, en}.length, 3);
    });

    test('Jede Sprache hat Label und Flagge', () {
      for (final l in AppLanguage.values) {
        expect(l.label.trim(), isNotEmpty);
        expect(l.flag.trim(), isNotEmpty);
      }
    });

    test('Standardsprache ist Deutsch', () {
      expect(LanguageService.current, AppLanguage.de);
    });
  });
}
