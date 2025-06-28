import 'package:flutter/material.dart';

class VoiceVideoPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Voice/Video Chat')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mic, size: 64),
            SizedBox(height: 16),
            Text('Voice/Video Chat Placeholder (LiveKit integration)'),
          ],
        ),
      ),
    );
  }
} 