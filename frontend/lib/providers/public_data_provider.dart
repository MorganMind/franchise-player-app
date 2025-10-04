import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import '../models/player.dart';
import '../supabase_client.dart';

// Public data provider that works without authentication
class PublicDataNotifier extends StateNotifier<AsyncValue<List<Player>>> {
  PublicDataNotifier() : super(const AsyncValue.loading()) {
    _loadPublicData();
  }

  List<Player> _allPlayers = [];

  Future<void> _loadPublicData() async {
    try {
      state = const AsyncValue.loading();
      
      // Try to load from Supabase with public access
      await _loadFromSupabase();
      
      if (_allPlayers.isNotEmpty) {
        state = AsyncValue.data(_allPlayers);
      } else {
        // Fallback to hardcoded data if no Supabase data
        _loadHardcodedData();
        state = AsyncValue.data(_allPlayers);
      }
          } catch (error, stackTrace) {
        print('Error loading public data: $error');
        // Fallback to hardcoded data on error
        _loadHardcodedData();
        state = AsyncValue.data(_allPlayers);
      }
  }



  Future<void> _loadFromSupabase() async {
    try {
      print('Loading public data from Supabase...');
      
      // First, try to query the versioned_uploads table directly to see if RLS is the issue
      print('Testing direct query to versioned_uploads...');
      final directResponse = await supabase
          .from('versioned_uploads')
          .select('*')
          .eq('version_status', 'live')
          .eq('upload_type', 'roster')
          .order('uploaded_at', ascending: false);
      
      print('Direct versioned_uploads response: Found ${directResponse.length} live roster uploads');
      
      // Use the anonymous client to access public data - get live versions only
      print('Testing live_uploads view...');
      final response = await supabase
          .from('live_uploads')
          .select('*')
          .eq('upload_type', 'roster')
          .order('uploaded_at', ascending: false);
      
      print('Public Supabase response: Found ${response.length} live roster uploads');
      
      // Use the response that has data
      final dataToProcess = response.isNotEmpty ? response : directResponse;
      print('Using data from: ${response.isNotEmpty ? 'live_uploads view' : 'versioned_uploads table'}');
      
      List<Player> allSupabasePlayers = [];
      
      for (int i = 0; i < dataToProcess.length; i++) {
        final upload = dataToProcess[i];
        print('\n--- Processing Live Upload ${i + 1} ---');
        print('Upload ID: ${upload['id']}');
        print('User ID: ${upload['user_id']}');
        print('Franchise ID: ${upload['franchise_id']}');
        print('Upload Type: ${upload['upload_type']}');
        print('Uploaded at: ${upload['uploaded_at']}');
        
        if (upload['payload'] != null) {
          final payload = upload['payload'];
          List<Player> uploadPlayers = [];
          
          if (payload is List) {
            uploadPlayers = payload.map<Player>((e) => Player.fromJson(e)).toList();
          } else if (payload is Map && payload['rosters'] is List) {
            uploadPlayers = (payload['rosters'] as List).map<Player>((e) => Player.fromJson(e)).toList();
          }
          
          print('Parsed ${uploadPlayers.length} players from this live upload');
          
          // Group players by franchise for this upload
          final franchiseCounts = <String, int>{};
          for (final player in uploadPlayers) {
            franchiseCounts[player.franchiseId] = (franchiseCounts[player.franchiseId] ?? 0) + 1;
          }
          
          print('Franchise distribution in this live upload:');
          franchiseCounts.forEach((franchiseId, count) {
            print('  $franchiseId: $count players');
          });
          
          // Show first few players from each franchise
          for (final franchiseId in franchiseCounts.keys) {
            final franchisePlayers = uploadPlayers.where((p) => p.franchiseId == franchiseId).take(3).toList();
            print('  First 3 players in $franchiseId:');
            for (final player in franchisePlayers) {
              print('    - ${player.firstName} ${player.lastName} (${player.position}) - OVR: ${player.playerBestOvr}');
            }
          }
          
          allSupabasePlayers.addAll(uploadPlayers);
        }
      }
      
      if (allSupabasePlayers.isNotEmpty) {
        _allPlayers = allSupabasePlayers;
        print('\n=== TOTAL SUMMARY ===');
        print('Total players across all live uploads: ${_allPlayers.length}');
        
        // Debug: Log overall franchise distribution
        final franchiseCounts = <String, int>{};
        for (final player in allSupabasePlayers) {
          franchiseCounts[player.franchiseId] = (franchiseCounts[player.franchiseId] ?? 0) + 1;
        }
        print('Overall franchise distribution: $franchiseCounts');
        
        return;
      }
      
      print('No public Supabase data available');
    } catch (e) {
      print('Error fetching public data from Supabase: $e');
    }
  }

  void _loadHardcodedData() {
    // TODO: Remove hardcoded data - use real database data only
    print('ERROR: Hardcoded data should not be used. Implement real database queries.');
    _allPlayers = [];
  }

  List<Player> searchPlayers(String query) {
    if (query.isEmpty) return _allPlayers;
    
    final lowercaseQuery = query.toLowerCase();
    return _allPlayers.where((player) {
      return player.fullName.toLowerCase().contains(lowercaseQuery) ||
             player.position.toLowerCase().contains(lowercaseQuery) ||
             (player.team?.toLowerCase().contains(lowercaseQuery) ?? false);
    }).toList();
  }

  Player? getPlayerById(String id) {
    try {
      return _allPlayers.firstWhere((player) => player.id == id);
    } catch (e) {
      return null;
    }
  }

  void refreshData() {
    _loadPublicData();
  }
}

// Public data provider
final publicDataProvider = StateNotifierProvider<PublicDataNotifier, AsyncValue<List<Player>>>((ref) {
  return PublicDataNotifier();
});

// Public search results provider
final publicSearchResultsProvider = Provider<List<Player>>((ref) {
  final searchQuery = ref.watch(searchQueryProvider);
  final players = ref.watch(publicDataProvider);
  
  return players.when(
    data: (players) {
      final notifier = ref.read(publicDataProvider.notifier);
      return notifier.searchPlayers(searchQuery);
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// Search query provider (shared with authenticated version)
final searchQueryProvider = StateProvider<String>((ref) => '');



