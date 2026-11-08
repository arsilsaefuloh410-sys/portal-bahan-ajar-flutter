import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Token desain disalin langsung dari assets/css/style.css web (mode terang).
class AppColors {
  static const primary = Color(0xFF2A4D88);
  static const primaryDark = Color(0xFF213E6E);
  static const primaryLight = Color(0xFF7C94B8);
  static const accent = Color(0xFFB1BBC8);
  static const ice = Color(0xFFC9D0DB);
  static const body = Color(0xFFD9D9D8);
  static const surface = Color(0xFFFFFFFF);
  static const input = Color(0xFFF0F1F0);
  static const textMain = Color(0xFF16264A);
  static const textMuted = Color(0xFF46557A);
  static const textLight = Color(0xFF5A6B87);
  static const border = Color(0xFFB8C0CC);
  static const orange = Color(0xFFEA580C);
}

/// Warna mode gelap dari selektor [data-theme="dark"] di style.css.
class AppColorsDark {
  static const body = Color(0xFF0E1D2E);
  static const surface = Color(0xFF152A40);
  static const surface2 = Color(0xFF1B3350);
  static const input = Color(0xFF1B3350);
  static const textMain = Color(0xFFE9F3FA);
  static const textMuted = Color(0xFF9EB9D0);
  static const border = Color(0xFF2C5177);
  static const primary = Color(0xFF7C94B8);
  static const ice = Color(0xFF1B3350);
}

ThemeData buildLightTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: AppColors.surface,
      error: const Color(0xFFDC2626),
    ),
    scaffoldBackgroundColor: AppColors.body,
  );

  return base.copyWith(
    textTheme: _applyFonts(base.textTheme),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: const TextStyle(color: AppColors.textLight),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.border),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      margin: EdgeInsets.zero,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textMain,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColors.textMain,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.textMain,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}

ThemeData buildDarkTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColorsDark.primary,
      brightness: Brightness.dark,
      primary: AppColorsDark.primary,
      surface: AppColorsDark.surface,
      error: const Color(0xFFF87171),
    ),
    scaffoldBackgroundColor: AppColorsDark.body,
  );

  return base.copyWith(
    textTheme: _applyFonts(base.textTheme),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColorsDark.input,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: const TextStyle(color: AppColorsDark.textMuted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColorsDark.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColorsDark.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColorsDark.primary, width: 1.6),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColorsDark.primary,
        foregroundColor: AppColorsDark.body,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColorsDark.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColorsDark.border),
      ),
      margin: EdgeInsets.zero,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColorsDark.surface,
      foregroundColor: AppColorsDark.textMain,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColorsDark.textMain,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    ),
    dividerTheme: DividerThemeData(color: AppColorsDark.border, thickness: 1),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColorsDark.textMain,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}

/// Judul memakai Outfit, teks isi memakai Plus Jakarta Sans (sama seperti web).
TextTheme _applyFonts(TextTheme base) {
  return GoogleFonts.plusJakartaSansTextTheme(base).copyWith(
    displayLarge: GoogleFonts.outfit(textStyle: base.displayLarge),
    displayMedium: GoogleFonts.outfit(textStyle: base.displayMedium),
    displaySmall: GoogleFonts.outfit(textStyle: base.displaySmall),
    headlineLarge: GoogleFonts.outfit(textStyle: base.headlineLarge),
    headlineMedium: GoogleFonts.outfit(textStyle: base.headlineMedium),
    headlineSmall: GoogleFonts.outfit(textStyle: base.headlineSmall),
    titleLarge: GoogleFonts.outfit(textStyle: base.titleLarge),
    titleMedium: GoogleFonts.outfit(textStyle: base.titleMedium),
    titleSmall: GoogleFonts.outfit(textStyle: base.titleSmall),
  );
}
