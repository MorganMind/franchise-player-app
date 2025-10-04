class Message {
  final String id;
  final String? content;
  final String authorId;
  final String? dmChannelId;
  final String? channelId;
  final String? franchiseChannelId;
  final DateTime createdAt;
  final DateTime? editedAt;
  final bool isDeleted;
  final DateTime? deletedAt;
  final List<Map<String, dynamic>> attachments;
  final List<Map<String, dynamic>> embeds;
  final String? replyToId;

  Message({
    required this.id,
    this.content,
    required this.authorId,
    this.dmChannelId,
    this.channelId,
    this.franchiseChannelId,
    required this.createdAt,
    this.editedAt,
    this.isDeleted = false,
    this.deletedAt,
    this.attachments = const [],
    this.embeds = const [],
    this.replyToId,
  });

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'] as String,
      content: map['content'] as String?,
      authorId: map['author_id'] as String,
      dmChannelId: map['dm_channel_id'] as String?,
      channelId: map['channel_id'] as String?,
      franchiseChannelId: map['franchise_channel_id'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      editedAt: map['edited_at'] != null ? DateTime.parse(map['edited_at'] as String) : null,
      isDeleted: map['is_deleted'] as bool? ?? false,
      deletedAt: map['deleted_at'] != null ? DateTime.parse(map['deleted_at'] as String) : null,
      attachments: map['attachments'] != null 
          ? List<Map<String, dynamic>>.from(map['attachments'] as List)
          : [],
      embeds: map['embeds'] != null 
          ? List<Map<String, dynamic>>.from(map['embeds'] as List)
          : [],
      replyToId: map['reply_to_id'] as String?,
    );
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message.fromMap(json);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'author_id': authorId,
      'dm_channel_id': dmChannelId,
      'channel_id': channelId,
      'franchise_channel_id': franchiseChannelId,
      'created_at': createdAt.toIso8601String(),
      'edited_at': editedAt?.toIso8601String(),
      'is_deleted': isDeleted,
      'deleted_at': deletedAt?.toIso8601String(),
      'attachments': attachments,
      'embeds': embeds,
      'reply_to_id': replyToId,
    };
  }

  Map<String, dynamic> toJson() {
    return toMap();
  }

  // Helper method to format timestamp
  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'now';
    }
  }

  // Helper method to check if message is from today
  bool get isFromToday {
    final now = DateTime.now();
    return createdAt.year == now.year &&
           createdAt.month == now.month &&
           createdAt.day == now.day;
  }

  // Helper method to check if message is from yesterday
  bool get isFromYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return createdAt.year == yesterday.year &&
           createdAt.month == yesterday.month &&
           createdAt.day == yesterday.day;
  }

  // Helper method to check if message is edited
  bool get isEdited => editedAt != null;

  // Helper method to get display content
  String get displayContent {
    if (isDeleted) {
      return '*This message was deleted*';
    }
    return content ?? '';
  }
} 