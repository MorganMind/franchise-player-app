import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/supabase/supabase_init.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Use path URLs instead of hash URLs for web
  setUrlStrategy(PathUrlStrategy());
  
  await initSupabase();
  
  // Handle OAuth callbacks
  supabase.auth.onAuthStateChange.listen((data) {
    print('🔐 Auth state changed: ${data.event}');
    if (data.event == AuthChangeEvent.signedIn) {
      print('✅ User signed in successfully');
    } else if (data.event == AuthChangeEvent.signedOut) {
      print('👋 User signed out');
    }
  });
  
  runApp(const ProviderScope(child: FranchisePlayerApp()));
} 