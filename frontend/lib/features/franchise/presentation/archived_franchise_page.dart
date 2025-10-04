import 'package:flutter/material.dart';

class ArchivedFranchisePage extends StatelessWidget {
  const ArchivedFranchisePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Archived Franchise')),
      body: const Center(
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