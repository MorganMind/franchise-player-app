import 'package:flutter/material.dart';

class RankingsPage extends StatelessWidget {
  const RankingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rankings')),
      body: const Center(
        child: Card(
          margin: EdgeInsets.all(32),
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Text('Power rankings and sortable lists will be shown here.', style: TextStyle(fontSize: 20)),
          ),
        ),
      ),
    );
  }
} 