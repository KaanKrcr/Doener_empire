import 'dart:ui' show Color;

/// Kosmetische Marken-Themen ("Skins") für die Kette. Ändern die Akzentfarbe
/// der Filialen + ein Marken-Badge. Werden über Achievements freigeschaltet —
/// macht den Sammeltrieb sichtbar, ohne ins Gameplay einzugreifen.
class BrandTheme {
  final String id;
  final String name;
  final String emoji;
  final Color accent;
  final Color accentDark;

  /// Achievement-ID, die dieses Thema freischaltet. null = von Anfang an frei.
  final String? unlockAchievementId;

  const BrandTheme({
    required this.id,
    required this.name,
    required this.emoji,
    required this.accent,
    required this.accentDark,
    this.unlockAchievementId,
  });

  bool unlocked(Set<String> achievementIds) =>
      unlockAchievementId == null || achievementIds.contains(unlockAchievementId);
}

const List<BrandTheme> kBrandThemes = [
  BrandTheme(
    id: 'klassik',
    name: 'Klassik',
    emoji: '🥙',
    accent: Color(0xFFE8743B),
    accentDark: Color(0xFFC25728),
  ),
  BrandTheme(
    id: 'bronze',
    name: 'Bronze-Boss',
    emoji: '🥉',
    accent: Color(0xFFCD7F32),
    accentDark: Color(0xFF9C5F25),
    unlockAchievementId: 'first_week',
  ),
  BrandTheme(
    id: 'tomate',
    name: 'Tomaten-Rot',
    emoji: '🍅',
    accent: Color(0xFFE3433B),
    accentDark: Color(0xFFB12F29),
    unlockAchievementId: 'three_cities',
  ),
  BrandTheme(
    id: 'gold',
    name: 'Gold-Standard',
    emoji: '👑',
    accent: Color(0xFFF2B53C),
    accentDark: Color(0xFFC98F1F),
    unlockAchievementId: 'cash_250k',
  ),
  BrandTheme(
    id: 'neon',
    name: 'Neon-Nacht',
    emoji: '🌃',
    accent: Color(0xFF22D3EE),
    accentDark: Color(0xFF0E7490),
    unlockAchievementId: 'brand_40',
  ),
  BrandTheme(
    id: 'platin',
    name: 'Platin-Imperium',
    emoji: '💎',
    accent: Color(0xFF9AA7C7),
    accentDark: Color(0xFF6B7596),
    unlockAchievementId: 'twenty_shops',
  ),
  BrandTheme(
    id: 'royal',
    name: 'Royal-Purpur',
    emoji: '🟣',
    accent: Color(0xFF8B5CF6),
    accentDark: Color(0xFF6D28D9),
    unlockAchievementId: 'million_revenue',
  ),
];

BrandTheme brandThemeById(String id) {
  for (final t in kBrandThemes) {
    if (t.id == id) return t;
  }
  return kBrandThemes.first; // Klassik als Fallback
}
