import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/supabase/supabase_init.dart';

final userSearchProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, query) async {
  final response = await supabase.rpc('search_users', params: {'search_query': query});
  return List<Map<String, dynamic>>.from(response);
}); 