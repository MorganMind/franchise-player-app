import 'package:flutter/material.dart';

class DMInboxPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Dummy DM threads
    final threads = [
      {'id': 'dm1', 'name': 'Nash'},
      {'id': 'dm2', 'name': 'Bot'},
    ];
    return Scaffold(
      appBar: AppBar(title: Text('Direct Messages')),
      body: ListView.builder(
        itemCount: threads.length,
        itemBuilder: (context, index) {
          final thread = threads[index];
          return ListTile(
            title: Text(thread['name']!),
            onTap: () {
              Navigator.of(context).pushNamed('/dm/${thread['id']}');
            },
          );
        },
      ),
    );
  }
} 