import 'package:flutter/material.dart';

class FriendsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Dummy friends
    final pending = ['UserA'];
    final accepted = ['Nash', 'Bot'];
    return Scaffold(
      appBar: AppBar(title: Text('Friends')),
      body: ListView(
        children: [
          ListTile(title: Text('Pending'), tileColor: Colors.yellow[100]),
          ...pending.map((f) => ListTile(title: Text(f), trailing: Row(mainAxisSize: MainAxisSize.min, children: [IconButton(icon: Icon(Icons.check), onPressed: () {}), IconButton(icon: Icon(Icons.close), onPressed: () {})]))),
          Divider(),
          ListTile(title: Text('Accepted'), tileColor: Colors.green[100]),
          ...accepted.map((f) => ListTile(title: Text(f), trailing: Icon(Icons.message))),
          Divider(),
          ListTile(
            title: TextField(decoration: InputDecoration(hintText: 'Add friend by username')), trailing: Icon(Icons.person_add),
          ),
        ],
      ),
    );
  }
} 