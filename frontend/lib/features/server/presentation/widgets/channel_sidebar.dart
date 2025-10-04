import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/franchise_providers.dart';
import '../../../../models/franchise.dart';
import '../../../../core/supabase/supabase_init.dart';

class ChannelSidebar extends ConsumerStatefulWidget {
  final String serverId;
  final String? currentFranchiseId;
  final String? currentChannelId;
  final String? currentSubcategoryId;
  final void Function(String? franchiseId, String? channelId, String? subcategoryId)? onSelect;

  const ChannelSidebar({
    Key? key,
    required this.serverId,
    this.currentFranchiseId,
    this.currentChannelId,
    this.currentSubcategoryId,
    this.onSelect,
  }) : super(key: key);

  @override
  ConsumerState<ChannelSidebar> createState() => _ChannelSidebarState();
}

class _ChannelSidebarState extends ConsumerState<ChannelSidebar> {
  String? expandedFranchiseId;
  String? expandedChannelId;

  @override
  Widget build(BuildContext context) {
    // Get real server channels
    final serverChannelsAsync = ref.watch(serverChannelsProvider(widget.serverId));
    
    // Get real franchises
    final franchisesAsync = ref.watch(franchisesProvider(widget.serverId));

    return Container(
      width: 240,
      color: const Color(0xFFF2F3F5),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // Server Text Channels Section
          _buildSectionHeader('TEXT CHANNELS'),
          serverChannelsAsync.when(
            data: (channels) => Column(
              children: channels
                  .where((channel) => channel['type'] == 'text')
                  .map((channel) => _buildTextChannel(channel))
                  .toList(),
            ),
            loading: () => const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stack) => Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Error loading channels: $error'),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Franchises Section
          _buildSectionHeader('FRANCHISES'),
          franchisesAsync.when(
            data: (franchises) => Column(
              children: franchises.map((franchise) => _buildFranchise(franchise)).toList(),
            ),
            loading: () => const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stack) => Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Error loading franchises: $error'),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Special Navigation Tabs (only show if a franchise is selected)
          if (widget.currentFranchiseId != null) ...[
            _buildSectionHeader('NAVIGATION'),
            _buildSpecialNavTab('players', 'Players', Icons.people),
            _buildSpecialNavTab('teams', 'Teams', Icons.groups),
            _buildSpecialNavTab('games', 'Games', Icons.sports),
            _buildSpecialNavTab('standings', 'Standings', Icons.leaderboard),
            _buildSpecialNavTab('statistics', 'Statistics', Icons.bar_chart),
            _buildSpecialNavTab('trades', 'Trades', Icons.swap_horiz),
            _buildSpecialNavTab('awards', 'Awards', Icons.emoji_events),
            _buildSpecialNavTab('news', 'News', Icons.newspaper),
            _buildSpecialNavTab('rules', 'Rules', Icons.rule),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF6C757D),
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildTextChannel(Map<String, dynamic> channel) {
    final isActive = widget.currentFranchiseId == null && widget.currentChannelId == channel['id'];
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: () {
          if (widget.onSelect != null) {
            widget.onSelect!(null, channel['id'], null);
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFE9ECEF) : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              const Icon(Icons.tag, color: Color(0xFF6C757D), size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  channel['name'],
                  style: TextStyle(
                    color: isActive ? Colors.black : const Color(0xFF6C757D),
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFranchise(Franchise franchise) {
    final isExpanded = expandedFranchiseId == franchise.id;
    final isActive = widget.currentFranchiseId == franchise.id;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(4),
            onTap: () {
              setState(() {
                expandedFranchiseId = isExpanded ? null : franchise.id;
                expandedChannelId = null;
              });
              if (widget.onSelect != null) {
                widget.onSelect!(franchise.id, null, null);
              }
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFFE9ECEF) : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  const Icon(Icons.sports_football, color: Color(0xFF6C757D), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      franchise.name,
                      style: TextStyle(
                        color: isActive ? Colors.black : const Color(0xFF6C757D),
                        fontSize: 14,
                        fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
                      ),
                    ),
                  ),
                  Icon(isExpanded ? Icons.expand_less : Icons.expand_more, color: const Color(0xFF6C757D), size: 18),
                ],
              ),
            ),
          ),
        ),
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 20.0),
            child: _buildFranchiseChannels(franchise.id),
          ),
      ],
    );
  }

  Widget _buildFranchiseChannels(String franchiseId) {
    final channelsAsync = ref.watch(franchiseChannelsProvider(franchiseId));
    
    return channelsAsync.when(
      data: (channels) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: channels.map((channel) => _buildFranchiseChannel(franchiseId, channel)).toList(),
      ),
      loading: () => const Padding(
        padding: EdgeInsets.all(8.0),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text('Error loading channels: $error'),
      ),
    );
  }

  Widget _buildFranchiseChannel(String franchiseId, FranchiseChannel channel) {
    final isActive = widget.currentFranchiseId == franchiseId && widget.currentChannelId == channel.id;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: () {
          if (widget.onSelect != null) {
            widget.onSelect!(franchiseId, channel.id, null);
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFD1E7DD) : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Icon(
                _getChannelIcon(channel.type),
                color: const Color(0xFF6C757D),
                size: 15,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  channel.name,
                  style: TextStyle(
                    color: isActive ? Colors.black : const Color(0xFF6C757D),
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
                  ),
                ),
              ),
              if (channel.isPrivate)
                const Icon(Icons.lock, color: Color(0xFF6C757D), size: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialNavTab(String id, String name, IconData icon) {
    final isActive = widget.currentSubcategoryId == id;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: () {
          if (widget.onSelect != null) {
            widget.onSelect!(null, null, id);
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFE9ECEF) : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF6C757D), size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    color: isActive ? Colors.black : const Color(0xFF6C757D),
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getChannelIcon(String type) {
    switch (type) {
      case 'text':
        return Icons.tag;
      case 'voice':
        return Icons.volume_up;
      case 'video':
        return Icons.videocam;
      default:
        return Icons.tag;
    }
  }
}

// Provider for server channels
final serverChannelsProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, serverId) {
  return supabase
      .from('channels')
      .stream(primaryKey: ['id'])
      .eq('server_id', serverId)
      .order('name')
      .map((event) => event.map((json) => Map<String, dynamic>.from(json)).toList());
}); 