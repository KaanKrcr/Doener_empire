import 'package:flutter/material.dart';

/// Warme Imbiss/Döner-Farbpalette — keine externen Fonts, läuft offline.
class AppColors {
  // ── Primärfarben (warmes Döner-Rot, geröstet) ────────────────────────────
  static const primary = Color(0xFFE85D2F);      // Spieß-Orange-Rot, geröstet
  static const primaryDark = Color(0xFFC44820);  // Dunkleres Spieß-Rot
  static const primaryGlow = Color(0x33E85D2F);

  // ── Akzente ───────────────────────────────────────────────────────────────
  static const secondary = Color(0xFFFFB347);   // Warmes Curry-Gelb-Orange
  static const accent = Color(0xFF7BC950);      // Frisches Salat-Grün
  static const gold = Color(0xFFFFC93C);        // Goldgelb wie frisches Brot
  static const cream = Color(0xFFFFE8B0);       // Helles Brot-Beige
  static const tomato = Color(0xFFE74C3C);      // Tomaten-Rot
  static const onion = Color(0xFFB565A7);       // Zwiebel-Lila

  // ── Hintergründe (warmes Dunkel, leicht bräunlich) ──────────────────────
  static const bg = Color(0xFF14100E);          // Sehr dunkles Holz-Braun
  static const bgCard = Color(0xFF1F1813);      // Karten-Hintergrund warm
  static const bgCardHover = Color(0xFF2A1F18); // Hover
  static const bgSurface = Color(0xFF241B15);   // Modals
  static const bgTab = Color(0xFF18130F);       // Bottom Nav — wie Theke
  static const bgGlow = Color(0x22E85D2F);      // Spieß-Glow

  // ── Text ──────────────────────────────────────────────────────────────────
  static const textPrimary = Color(0xFFFAF4E8);    // Cremig, nicht reinweiß
  static const textSecondary = Color(0xFFC4B5A0);  // Sand
  static const textMuted = Color(0xFF7A6A5C);      // Dunkles Sand

  // ── Status ────────────────────────────────────────────────────────────────
  static const success = Color(0xFF7BC950);     // Salat-grün
  static const warning = Color(0xFFFFC93C);     // Brot-Gold
  static const danger = Color(0xFFE74C3C);      // Tomate

  // ── Borders ───────────────────────────────────────────────────────────────
  static const border = Color(0xFF2F2419);       // Braun
  static const borderLight = Color(0xFF3D2E22);  // Helleres Braun
}

class AppTheme {
  // System-Default Sans-Serif (Roboto auf Android, San Francisco auf iOS).
  // Kein externer Download → läuft offline.
  static const String _fontFamily = 'Roboto';

  static ThemeData get dark {
    const base = ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.bgCard,
      error: AppColors.danger,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: _fontFamily,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: base,
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 34,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.0,
        ),
        displayMedium: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 26,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        titleMedium: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
        ),
        bodySmall: TextStyle(
          color: AppColors.textMuted,
          fontSize: 11,
          letterSpacing: 0.2,
        ),
        labelLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.borderLight, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        iconTheme:
            IconThemeData(color: AppColors.textSecondary, size: 22),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.bgTab,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle:
            TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 11),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgSurface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        labelStyle:
            const TextStyle(color: AppColors.textMuted, fontSize: 14),
        hintStyle:
            const TextStyle(color: AppColors.textMuted, fontSize: 14),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.bgCardHover,
        contentTextStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
