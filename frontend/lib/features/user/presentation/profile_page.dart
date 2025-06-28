import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Dummy user info
    final user = {'username': 'Nash', 'bio': 'Madden enthusiast', 'avatar': null};
    return Scaffold(
      appBar: AppBar(title: Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(radius: 40, child: Text(user['username']![0])),
            SizedBox(height: 16),
            Text('Username: ${user['username']}'),
            Text('Bio: ${user['bio']}'),
            SizedBox(height: 24),
            ElevatedButton(onPressed: () {}, child: Text('Edit Profile')),
          ],
        ),
      ),
    );
  }
} 