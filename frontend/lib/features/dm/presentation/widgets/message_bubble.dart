import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/user_provider.dart';
import '../../../../models/message.dart';

class MessageBubble extends ConsumerWidget {
  final Message message;
  final bool showAvatar;
  final bool showTimestamp;

  const MessageBubble({
    Key? key,
    required this.message,
    this.showAvatar = true,
    this.showTimestamp = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider(message.authorId));
    
    return userAsync.when(
      data: (user) => _buildMessageBubble(context, user),
      loading: () => _buildLoadingBubble(context),
      error: (_, __) => _buildErrorBubble(context),
    );
  }

  Widget _buildMessageBubble(BuildContext context, Map<String, dynamic>? user) {
    final displayName = user?['display_name'] ?? user?['username'] ?? 'Unknown User';
    final avatarUrl = user?['avatar_url'];
    const isOwnMessage = false; // TODO: Compare with current user

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showAvatar && !isOwnMessage) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: _getAvatarColor(displayName),
              child: avatarUrl != null
                  ? ClipOval(
                      child: Image.network(
                        avatarUrl,
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildAvatarFallback(displayName),
                      ),
                    )
                  : _buildAvatarFallback(displayName),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: isOwnMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isOwnMessage) ...[
                  SelectableText(
                    displayName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isOwnMessage
                        ? Theme.of(context).colorScheme.primary
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16).copyWith(
                      bottomLeft: isOwnMessage ? const Radius.circular(16) : const Radius.circular(4),
                      bottomRight: isOwnMessage ? const Radius.circular(4) : const Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Message content
                      SelectableText(
                        message.content ?? 'Empty message',
                        style: TextStyle(
                          color: isOwnMessage
                              ? Colors.white
                              : Theme.of(context).colorScheme.onSurface,
                          fontSize: 14,
                        ),
                      ),
                      
                      // Timestamp
                      if (showTimestamp) ...[
                        const SizedBox(height: 4),
                        SelectableText(
                          _formatTimestamp(message.createdAt),
                          style: TextStyle(
                            fontSize: 10,
                            color: isOwnMessage
                                ? Colors.white.withOpacity(0.7)
                                : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (showAvatar && isOwnMessage) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: _getAvatarColor(displayName),
              child: avatarUrl != null
                  ? ClipOval(
                      child: Image.network(
                        avatarUrl,
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildAvatarFallback(displayName),
                      ),
                    )
                  : _buildAvatarFallback(displayName),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingBubble(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 12,
                  width: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 40,
                  width: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBubble(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey[400],
            child: Icon(
              Icons.error_outline,
              color: Colors.grey[600],
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: SelectableText(
                'Failed to load message',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarFallback(String displayName) {
    return Text(
      displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 12,
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

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${timestamp.day}/${timestamp.month} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
} 