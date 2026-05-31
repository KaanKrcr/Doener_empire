import 'package:intl/intl.dart';
import '../models/game_state.dart';
import '../models/achievement_model.dart';
import '../models/campaign_model.dart';
import '../core/constants.dart';
import 'campaign_engine.dart';
import 'game_engine.dart';

final _fmt = NumberFormat('#,##0', 'de_DE');
final _fmtPrice = NumberFormat('#,##0.00', 'de_DE');

/// Erzeugt eine teilbare Text-Zusammenfassung des Imperiums (Zwischenablage).
String empireSummaryText(GameState state) {
  final avgRep = state.shops.isEmpty
      ? 0.0
      : state.shops.fold<double>(0, (s, sh) => s + sh.reputation) /
          state.shops.length;
  final chapters = CampaignEngine.completedCount(state);
  final avgDoener = GameEngine.playerAvgDoenerPrice(state);
  final buf = StringBuffer()
    ..writeln('🥙 ${state.companyName}')
    ..writeln('Tag ${state.currentDay} · ${_fmt.format(state.cash)} € Kasse')
    ..writeln(
        '🏪 ${state.shopCount} Filialen · 👥 ${state.employeeCount} Mitarbeiter')
    ..writeln(
        '📢 Marke ${state.brand.brandAwareness.toStringAsFixed(0)}/100 · ⭐ Ø ${avgRep.toStringAsFixed(1)}')
    ..writeln('💰 Gesamtumsatz ${_fmt.format(state.totalRevenue)} €');
  if (avgDoener != null) {
    final diff = avgDoener - kNationalAvgDoenerPrice;
    final tag = diff <= -0.01
        ? 'unter'
        : diff >= 0.01
            ? 'über'
            : 'genau auf';
    buf.writeln(
        '🥙 Mein Ø-Döner ${_fmtPrice.format(avgDoener)} € — $tag dem Bundesschnitt (${_fmtPrice.format(kNationalAvgDoenerPrice)} €)');
  }
  if (state.prestigePoints > 0) {
    buf.writeln('🏅 Prestige-Stufe ${state.prestigePoints}');
  }
  buf
    ..writeln(
        '🏆 ${state.achievementIds.length}/${kAllAchievements.length} Trophäen · 📖 Kapitel $chapters/${kCampaignChapters.length}')
    ..write('#DönerEmpire #Döner-Index');
  return buf.toString();
}
