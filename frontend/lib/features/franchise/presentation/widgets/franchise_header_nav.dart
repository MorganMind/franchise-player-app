import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/franchise_providers.dart';
import '../../../../models/franchise.dart';

class FranchiseHeaderNav extends ConsumerWidget {
  final String franchiseId;
  final String? selectedChannelId;

  const FranchiseHeaderNav({
    Key? key,
    required this.franchiseId,
    this.selectedChannelId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final franchiseAsync = ref.watch(franchiseProvider(franchiseId));
    final channelAsync = selectedChannelId != null 
        ? ref.watch(franchiseChannelProvider(selectedChannelId!))
        : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.red, width: 2),
      ),
      child: Row(
        children: [
          // Franchise icon and name
          franchiseAsync.when(
            data: (franchise) {
              if (franchise == null) {
                return _buildLoadingFranchiseInfo();
              }
              return _buildFranchiseInfo(franchise);
            },
            loading: () => _buildLoadingFranchiseInfo(),
            error: (error, stack) => _buildErrorFranchiseInfo(),
          ),
          
          // Separator
          Container(
            width: 1,
            height: 24,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: Colors.grey[300],
          ),
          
          // Channel info (if a channel is selected)
          if (selectedChannelId != null) ...[
            Expanded(
              child: channelAsync!.when(
                data: (channel) {
                  if (channel == null) {
                    return _buildLoadingChannelInfo();
                  }
                  return _buildChannelInfo(channel);
                },
                loading: () => _buildLoadingChannelInfo(),
                error: (error, stack) => _buildErrorChannelInfo(),
              ),
            ),
          ] else ...[
            Expanded(
              child: _buildNoChannelSelected(),
            ),
          ],
          
          // Action buttons
          _buildActionButtons(context, ref),
        ],
      ),
    );
  }

  Widget _buildFranchiseInfo(Franchise franchise) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.orange[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.sports_football,
            size: 20,
            color: Colors.orange[600],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SelectableText(
              franchise.name,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Colors.grey[800],
              ),
            ),
            if (franchise.externalId != null)
              SelectableText(
                'ID: ${franchise.externalId}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoadingFranchiseInfo() {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.sports_football,
            size: 20,
            color: Colors.grey[400],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 80,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorFranchiseInfo() {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.red[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.error_outline,
            size: 20,
            color: Colors.red[400],
          ),
        ),
        const SizedBox(width: 12),
        SelectableText(
          'Error loading franchise',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: Colors.red[600],
          ),
        ),
      ],
    );
  }

  Widget _buildChannelInfo(FranchiseChannel channel) {
    return Row(
      children: [
        Icon(
          _getChannelIcon(channel.type),
          size: 20,
          color: _getChannelColor(channel.type),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  SelectableText(
                    '#${channel.name}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.grey[800],
                    ),
                  ),
                  if (channel.isPrivate) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.lock,
                      size: 14,
                      color: Colors.grey[500],
                    ),
                  ],
                ],
              ),
              SelectableText(
                '${channel.type.toUpperCase()} Channel',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingChannelInfo() {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 80,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorChannelInfo() {
    return Row(
      children: [
        Icon(
          Icons.error_outline,
          size: 20,
          color: Colors.red[400],
        ),
        const SizedBox(width: 8),
        SelectableText(
          'Error loading channel',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: Colors.red[600],
          ),
        ),
      ],
    );
  }

  Widget _buildNoChannelSelected() {
    return Row(
      children: [
        Icon(
          Icons.dashboard,
          size: 20,
          color: Colors.grey[400],
        ),
        const SizedBox(width: 8),
        SelectableText(
          'Franchise Overview',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        // Search button
        IconButton(
          onPressed: () {
            // TODO: Implement franchise search
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: SelectableText('Franchise search coming soon!')),
            );
          },
          icon: const Icon(Icons.search, size: 20),
          tooltip: 'Search franchise',
        ),
        
        // Notifications button
        IconButton(
          onPressed: () {
            // TODO: Implement franchise notifications
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: SelectableText('Franchise notifications coming soon!')),
            );
          },
          icon: const Icon(Icons.notifications_outlined, size: 20),
          tooltip: 'Franchise notifications',
        ),
        
        // Settings button
        IconButton(
          onPressed: () {
            // TODO: Implement franchise settings
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: SelectableText('Franchise settings coming soon!')),
            );
          },
          icon: const Icon(Icons.settings_outlined, size: 20),
          tooltip: 'Franchise settings',
        ),
      ],
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

  Color _getChannelColor(String type) {
    switch (type) {
      case 'text':
        return Colors.grey[600]!;
      case 'voice':
        return Colors.green[600]!;
      case 'video':
        return Colors.purple[600]!;
      default:
        return Colors.grey[600]!;
    }
  }
} 