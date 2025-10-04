import 'package:supabase_flutter/supabase_flutter.dart';
import '../../env.dart';

late final SupabaseClient supabase;

Future<void> initSupabase() async {
  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
  );
  supabase = Supabase.instance.client;
} 