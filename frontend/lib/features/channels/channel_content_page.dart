import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/channel_messages_provider.dart';
import '../../core/supabase/supabase_init.dart';
import '../../providers/user_profile_provider.dart';
import '../../models/message.dart';
import '../../models/user.dart' as app_user;
import '../dm/widgets/message_bubble.dart';
import '../voice/presentation/voice_channel_widget.dart';

class ChannelContentPage extends ConsumerStatefulWidget {
  final String channelId;
  final String channelName;
  final String? channelType;
  
  const ChannelContentPage({
    required this.channelId,
    required this.channelName,
    this.channelType,
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<ChannelContentPage> createState() => _ChannelContentPageState();
}

class _ChannelContentPageState extends ConsumerState<ChannelContentPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;
  bool _hasText = false;
  bool _shouldAutoScroll = true; // Track if we should auto-scroll
  List<Message> _previousMessages = []; // Track previous messages to detect new ones
  bool _hasNewMessages = false; // Track if there are new messages when scrolled up
  bool _isScrolledPastLatest = false; // Track if user has scrolled past the latest message
  
  // Custom formatter to handle Enter key
  TextInputFormatter? _enterKeyFormatter;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    
    // Create the Enter key formatter
    _enterKeyFormatter = TextInputFormatter.withFunction((oldValue, newValue) {
      final text = newValue.text;
      
      // Check if Enter was pressed (new line added)
      if (text.length > oldValue.text.length && text.contains('\n')) {
        final lines = text.split('\n');
        final lastLine = lines.last;
        
        // If the last line is empty (just Enter pressed), remove it and send
        if (lastLine.isEmpty && lines.length > 1) {
          final messageText = lines.take(lines.length - 1).join('\n');
          // Schedule the send after the formatter completes
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (messageText.trim().isNotEmpty) {
              _sendMessage();
            }
          });
          return TextEditingValue(
            text: messageText,
            selection: TextSelection.collapsed(offset: messageText.length),
          );
        }
      }
      
      return newValue;
    });
    
    // Listen for scroll changes to determine if user has scrolled up
    _scrollController.addListener(_onScrollChanged);
    
    // Auto-scroll to bottom when first opening the channel
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _scrollController.removeListener(_onScrollChanged);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
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

  @override
  Widget build(BuildContext context) {
    // Check if this is a voice channel
    final isVoiceChannel = widget.channelType == 'voice';
    
    if (isVoiceChannel) {
      return VoiceChannelWidget(
        channelId: widget.channelId,
        channelName: widget.channelName,
      );
    }
    
    // Text channel - show messages
    final messagesAsync = ref.watch(channelMessagesProvider(widget.channelId));
    final currentUserAsync = ref.watch(currentUserProfileProvider);
    
    // Listen for message changes and auto-scroll if needed
    messagesAsync.whenData((messages) {
      _handleMessagesUpdate(messages);
    });
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.tag, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 8),
            SelectableText(
              widget.channelName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showChannelInfo(context),
          ),
        ],
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

  Widget _buildMessagesList(BuildContext context, List<Message> messages, app_user.User? currentUser) {
    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            SelectableText(
              'No messages in this channel yet',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 8),
            SelectableText(
              'Be the first to start the conversation!',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        ListView.builder(
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
                showAvatar: index == 0 || 
                           messages[index - 1].authorId != message.authorId ||
                           _shouldShowAvatar(messages, index),
              ),
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
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          SelectableText('Loading channel messages...'),
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
            'Failed to load channel messages',
            style: TextStyle(color: Colors.red[600], fontSize: 16),
          ),
          const SizedBox(height: 8),
          SelectableText(
            error.toString(),
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref.invalidate(channelMessagesProvider(widget.channelId));
            },
            child: const SelectableText('Retry'),
          ),
        ],
      ),
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
              inputFormatters: _enterKeyFormatter != null ? [_enterKeyFormatter!] : [],
              decoration: InputDecoration(
                hintText: 'Message #${widget.channelName}',
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
              onTapOutside: (event) {
                // Close keyboard when tapping outside
                FocusScope.of(context).unfocus();
              },
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
                  onPressed: _hasText ? () {
                    print('Send button clicked!'); // Debug print
                    _sendMessage();
                  } : null,
                  icon: Icon(
                    Icons.send, 
                    color: _hasText ? Colors.white : Colors.grey[400],
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: _hasText ? Colors.blue : Colors.grey[200],
                    shape: const CircleBorder(),
                    minimumSize: const Size(40, 40),
                  ),
                ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    print('_sendMessage called'); // Debug print
    
    if (_controller.text.trim().isEmpty) {
      print('Message is empty, returning'); // Debug print
      return;
    }

    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) {
      print('No current user, returning'); // Debug print
      return;
    }

    print('Sending message: ${_controller.text.trim()}'); // Debug print

    setState(() {
      _isSending = true;
    });

    try {
      final message = _controller.text.trim();
      _controller.clear();
      _onTextChanged(); // Update the hasText state

      print('Calling sendChannelMessage with channelId: ${widget.channelId}, content: $message'); // Debug print
      // Send message using the provider function
      await sendChannelMessage(
        channelId: widget.channelId,
        content: message,
      );

      print('Message sent successfully!'); // Debug print

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
      print('Error sending message: $e'); // Debug print
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

  Future<void> _ensureUserProfile(String userId) async {
    try {
      // Check if user profile exists
      final existing = await supabase
          .from('user_profiles')
          .select('id')
          .eq('id', userId)
          .maybeSingle();
      
      if (existing == null) {
        // Create user profile
        await supabase.from('user_profiles').insert({
          'id': userId,
          'username': 'user_${userId.substring(0, 8)}',
          'display_name': 'User ${userId.substring(0, 8)}',
          'status': 'online',
        });
      }
    } catch (e) {
      // Profile might already exist, ignore error
      print('Error ensuring user profile: $e');
    }
  }

  bool _shouldShowAvatar(List<Message> messages, int index) {
    if (index == messages.length - 1) return true;
    
    final currentMessage = messages[index];
    final nextMessage = messages[index + 1];
    
    // Show avatar if next message is from different author or if there's a time gap
    if (currentMessage.authorId != nextMessage.authorId) return true;
    
    final timeDiff = nextMessage.createdAt.difference(currentMessage.createdAt);
    return timeDiff.inMinutes > 5; // Show avatar if more than 5 minutes apart
  }

  void _showChannelInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const SelectableText('Channel Info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText('Name: #${widget.channelName}'),
            const SizedBox(height: 8),
            SelectableText('ID: ${widget.channelId}'),
            const SizedBox(height: 8),
            SelectableText('Type: ${widget.channelType ?? 'text'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const SelectableText('Close'),
          ),
        ],
      ),
    );
  }
} 