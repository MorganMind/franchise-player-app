import 'package:flutter/material.dart';

class MockChannel extends StatefulWidget {
  final String channelName;
  final String? subcategoryName;

  const MockChannel({
    Key? key,
    required this.channelName,
    this.subcategoryName,
  }) : super(key: key);

  @override
  State<MockChannel> createState() => _MockChannelState();
}

class _MockChannelState extends State<MockChannel> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [
    {
      'user': 'Nash',
      'message': 'Welcome to the channel!',
      'timestamp': '2:30 PM',
      'avatar': 'N',
    },
    {
      'user': 'CoachMike',
      'message': 'Great to be here! How is everyone doing today?',
      'timestamp': '2:32 PM',
      'avatar': 'C',
    },
    {
      'user': 'FranchiseKing',
      'message': 'Just finished my game against the Cowboys. Won 28-24!',
      'timestamp': '2:35 PM',
      'avatar': 'F',
    },
    {
      'user': 'MaddenPro',
      'message': 'Nice win! What was your key play?',
      'timestamp': '2:37 PM',
      'avatar': 'M',
    },
    {
      'user': 'FranchiseKing',
      'message': 'Fourth quarter, 3rd and 8, hit my WR on a slant for 45 yards. Game changer!',
      'timestamp': '2:38 PM',
      'avatar': 'F',
    },
  ];

  @override
  void initState() {
    super.initState();
    // Update the first message with the channel name
    if (_messages.isNotEmpty) {
      _messages[0]['message'] = 'Welcome to the ${widget.channelName} channel!';
    }
    
    // Add some channel-specific messages
    if (widget.channelName == 'trades') {
      _messages.addAll([
        {
          'user': 'TradeMaster',
          'message': 'Anyone looking for a backup QB? I have a 75 OVR available.',
          'timestamp': '2:40 PM',
          'avatar': 'T',
        },
        {
          'user': 'TeamBuilder',
          'message': 'I might be interested. What are you looking for in return?',
          'timestamp': '2:42 PM',
          'avatar': 'T',
        },
      ]);
    } else if (widget.channelName == 'schedule') {
      _messages.addAll([
        {
          'user': 'ScheduleBot',
          'message': 'Week 5 games are now available to schedule!',
          'timestamp': '2:40 PM',
          'avatar': 'S',
        },
        {
          'user': 'LeagueAdmin',
          'message': 'Please schedule your games by Friday night.',
          'timestamp': '2:41 PM',
          'avatar': 'L',
        },
      ]);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty) {
      setState(() {
        _messages.add({
          'user': 'You',
          'message': _messageController.text,
          'timestamp': 'Now',
          'avatar': 'Y',
        });
      });
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = widget.subcategoryName != null 
        ? '${widget.channelName} > ${widget.subcategoryName}'
        : widget.channelName;

    return Column(
      children: [
        // Channel header
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Color(0xFFE9ECEF), width: 1)),
          ),
          child: Row(
            children: [
              Icon(Icons.tag, color: Color(0xFF6C757D)),
              SizedBox(width: 8),
              Text(
                displayName,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
        
        // Messages area
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final message = _messages[index];
              return Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: _getAvatarColor(message['avatar']),
                      child: Text(
                        message['avatar'],
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                message['user'],
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                message['timestamp'],
                                style: TextStyle(
                                  color: Color(0xFF6C757D),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Text(
                            message['message'],
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        
        // Message input
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE9ECEF), width: 1)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Message #${widget.channelName}',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: Color(0xFFE9ECEF)),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              SizedBox(width: 8),
              IconButton(
                onPressed: _sendMessage,
                icon: Icon(Icons.send, color: Theme.of(context).primaryColor),
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor.withAlpha(50),
                  shape: CircleBorder(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getAvatarColor(String avatar) {
    final colors = [
      Color(0xFF5865F2), // Blue
      Color(0xFF57F287), // Green
      Color(0xFFFEE75C), // Yellow
      Color(0xFFEB459E), // Pink
      Color(0xFFED4245), // Red
      Color(0xFF3BA55C), // Dark Green
    ];
    return colors[avatar.codeUnitAt(0) % colors.length];
  }
} 