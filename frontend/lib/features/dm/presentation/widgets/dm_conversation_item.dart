import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/auth_provider.dart';

class DMConversationItem extends ConsumerWidget {
  final Map<String, dynamic> conversation;
  final bool isSelected;
  final VoidCallback onTap;

  const DMConversationItem({
    Key? key,
    required this.conversation,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final otherUserProfile = conversation['other_user_profile'] as Map<String, dynamic>?;
    final latestMessage = conversation['latest_message'] as Map<String, dynamic>?;
    final isSelfDm = conversation['other_user_id'] == currentUser?.id;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected 
            ? Colors.white
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isSelected 
            ? Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                width: 1,
              )
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelfDm 
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.secondary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isSelfDm
                        ? const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 20,
                          )
                        : Text(
                            (otherUserProfile?['display_name'] ?? '?')[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name
                      SelectableText(
                        isSelfDm 
                            ? 'Yourself'
                            : otherUserProfile?['display_name'] ?? 'Unknown User',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isSelected 
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                        maxLines: 1,
                      ),
                      
                      // Latest message or status
                      if (latestMessage != null) ...[
                        const SizedBox(height: 2),
                        SelectableText(
                          latestMessage['content'] ?? '',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                          maxLines: 1,
                        ),
                      ] else ...[
                        const SizedBox(height: 2),
                        Text(
                          isSelfDm ? 'Your personal space' : 'No messages yet',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Timestamp or status indicator
                if (latestMessage != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    _formatTimestamp(latestMessage['created_at']),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return '';
    
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inDays > 0) {
        return '${difference.inDays}d';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m';
      } else {
        return 'now';
      }
    } catch (e) {
      return '';
    }
  }
} 