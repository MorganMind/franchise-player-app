import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Dummy settings
    bool notifications = true;
    bool darkMode = false;
    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            value: notifications,
            onChanged: (v) {},
            title: Text('Enable Notifications'),
          ),
          SwitchListTile(
            value: darkMode,
            onChanged: (v) {},
            title: Text('Dark Mode'),
          ),
          ListTile(title: Text('Account Preferences'), onTap: () {}),
        ],
      ),
    );
  }
} 