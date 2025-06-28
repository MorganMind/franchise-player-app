import 'package:flutter_riverpod/flutter_riverpod.dart' as r;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_client.dart';

// Auth state notifier
class AuthNotifier extends r.StateNotifier<r.AsyncValue<User?>> {
  AuthNotifier() : super(const r.AsyncValue.loading()) {
    _init();
  }

  void _init() {
    // Listen to auth state changes
    supabase.auth.onAuthStateChange.listen((data) {
      state = r.AsyncValue.data(data.session?.user);
    });
    
    // Get initial auth state
    _getCurrentUser();
  }

  Future<void> _getCurrentUser() async {
    try {
      final user = supabase.auth.currentUser;
      state = r.AsyncValue.data(user);
    } catch (error, stackTrace) {
      state = r.AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> signInWithMagicLink(String email) async {
    state = const r.AsyncValue.loading();
    try {
      await supabase.auth.signInWithOtp(
        email: email,
        emailRedirectTo: 'http://localhost:4000',
      );
      // State will be updated by the auth listener
    } catch (error, stackTrace) {
      state = r.AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> signOut() async {
    try {
      await supabase.auth.signOut();
      // State will be updated by the auth listener
    } catch (error, stackTrace) {
      state = r.AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refreshSession() async {
    try {
      await supabase.auth.refreshSession();
      // State will be updated by the auth listener
    } catch (error, stackTrace) {
      state = r.AsyncValue.error(error, stackTrace);
    }
  }
}

// Auth provider
final authProvider = r.StateNotifierProvider<AuthNotifier, r.AsyncValue<User?>>((ref) {
  return AuthNotifier();
});

// Convenience providers
final isAuthenticatedProvider = r.Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  return authState.when(
    data: (user) => user != null,
    loading: () => false,
    error: (_, __) => false,
  );
});

final currentUserProvider = r.Provider<User?>((ref) {
  final authState = ref.watch(authProvider);
  return authState.when(
    data: (user) => user,
    loading: () => null,
    error: (_, __) => null,
  );
});

final userEmailProvider = r.Provider<String?>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.email;
}); 