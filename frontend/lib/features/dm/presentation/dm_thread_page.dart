import 'package:flutter/material.dart';

class DMThreadPage extends StatelessWidget {
  final String threadId;
  const DMThreadPage({required this.threadId});

  @override
  Widget build(BuildContext context) {
    // Dummy messages
    final messages = [
      {'user': 'Nash', 'content': 'Hey!'},
      {'user': 'Bot', 'content': 'Hello!'},
    ];
    return Scaffold(
      appBar: AppBar(title: Text('DM $threadId')),
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
                Expanded(child: TextField(decoration: InputDecoration(hintText: 'Type a message...'))),
                IconButton(onPressed: () {}, icon: Icon(Icons.send)),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 