import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Theme state notifier
class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.light);

  void toggleTheme() {
    state = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
  }

  void setTheme(ThemeMode theme) {
    state = theme;
  }

  bool get isDarkMode => state == ThemeMode.dark;
  bool get isLightMode => state == ThemeMode.light;
}

// Theme provider
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

// Convenience providers
final isDarkModeProvider = Provider<bool>((ref) {
  return ref.watch(themeProvider) == ThemeMode.dark;
});

final isLightModeProvider = Provider<bool>((ref) {
  return ref.watch(themeProvider) == ThemeMode.light;
});

// Theme data providers
final lightThemeProvider = Provider<ThemeData>((ref) {
  return ThemeData(
    brightness: Brightness.light,
    primaryColor: Colors.black,
    colorScheme: const ColorScheme.light(
      primary: Colors.black,
      secondary: Colors.white,
    ),
    cardTheme: CardThemeData(
      elevation: 4,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      elevation: 2,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
    ),
    fontFamily: 'Roboto',
  );
});

final darkThemeProvider = Provider<ThemeData>((ref) {
  return ThemeData(
    brightness: Brightness.dark,
    primaryColor: Colors.white,
    colorScheme: const ColorScheme.dark(
      primary: Colors.white,
      secondary: Colors.black,
    ),
    cardTheme: CardThemeData(
      elevation: 4,
      color: Colors.black,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 2,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
    ),
    fontFamily: 'Roboto',
  );
}); 