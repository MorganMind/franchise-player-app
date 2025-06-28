import 'package:flutter/material.dart';

class ArchivedFranchisePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Archived Franchise')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.archive, size: 64),
            SizedBox(height: 16),
            Text('Archived Franchise Placeholder'),
          ],
        ),
      ),
    );
  }
} 