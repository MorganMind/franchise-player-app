import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as r;
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class FranchisePlayerApp extends r.ConsumerWidget {
  const FranchisePlayerApp({super.key});

  @override
  Widget build(BuildContext context, r.WidgetRef ref) {
    final themeMode = ref.watch(appThemeProvider);
    final lightTheme = ref.watch(lightThemeLightProvider);
    final darkTheme = ref.watch(lightThemeDarkProvider);
    return MaterialApp.router(
      title: 'Franchise Player',
      routerConfig: AppRouter.router,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
    );
  }
} 