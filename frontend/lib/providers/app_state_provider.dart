import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase/supabase_init.dart';
import '../models/user.dart' as app_user;
import 'package:gotrue/src/types/user.dart' as supa_user;

// App state provider
final appStateProvider = StateNotifierProvider<AppStateNotifier, AppState>((ref) {
  return AppStateNotifier();
});

class AppState {
  final bool isAuthenticated;
  final app_user.User? currentUser;
  final bool isLoading;
  final String? error;
  final bool isOnline;
  final String currentRoute;
  final Map<String, dynamic> routeArguments;

  AppState({
    this.isAuthenticated = false,
    this.currentUser,
    this.isLoading = false,
    this.error,
    this.isOnline = true,
    this.currentRoute = '/',
    this.routeArguments = const {},
  });

  AppState copyWith({
    bool? isAuthenticated,
    app_user.User? currentUser,
    bool? isLoading,
    String? error,
    bool? isOnline,
    String? currentRoute,
    Map<String, dynamic>? routeArguments,
  }) {
    return AppState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      currentUser: currentUser ?? this.currentUser,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isOnline: isOnline ?? this.isOnline,
      currentRoute: currentRoute ?? this.currentRoute,
      routeArguments: routeArguments ?? this.routeArguments,
    );
  }
}

class AppStateNotifier extends StateNotifier<AppState> {
  AppStateNotifier() : super(AppState()) {
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    state = state.copyWith(isLoading: true);
    
    try {
      // Check authentication status
      final session = supabase.auth.currentSession;
      if (session != null) {
        await _loadCurrentUser(session.user);
      }
      
      // Listen to auth changes
      supabase.auth.onAuthStateChange.listen((data) async {
        final event = data.event;
        final session = data.session;
        
        switch (event) {
          case AuthChangeEvent.signedIn:
            if (session != null) {
              await _loadCurrentUser(session.user);
            }
            break;
          case AuthChangeEvent.signedOut:
            _clearUser();
            break;
          case AuthChangeEvent.tokenRefreshed:
            if (session != null) {
              await _loadCurrentUser(session.user);
            }
            break;
          default:
            break;
        }
      });
      
    } catch (e) {
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> _loadCurrentUser(supa_user.User user) async {
    try {
      // Fetch user profile from user_profiles table
      final response = await supabase
          .from('user_profiles')
          .select()
          .eq('id', user.id)
          .single();
      
      final userProfile = app_user.User.fromJson(response);
      state = state.copyWith(
        isAuthenticated: true,
        currentUser: userProfile,
        error: null,
      );
    } catch (e) {
      // If user profile doesn't exist, create a basic user object
      final basicUser = app_user.User(
        id: user.id,
        email: user.email ?? '',
        username: user.email?.split('@').first ?? 'user',
        displayName: user.email?.split('@').first ?? 'User',
        avatarUrl: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      state = state.copyWith(
        isAuthenticated: true,
        currentUser: basicUser,
        error: null,
      );
    }
  }

  void _clearUser() {
    state = state.copyWith(
      isAuthenticated: false,
      currentUser: null,
      error: null,
    );
  }

  // Update current route
  void updateRoute(String route, [Map<String, dynamic>? arguments]) {
    state = state.copyWith(
      currentRoute: route,
      routeArguments: arguments ?? {},
    );
  }

  // Set loading state
  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  // Set error
  void setError(String? error) {
    state = state.copyWith(error: error);
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Set online status
  void setOnlineStatus(bool isOnline) {
    state = state.copyWith(isOnline: isOnline);
  }

  // Sign out
  Future<void> signOut() async {
    try {
      state = state.copyWith(isLoading: true);
      await supabase.auth.signOut();
      _clearUser();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? username,
    String? displayName,
    String? avatarUrl,
  }) async {
    if (state.currentUser == null) return;

    try {
      state = state.copyWith(isLoading: true);
      
      final updates = <String, dynamic>{};
      if (username != null) updates['username'] = username;
      if (displayName != null) updates['display_name'] = displayName;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
      updates['updated_at'] = DateTime.now().toIso8601String();

      await supabase
          .from('user_profiles')
          .update(updates)
          .eq('id', state.currentUser!.id);

      // Update local state
      final updatedUser = state.currentUser!.copyWith(
        username: username ?? state.currentUser!.username,
        displayName: displayName ?? state.currentUser!.displayName,
        avatarUrl: avatarUrl ?? state.currentUser!.avatarUrl,
        updatedAt: DateTime.now(),
      );

      state = state.copyWith(currentUser: updatedUser);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}

// Convenience providers
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(appStateProvider).isAuthenticated;
});

final currentUserProvider = Provider<app_user.User?>((ref) {
  return ref.watch(appStateProvider).currentUser;
});

final isLoadingProvider = Provider<bool>((ref) {
  return ref.watch(appStateProvider).isLoading;
});

final errorProvider = Provider<String?>((ref) {
  return ref.watch(appStateProvider).error;
});

final isOnlineProvider = Provider<bool>((ref) {
  return ref.watch(appStateProvider).isOnline;
}); 