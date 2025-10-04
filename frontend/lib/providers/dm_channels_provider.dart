import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/supabase/supabase_init.dart';

final dmChannelsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final currentUser = supabase.auth.currentUser;
  if (currentUser == null) return [];

  try {
    // Get DM channels where the current user is a participant
    final response = await supabase
        .from('dm_participants')
        .select('dm_channel_id')
        .eq('user_id', currentUser.id);

    if (response.isEmpty) return [];

    final dmChannelIds = response.map((r) => r['dm_channel_id'] as String).toList();

    // Get DM channel details with participant info
    final dmChannels = <Map<String, dynamic>>[];
    
    for (final dmChannelId in dmChannelIds) {
      // Get participants for this DM channel
      final participants = await supabase
          .from('dm_participants')
          .select('user_id')
          .eq('dm_channel_id', dmChannelId);

      final participantIds = participants.map((p) => p['user_id'] as String).toList();
      
      // Get the other user's info (not the current user)
      final otherUserId = participantIds.firstWhere(
        (id) => id != currentUser.id,
        orElse: () => currentUser.id, // Fallback to self-DM
      );

      // Get user profile
      final userProfile = await supabase
          .from('user_profiles')
          .select()
          .eq('id', otherUserId)
          .maybeSingle();

      // Get last message
      final lastMessage = await supabase
          .from('messages')
          .select('content, created_at')
          .eq('dm_channel_id', dmChannelId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      dmChannels.add({
        'dm_channel_id': dmChannelId,
        'display_name': userProfile?['display_name'] ?? userProfile?['username'] ?? 'Unknown User',
        'username': userProfile?['username'] ?? 'unknown',
        'avatar_url': userProfile?['avatar_url'],
        'last_message': lastMessage?['content'] ?? 'No messages yet',
        'last_message_time': lastMessage?['created_at'],
      });
    }

    // Sort by last message time
    dmChannels.sort((a, b) {
      final aTime = a['last_message_time'];
      final bTime = b['last_message_time'];
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return DateTime.parse(bTime).compareTo(DateTime.parse(aTime));
    });

    return dmChannels;
  } catch (e) {
    print('Error fetching DM channels: $e');
    return [];
  }
}); 