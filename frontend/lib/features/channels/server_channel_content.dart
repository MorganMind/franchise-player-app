import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/channel_messages_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/message.dart';
import '../../core/supabase/supabase_init.dart';
import '../channels/channel_content_page.dart';

class ServerChannelContent extends ConsumerWidget {
  final String channelId;

  const ServerChannelContent({
    Key? key,
    required this.channelId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get channel info
    final channelAsync = ref.watch(serverChannelProvider(channelId));
    
    return channelAsync.when(
      data: (channel) {
        if (channel == null) {
          return const Center(child: Text('Channel not found'));
        }
        
        return ChannelContentPage(
          channelId: channelId,
          channelName: channel['name'] ?? 'Unknown Channel',
          channelType: channel['type'] ?? 'text',
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error loading channel: $error')),
    );
  }
}

// Provider for server channel info
final serverChannelProvider = StreamProvider.family<Map<String, dynamic>?, String>((ref, channelId) {
  return supabase
      .from('channels')
      .stream(primaryKey: ['id'])
      .eq('id', channelId)
      .limit(1)
      .map((event) {
        if (event.isEmpty) return null;
        return Map<String, dynamic>.from(event.first);
      });
});


