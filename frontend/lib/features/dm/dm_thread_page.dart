import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/supabase/supabase_init.dart';
import '../../providers/dm_messages_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/message.dart';
import '../../models/user.dart' as app_user;
import 'widgets/message_bubble.dart';

class DMThreadPage extends ConsumerStatefulWidget {
  final String threadId;
  const DMThreadPage({required this.threadId, Key? key}) : super(key: key);

  @override
  ConsumerState<DMThreadPage> createState() => _DMThreadPageState();
}

class _DMThreadPageState extends ConsumerState<DMThreadPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(dmMessagesProvider(widget.threadId));
    final currentUserAsync = ref.watch(currentUserProfileProvider);
    final dmChannelAsync = ref.watch(dmChannelsProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: currentUserAsync.when(
          data: (currentUser) => _buildHeader(context, currentUser, dmChannelAsync),
          loading: () => const SelectableText('Loading...'),
          error: (_, __) => const SelectableText('Error'),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: messagesAsync.when(
              data: (messages) => currentUserAsync.when(
                data: (currentUser) => _buildMessagesList(context, messages, currentUser),
                loading: () => _buildLoadingState(context),
                error: (_, __) => _buildErrorState(context, 'Failed to load user'),
              ),
              loading: () => _buildLoadingState(context),
              error: (error, stackTrace) => _buildErrorState(context, error),
            ),
          ),
          
          // Message Input
          currentUserAsync.when(
            data: (currentUser) => _buildMessageInput(context, currentUser),
            loading: () => Container(
              padding: const EdgeInsets.all(16),
              child: const Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => Container(
              padding: const EdgeInsets.all(16),
              child: const Center(child: SelectableText('Error loading user')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, app_user.User? currentUser, AsyncValue<List<Map<String, dynamic>>> dmChannelAsync) {
    return dmChannelAsync.when(
      data: (channels) {
        final channel = channels.firstWhere(
          (c) => c['dm_channel_id'] == widget.threadId,
          orElse: () => <String, dynamic>{},
        );
        
        if (channel.isEmpty) {
          return const SelectableText('Unknown Conversation');
        }
        
        // Fetch participants from dm_participants
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: supabase
              .from('dm_participants')
              .select('user_id')
              .eq('dm_channel_id', widget.threadId)
              .then((res) => List<Map<String, dynamic>>.from(res)),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Container(
                height: 16,
                width: 150,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }
            final participants = snapshot.data!;
            final participantIds = participants.map((p) => p['user_id'] as String).toList();
            if (participantIds.length == 1 && participantIds.first == currentUser?.id) {
              // Self-DM logic
              final userAsync = ref.watch(userProfileProvider(currentUser!.id));
              return userAsync.when(
                data: (user) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: _getAvatarColor(user?.username ?? currentUser.id),
                      child: user?.avatarUrl != null
                          ? ClipOval(
                              child: Image.network(
                                user!.avatarUrl!,
                                width: 32,
                                height: 32,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => _buildAvatarFallback(user.username ?? currentUser.id),
                              ),
                            )
                          : _buildAvatarFallback(user?.username ?? currentUser.id),
                    ),
                    const SizedBox(width: 12),
                    SelectableText(
                      user?.displayName ?? user?.username ?? 'Yourself',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                loading: () => Container(
                  height: 16,
                  width: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                error: (_, __) => const SelectableText('Yourself'),
              );
            } else if (participantIds.length == 2) {
              // Normal DM logic
              final otherUserId = participantIds.firstWhere((id) => id != currentUser?.id);
              final userAsync = ref.watch(userProfileProvider(otherUserId));
              return userAsync.when(
                data: (user) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: _getAvatarColor(user?.username ?? otherUserId),
                      child: user?.avatarUrl != null
                          ? ClipOval(
                              child: Image.network(
                                user!.avatarUrl!,
                                width: 32,
                                height: 32,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => _buildAvatarFallback(user.username ?? otherUserId),
                              ),
                            )
                          : _buildAvatarFallback(user?.username ?? otherUserId),
                    ),
                    const SizedBox(width: 12),
                    SelectableText(
                      user?.displayName ?? user?.username ?? 'Unknown User',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                loading: () => Container(
                  height: 16,
                  width: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                error: (_, __) => const SelectableText('Unknown User'),
              );
            } else {
              // Fallback for group DMs or unexpected cases
              return const SelectableText('Unknown Conversation');
            }
          },
        );
      },
      loading: () => Container(
        height: 16,
        width: 150,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      error: (_, __) => const SelectableText('Error'),
    );
  }

  Widget _buildMessagesList(BuildContext context, List<Message> messages, app_user.User? currentUser) {
    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            SelectableText(
              'No messages yet',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 8),
            SelectableText(
              'Start the conversation!',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isOwnMessage = message.authorId == currentUser?.id;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: MessageBubble(
            message: message,
            isOwnMessage: isOwnMessage,
            showAvatar: !isOwnMessage,
          ),
        );
      },
    );
  }

  Widget _buildMessageInput(BuildContext context, app_user.User? currentUser) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: Colors.black),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
          const SizedBox(width: 8),
          _isSending
              ? const SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : IconButton(
                  onPressed: _controller.text.trim().isEmpty ? null : _sendMessage,
                  icon: const Icon(Icons.send, color: Colors.black),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey[100],
                    shape: const CircleBorder(),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          SelectableText('Loading messages...'),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
          const SizedBox(height: 16),
          SelectableText(
            'Failed to load messages',
            style: TextStyle(color: Colors.red[600], fontSize: 16),
          ),
          const SizedBox(height: 8),
          SelectableText(
            error.toString(),
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) return;

    setState(() {
      _isSending = true;
    });

    try {
      final message = _controller.text.trim();
      _controller.clear();

      await supabase.from('messages').insert({
        'dm_channel_id': widget.threadId,
        'author_id': currentUser.id,
        'content': message,
      });

      // Scroll to bottom after sending
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: SelectableText('Failed to send message: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  Color _getAvatarColor(String seed) {
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
    
    final index = seed.hashCode % colors.length;
    return colors[index];
  }

  Widget _buildAvatarFallback(String seed) {
    final color = _getAvatarColor(seed);
    final initials = seed.isNotEmpty ? seed[0].toUpperCase() : '?';
    
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
} 