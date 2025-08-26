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
    supabase.auth.onAuthStateChange.listen((data) async {
      print('🔐 Auth state change: ${data.event}');
      
      // Handle new user creation
      if (data.event == AuthChangeEvent.signedIn && data.session?.user != null) {
        await _ensureUserProfile(data.session!.user);
      }
      
      state = r.AsyncValue.data(data.session?.user);
    });
    
    // Get initial auth state
    _getCurrentUser();
  }

  Future<void> _ensureUserProfile(User user) async {
    try {
      print('🔐 Ensuring user profile exists for: ${user.email}');
      
      // Check if email already exists
      if (user.email != null) {
        final emailCheck = await supabase.rpc('check_email_exists', params: {
          'user_email': user.email,
        });
        
        if (emailCheck.isNotEmpty && emailCheck.first['email_exists'] == true) {
          print('⚠️ Email already exists in database: ${user.email}');
          print('ℹ️ This might be a linked account or existing user');
        }
      }
      
      // Call the create_user_profile function
      await supabase.rpc('create_user_profile', params: {
        'user_id': user.id,
        'user_email': user.email,
        'user_username': user.userMetadata?['username'] ?? user.email?.split('@')[0],
        'user_display_name': user.userMetadata?['full_name'] ?? user.email?.split('@')[0],
      });
      
      print('✅ User profile created/updated successfully');
    } catch (error) {
      print('❌ Error creating user profile: $error');
      // Don't throw here - we don't want to break the auth flow
    }
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
      // Immediately update state to null to ensure logout is reflected
      state = const r.AsyncValue.data(null);
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