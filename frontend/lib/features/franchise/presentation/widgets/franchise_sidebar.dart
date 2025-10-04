import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/franchise_providers.dart';
import '../../../../models/franchise.dart';

class FranchiseSidebar extends ConsumerWidget {
  final String serverId;
  final Function(String franchiseId) onFranchiseSelected;
  final Function(String franchiseId, String channelId, String channelName) onFranchiseChannelSelected;
  final String? selectedFranchiseId;
  final String? selectedChannelId;

  const FranchiseSidebar({
    Key? key,
    required this.serverId,
    required this.onFranchiseSelected,
    required this.onFranchiseChannelSelected,
    this.selectedFranchiseId,
    this.selectedChannelId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final franchisesAsync = ref.watch(safeFranchisesProvider(serverId));
    
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
                  Icon(Icons.sports_football, color: Colors.orange[700]),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: SelectableText(
                      'Franchises',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, size: 20),
                    onPressed: () => _showCreateOptionsDialog(context, ref),
                    tooltip: 'Create Franchise, Category, or Channel',
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
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
                    franchisesAsync.when(
                      data: (franchises) => _buildFranchisesList(context, ref, franchises),
                      loading: () => _buildLoadingIndicator(),
                      error: (e, _) => _buildErrorWidget('Error loading franchises: $e'),
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

  Widget _buildFranchisesList(BuildContext context, WidgetRef ref, List<Franchise> franchises) {
    if (franchises.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: SelectableText(
          'No franchises available',
          style: TextStyle(color: Colors.grey[500], fontSize: 12),
        ),
      );
    }

    return Column(
      children: franchises.map((franchise) {
        return _buildFranchiseSection(context, ref, franchise);
      }).toList(),
    );
  }

  Widget _buildFranchiseSection(BuildContext context, WidgetRef ref, Franchise franchise) {
    final isSelected = selectedFranchiseId == franchise.id;
    final isExpanded = isSelected || selectedChannelId != null;
    
    return ExpansionTile(
      leading: Icon(
        Icons.sports_football,
        color: isSelected ? Colors.orange[700] : Colors.grey[600],
        size: 20,
      ),
      title: SelectableText(
        franchise.name,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? Colors.orange[700] : Colors.grey[800],
        ),
      ),
      initiallyExpanded: isExpanded,
      onExpansionChanged: (expanded) {
        if (expanded) {
          onFranchiseSelected(franchise.id);
        }
      },
      children: [
        _buildFranchiseChannels(context, ref, franchise.id),
      ],
    );
  }

  Widget _buildFranchiseChannels(BuildContext context, WidgetRef ref, String franchiseId) {
    final channelsAsync = ref.watch(franchiseChannelsProvider(franchiseId));
    
    return channelsAsync.when(
      data: (channels) => _buildChannelsList(context, channels),
      loading: () => _buildLoadingIndicator(),
      error: (e, _) => _buildErrorWidget('Error loading channels: $e'),
    );
  }

  Widget _buildChannelsList(BuildContext context, List<FranchiseChannel> channels) {
    if (channels.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(32, 8, 16, 8),
        child: SelectableText(
          'No channels',
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

  Widget _buildChannelTile(BuildContext context, FranchiseChannel channel) {
    final isSelected = selectedChannelId == channel.id;
    final icon = _getChannelIcon(channel.type);
    
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: ListTile(
        leading: Icon(
          icon,
          size: 16,
          color: isSelected ? Colors.blue[700] : Colors.grey[600],
        ),
        title: SelectableText(
          channel.name,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? Colors.blue[700] : Colors.grey[800],
          ),
        ),
        onTap: () {
          onFranchiseChannelSelected(channel.franchiseId, channel.id, channel.name);
        },
      ),
    );
  }

  IconData _getChannelIcon(String channelType) {
    switch (channelType.toLowerCase()) {
      case 'text':
        return Icons.chat;
      case 'voice':
        return Icons.mic;
      case 'video':
        return Icons.videocam;
      default:
        return Icons.tag;
    }
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(
        child: SizedBox(
          height: 16,
          width: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SelectableText(
        message,
        style: TextStyle(
          fontSize: 12,
          color: Colors.red[500],
        ),
      ),
    );
  }

  void _showCreateOptionsDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.sports_football),
              title: const Text('Franchise'),
              subtitle: const Text('Create a new franchise'),
              onTap: () {
                Navigator.of(context).pop();
                _showCreateFranchiseDialog(context, ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder),
              title: const Text('Category'),
              subtitle: const Text('Create a new category'),
              onTap: () {
                Navigator.of(context).pop();
                _showCreateCategoryDialog(context, ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.tag),
              title: const Text('Channel'),
              subtitle: const Text('Create a new channel'),
              onTap: () {
                Navigator.of(context).pop();
                _showCreateChannelDialog(context, ref);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showCreateFranchiseDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Franchise'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Franchise Name',
                hintText: 'Enter franchise name',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                try {
                  await FranchiseRepository.createFranchise(
                    serverId: serverId,
                    name: nameController.text.trim(),
                  );
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Franchise created successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error creating franchise: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showCreateCategoryDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _CreateCategoryDialog(serverId: serverId),
    );
  }

  void _showCreateChannelDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _CreateChannelDialog(serverId: serverId),
    );
  }
}

class _CreateCategoryDialog extends ConsumerStatefulWidget {
  final String serverId;

  const _CreateCategoryDialog({required this.serverId});

  @override
  ConsumerState<_CreateCategoryDialog> createState() => _CreateCategoryDialogState();
}

class _CreateCategoryDialogState extends ConsumerState<_CreateCategoryDialog> {
  final nameController = TextEditingController();
  String? selectedFranchiseId;

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final franchisesAsync = ref.watch(safeFranchisesProvider(widget.serverId));

    return AlertDialog(
      title: const Text('Create Category'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Category Name',
              hintText: 'Enter category name',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          const SizedBox(height: 16),
          franchisesAsync.when(
            data: (franchises) {
              if (franchises.isEmpty) {
                return const Text(
                  'No franchises available. Create a franchise first.',
                  style: TextStyle(color: Colors.red),
                );
              }
              return DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Select Franchise',
                  border: OutlineInputBorder(),
                ),
                value: selectedFranchiseId,
                items: franchises.map((franchise) {
                  return DropdownMenuItem(
                    value: franchise.id,
                    child: Text(franchise.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedFranchiseId = value;
                  });
                },
              );
            },
            loading: () => const CircularProgressIndicator(),
            error: (error, stack) => Text('Error: $error'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (nameController.text.trim().isNotEmpty && selectedFranchiseId != null) {
              try {
                // Create a category channel (categories are implemented as channels with type 'category')
                await FranchiseRepository.createFranchiseChannel(
                  franchiseId: selectedFranchiseId!,
                  name: nameController.text.trim(),
                  type: 'category',
                );
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Category created successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error creating category: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}

class _CreateChannelDialog extends ConsumerStatefulWidget {
  final String serverId;

  const _CreateChannelDialog({required this.serverId});

  @override
  ConsumerState<_CreateChannelDialog> createState() => _CreateChannelDialogState();
}

class _CreateChannelDialogState extends ConsumerState<_CreateChannelDialog> {
  final nameController = TextEditingController();
  String? selectedFranchiseId;
  String selectedChannelType = 'text';

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final franchisesAsync = ref.watch(safeFranchisesProvider(widget.serverId));

    return AlertDialog(
      title: const Text('Create Channel'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Channel Name',
              hintText: 'Enter channel name',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          const SizedBox(height: 16),
          franchisesAsync.when(
            data: (franchises) {
              if (franchises.isEmpty) {
                return const Text(
                  'No franchises available. Create a franchise first.',
                  style: TextStyle(color: Colors.red),
                );
              }
              return DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Select Franchise',
                  border: OutlineInputBorder(),
                ),
                value: selectedFranchiseId,
                items: franchises.map((franchise) {
                  return DropdownMenuItem(
                    value: franchise.id,
                    child: Text(franchise.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedFranchiseId = value;
                  });
                },
              );
            },
            loading: () => const CircularProgressIndicator(),
            error: (error, stack) => Text('Error: $error'),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Channel Type',
              border: OutlineInputBorder(),
            ),
            value: selectedChannelType,
            items: const [
              DropdownMenuItem(value: 'text', child: Text('Text Channel')),
              DropdownMenuItem(value: 'voice', child: Text('Voice Channel')),
              DropdownMenuItem(value: 'video', child: Text('Video Channel')),
            ],
            onChanged: (value) {
              setState(() {
                selectedChannelType = value!;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (nameController.text.trim().isNotEmpty && selectedFranchiseId != null) {
              try {
                await FranchiseRepository.createFranchiseChannel(
                  franchiseId: selectedFranchiseId!,
                  name: nameController.text.trim(),
                  type: selectedChannelType,
                );
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Channel created successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error creating channel: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
} 