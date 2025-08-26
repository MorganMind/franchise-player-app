import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'core/supabase/supabase_init.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Use path URLs instead of hash URLs for web
  setUrlStrategy(PathUrlStrategy());
  
  await initSupabase();
  runApp(const ProviderScope(child: FranchisePlayerApp()));
} 