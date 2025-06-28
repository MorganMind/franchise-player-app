import 'package:supabase_flutter/supabase_flutter.dart';

late final SupabaseClient supabase;

Future<void> initSupabase() async {
  await Supabase.initialize(
    url: 'https://fxbpsuisqzffyggihvin.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ4YnBzdWlzcXpmZnlnZ2lodmluIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTEwMzkwNTMsImV4cCI6MjA2NjYxNTA1M30.HxGXe3Jn7HV6GFeLXtvi5tTeqPYG092ZstmrEkpA8mw',
  );
  supabase = Supabase.instance.client;
} 