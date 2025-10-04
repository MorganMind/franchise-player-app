import 'package:flutter/material.dart';

class AwardsPage extends StatelessWidget {
  const AwardsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Awards')),
      body: const Center(
        child: Card(
          margin: EdgeInsets.all(32),
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Text('Season and career awards will be shown here.', style: TextStyle(fontSize: 20)),
          ),
        ),
      ),
    );
  }
} 