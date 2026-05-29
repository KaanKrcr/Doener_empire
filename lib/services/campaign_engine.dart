import '../models/campaign_model.dart';
import '../models/mission_model.dart';
import '../models/game_state.dart';
import 'mission_engine.dart';

/// Wertet die Story-Kampagne aus. Nutzt die Bedingungs-Logik der MissionEngine
/// wieder, statt sie zu duplizieren.
class CampaignEngine {
  /// Das aktuell aktive Kapitel = erstes nicht abgeschlossenes.
  /// null, wenn die Kampagne komplett durchgespielt ist.
  static CampaignChapter? activeChapter(GameState state) {
    for (final c in kCampaignChapters) {
      if (!state.completedChapterIds.contains(c.id)) return c;
    }
    return null;
  }

  static int completedCount(GameState state) =>
      kCampaignChapters
          .where((c) => state.completedChapterIds.contains(c.id))
          .length;

  static bool isComplete(GameState state) => activeChapter(state) == null;

  /// Aktueller Messwert eines Ziels (z.B. Anzahl Filialen).
  static double objectiveCurrent(CampaignObjective obj, GameState state) {
    final probe = Mission(
      id: obj.specialId ?? 'campaign',
      title: '',
      description: '',
      emoji: '',
      cashReward: 0,
      type: obj.type,
      target: obj.target,
    );
    return MissionEngine.currentValueFor(probe, state);
  }

  static bool objectiveDone(CampaignObjective obj, GameState state) =>
      objectiveCurrent(obj, state) >= obj.target;

  /// Fortschritt eines einzelnen Ziels (0..1).
  static double objectiveProgress(CampaignObjective obj, GameState state) {
    if (obj.target <= 0) return 1.0;
    return (objectiveCurrent(obj, state) / obj.target).clamp(0.0, 1.0);
  }

  /// Gesamt-Fortschritt eines Kapitels (Mittel der Ziel-Fortschritte, 0..1).
  static double chapterProgress(CampaignChapter chapter, GameState state) {
    if (chapter.objectives.isEmpty) return 1.0;
    final sum = chapter.objectives.fold<double>(
        0, (s, o) => s + objectiveProgress(o, state));
    return (sum / chapter.objectives.length).clamp(0.0, 1.0);
  }

  static bool isChapterComplete(CampaignChapter chapter, GameState state) =>
      chapter.objectives.every((o) => objectiveDone(o, state));

  /// Prüft das aktive Kapitel; ist es erfüllt, wird es als abgeschlossen
  /// markiert, die Belohnung gutgeschrieben und das Kapitel zurückgegeben
  /// (für die Abschluss-Feier).
  static CampaignCheckResult checkAndApply(GameState state) {
    final chapter = activeChapter(state);
    if (chapter == null) {
      return CampaignCheckResult(state: state, justCompleted: null);
    }
    if (!isChapterComplete(chapter, state)) {
      return CampaignCheckResult(state: state, justCompleted: null);
    }
    final newState = state.copyWith(
      cash: state.cash + chapter.cashReward,
      completedChapterIds: [...state.completedChapterIds, chapter.id],
    );
    return CampaignCheckResult(state: newState, justCompleted: chapter);
  }
}

class CampaignCheckResult {
  final GameState state;
  final CampaignChapter? justCompleted;
  CampaignCheckResult({required this.state, required this.justCompleted});
}
