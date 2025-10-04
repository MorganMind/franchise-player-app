import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy settings
    bool notifications = true;
    bool darkMode = false;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            value: notifications,
            onChanged: (v) {},
            title: const Text('Enable Notifications'),
          ),
          SwitchListTile(
            value: darkMode,
            onChanged: (v) {},
            title: const Text('Dark Mode'),
          ),
          ListTile(title: const Text('Account Preferences'), onTap: () {}),
          const Divider(),
          ListTile(
            title: const Text('Valuation Settings'),
            subtitle: const Text('Configure player valuation parameters'),
            leading: const Icon(Icons.calculate),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => context.go('/valuation-settings'),
          ),
        ],
      ),
    );
  }
} 