import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/supabase/supabase_init.dart';
import '../models/user.dart' as app_user;

// Provider that returns our custom User model
final currentUserProfileProvider = FutureProvider<app_user.User?>((ref) async {
  final currentUser = supabase.auth.currentUser;
  if (currentUser == null) return null;

  try {
    // Fetch user profile from user_profiles table
    final response = await supabase
        .from('user_profiles')
        .select()
        .eq('id', currentUser.id)
        .maybeSingle();
    
    if (response != null) {
      return app_user.User.fromJson(response);
    } else {
      // If user profile doesn't exist, create a basic user object
      return app_user.User(
        id: currentUser.id,
        email: currentUser.email ?? '',
        username: currentUser.email?.split('@').first ?? 'user',
        displayName: currentUser.email?.split('@').first ?? 'User',
        avatarUrl: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  } catch (e) {
    print('Error fetching user profile: $e');
    // Fallback to basic user object
    return app_user.User(
      id: currentUser.id,
      email: currentUser.email ?? '',
      username: currentUser.email?.split('@').first ?? 'user',
      displayName: currentUser.email?.split('@').first ?? 'User',
      avatarUrl: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
});

// Provider for a specific user by ID
final userProfileProvider = FutureProvider.family<app_user.User?, String>((ref, userId) async {
  try {
    final response = await supabase
        .from('user_profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    
    if (response != null) {
      return app_user.User.fromJson(response);
    }
    return null;
  } catch (e) {
    print('Error fetching user profile for $userId: $e');
    return null;
  }
}); 