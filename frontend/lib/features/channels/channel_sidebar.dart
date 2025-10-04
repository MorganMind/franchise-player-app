import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../supabase_client.dart';
import 'create_channel_dialog.dart';
import 'create_voice_channel_dialog.dart';

final allChannelsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, serverId) async {
  final response = await supabase
      .from('channels')
      .select()
      .eq('server_id', serverId)
      .order('name');
  return List<Map<String, dynamic>>.from(response);
});

class ChannelSidebar extends ConsumerWidget {
  final String serverId;
  final Function(String channelId, String channelName, String? channelType) onChannelSelected;
  final String? selectedChannelId;

  const ChannelSidebar({
    Key? key,
    required this.serverId,
    required this.onChannelSelected,
    this.selectedChannelId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channelsAsync = ref.watch(allChannelsProvider(serverId));
    
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.tag, color: Colors.black),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: SelectableText(
                      'Channels',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  // Create buttons (admin only)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Create text channel button
                      IconButton(
                        onPressed: () => _showCreateChannelDialog(context, ref),
                        icon: const Icon(Icons.chat, size: 18),
                        tooltip: 'Create Text Channel',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      // Create voice channel button
                      IconButton(
                        onPressed: () => _showCreateVoiceChannelDialog(context, ref),
                        icon: const Icon(Icons.headphones, size: 18),
                        tooltip: 'Create Voice Channel',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Text Channels Section
                    _buildSectionHeader('Text Channels'),
                    channelsAsync.when(
                      data: (channels) => _buildChannelsList(context, channels.where((c) => c['type'] == 'text' || c['type'] == null).toList()),
                      loading: () => _buildLoadingIndicator(),
                      error: (e, _) => _buildErrorWidget('Error loading channels: $e'),
                    ),
                    
                    // Voice Channels Section
                    _buildSectionHeader('Voice Channels'),
                    channelsAsync.when(
                      data: (channels) => _buildChannelsList(
                        context,
                        channels.where((c) => c['type'] == 'voice').toList(),
                      ),
                      loading: () => _buildLoadingIndicator(),
                      error: (e, _) => _buildErrorWidget('Error loading channels: $e'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: SelectableText(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildChannelsList(BuildContext context, List<Map<String, dynamic>> channels) {
    if (channels.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SelectableText(
          'No channels available',
          style: TextStyle(color: Colors.grey[500], fontSize: 12),
        ),
      );
    }

    return Column(
      children: channels.map((channel) {
        return _buildChannelTile(context, channel);
      }).toList(),
    );
  }

  Widget _buildChannelTile(BuildContext context, Map<String, dynamic> channel) {
    final isSelected = selectedChannelId == channel['id'];
    final channelType = channel['type'] ?? 'text';
    final isVoiceChannel = channelType == 'voice';
    
    return ListTile(
      leading: Icon(
        isVoiceChannel ? Icons.headphones : Icons.tag,
        size: 20,
        color: isVoiceChannel ? Colors.green[600] : Colors.grey[600],
      ),
      title: SelectableText(
        '${isVoiceChannel ? '' : '#'}${channel['name']}',
        style: TextStyle(
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? Colors.blue[700] : Colors.grey[800],
        ),
      ),
      subtitle: SelectableText(
        channel['description'] ?? (isVoiceChannel ? 'Voice channel' : 'No description'),
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        maxLines: 1,
      ),
      onTap: () async {
        final userId = supabase.auth.currentUser?.id;
        if (userId == null) return;
        
        // Check if user is a member of the server
        final member = await supabase
            .from('server_members')
            .select()
            .filter('user_id', 'eq', userId)
            .filter('server_id', 'eq', channel['server_id'])
            .maybeSingle();
            
        if (member == null) {
          final joined = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const SelectableText('Join Channel?'),
              content: const SelectableText(
                'You are not a member of this channel\'s server. Would you like to join?'
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const SelectableText('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      await supabase.from('server_members').insert({
                        'server_id': channel['server_id'],
                        'user_id': userId,
                      });
                      Navigator.pop(context, true);
                    } catch (e) {
                      Navigator.pop(context, false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: SelectableText('Failed to join server: $e')),
                      );
                    }
                  },
                  child: const SelectableText('Join'),
                ),
              ],
            ),
          );
          
          if (joined != true) return;
        }
        
        onChannelSelected(
          channel['id'],
          channel['name'],
          channelType,
        );
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 16,
        width: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SelectableText(
        message,
        style: TextStyle(
          color: Colors.red[600],
          fontSize: 12,
        ),
      ),
    );
  }

  void _showCreateChannelDialog(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => CreateChannelDialog(serverId: serverId),
    );
    
    if (result == true) {
      // Refresh the channels list by invalidating the provider
      ref.invalidate(allChannelsProvider(serverId));
    }
  }

  void _showCreateVoiceChannelDialog(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => CreateVoiceChannelDialog(serverId: serverId),
    );
    
    if (result == true) {
      // Refresh the channels list by invalidating the provider
      ref.invalidate(allChannelsProvider(serverId));
    }
  }
} 