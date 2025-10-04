import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  // Initialize Supabase (you'll need to add your credentials)
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );

  final supabase = Supabase.instance.client;

  try {
    // Query all uploads
    final response = await supabase
        .from('json_uploads')
        .select('*')
        .order('uploaded_at', ascending: false);

    print('=== UPLOADED ROSTER DATA ===');
    print('Total uploads: ${response.length}');
    
    for (int i = 0; i < response.length; i++) {
      final upload = response[i];
      print('\n--- Upload ${i + 1} ---');
      print('ID: ${upload['id']}');
      print('User ID: ${upload['user_id']}');
      print('Uploaded at: ${upload['uploaded_at']}');
      
      final payload = upload['payload'] as List;
      print('Number of players: ${payload.length}');
      
      // Group players by franchise
      final franchiseCounts = <String, int>{};
      for (final player in payload) {
        final franchiseId = player['franchiseId'] ?? 'unknown';
        franchiseCounts[franchiseId] = (franchiseCounts[franchiseId] ?? 0) + 1;
      }
      
      print('Franchise distribution:');
      franchiseCounts.forEach((franchiseId, count) {
        print('  $franchiseId: $count players');
      });
      
      // Show first few players from each franchise
      for (final franchiseId in franchiseCounts.keys) {
        final franchisePlayers = payload.where((p) => p['franchiseId'] == franchiseId).take(3).toList();
        print('\n  First 3 players in $franchiseId:');
        for (final player in franchisePlayers) {
          print('    - ${player['firstName']} ${player['lastName']} (${player['position']}) - OVR: ${player['playerBestOvr']}');
        }
      }
    }
    
  } catch (e) {
    print('Error querying uploads: $e');
  }
}
