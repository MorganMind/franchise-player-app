import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../providers/dm_messages_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../models/message.dart';
import 'widgets/message_bubble.dart';
import '../../../core/supabase/supabase_init.dart';

class DMThreadView extends ConsumerStatefulWidget {
  final String threadId;
  const DMThreadView({required this.threadId, Key? key}) : super(key: key);

  @override
  ConsumerState<DMThreadView> createState() => _DMThreadViewState();
}

class _DMThreadViewState extends ConsumerState<DMThreadView> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;
  bool _shouldAutoScroll = true; // Track if we should auto-scroll
  List<Message> _previousMessages = []; // Track previous messages to detect new ones
  bool _hasNewMessages = false; // Track if there are new messages when scrolled up
  bool _isScrolledPastLatest = false; // Track if user has scrolled past the latest message

  @override
  void initState() {
    super.initState();
    
    // Listen for scroll changes to determine if user has scrolled up
    _scrollController.addListener(_onScrollChanged);
    
    // Auto-scroll to bottom when first opening the DM
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScrollChanged);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScrollChanged() {
    if (!_scrollController.hasClients) return;
    
    final position = _scrollController.position;
    final maxScroll = position.maxScrollExtent;
    final currentScroll = position.pixels;
    
    // Check if user is at the bottom (within 50 pixels)
    final isAtBottom = (maxScroll - currentScroll) <= 50;
    
    // Check if user has scrolled past the latest message entirely
    // This means they're not at the bottom and there's content below
    final isScrolledPastLatest = !isAtBottom && maxScroll > 0;
    
    if (_shouldAutoScroll != isAtBottom) {
      setState(() {
        _shouldAutoScroll = isAtBottom;
        // Clear new messages indicator when user scrolls to bottom
        if (isAtBottom) {
          _hasNewMessages = false;
        }
      });
    }
    
    if (_isScrolledPastLatest != isScrolledPastLatest) {
      setState(() {
        _isScrolledPastLatest = isScrolledPastLatest;
      });
    }
  }

  void _handleMessagesUpdate(List<Message> messages) {
    // Check if new messages were added
    if (messages.length > _previousMessages.length) {
      // New messages arrived
      if (_shouldAutoScroll) {
        // Auto-scroll to bottom if user hasn't scrolled up
        // Use a delay to ensure the UI has updated
        Future.delayed(const Duration(milliseconds: 100), () {
          _scrollToBottom();
        });
        setState(() {
          _hasNewMessages = false;
        });
      } else {
        // User has scrolled up, show indicator
        setState(() {
          _hasNewMessages = true;
        });
      }
    }
    
    // Update previous messages
    _previousMessages = List.from(messages);
  }

  void _scrollToBottom() {
    // Use a longer delay to ensure the UI has fully updated
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        final position = _scrollController.position;
        if (position.maxScrollExtent > 0) {
          _scrollController.animateTo(
            position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    print('DMThreadView for threadId: [34m[1m[4m[7m${widget.threadId}[0m'); // DEBUG
    final messagesAsync = ref.watch(dmMessagesProvider(widget.threadId));
    print('messagesAsync: $messagesAsync'); // DEBUG
    final currentUser = ref.watch(currentUserProvider);
    final dmChannelAsync = ref.watch(dmChannelsProvider);
    
    // Listen for message changes and auto-scroll if needed
    messagesAsync.whenData((messages) {
      _handleMessagesUpdate(messages);
    });
    
    return Column(
      children: [
        // Header
        _buildHeader(context, currentUser, dmChannelAsync),
        
        // Messages
        Expanded(
          child: messagesAsync.when(
            data: (messages) => _buildMessagesList(context, messages, currentUser),
            loading: () => _buildLoadingState(context),
            error: (error, stackTrace) => _buildErrorState(context, error),
          ),
        ),
        
        // Message Input
        _buildMessageInput(context, currentUser),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, User? currentUser, AsyncValue<List<Map<String, dynamic>>> dmChannelAsync) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Back button for mobile
          if (MediaQuery.of(context).size.width < 600)
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
            ),
          
          // User info
          Expanded(
            child: dmChannelAsync.when(
              data: (channels) {
                final channel = channels.firstWhere(
                  (c) => c['id'] == widget.threadId,
                  orElse: () => <String, dynamic>{},
                );
                
                if (channel.isEmpty) {
                  return SelectableText(
                    'Unknown Conversation',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  );
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
                      final userAsync = ref.watch(userProvider(currentUser!.id));
                      return userAsync.when(
                        data: (user) => Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: _getAvatarColor(user?['username'] ?? currentUser.id),
                              child: user?['avatar_url'] != null
                                  ? ClipOval(
                                      child: Image.network(
                                        user!['avatar_url'],
                                        width: 32,
                                        height: 32,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => _buildAvatarFallback(user['username'] ?? currentUser.id),
                                      ),
                                    )
                                  : _buildAvatarFallback(user?['username'] ?? currentUser.id),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SelectableText(
                                    user?['display_name'] ?? user?['username'] ?? 'Yourself',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SelectableText(
                                    'Your personal space',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        loading: () => Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              height: 16,
                              width: 120,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                        error: (_, __) => SelectableText(
                          'Yourself',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    } else if (participantIds.length == 2) {
                      // Normal DM logic
                      final otherUserId = participantIds.firstWhere((id) => id != currentUser?.id);
                      final userAsync = ref.watch(userProvider(otherUserId));
                      return userAsync.when(
                        data: (user) => Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: _getAvatarColor(user?['username'] ?? otherUserId),
                              child: user?['avatar_url'] != null
                                  ? ClipOval(
                                      child: Image.network(
                                        user!['avatar_url'],
                                        width: 32,
                                        height: 32,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => _buildAvatarFallback(user['username'] ?? otherUserId),
                                      ),
                                    )
                                  : _buildAvatarFallback(user?['username'] ?? otherUserId),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SelectableText(
                                    user?['display_name'] ?? user?['username'] ?? 'Unknown User',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SelectableText(
                                    'Online',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        loading: () => Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              height: 16,
                              width: 120,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                        error: (_, __) => SelectableText(
                          'Unknown User',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    } else {
                      // Fallback for group DMs or unexpected cases
                      return SelectableText(
                        'Unknown Conversation',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      );
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
              error: (_, __) => SelectableText(
                'Error loading conversation',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          
          // Actions
          IconButton(
            onPressed: () {
              // TODO: Implement call functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: SelectableText('Call feature coming soon!')),
              );
            },
            icon: const Icon(Icons.call),
            tooltip: 'Call',
          ),
          IconButton(
            onPressed: () {
              // TODO: Implement video call functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: SelectableText('Video call feature coming soon!')),
              );
            },
            icon: const Icon(Icons.videocam),
            tooltip: 'Video Call',
          ),
          IconButton(
            onPressed: () {
              // TODO: Implement more options
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: SelectableText('More options coming soon!')),
              );
            },
            icon: const Icon(Icons.more_vert),
            tooltip: 'More Options',
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(BuildContext context, List<Message> messages, User? currentUser) {
    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No messages yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start the conversation!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            final isOwnMessage = currentUser?.id == message.authorId;
            
            return MessageBubble(
              message: message,
              showAvatar: !isOwnMessage,
              showTimestamp: true,
            );
          },
        ),
        
        // New messages indicator (when user has scrolled up but not past latest)
        if (_hasNewMessages && !_isScrolledPastLatest)
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton.small(
              onPressed: () {
                _scrollToBottom();
                setState(() {
                  _hasNewMessages = false;
                  _shouldAutoScroll = true;
                });
              },
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.keyboard_arrow_down, size: 16),
                  SizedBox(width: 4),
                  Text('New', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ),
        
        // Latest Messages button (when user has scrolled past latest message entirely)
        if (_isScrolledPastLatest)
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton.small(
              onPressed: () {
                _scrollToBottom();
                setState(() {
                  _hasNewMessages = false;
                  _shouldAutoScroll = true;
                  _isScrolledPastLatest = false;
                });
              },
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.keyboard_arrow_down, size: 16),
                  SizedBox(width: 4),
                  Text('Latest', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          SelectableText(
            'Loading messages...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          SelectableText(
            'Failed to load messages',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          SelectableText(
            'Please check your connection and try again',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement retry functionality
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput(BuildContext context, User? currentUser) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Attachment button
          IconButton(
            onPressed: () {
              // TODO: Implement file attachment
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: SelectableText('File attachment coming soon!')),
              );
            },
            icon: Icon(
              Icons.attach_file,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            tooltip: 'Attach File',
          ),
          
          // Emoji button
          IconButton(
            onPressed: () {
              // TODO: Implement emoji picker
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: SelectableText('Emoji picker coming soon!')),
              );
            },
            icon: Icon(
              Icons.emoji_emotions_outlined,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            tooltip: 'Emoji',
          ),
          
          // Message input field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: TextField(
                controller: _controller,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  suffixIcon: _isSending
                      ? Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        )
                      : null,
                ),
                onChanged: (value) {
                  setState(() {});
                },
                onSubmitted: (value) {
                  _sendMessage(currentUser);
                },
              ),
            ),
          ),
          
          // Send button
          const SizedBox(width: 8),
          IconButton(
            onPressed: _canSendMessage(currentUser) ? () => _sendMessage(currentUser) : null,
            icon: Icon(
              Icons.send,
              color: _canSendMessage(currentUser)
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            tooltip: 'Send Message',
          ),
        ],
      ),
    );
  }

  bool _canSendMessage(User? currentUser) {
    return currentUser != null && 
           _controller.text.trim().isNotEmpty && 
           !_isSending;
  }

  Future<void> _sendMessage(User? currentUser) async {
    if (!_canSendMessage(currentUser)) return;
    
    final text = _controller.text.trim();
    _controller.clear();
    setState(() {
      _isSending = true;
    });
    
    try {
      await sendDmMessage(
        dmChannelId: widget.threadId,
        authorId: currentUser!.id,
        content: text,
      );
      
      // Always scroll to bottom after sending (regardless of auto-scroll setting)
      // Use a longer delay to ensure the message is added to the list
      Future.delayed(const Duration(milliseconds: 200), () {
        _scrollToBottom();
      });
      
      // Re-enable auto-scroll since user just sent a message
      setState(() {
        _shouldAutoScroll = true;
        _isScrolledPastLatest = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: SelectableText('Failed to send message: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      // Restore the text if sending failed
      _controller.text = text;
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  String _getOtherUserId(Map<String, dynamic> channel, String currentUserId) {
    if (channel['user1_id'] == currentUserId && channel['user2_id'] == currentUserId) {
      return currentUserId;
    }
    final user1Id = channel['user1_id'] as String?;
    final user2Id = channel['user2_id'] as String?;
    if (user1Id == null || user2Id == null) return currentUserId;
    return user1Id == currentUserId ? user2Id : user1Id;
  }

  Widget _buildAvatarFallback(String identifier) {
    return Text(
      identifier.isNotEmpty ? identifier[0].toUpperCase() : '?',
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),
    );
  }

  Color _getAvatarColor(String identifier) {
    final colors = [
      Colors.red,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.yellow,
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
      Colors.brown,
      Colors.grey,
      Colors.black,
      Colors.white,
    ];
    final hash = identifier.hashCode;
    return colors[hash.abs() % colors.length];
  }
} 