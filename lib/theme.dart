import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppTheme {
  static const String _themePreferenceKey = 'admin_dark_mode';
  static final ValueNotifier<ThemeMode> themeMode = ValueNotifier(
    ThemeMode.dark,
  );

  static const Color primary = Color(0xFF4F46E5);
  static const Color primaryDark = Color(0xFF4338CA);
  static const Color danger = Color(0xFFEF4444);
  static const Color success = Color(0xFF047857);
  static const Color warning = Color(0xFFF59E0B);

  static const Color darkBg = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);

  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);

  static Color bg = darkBg;
  static Color surface = darkSurface;
  static Color textPrimary = darkTextPrimary;
  static Color textSecondary = darkTextSecondary;
  static Color border = darkBorder;

  static ThemeData dark() => _buildTheme(
    brightness: Brightness.dark,
    background: darkBg,
    surface: darkSurface,
    foreground: darkTextPrimary,
    secondaryForeground: darkTextSecondary,
    outline: darkBorder,
    accent: primary,
  );

  static ThemeData light() => _buildTheme(
    brightness: Brightness.light,
    background: lightBg,
    surface: lightSurface,
    foreground: lightTextPrimary,
    secondaryForeground: lightTextSecondary,
    outline: lightBorder,
    accent: primaryDark,
  );

  static void setBrightness(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    bg = isDark ? darkBg : lightBg;
    surface = isDark ? darkSurface : lightSurface;
    textPrimary = isDark ? darkTextPrimary : lightTextPrimary;
    textSecondary = isDark ? darkTextSecondary : lightTextSecondary;
    border = isDark ? darkBorder : lightBorder;
  }

  static Future<void> setDarkMode(bool enabled) async {
    final mode = enabled ? ThemeMode.dark : ThemeMode.light;
    if (themeMode.value == mode) return;
    setBrightness(enabled ? Brightness.dark : Brightness.light);
    themeMode.value = mode;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_themePreferenceKey, enabled);
  }

  static Future<void> loadSavedMode() async {
    final preferences = await SharedPreferences.getInstance();
    final enabled = preferences.getBool(_themePreferenceKey) ?? true;
    setBrightness(enabled ? Brightness.dark : Brightness.light);
    themeMode.value = enabled ? ThemeMode.dark : ThemeMode.light;
  }

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color foreground,
    required Color secondaryForeground,
    required Color outline,
    required Color accent,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: brightness,
      surface: surface,
      primary: accent,
      secondary: success,
      error: danger,
    );
    final rounded = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
      side: BorderSide(color: outline),
    );
    final cairoFontFamily = kIsWeb ? GoogleFonts.cairo().fontFamily : 'Cairo';
    TextStyle cairoStyle({
      double? fontSize,
      FontWeight? fontWeight,
      Color? color,
      double? height,
    }) {
      final style = kIsWeb
          ? GoogleFonts.cairo(
              fontSize: fontSize,
              fontWeight: fontWeight,
              color: color,
              height: height,
            )
          : const TextStyle(fontFamily: 'Cairo');
      return style.copyWith(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
      );
    }

    final baseTextTheme = ThemeData(brightness: brightness).textTheme;
    final cairoTextTheme = kIsWeb
        ? GoogleFonts.cairoTextTheme(baseTextTheme)
        : baseTextTheme.apply(fontFamily: cairoFontFamily);
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: cairoFontFamily,
      colorScheme: scheme.copyWith(
        surface: surface,
        outline: outline,
        outlineVariant: outline,
        onSurface: foreground,
      ),
      scaffoldBackgroundColor: background,
      canvasColor: background,
      cardColor: surface,
      dividerColor: outline,
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: outline),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: foreground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: foreground),
        titleTextStyle: cairoStyle(
          color: foreground,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      textTheme: cairoTextTheme.copyWith(
        headlineSmall: cairoStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: foreground,
        ),
        titleLarge: cairoStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: foreground,
        ),
        bodyLarge: cairoStyle(fontSize: 14, color: foreground),
        bodyMedium: cairoStyle(
          fontSize: 13,
          color: secondaryForeground,
          height: 1.45,
        ),
        labelLarge: cairoStyle(color: foreground, fontWeight: FontWeight.w700),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: cairoStyle(color: secondaryForeground),
        labelStyle: cairoStyle(color: secondaryForeground),
        prefixIconColor: secondaryForeground,
        suffixIconColor: secondaryForeground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        shape: rounded,
        margin: EdgeInsets.zero,
      ),
      dividerTheme: DividerThemeData(color: outline),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: accent.withValues(alpha: 0.18),
        side: BorderSide(color: outline),
        labelStyle: cairoStyle(color: foreground),
        secondaryLabelStyle: cairoStyle(color: foreground),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        textStyle: cairoStyle(color: foreground),
        surfaceTintColor: Colors.transparent,
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: cairoStyle(color: foreground),
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(surface),
          side: WidgetStatePropertyAll(BorderSide(color: outline)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 22),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: cairoStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: accent),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: Colors.white,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: accent),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surface,
        contentTextStyle: cairoStyle(color: foreground),
      ),
    );
  }
}
