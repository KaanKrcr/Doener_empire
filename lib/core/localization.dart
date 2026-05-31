import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Unterstützte App-Sprachen.
enum AppLanguage { de, tr, en }

extension AppLanguageInfo on AppLanguage {
  String get label {
    switch (this) {
      case AppLanguage.de:
        return 'Deutsch';
      case AppLanguage.tr:
        return 'Türkçe';
      case AppLanguage.en:
        return 'English';
    }
  }

  String get flag {
    switch (this) {
      case AppLanguage.de:
        return '🇩🇪';
      case AppLanguage.tr:
        return '🇹🇷';
      case AppLanguage.en:
        return '🇬🇧';
    }
  }
}

/// Persistiert die gewählte Sprache (gleiches Muster wie [SoundService]).
class LanguageService {
  LanguageService._();

  static AppLanguage current = AppLanguage.de;
  static const _prefsKey = 'doener_language';

  /// Beim App-Start aufrufen.
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefsKey);
      current = AppLanguage.values.firstWhere(
        (l) => l.name == saved,
        orElse: () => AppLanguage.de,
      );
    } catch (_) {/* ignore */}
  }

  static Future<void> setLanguage(AppLanguage lang) async {
    current = lang;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, lang.name);
    } catch (_) {/* ignore */}
  }
}

/// App-weite Sprache. Widgets, die `ref.watch` nutzen, bauen bei Wechsel neu.
final languageProvider =
    StateProvider<AppLanguage>((ref) => LanguageService.current);

/// Übersetzte UI-Texte.
///
/// Bewusst als getter-basierte Fassade mit Inline-Übersetzungen umgesetzt
/// (statt gen-l10n/ARB), damit die Lokalisierung schrittweise und ohne Build-
/// Pipeline-Umbau wachsen kann. Deckt aktuell die App-Navigation und das
/// Spielmenü vollständig in DE/TR/EN ab; weitere Oberflächen folgen inkrementell.
class AppStrings {
  final AppLanguage lang;
  const AppStrings(this.lang);

  String _pick(String de, String tr, String en) {
    switch (lang) {
      case AppLanguage.de:
        return de;
      case AppLanguage.tr:
        return tr;
      case AppLanguage.en:
        return en;
    }
  }

  // ── Navigation ──────────────────────────────────────────────────────────
  String get navShop => _pick('Imbiss', 'Dükkan', 'Shop');
  String get navCities => _pick('Städte', 'Şehirler', 'Cities');
  String get navEmpire => _pick('Imperium', 'İmparatorluk', 'Empire');
  String get navCorporate => _pick('Konzern', 'Holding', 'Corporate');
  String get navFinance => _pick('Finanzen', 'Finans', 'Finance');
  String get navBank => _pick('Bank', 'Banka', 'Bank');

  // ── Spielmenü ───────────────────────────────────────────────────────────
  String get gameMenu => _pick('Spielmenü', 'Oyun Menüsü', 'Game Menu');
  String get backToMainMenu =>
      _pick('Zurück zum Hauptmenü', 'Ana Menüye Dön', 'Back to Main Menu');
  String get backToMainMenuSub => _pick('Aktueller Stand bleibt gespeichert.',
      'Mevcut ilerleme kaydedilir.', 'Current progress stays saved.');
  String get settings => _pick('Einstellungen', 'Ayarlar', 'Settings');
  String get settingsSub => _pick('Optionen und Systemstatus anzeigen.',
      'Seçenekleri ve sistem durumunu göster.', 'Show options and system status.');
  String get brandDesign =>
      _pick('Marken-Design', 'Marka Tasarımı', 'Brand Design');
  String get brandDesignSub => _pick('Skins über Trophäen freischalten.',
      'Kupalarla görünümleri aç.', 'Unlock skins via trophies.');
  String get myEmpire => _pick('Mein Imperium', 'İmparatorluğum', 'My Empire');
  String get myEmpireSub => _pick('Zusammenfassung teilen/kopieren.',
      'Özeti paylaş/kopyala.', 'Share/copy your summary.');
  String get soundEffects =>
      _pick('Sound-Effekte', 'Ses Efektleri', 'Sound Effects');
  String get language => _pick('Sprache', 'Dil', 'Language');
  String get languageSub => _pick('App-Sprache wählen.', 'Uygulama dilini seç.',
      'Choose the app language.');

  // ── Allgemein ───────────────────────────────────────────────────────────
  String get on => _pick('An', 'Açık', 'On');
  String get off => _pick('Aus', 'Kapalı', 'Off');
  String get cancel => _pick('Abbrechen', 'İptal', 'Cancel');
}

/// Bequemer Zugriff in Consumer-Widgets: `ref.strings`.
extension AppStringsRef on WidgetRef {
  AppStrings get strings => AppStrings(watch(languageProvider));
}
