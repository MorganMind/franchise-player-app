import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appThemeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);
final lightThemeLightProvider = Provider<ThemeData>((ref) => ThemeData.light());
final lightThemeDarkProvider = Provider<ThemeData>((ref) => ThemeData.dark()); 