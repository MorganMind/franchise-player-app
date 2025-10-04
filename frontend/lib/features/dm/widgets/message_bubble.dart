import 'package:flutter/material.dart';
import '../../../models/message.dart';
import '../../../providers/user_profile_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MessageBubble extends ConsumerWidget {
  final Message message;
  final bool isOwnMessage;
  final bool showAvatar;

  const MessageBubble({
    required this.message,
    required this.isOwnMessage,
    required this.showAvatar,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isOwnMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isOwnMessage && showAvatar) ...[
            _buildAvatar(ref),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isOwnMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isOwnMessage && showAvatar) ...[
                  _buildUsername(ref),
                  const SizedBox(height: 4),
                ],
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isOwnMessage ? Colors.black : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20).copyWith(
                      bottomLeft: isOwnMessage ? const Radius.circular(20) : const Radius.circular(4),
                      bottomRight: isOwnMessage ? const Radius.circular(4) : const Radius.circular(20),
                    ),
                  ),
                  child: SelectableText(
                    message.displayContent,
                    style: TextStyle(
                      color: isOwnMessage ? Colors.white : Colors.black,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                _buildTimestamp(),
              ],
            ),
          ),
          if (isOwnMessage && showAvatar) ...[
            const SizedBox(width: 8),
            _buildAvatar(ref),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(WidgetRef ref) {
    final userAsync = ref.watch(userProfileProvider(message.authorId));
    return userAsync.when(
      data: (user) {
        final username = user?.username ?? message.authorId;
        final avatarUrl = user?.avatarUrl;
        
        return CircleAvatar(
          radius: 16,
          backgroundColor: _getAvatarColor(username),
          child: avatarUrl != null
              ? ClipOval(
                  child: Image.network(
                    avatarUrl,
                    width: 32,
                    height: 32,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _buildAvatarFallback(username),
                  ),
                )
              : _buildAvatarFallback(username),
        );
      },
      loading: () => CircleAvatar(
        radius: 16,
        backgroundColor: Colors.grey[300],
        child: const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (_, __) => CircleAvatar(
        radius: 16,
        backgroundColor: Colors.grey[300],
        child: Icon(Icons.person, size: 16, color: Colors.grey[600]),
      ),
    );
  }

  Widget _buildUsername(WidgetRef ref) {
    final userAsync = ref.watch(userProfileProvider(message.authorId));
    return userAsync.when(
      data: (user) {
        final displayName = user?.displayName;
        final username = user?.username ?? message.authorId;
        
        return Padding(
          padding: const EdgeInsets.only(left: 4),
          child: SelectableText(
            displayName ?? username,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        );
      },
      loading: () => Container(
        height: 12,
        width: 80,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      error: (_, __) => SelectableText(
        'Unknown User',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildTimestamp() {
    final now = DateTime.now();
    final messageTime = message.createdAt;
    final difference = now.difference(messageTime);
    
    String timeText;
    if (difference.inDays > 0) {
      timeText = '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      timeText = '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      timeText = '${difference.inMinutes}m ago';
    } else {
      timeText = 'now';
    }
    
    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 4),
      child: SelectableText(
        timeText,
        style: TextStyle(
          fontSize: 10,
          color: Colors.grey[500],
        ),
      ),
    );
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
} 