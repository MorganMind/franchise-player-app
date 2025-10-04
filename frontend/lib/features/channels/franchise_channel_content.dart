import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/franchise_providers.dart';
import '../../providers/channel_messages_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/message.dart';
import '../../models/franchise.dart';
import '../../core/supabase/supabase_init.dart';
import '../channels/channel_content_page.dart';

class FranchiseChannelContent extends ConsumerWidget {
  final String franchiseId;
  final String channelId;

  const FranchiseChannelContent({
    Key? key,
    required this.franchiseId,
    required this.channelId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get franchise channel info
    final channelAsync = ref.watch(franchiseChannelProvider(channelId));
    
    return channelAsync.when(
      data: (channel) {
        if (channel == null) {
          return const Center(child: Text('Channel not found'));
        }
        
        // Check if this is a voice/video channel
        if (channel.type == 'voice' || channel.type == 'video') {
          return _buildVoiceVideoChannel(context, channel);
        }
        
        // Text channel - use the existing channel content page
        return ChannelContentPage(
          channelId: channelId,
          channelName: channel.name,
          channelType: channel.type,
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error loading channel: $error')),
    );
  }

  Widget _buildVoiceVideoChannel(BuildContext context, FranchiseChannel channel) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              channel.type == 'voice' ? Icons.volume_up : Icons.videocam,
              size: 20,
              color: channel.type == 'voice' ? Colors.green[600] : Colors.purple[600],
            ),
            const SizedBox(width: 8),
            Text(
              channel.name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              channel.type == 'voice' ? Icons.volume_up : Icons.videocam,
              size: 64,
              color: channel.type == 'voice' ? Colors.green[400] : Colors.purple[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Welcome to ${channel.name}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This is a ${channel.type} channel in your franchise.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Implement voice/video call functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${channel.type.toUpperCase()} calls coming soon!'),
                  ),
                );
              },
              icon: Icon(channel.type == 'voice' ? Icons.volume_up : Icons.videocam),
              label: Text('Join ${channel.type} call'),
            ),
          ],
        ),
      ),
    );
  }
}
