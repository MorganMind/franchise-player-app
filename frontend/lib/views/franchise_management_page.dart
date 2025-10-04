import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/franchise.dart';
import '../providers/franchise_providers.dart';
import '../features/server/data/server_providers.dart';

class FranchiseManagementPage extends ConsumerStatefulWidget {
  const FranchiseManagementPage({super.key});

  @override
  ConsumerState<FranchiseManagementPage> createState() => _FranchiseManagementPageState();
}

class _FranchiseManagementPageState extends ConsumerState<FranchiseManagementPage> {
  final _formKey = GlobalKey<FormState>();
  final _franchiseNameController = TextEditingController();
  final _channelNameController = TextEditingController();
  String _selectedChannelType = 'text';
  bool _isLoading = false;

  @override
  void dispose() {
    _franchiseNameController.dispose();
    _channelNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentServerId = ref.watch(currentServerIdProvider);
    final franchisesAsync = ref.watch(franchisesProvider(currentServerId ?? ''));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Franchise Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: currentServerId == null ? null : () => _showAddFranchiseDialog(context),
            tooltip: currentServerId == null ? 'Select a server first' : 'Add New Franchise',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Franchises',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: currentServerId == null
                  ? const Center(
                      child: Text('Please select a server first to manage franchises.'),
                    )
                  : franchisesAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (error, stack) => Center(
                        child: Text('Error: $error'),
                      ),
                      data: (franchises) => franchises.isEmpty
                          ? const Center(
                              child: Text('No franchises found. Create your first franchise!'),
                            )
                          : ListView.builder(
                              itemCount: franchises.length,
                              itemBuilder: (context, index) {
                                final franchise = franchises[index];
                                return _buildFranchiseCard(franchise);
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFranchiseCard(Franchise franchise) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Row(
          children: [
            Expanded(
              child: Text(
                franchise.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showEditFranchiseDialog(context, franchise),
              tooltip: 'Edit Franchise',
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showAddChannelDialog(context, franchise.id),
              tooltip: 'Add Channel',
            ),
          ],
        ),
        subtitle: Text('ID: ${franchise.id}'),
        children: [
          _buildFranchiseChannels(franchise.id),
        ],
      ),
    );
  }

  Widget _buildFranchiseChannels(String franchiseId) {
    final channelsAsync = ref.watch(franchiseChannelsProvider(franchiseId));

    return channelsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text('Error loading channels: $error'),
      ),
      data: (channels) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Channels (${channels.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add Channel'),
                  onPressed: () => _showAddChannelDialog(context, franchiseId),
                ),
              ],
            ),
          ),
          if (channels.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No channels yet. Add your first channel!'),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: channels.length,
              itemBuilder: (context, index) {
                final channel = channels[index];
                return _buildChannelTile(channel);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildChannelTile(FranchiseChannel channel) {
    return ListTile(
      leading: Icon(
        _getChannelTypeIcon(channel.type),
        color: _getChannelTypeColor(channel.type),
      ),
      title: Text(channel.name),
      subtitle: Text('Type: ${channel.type} • Position: ${channel.position}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (channel.voiceEnabled)
            const Icon(Icons.mic, size: 16, color: Colors.green),
          if (channel.videoEnabled)
            const Icon(Icons.videocam, size: 16, color: Colors.blue),
          if (channel.isPrivate)
            const Icon(Icons.lock, size: 16, color: Colors.orange),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditChannelDialog(context, channel),
            tooltip: 'Edit Channel',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _showDeleteChannelDialog(context, channel),
            tooltip: 'Delete Channel',
          ),
        ],
      ),
    );
  }

  IconData _getChannelTypeIcon(String type) {
    switch (type) {
      case 'text':
        return Icons.chat_bubble;
      case 'voice':
        return Icons.mic;
      case 'video':
        return Icons.videocam;
      default:
        return Icons.chat_bubble;
    }
  }

  Color _getChannelTypeColor(String type) {
    switch (type) {
      case 'text':
        return Colors.grey;
      case 'voice':
        return Colors.green;
      case 'video':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  void _showAddFranchiseDialog(BuildContext context) {
    _franchiseNameController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Franchise'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _franchiseNameController,
                decoration: const InputDecoration(
                  labelText: 'Franchise Name',
                  hintText: 'Enter franchise name',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a franchise name';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : () => _addFranchise(context),
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditFranchiseDialog(BuildContext context, Franchise franchise) {
    _franchiseNameController.text = franchise.name;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Franchise'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _franchiseNameController,
                decoration: const InputDecoration(
                  labelText: 'Franchise Name',
                  hintText: 'Enter franchise name',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a franchise name';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : () => _updateFranchise(context, franchise.id),
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showAddChannelDialog(BuildContext context, String franchiseId) {
    _channelNameController.clear();
    _selectedChannelType = 'text';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Channel'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _channelNameController,
                decoration: const InputDecoration(
                  labelText: 'Channel Name',
                  hintText: 'Enter channel name',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a channel name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedChannelType,
                decoration: const InputDecoration(
                  labelText: 'Channel Type',
                ),
                items: const [
                  DropdownMenuItem(value: 'text', child: Text('Text')),
                  DropdownMenuItem(value: 'voice', child: Text('Voice')),
                  DropdownMenuItem(value: 'video', child: Text('Video')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedChannelType = value!;
                  });
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : () => _addChannel(context, franchiseId),
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditChannelDialog(BuildContext context, FranchiseChannel channel) {
    _channelNameController.text = channel.name;
    _selectedChannelType = channel.type;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Channel'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _channelNameController,
                decoration: const InputDecoration(
                  labelText: 'Channel Name',
                  hintText: 'Enter channel name',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a channel name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedChannelType,
                decoration: const InputDecoration(
                  labelText: 'Channel Type',
                ),
                items: const [
                  DropdownMenuItem(value: 'text', child: Text('Text')),
                  DropdownMenuItem(value: 'voice', child: Text('Voice')),
                  DropdownMenuItem(value: 'video', child: Text('Video')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedChannelType = value!;
                  });
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : () => _updateChannel(context, channel.id),
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteChannelDialog(BuildContext context, FranchiseChannel channel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Channel'),
        content: Text('Are you sure you want to delete the channel "${channel.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : () => _deleteChannel(context, channel.id),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _addFranchise(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final currentServerId = ref.read(currentServerIdProvider);
      if (currentServerId == null) {
        throw Exception('No server selected. Please select a server first.');
      }
      await FranchiseRepository.createFranchise(
        serverId: currentServerId,
        name: _franchiseNameController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Franchise "${_franchiseNameController.text.trim()}" created successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating franchise: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateFranchise(BuildContext context, String franchiseId) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await FranchiseRepository.updateFranchise(
        franchiseId: franchiseId,
        name: _franchiseNameController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Franchise updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating franchise: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addChannel(BuildContext context, String franchiseId) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await FranchiseRepository.createFranchiseChannel(
        franchiseId: franchiseId,
        name: _channelNameController.text.trim(),
        type: _selectedChannelType,
        voiceEnabled: _selectedChannelType == 'voice' || _selectedChannelType == 'video',
        videoEnabled: _selectedChannelType == 'video',
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Channel "${_channelNameController.text.trim()}" created successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating channel: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateChannel(BuildContext context, String channelId) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await FranchiseRepository.updateFranchiseChannel(
        channelId: channelId,
        name: _channelNameController.text.trim(),
        type: _selectedChannelType,
        voiceEnabled: _selectedChannelType == 'voice' || _selectedChannelType == 'video',
        videoEnabled: _selectedChannelType == 'video',
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Channel updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating channel: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteChannel(BuildContext context, String channelId) async {
    setState(() => _isLoading = true);

    try {
      await FranchiseRepository.deleteFranchiseChannel(channelId);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Channel deleted successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting channel: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
