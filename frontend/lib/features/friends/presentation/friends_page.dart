import 'package:flutter/material.dart';

class FriendsPage extends StatelessWidget {
  const FriendsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy friends
    final pending = ['UserA'];
    final accepted = ['Nash', 'Bot'];
    return Scaffold(
      appBar: AppBar(title: const Text('Friends')),
      body: ListView(
        children: [
          ListTile(title: const Text('Pending'), tileColor: Colors.yellow[100]),
          ...pending.map((f) => ListTile(title: Text(f), trailing: Row(mainAxisSize: MainAxisSize.min, children: [IconButton(icon: const Icon(Icons.check), onPressed: () {}), IconButton(icon: const Icon(Icons.close), onPressed: () {})]))),
          const Divider(),
          ListTile(title: const Text('Accepted'), tileColor: Colors.green[100]),
          ...accepted.map((f) => ListTile(title: Text(f), trailing: const Icon(Icons.message))),
          const Divider(),
          const ListTile(
            title: TextField(decoration: InputDecoration(hintText: 'Add friend by username')), trailing: Icon(Icons.person_add),
          ),
        ],
      ),
    );
  }
} 