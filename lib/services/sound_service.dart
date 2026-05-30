import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum Sfx { tap, purchase, reward, dayend, error }

/// Schlanker Sound-Effekt-Dienst. Feuert kurze CC0-SFX (Kenney) ab.
///
/// Test-sicher: der AudioPlayer wird erst beim ersten echten Abspielen lazy
/// erzeugt und jeder Aufruf ist in try/catch gekapselt — in Test-/Headless-
/// Umgebungen ohne Audio-Plugin passiert dadurch einfach nichts.
class SoundService {
  SoundService._();

  static bool enabled = true;
  static const _prefsKey = 'doener_sound_enabled';

  static AudioPlayer? _p;
  static AudioPlayer get _player =>
      _p ??= AudioPlayer()..setReleaseMode(ReleaseMode.stop);

  static String _asset(Sfx s) => switch (s) {
        Sfx.tap => 'sfx/tap.ogg',
        Sfx.purchase => 'sfx/purchase.ogg',
        Sfx.reward => 'sfx/reward.ogg',
        Sfx.dayend => 'sfx/dayend.ogg',
        Sfx.error => 'sfx/error.ogg',
      };

  /// Beim App-Start aufrufen (lädt die Mute-Einstellung).
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      enabled = prefs.getBool(_prefsKey) ?? true;
    } catch (_) {/* ignore */}
  }

  static Future<void> setEnabled(bool value) async {
    enabled = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKey, value);
    } catch (_) {/* ignore */}
  }

  /// Spielt einen Effekt ab (fire-and-forget, fehlertolerant).
  static void play(Sfx s) {
    if (!enabled) return;
    try {
      _player.stop();
      _player.play(AssetSource(_asset(s)), volume: 0.55);
    } catch (_) {/* ignore (z.B. kein Audio im Test) */}
  }
}
