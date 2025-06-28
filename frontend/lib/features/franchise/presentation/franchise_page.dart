import 'package:flutter/material.dart';

class FranchisePage extends StatelessWidget {
  final String serverId;
  final String franchiseId;
  const FranchisePage({required this.serverId, required this.franchiseId});

  @override
  Widget build(BuildContext context) {
    // Dummy channels
    final channels = [
      {'id': 'c1', 'name': 'text-chat'},
      {'id': 'c2', 'name': 'stats'},
      {'id': 'c3', 'name': 'schedule'},
    ];
    return Scaffold(
      appBar: AppBar(title: Text('Franchise $franchiseId')),
      body: ListView(
        children: channels.map((c) => ListTile(
          title: Text(c['name']!),
          onTap: () {
            Navigator.of(context).pushNamed('/home/server/$serverId/franchise/$franchiseId/channel/${c['id']}');
          },
        )).toList(),
      ),
    );
  }
} 