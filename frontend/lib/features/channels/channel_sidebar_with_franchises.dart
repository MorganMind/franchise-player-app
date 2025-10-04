import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../franchise/presentation/widgets/franchise_sidebar.dart';
import '../../supabase_client.dart';

final allChannelsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final response = await supabase.from('channels').select();
  return List<Map<String, dynamic>>.from(response);
});

class ChannelSidebarWithFranchises extends ConsumerWidget {
  final String serverId;
  final Function(String channelId, String channelName) onChannelSelected;
  final Function(String franchiseId) onFranchiseSelected;
  final Function(String franchiseId, String channelId, String channelName) onFranchiseChannelSelected;
  final String? selectedChannelId;
  final String? selectedFranchiseId;
  final String? selectedFranchiseChannelId;

  const ChannelSidebarWithFranchises({
    Key? key,
    required this.serverId,
    required this.onChannelSelected,
    required this.onFranchiseSelected,
    required this.onFranchiseChannelSelected,
    this.selectedChannelId,
    this.selectedFranchiseId,
    this.selectedFranchiseChannelId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channelsAsync = ref.watch(allChannelsProvider);
    
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
                  Icon(Icons.discord, color: Colors.indigo[600]),
                  const SizedBox(width: 8),
                  const SelectableText(
                    'Server Channels',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
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
                    // Franchises Section
                    _buildSectionHeader('Franchises', Icons.sports_football, Colors.orange[700]!),
                    _buildFranchisesSection(context, ref),
                    
                    const SizedBox(height: 16),
                    
                    // Regular Channels Section
                    _buildSectionHeader('Text Channels', Icons.tag, Colors.grey[600]!),
                    _buildChannelsSection(context, ref, channelsAsync),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          SelectableText(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: Colors.grey[600],
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFranchisesSection(BuildContext context, WidgetRef ref) {
    return FranchiseSidebar(
      serverId: serverId,
      onFranchiseSelected: onFranchiseSelected,
      onFranchiseChannelSelected: onFranchiseChannelSelected,
      selectedFranchiseId: selectedFranchiseId,
      selectedChannelId: selectedFranchiseChannelId,
    );
  }

  Widget _buildChannelsSection(BuildContext context, WidgetRef ref, AsyncValue<List<Map<String, dynamic>>> channelsAsync) {
    return channelsAsync.when(
      data: (channels) => _buildChannelsList(context, channels),
      loading: () => _buildLoadingIndicator(),
      error: (e, _) => _buildErrorWidget('Error loading channels: $e'),
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
    
    return ListTile(
      leading: Icon(
        Icons.tag,
        size: 20,
        color: Colors.grey[600],
      ),
      title: SelectableText(
        '#${channel['name']}',
        style: TextStyle(
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? Colors.blue[700] : Colors.grey[800],
        ),
      ),
      subtitle: SelectableText(
        channel['description'] ?? 'No description',
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
            .eq('user_id', userId)
            .eq('server_id', channel['server_id'])
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
        
        onChannelSelected(channel['id'], channel['name']);
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
          fontSize: 12,
          color: Colors.red[500],
        ),
      ),
    );
  }
} 