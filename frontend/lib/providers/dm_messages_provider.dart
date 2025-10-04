import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/supabase/supabase_init.dart';
import '../models/message.dart';

final dmMessagesProvider = StreamProvider.family<List<Message>, String>((ref, dmChannelId) {
  return supabase
      .from('messages')
      .stream(primaryKey: ['id'])
      .eq('dm_channel_id', dmChannelId)
      .order('created_at')
      .map((event) => event.map((json) => Message.fromJson(json)).toList());
});

// Provider for the latest message in a DM channel
final latestDmMessageProvider = StreamProvider.family<Message?, String>((ref, dmChannelId) {
  final stream = supabase
      .from('messages')
      .stream(primaryKey: ['id'])
      .eq('dm_channel_id', dmChannelId)
      .order('created_at', ascending: false)
      .limit(1);
  
  return stream.map((event) {
    if (event.isEmpty) return null;
    try {
      // Filter out deleted messages
      final nonDeletedMessages = event.where((msg) => msg['is_deleted'] != true).toList();
      if (nonDeletedMessages.isEmpty) return null;
      return Message.fromMap(nonDeletedMessages.first);
    } catch (e) {
      return null;
    }
  });
});

// Provider to get or create DM channel between two users
final dmChannelProvider = FutureProvider.family<String, String>((ref, otherUserId) async {
  final currentUser = supabase.auth.currentUser;
  if (currentUser == null) throw Exception('User not authenticated');
  
  // Check if DM channel already exists
  final existingChannels = await supabase
      .from('dm_participants')
      .select('dm_channel_id')
      .eq('user_id', currentUser.id);
  
  for (final channel in existingChannels) {
    final otherParticipant = await supabase
        .from('dm_participants')
        .select('user_id')
        .eq('dm_channel_id', channel['dm_channel_id'])
        .eq('user_id', otherUserId)
        .maybeSingle();
    
    if (otherParticipant != null) {
      return channel['dm_channel_id'] as String;
    }
  }
  
  // Create new DM channel
  final newChannel = await supabase
      .from('dm_channels')
      .insert({})
      .select()
      .single();
  
  // Add participants
  await supabase.from('dm_participants').insert([
    {'dm_channel_id': newChannel['id'], 'user_id': currentUser.id},
    {'dm_channel_id': newChannel['id'], 'user_id': otherUserId},
  ]);
  
  return newChannel['id'] as String;
});

Future<void> sendDmMessage({
  required String dmChannelId,
  required String authorId,
  required String content,
}) async {
  await supabase.from('messages').insert({
    'dm_channel_id': dmChannelId,
    'author_id': authorId,
    'content': content,
  });
}

Future<void> editDmMessage({
  required String messageId,
  required String content,
}) async {
  if (content.trim().isEmpty) {
    throw Exception('Message content cannot be empty');
  }
  
  if (content.length > 2000) {
    throw Exception('Message too long (max 2000 characters)');
  }
  
  try {
    await supabase
        .from('messages')
        .update({
          'content': content.trim(),
          'edited_at': DateTime.now().toIso8601String(),
        })
        .eq('id', messageId);
  } catch (e) {
    throw Exception('Failed to edit message: $e');
  }
}

Future<void> deleteDmMessage(String messageId) async {
  try {
    await supabase
        .from('messages')
        .update({
          'is_deleted': true,
          'deleted_at': DateTime.now().toIso8601String(),
        })
        .eq('id', messageId);
  } catch (e) {
    throw Exception('Failed to delete message: $e');
  }
}

// Function to create a user profile if it doesn't exist
Future<void> ensureUserProfile(String userId, {String? username, String? displayName}) async {
  try {
    // Check if profile exists
    final existing = await supabase
        .from('user_profiles')
        .select('id')
        .eq('id', userId)
        .maybeSingle();
    
    if (existing == null) {
      // Create profile
      await supabase.from('user_profiles').insert({
        'id': userId,
        'username': username ?? 'user_${userId.substring(0, 8)}',
        'display_name': displayName ?? username ?? 'User',
      });
    }
  } catch (e) {
    // Profile might already exist, ignore error
  }
} 