import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

export 'app_colors.dart';

class AppTheme {
  AppTheme._();

  /// The full Material theme for [brightness] and colour [scheme]. Also flips
  /// [AppColors] so the two always agree.
  static ThemeData build(
    Brightness brightness, [
    AppScheme scheme = AppScheme.gold,
  ]) {
    AppColors.setLook(brightness, scheme);
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
