import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'user_search_provider.dart';
import '../../core/supabase/supabase_init.dart';
import 'package:go_router/go_router.dart';

class UserSearchPage extends ConsumerStatefulWidget {
  const UserSearchPage({super.key});

  @override
  ConsumerState<UserSearchPage> createState() => _UserSearchPageState();
}

class _UserSearchPageState extends ConsumerState<UserSearchPage> {
  String _query = '';
  bool _isCreatingDM = false;

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(userSearchProvider(_query));
    
    return Scaffold(
      appBar: AppBar(
        title: const SelectableText(
          'Find People',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Input
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Search by username or display name',
                hintText: 'Enter username or display name...',
                prefixIcon: const Icon(Icons.search, color: Colors.black),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.black, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: (val) => setState(() => _query = val),
            ),
          ),
          
          // Results
          Expanded(
            child: usersAsync.when(
              data: (users) => _buildUsersList(context, users),
              loading: () => _buildLoadingState(),
              error: (e, _) => _buildErrorState(e),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList(BuildContext context, List<Map<String, dynamic>> users) {
    if (_query.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            SelectableText(
              'Search for users to start a conversation',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 8),
            SelectableText(
              'Enter a username or display name above',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            SelectableText(
              'No users found',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 8),
            SelectableText(
              'Try a different search term',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: users.length,
      separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[200]),
      itemBuilder: (context, i) {
        final user = users[i];
        return _buildUserTile(context, user);
      },
    );
  }

  Widget _buildUserTile(BuildContext context, Map<String, dynamic> user) {
    final username = user['username'] ?? 'unknown';
    final displayName = user['display_name'];
    final avatarUrl = user['avatar_url'];
    
    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: _getAvatarColor(username),
        backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
        child: avatarUrl == null
            ? Text(
                username.isNotEmpty ? username[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              )
            : null,
      ),
      title: SelectableText(
        displayName ?? username,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: SelectableText(
        '@$username',
        style: TextStyle(color: Colors.grey[600]),
      ),
      trailing: _isCreatingDM
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(Icons.chat_bubble_outline, color: Colors.grey[600]),
      onTap: () => _createDMChannel(context, user),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          SelectableText('Searching users...'),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          SelectableText(
            'Failed to search users',
            style: TextStyle(color: Colors.red[600], fontSize: 16),
          ),
          const SizedBox(height: 8),
          SelectableText(
            'Please check your connection and try again.',
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref.invalidate(userSearchProvider(_query));
            },
            child: const SelectableText('Retry'),
          ),
        ],
      ),
    );
  }

  Future<void> _createDMChannel(BuildContext context, Map<String, dynamic> user) async {
    if (_isCreatingDM) return;

    setState(() {
      _isCreatingDM = true;
    });

    try {
      final res = await supabase.rpc(
        'create_or_get_dm_channel',
        params: {'other_user_id': user['user_id']},
      );
      
      if (context.mounted) {
        context.go('/home/dm/$res');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: SelectableText('Failed to create DM: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingDM = false;
        });
      }
    }
  }

  Color _getAvatarColor(String identifier) {
    final colors = [
      Colors.red[400]!,
      Colors.blue[400]!,
      Colors.green[400]!,
      Colors.orange[400]!,
      Colors.purple[400]!,
      Colors.teal[400]!,
      Colors.pink[400]!,
      Colors.indigo[400]!,
    ];
    
    final hash = identifier.hashCode;
    return colors[hash.abs() % colors.length];
  }
} 