import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Navigation state provider
final navigationStateProvider = StateProvider<NavigationState>((ref) {
  return NavigationState();
});

class NavigationState {
  final String? currentRoute;
  final Map<String, dynamic>? routeArguments;
  final List<String> routeHistory;

  NavigationState({
    this.currentRoute,
    this.routeArguments,
    this.routeHistory = const [],
  });

  NavigationState copyWith({
    String? currentRoute,
    Map<String, dynamic>? routeArguments,
    List<String>? routeHistory,
  }) {
    return NavigationState(
      currentRoute: currentRoute ?? this.currentRoute,
      routeArguments: routeArguments ?? this.routeArguments,
      routeHistory: routeHistory ?? this.routeHistory,
    );
  }
}

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static NavigatorState? get navigator => navigatorKey.currentState;

  // Navigate to a named route
  static Future<T?> navigateTo<T>({
    required String route,
    Map<String, dynamic>? arguments,
    WidgetRef? ref,
    required BuildContext context,
  }) async {
    if (ref != null) {
      ref.read(navigationStateProvider.notifier).state = NavigationState(
        currentRoute: route,
        routeArguments: arguments,
        routeHistory: [
          ...ref.read(navigationStateProvider).routeHistory,
          route,
        ],
      );
    }
    context.go(route);
    return null;
  }

  // Navigate to DM thread
  static Future<T?> navigateToDM<T>({
    required String threadId,
    WidgetRef? ref,
    required BuildContext context,
  }) async {
    return navigateTo<T>(
      route: '/dm',
      arguments: {'threadId': threadId},
      ref: ref,
      context: context,
    );
  }

  // Navigate to channel
  static Future<T?> navigateToChannel<T>({
    required String channelId,
    required String channelName,
    WidgetRef? ref,
    required BuildContext context,
  }) async {
    return navigateTo<T>(
      route: '/channel',
      arguments: {
        'channelId': channelId,
        'channelName': channelName,
      },
      ref: ref,
      context: context,
    );
  }

  // Navigate to user search
  static Future<T?> navigateToUserSearch<T>({WidgetRef? ref, required BuildContext context}) async {
    return navigateTo<T>(
      route: '/search',
      ref: ref,
      context: context,
    );
  }

  // Go back
  static void goBack<T>([T? result]) {
    navigator?.pop<T>(result);
  }

  // Go back to a specific route
  static void goBackTo(String routeName) {
    navigator?.popUntil((r) => r.settings.name == routeName);
  }

  // Replace current route
  static Future<T?> replaceRoute<T>({
    required String route,
    Map<String, dynamic>? arguments,
    WidgetRef? ref,
  }) async {
    if (ref != null) {
      ref.read(navigationStateProvider.notifier).state = NavigationState(
        currentRoute: route,
        routeArguments: arguments,
        routeHistory: ref.read(navigationStateProvider).routeHistory,
      );
    }

    return navigator?.pushReplacementNamed<T, void>(route, arguments: arguments);
  }

  // Clear navigation stack and go to route
  static Future<T?> navigateAndClear<T>({
    required String route,
    Map<String, dynamic>? arguments,
    WidgetRef? ref,
  }) async {
    if (ref != null) {
      ref.read(navigationStateProvider.notifier).state = NavigationState(
        currentRoute: route,
        routeArguments: arguments,
        routeHistory: [route],
      );
    }

    return navigator?.pushNamedAndRemoveUntil<T>(
      route,
      (route) => false,
      arguments: arguments,
    );
  }

  // Get current route
  static String? getCurrentRoute() {
    return navigator?.widget.initialRoute;
  }

  // Check if can go back
  static bool canGoBack() {
    return navigator?.canPop() ?? false;
  }
} 