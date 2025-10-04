import 'package:flutter/material.dart';

class TransactionsPage extends StatelessWidget {
  const TransactionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transactions')),
      body: const Center(
        child: Card(
          margin: EdgeInsets.all(32),
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Text('Recent trades, signings, and releases will be shown here.', style: TextStyle(fontSize: 20)),
          ),
        ),
      ),
    );
  }
} 