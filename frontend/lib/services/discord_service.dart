import 'package:supabase_flutter/supabase_flutter.dart';

class DiscordService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Check if the current user signed up with Discord
  static bool isDiscordUser(User? user) {
    return user?.appMetadata['provider'] == 'discord';
  }

  /// Get Discord ID for the current user
  static String? getDiscordId(User? user) {
    if (user?.appMetadata['provider'] == 'discord') {
      return user?.id;
    }
    return null;
  }

  /// Get Discord username from user metadata
  static String? getDiscordUsername(User? user) {
    return user?.userMetadata?['username'] as String?;
  }

  /// Get Discord avatar URL from user metadata
  static String? getDiscordAvatar(User? user) {
    return user?.userMetadata?['avatar_url'] as String?;
  }

  /// Get Discord full name from user metadata
  static String? getDiscordFullName(User? user) {
    return user?.userMetadata?['full_name'] as String?;
  }

  /// Check if a user profile has a Discord ID
  static bool hasDiscordId(Map<String, dynamic> userProfile) {
    return userProfile['discord_id'] != null && userProfile['discord_id'].toString().isNotEmpty;
  }

  /// Format Discord username with discriminator if available
  static String formatDiscordUsername(String? username, String? discriminator) {
    if (username == null) return 'Unknown User';
    if (discriminator != null && discriminator != '0') {
      return '$username#$discriminator';
    }
    return username;
  }

  /// Get Discord user info from Supabase auth user
  static Map<String, dynamic> getDiscordUserInfo(User? user) {
    if (user == null) return {};
    
    return {
      'discord_id': getDiscordId(user),
      'username': getDiscordUsername(user),
      'full_name': getDiscordFullName(user),
      'avatar_url': getDiscordAvatar(user),
      'provider': user.appMetadata['provider'],
    };
  }

  /// Check if the current user can link Discord account
  static Future<bool> canLinkDiscord() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      // Check if user already has Discord linked
      final response = await _supabase
          .from('user_profiles')
          .select('discord_id')
          .eq('id', user.id)
          .single();

      return response['discord_id'] == null;
    } catch (e) {
      print('Error checking Discord link status: $e');
      return false;
    }
  }

  /// Get Discord profile information for display
  static Map<String, String> getDiscordProfileInfo(User? user) {
    final info = <String, String>{};
    
    if (user?.userMetadata != null) {
      final metadata = user!.userMetadata!;
      
      if (metadata['username'] != null) {
        info['username'] = metadata['username'] as String;
      }
      
      if (metadata['full_name'] != null) {
        info['full_name'] = metadata['full_name'] as String;
      }
      
      if (metadata['avatar_url'] != null) {
        info['avatar_url'] = metadata['avatar_url'] as String;
      }
    }
    
    return info;
  }
}


