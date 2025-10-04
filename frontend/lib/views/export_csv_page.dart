import 'package:flutter/material.dart';

class ExportCsvPage extends StatelessWidget {
  const ExportCsvPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Export CSV')),
      body: const Center(
        child: Card(
          margin: EdgeInsets.all(32),
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Text('Export franchise data as CSV will be available here.', style: TextStyle(fontSize: 20)),
          ),
        ),
      ),
    );
  }
} 