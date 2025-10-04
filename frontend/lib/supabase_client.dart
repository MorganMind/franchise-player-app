import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> initSupabase() async {
  await Supabase.initialize(
    url: 'https://fxbpsuisqzffyggihvin.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ4YnBzdWlzcXpmZnlnZ2lodmluIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTEwMzkwNTMsImV4cCI6MjA2NjYxNTA1M30.HxGXe3Jn7HV6GFeLXtvi5tTeqPYG092ZstmrEkpA8mw',
  );
  
  // Set up auth state listener
  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    print('Auth state changed: ${data.event}');
    print('User: ${data.session?.user.email ?? 'None'}');
    
    // Handle specific auth events
    switch (data.event) {
      case AuthChangeEvent.signedIn:
        print('User signed in successfully');
        break;
      case AuthChangeEvent.signedOut:
        print('User signed out');
        break;
      case AuthChangeEvent.tokenRefreshed:
        print('Token refreshed');
        break;
      case AuthChangeEvent.userUpdated:
        print('User updated');
        break;
      case AuthChangeEvent.userDeleted:
        print('User deleted');
        break;
      case AuthChangeEvent.mfaChallengeVerified:
        print('MFA challenge verified');
        break;
      case AuthChangeEvent.passwordRecovery:
        print('Password recovery');
        break;
      default:
        print('Unknown auth event: ${data.event}');
    }
  });
}

final supabase = Supabase.instance.client; 