import 'package:flutter/material.dart';

class ChannelPage extends StatelessWidget {
  final String serverId;
  final String franchiseId;
  final String channelId;
  const ChannelPage({super.key, required this.serverId, required this.franchiseId, required this.channelId});

  @override
  Widget build(BuildContext context) {
    // Dummy messages
    final messages = [
      {'user': 'Nash', 'content': 'Welcome to the channel!'},
      {'user': 'Bot', 'content': 'This is a placeholder.'},
    ];
    return Scaffold(
      appBar: AppBar(title: Text('Channel $channelId')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: messages.map((m) => ListTile(
                title: Text(m['user']!),
                subtitle: Text(m['content']!),
              )).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                const Expanded(child: TextField(decoration: InputDecoration(hintText: 'Type a message...'))),
                IconButton(onPressed: () {}, icon: const Icon(Icons.send)),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 