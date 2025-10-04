import 'package:flutter/material.dart';

class RulesPage extends StatelessWidget {
  const RulesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('League Rules')),
      body: const Center(
        child: Card(
          margin: EdgeInsets.all(32),
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Text('League rules will be listed here.', style: TextStyle(fontSize: 20)),
          ),
        ),
      ),
    );
  }
} 