import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DebugOAuthPage extends StatefulWidget {
  const DebugOAuthPage({super.key});

  @override
  State<DebugOAuthPage> createState() => _DebugOAuthPageState();
}

class _DebugOAuthPageState extends State<DebugOAuthPage> {
  String _debugInfo = '';

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  void _checkAuthState() {
    final user = Supabase.instance.client.auth.currentUser;
    setState(() {
      _debugInfo = '''
Current User: ${user?.id ?? 'null'}
Email: ${user?.email ?? 'null'}
Provider: ${user?.appMetadata['provider'] ?? 'null'}
Created: ${user?.createdAt ?? 'null'}
Last Sign In: ${user?.lastSignInAt ?? 'null'}
      ''';
    });
  }

  Future<void> _testDiscordOAuth() async {
    try {
      setState(() {
        _debugInfo += '\n\n🔐 Starting Discord OAuth...';
      });

      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.discord,
        authScreenLaunchMode: LaunchMode.externalApplication,
        redirectTo: 'https://franchise-player-app.onrender.com',
      );

      setState(() {
        _debugInfo += '\n✅ OAuth request sent successfully';
      });
    } catch (e) {
      setState(() {
        _debugInfo += '\n❌ OAuth error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('OAuth Debug')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'OAuth Debug Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _debugInfo,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _testDiscordOAuth,
              child: const Text('Test Discord OAuth'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _checkAuthState,
              child: const Text('Refresh Auth State'),
            ),
          ],
        ),
      ),
    );
  }
}
