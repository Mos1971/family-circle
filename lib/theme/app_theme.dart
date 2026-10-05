import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Black & gold palette for Family Circle, in a dark and a light version.
///
/// The colours are read through getters so that one switch ([setBrightness])
/// restyles the whole app. Screens still just write `AppColors.gold`; they are
/// rebuilt when the theme changes (see ThemeModeProvider / app.dart).
class AppColors {
  AppColors._();

  static bool _dark = true;

  /// Set once per theme change, before the widget tree rebuilds.
  static void setBrightness(Brightness b) => _dark = b == Brightness.dark;
  static Brightness get brightness =>
      _dark ? Brightness.dark : Brightness.light;
  static bool get isDark => _dark;

  // Gold: bright on dark; a deeper gold on light so text stays readable.
  static Color get gold =>
      _dark ? const Color(0xFFD4AF37) : const Color(0xFFB8860B);
  static Color get goldDark =>
      _dark ? const Color(0xFFB8921F) : const Color(0xFF8F6A08);
  static Color get goldLight =>
      _dark ? const Color(0xFFF0D77A) : const Color(0xFFD4AF37);

  static Color get bg =>
      _dark ? const Color(0xFF0A0A0A) : const Color(0xFFF8F4EA);
  static Color get surface =>
      _dark ? const Color(0xFF161616) : const Color(0xFFFFFFFF);
  static Color get surfaceHigh =>
      _dark ? const Color(0xFF211E16) : const Color(0xFFF1EADA);
  static Color get sidebar =>
      _dark ? const Color(0xFF0E0E0E) : const Color(0xFFFFFFFF);
  static Color get text =>
      _dark ? const Color(0xFFF5EFDC) : const Color(0xFF1B1A17);
  static Color get onGold => const Color(0xFF111111);
  static Color get muted =>
      _dark ? const Color(0xFF9C9684) : const Color(0xFF6D6858);
  static Color get border =>
      _dark ? const Color(0xFF2E2A1E) : const Color(0xFFE4DCC8);

  static Color get success =>
      _dark ? const Color(0xFF5CB88A) : const Color(0xFF2E8B57);
  static Color get danger =>
      _dark ? const Color(0xFFE5675A) : const Color(0xFFC0392B);

  /// Sign-in brand panel gradient.
  static List<Color> get brandGradient => _dark
      ? const [Color(0xFF241C06), Color(0xFF0A0A0A)]
      : const [Color(0xFFF3E6BA), Color(0xFFF8F4EA)];
}

class AppTheme {
  AppTheme._();

  /// The full Material theme for [brightness]. Also flips [AppColors] so the
  /// two always agree.
  static ThemeData build(Brightness brightness) {
    AppColors.setBrightness(brightness);
    return _theme(brightness);
  }

  static ThemeData get dark => build(Brightness.dark);
  static ThemeData get light => build(Brightness.light);

  static ThemeData _theme(Brightness brightness) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.gold,
        brightness: brightness,
        primary: AppColors.gold,
        onPrimary: AppColors.onGold,
        secondary: AppColors.goldLight,
        surface: AppColors.surface,
        onSurface: AppColors.text,
        error: AppColors.danger,
      ),
      scaffoldBackgroundColor: AppColors.bg,
      canvasColor: AppColors.surface,
    );

    final textTheme = GoogleFonts.poppinsTextTheme(base.textTheme).copyWith(
      headlineLarge: GoogleFonts.poppins(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppColors.text,
        height: 1.15,
      ),
      headlineMedium: GoogleFonts.poppins(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.text,
      ),
      titleLarge: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.text,
      ),
      titleMedium: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.text,
      ),
      bodyLarge: GoogleFonts.poppins(fontSize: 15, color: AppColors.text),
      bodyMedium: GoogleFonts.poppins(fontSize: 14, color: AppColors.text),
      bodySmall: GoogleFonts.poppins(fontSize: 12, color: AppColors.muted),
      labelLarge: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );

    final pill = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(28),
    );
    const buttonPadding = EdgeInsets.symmetric(horizontal: 22, vertical: 16);

    OutlineInputBorder fieldBorder(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: color, width: width),
        );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.gold,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: AppColors.border),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.onGold,
          padding: buttonPadding,
          textStyle: textTheme.labelLarge,
          shape: pill,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.gold,
          side: BorderSide(color: AppColors.gold, width: 1.4),
          padding: buttonPadding,
          textStyle: textTheme.labelLarge,
          shape: pill,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.gold,
          textStyle: textTheme.labelLarge,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.onGold,
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: AppColors.gold),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        hintStyle: TextStyle(color: AppColors.muted),
        labelStyle: TextStyle(color: AppColors.muted),
        border: fieldBorder(AppColors.border),
        enabledBorder: fieldBorder(AppColors.border),
        focusedBorder: fieldBorder(AppColors.gold, 1.6),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.surfaceHigh,
        selectedColor: AppColors.gold.withValues(alpha: 0.2),
        labelStyle: textTheme.bodyMedium,
        side: BorderSide(color: AppColors.border),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.gold,
        textColor: AppColors.text,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.gold
              : AppColors.muted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.gold.withValues(alpha: 0.35)
              : AppColors.border,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.gold
              : Colors.transparent,
        ),
        checkColor: WidgetStatePropertyAll(AppColors.onGold),
        side: BorderSide(color: AppColors.muted, width: 1.5),
      ),
      dividerTheme: DividerThemeData(color: AppColors.border, thickness: 1),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.gold,
        unselectedItemColor: AppColors.muted,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        constraints: BoxConstraints(maxWidth: 640),
      ),
      popupMenuTheme: PopupMenuThemeData(color: AppColors.surfaceHigh),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.gold,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.onGold,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
