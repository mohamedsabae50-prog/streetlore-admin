import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlore_admin/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AppTheme.themeMode.value = ThemeMode.dark;
    AppTheme.setBrightness(Brightness.dark);
  });

  tearDown(() {
    AppTheme.setBrightness(Brightness.dark);
    AppTheme.themeMode.value = ThemeMode.dark;
  });

  test(
    'defaults to dark mode and restores the saved theme preference',
    () async {
      expect(AppTheme.themeMode.value, ThemeMode.dark);

      await AppTheme.setDarkMode(false);
      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getBool('admin_dark_mode'), isFalse);
      expect(AppTheme.themeMode.value, ThemeMode.light);
      expect(AppTheme.surface, AppTheme.lightSurface);

      await AppTheme.loadSavedMode();
      expect(AppTheme.themeMode.value, ThemeMode.light);
      expect(AppTheme.textPrimary, AppTheme.lightTextPrimary);
    },
  );

  test('applies the Cairo font to the global text theme', () {
    final theme = AppTheme.light();

    expect(theme.textTheme.bodyMedium?.fontFamily, contains('Cairo'));
    expect(theme.textTheme.labelLarge?.fontFamily, contains('Cairo'));
    expect(theme.chipTheme.labelStyle?.fontFamily, contains('Cairo'));
  });
}
