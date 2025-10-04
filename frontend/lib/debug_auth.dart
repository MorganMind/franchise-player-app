import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://fxbpsuisqzffyggihvin.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ4YnBzdWlzcXpmZnlnZ2lodmluIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTEwMzkwNTMsImV4cCI6MjA2NjYxNTA1M30.HxGXe3Jn7HV6GFeLXtvi5tTeqPYG092ZstmrEkpA8mw',
  );

  print('🔍 Debugging Supabase Authentication...\n');

  try {
    // Check current session
    final session = Supabase.instance.client.auth.currentSession;
    print('📋 Current Session:');
    print('  - User: ${session?.user.email}');
    print('  - User ID: ${session?.user.id}');
    print('  - Access Token: ${session?.accessToken.substring(0, 20)}...');
    print('  - Refresh Token: ${session?.refreshToken?.substring(0, 20)}...');
    print('  - Expires At: ${session?.expiresAt}');
    print('  - Is Valid: ${session != null}');

    if (session != null) {
      print('\n✅ User is authenticated!');
      print('🔑 JWT Token: ${session.accessToken}');
    } else {
      print('\n❌ No active session found');
    }

    // Test auth state listener
    print('\n🎧 Setting up auth state listener...');
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      print('🔄 Auth state changed: ${data.event}');
      print('  - User: ${data.session?.user.email}');
      print('  - Event: ${data.event}');
    });

  } catch (e) {
    print('❌ Error: $e');
  }
} 