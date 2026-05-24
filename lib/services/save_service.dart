import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_state.dart';

class SaveService {
  static const _key = 'doener_empire_save';
  static const _hasGameKey = 'doener_empire_has_game';

  static Future<void> save(GameState state) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(state.toJson());
    await prefs.setString(_key, json);
    await prefs.setBool(_hasGameKey, true);
  }

  static Future<GameState?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key);
    if (json == null) return null;
    try {
      return GameState.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<bool> hasSave() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasGameKey) ?? false;
  }

  static Future<void> deleteSave() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    await prefs.remove(_hasGameKey);
  }
}
