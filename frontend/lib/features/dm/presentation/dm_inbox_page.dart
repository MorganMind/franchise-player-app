import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/dm_messages_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/user_provider.dart';
import 'widgets/dm_conversation_item.dart';

class DMInboxSidebar extends ConsumerStatefulWidget {
  final String? selectedThreadId;
  final Function(String) onSelectThread;

  const DMInboxSidebar({
    Key? key,
    this.selectedThreadId,
    required this.onSelectThread,
  }) : super(key: key);

  @override
  ConsumerState<DMInboxSidebar> createState() => _DMInboxSidebarState();
}

class _DMInboxSidebarState extends ConsumerState<DMInboxSidebar> {
  final bool _showNewConversationDialogFlag = false;

  @override
  Widget build(BuildContext context) {
    final dmChannelsAsync = ref.watch(dmChannelsProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'Direct Messages',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.person_add),
                  onPressed: () => _createSelfDm(),
                  tooltip: 'Create Self-DM',
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _showNewConversationDialog(),
                  tooltip: 'New Conversation',
                ),
              ],
            ),
          ),
          
          // Conversations list
          Expanded(
            child: dmChannelsAsync.when(
              data: (conversations) {
                if (conversations.isEmpty) {
                  return _buildEmptyState();
                }
                
                return ListView.builder(
                  itemCount: conversations.length,
                  itemBuilder: (context, index) {
                    final conversation = conversations[index];
                    final isSelected = widget.selectedThreadId == conversation['dm_channel_id'];
                    
                    return DMConversationItem(
                      conversation: conversation,
                      isSelected: isSelected,
                      onTap: () => widget.onSelectThread(conversation['dm_channel_id']),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load conversations',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 48,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No conversations yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a conversation with someone!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _showNewConversationDialog(),
            icon: const Icon(Icons.add),
            label: const Text('New Conversation'),
          ),
        ],
      ),
    );
  }

  void _showNewConversationDialog() {
    showDialog(
      context: context,
      builder: (context) => const NewConversationDialog(),
    );
  }

  void _createSelfDm() async {
    try {
      final dmChannelId = await ref.read(selfDmProvider.future);
      
      // Navigate to the self-DM
      if (context.mounted) {
        context.go('/home/dm/$dmChannelId');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: SelectableText('Failed to create self-DM: $e')),
        );
      }
    }
  }
}

class NewConversationDialog extends ConsumerStatefulWidget {
  const NewConversationDialog({Key? key}) : super(key: key);

  @override
  ConsumerState<NewConversationDialog> createState() => _NewConversationDialogState();
}

class _NewConversationDialogState extends ConsumerState<NewConversationDialog> {
  String? selectedUserId;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allUsersAsync = ref.watch(allUsersProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Dialog(
      child: Container(
        width: 400,
        height: 500,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'New Conversation',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => context.pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Search field
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
            const SizedBox(height: 16),
            
            // Users list
            Expanded(
              child: allUsersAsync.when(
                data: (users) {
                  final filteredUsers = users.where((user) {
                    if (_searchQuery.isEmpty) return true;
                    final displayName = user['display_name']?.toString().toLowerCase() ?? '';
                    final username = user['username']?.toString().toLowerCase() ?? '';
                    final query = _searchQuery.toLowerCase();
                    return displayName.contains(query) || username.contains(query);
                  }).where((user) => user['id'] != currentUser?.id).toList();

                  if (filteredUsers.isEmpty) {
                    return Center(
                      child: Text(
                        _searchQuery.isEmpty ? 'No users found' : 'No users match your search',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      final isSelected = selectedUserId == user['id'];
                      
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          child: Text(
                            (user['display_name'] ?? user['username'] ?? '?')[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(user['display_name'] ?? 'Unknown User'),
                        subtitle: Text('@${user['username'] ?? 'unknown'}'),
                        selected: isSelected,
                        onTap: () => setState(() => selectedUserId = user['id']),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Text('Error loading users: $error'),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: selectedUserId == null ? null : () => _startConversation(),
                  child: const Text('Start Conversation'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _startConversation() async {
    if (selectedUserId == null) return;
    
    try {
      final dmChannelId = await ref.read(dmChannelProvider(selectedUserId!).future);
      context.pop();
      
      // Navigate to the new conversation
      if (context.mounted) {
        context.go('/home/dm/$dmChannelId');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: SelectableText('Failed to start conversation: $e')),
        );
      }
    }
  }
} 