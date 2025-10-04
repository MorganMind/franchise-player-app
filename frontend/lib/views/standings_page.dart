import 'package:flutter/material.dart';

class StandingsPage extends StatelessWidget {
  const StandingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Standings')),
      body: const Center(
        child: Card(
          margin: EdgeInsets.all(32),
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Text('Team standings will be shown here.', style: TextStyle(fontSize: 20)),
          ),
        ),
      ),
    );
  }
} 