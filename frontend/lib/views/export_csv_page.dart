import 'package:flutter/material.dart';

class ExportCsvPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Export CSV')),
      body: Center(
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