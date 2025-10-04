import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/franchise_providers.dart';
import '../../../../models/franchise.dart';
import '../widgets/franchise_header_nav.dart';

class FranchiseContentPage extends ConsumerWidget {
  final String? franchiseId;
  final String? channelId;
  final String? channelName;

  const FranchiseContentPage({
    Key? key,
    this.franchiseId,
    this.channelId,
    this.channelName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (franchiseId == null) {
      return _buildNoFranchiseSelected(context);
    }

    return Column(
      children: [
        // Franchise header navigation
        FranchiseHeaderNav(
          franchiseId: franchiseId!,
          selectedChannelId: channelId,
        ),
        // Content area
        Expanded(
          child: _buildContentArea(context, ref),
        ),
      ],
    );
  }

  Widget _buildContentArea(BuildContext context, WidgetRef ref) {
    if (channelId == null) {
      return _buildFranchiseOverview(context, ref);
    }

    return _buildChannelContent(context, ref);
  }

  Widget _buildFranchiseOverview(BuildContext context, WidgetRef ref) {
    final franchiseAsync = ref.watch(franchiseProvider(franchiseId!));

    return franchiseAsync.when(
      data: (franchise) {
        if (franchise == null) {
          return _buildErrorState(context, 'Franchise not found');
        }

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Franchise header
              Row(
                children: [
                  Icon(
                    Icons.sports_football,
                    size: 48,
                    color: Colors.orange[600],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SelectableText(
                          franchise.name,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (franchise.externalId != null)
                          SelectableText(
                            'ID: ${franchise.externalId}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              // Franchise metadata
              if (franchise.metadata.isNotEmpty) ...[
                SelectableText(
                  'Franchise Details',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                _buildMetadataCard(franchise.metadata),
                const SizedBox(height: 32),
              ],

              // Quick actions
              SelectableText(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              _buildQuickActions(context),
            ],
          ),
        );
      },
      loading: () => _buildLoadingState(context),
      error: (error, stack) => _buildErrorState(context, 'Error loading franchise: $error'),
    );
  }

  Widget _buildChannelContent(BuildContext context, WidgetRef ref) {
    final channelAsync = ref.watch(franchiseChannelProvider(channelId!));

    return channelAsync.when(
      data: (channel) {
        if (channel == null) {
          return _buildErrorState(context, 'Channel not found');
        }

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Channel header
              Row(
                children: [
                  Icon(
                    _getChannelIcon(channel.type),
                    size: 32,
                    color: _getChannelColor(channel.type),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SelectableText(
                          '#${channel.name}',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SelectableText(
                          '${channel.type.toUpperCase()} Channel',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (channel.isPrivate)
                    Icon(
                      Icons.lock,
                      size: 20,
                      color: Colors.grey[500],
                    ),
                ],
              ),
              const SizedBox(height: 24),

              // Channel content placeholder
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _getChannelIcon(channel.type),
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        SelectableText(
                          'Welcome to #${channel.name}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        SelectableText(
                          'This is a ${channel.type} channel in your franchise.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[500],
                          ),
                        ),
                        if (channel.type == 'voice' || channel.type == 'video') ...[
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              // TODO: Implement voice/video call functionality
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: SelectableText('Voice/Video calls coming soon!'),
                                ),
                              );
                            },
                            icon: Icon(channel.type == 'voice' ? Icons.volume_up : Icons.videocam),
                            label: SelectableText('Join ${channel.type} call'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => _buildLoadingState(context),
      error: (error, stack) => _buildErrorState(context, 'Error loading channel: $error'),
    );
  }

  Widget _buildMetadataCard(Map<String, dynamic> metadata) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: metadata.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  child: SelectableText(
                    '${entry.key}:',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                Expanded(
                  child: SelectableText(
                    entry.value.toString(),
                    style: TextStyle(color: Colors.grey[800]),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        _buildActionButton(
          icon: Icons.add,
          label: 'Create Channel',
          onPressed: () {
            // TODO: Implement create channel functionality
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: SelectableText('Create channel coming soon!')),
            );
          },
        ),
        const SizedBox(width: 12),
        _buildActionButton(
          icon: Icons.settings,
          label: 'Franchise Settings',
          onPressed: () {
            // TODO: Implement franchise settings
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: SelectableText('Franchise settings coming soon!')),
            );
          },
        ),
        const SizedBox(width: 12),
        _buildActionButton(
          icon: Icons.analytics,
          label: 'View Stats',
          onPressed: () {
            // TODO: Implement franchise statistics
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: SelectableText('Franchise stats coming soon!')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: SelectableText(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildNoFranchiseSelected(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sports_football,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          SelectableText(
            'Select a Franchise',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          SelectableText(
            'Choose a franchise from the sidebar to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          SelectableText(
            'Loading...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          SelectableText(
            'Error',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.red[600],
            ),
          ),
          const SizedBox(height: 8),
          SelectableText(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
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