import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/supabase/supabase_init.dart';

// Provider to fetch a single user by ID
final userProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, userId) async {
  try {
    final response = await supabase
        .from('user_profiles')
        .select()
        .eq('id', userId)
        .single();
    return response;
  } catch (e) {
    return null;
  }
});

// Provider to fetch multiple users by IDs
final usersProvider = FutureProvider.family<List<Map<String, dynamic>>, List<String>>((ref, userIds) async {
  if (userIds.isEmpty) return [];
  
  try {
    final response = await supabase
        .from('user_profiles')
        .select()
        .inFilter('id', userIds);
    return List<Map<String, dynamic>>.from(response);
  } catch (e) {
    return [];
  }
});

// Provider to fetch DM channels for current user
final dmChannelsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final currentUser = supabase.auth.currentUser;
  if (currentUser == null) return Stream.value([]);
  
  return supabase
      .from('dm_participants')
      .stream(primaryKey: ['dm_channel_id', 'user_id'])
      .eq('user_id', currentUser.id)
      .map((participants) async {
        final List<Map<String, dynamic>> conversations = [];
        
        for (final participant in participants) {
          final dmChannelId = participant['dm_channel_id'] as String;
          
          try {
            // Get all participants in this DM channel
            final allParticipants = await supabase
                .from('dm_participants')
                .select('user_id')
                .eq('dm_channel_id', dmChannelId);
            
            // Get the other user (not current user)
            String otherUserId = '';
            for (final p in allParticipants) {
              if (p['user_id'] != currentUser.id) {
                otherUserId = p['user_id'] as String;
                break;
              }
            }
            
            // If no other user found, this might be a self-DM
            if (otherUserId.isEmpty) {
              otherUserId = currentUser.id;
            }
            
            // Get the other user's profile
            final otherUserProfile = await supabase
                .from('user_profiles')
                .select()
                .eq('id', otherUserId)
                .maybeSingle();
            
            // Get the latest message
            final latestMessage = await supabase
                .from('messages')
                .select()
                .eq('dm_channel_id', dmChannelId)
                .eq('is_deleted', false)
                .order('created_at', ascending: false)
                .limit(1)
                .maybeSingle();
            
            conversations.add({
              'dm_channel_id': dmChannelId,
              'other_user_id': otherUserId,
              'other_user_profile': otherUserProfile,
              'latest_message': latestMessage,
              'participant_count': allParticipants.length,
            });
          } catch (e) {
            // Skip this conversation if there's an error
            continue;
          }
        }
        
        // Sort by latest message timestamp
        conversations.sort((a, b) {
          final aTime = a['latest_message']?['created_at'] ?? '';
          final bTime = b['latest_message']?['created_at'] ?? '';
          return bTime.compareTo(aTime); // Most recent first
        });
        
        return conversations;
      }).asyncMap((future) => future);
});

// Provider to get all users for creating new conversations
final allUsersProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return supabase
      .from('user_profiles')
      .stream(primaryKey: ['id'])
      .order('display_name');
});

// Provider to create a self-DM for the current user
final selfDmProvider = FutureProvider<String>((ref) async {
  final currentUser = supabase.auth.currentUser;
  if (currentUser == null) throw Exception('User not authenticated');
  
  // Check if self-DM already exists
  final existingSelfDm = await supabase
      .from('dm_participants')
      .select('dm_channel_id')
      .eq('user_id', currentUser.id);
  
  for (final participant in existingSelfDm) {
    final otherParticipants = await supabase
        .from('dm_participants')
        .select('user_id')
        .eq('dm_channel_id', participant['dm_channel_id']);
    
    // If this DM only has the current user, it's a self-DM
    if (otherParticipants.length == 1 && otherParticipants.first['user_id'] == currentUser.id) {
      return participant['dm_channel_id'] as String;
    }
  }
  
  // Create new self-DM
  final newChannel = await supabase
      .from('dm_channels')
      .insert({})
      .select()
      .single();
  
  // Add current user as participant
  await supabase.from('dm_participants').insert({
    'dm_channel_id': newChannel['id'],
    'user_id': currentUser.id,
  });
  
  // Add a welcome message
  await supabase.from('messages').insert({
    'dm_channel_id': newChannel['id'],
    'author_id': currentUser.id,
    'content': 'Welcome to your personal space! You can use this to save notes, reminders, or just chat with yourself.',
  });
  
  return newChannel['id'] as String;
});

// Provider to get DM channel details with participants
final dmChannelDetailsProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, dmChannelId) async {
  try {
    // Get the DM channel
    final channelResponse = await supabase
        .from('dm_channels')
        .select()
        .eq('id', dmChannelId)
        .single();
    
    // Get participants
    final participantsResponse = await supabase
        .from('dm_participants')
        .select('user_id')
        .eq('dm_channel_id', dmChannelId);
    
    return {
      ...channelResponse,
      'participants': participantsResponse,
    };
  } catch (e) {
    return null;
  }
});

// Helper function to get the other user in a DM channel
String getOtherUserId(List<Map<String, dynamic>> participants, String currentUserId) {
  for (final participant in participants) {
    final userId = participant['user_id'] as String;
    if (userId != currentUserId) {
      return userId;
    }
  }
  return '';
} 