import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'dart:html' as html;
import '../models/player.dart';
import '../supabase_client.dart';

// Player state notifier
class PlayerNotifier extends StateNotifier<AsyncValue<List<Player>>> {
  PlayerNotifier() : super(const AsyncValue.loading()) {
    _loadPlayers();
  }

  List<Player> _allPlayers = [];
  bool _useLocalData = false;

  bool get useLocalData => _useLocalData;

  void _loadPlayers() async {
    try {
      await _loadFromStorage();
      await _loadFromSupabase();
      state = AsyncValue.data(_allPlayers);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> _loadFromStorage() async {
    final rostersJson = html.window.localStorage['rosters'];
    print('Loading from localStorage: ${rostersJson != null ? 'Data found' : 'No data'}');
    if (rostersJson != null) {
      try {
        final List<dynamic> jsonList = json.decode(rostersJson);
        _allPlayers = jsonList.map((e) => Player.fromJson(e)).toList();
        print('Loaded ${_allPlayers.length} players from localStorage');
      } catch (e) {
        print('Error parsing rosters from localStorage: $e');
      }
    }
  }

  Future<void> _loadFromSupabase() async {
    try {
      print('Loading from Supabase...');
      final response = await supabase
          .from('json_uploads')
          .select('payload')
          .order('uploaded_at', ascending: false)
          .limit(1)
          .maybeSingle();
      
      print('Supabase response: ${response != null ? 'Data found' : 'No data'}');
      
      if (response != null && response['payload'] != null) {
        final payload = response['payload'];
        List<Player> supabasePlayers = [];
        
        if (payload is List) {
          supabasePlayers = payload.map<Player>((e) => Player.fromJson(e)).toList();
        } else if (payload is Map && payload['rosters'] is List) {
          supabasePlayers = (payload['rosters'] as List).map<Player>((e) => Player.fromJson(e)).toList();
        }
        
        print('Parsed ${supabasePlayers.length} players from Supabase');
        
        // Use Supabase data if available and not using local data
        if (!_useLocalData && supabasePlayers.isNotEmpty) {
          _allPlayers = supabasePlayers;
          print('Using Supabase data (${_allPlayers.length} players)');
        } else if (_useLocalData) {
          print('Using local data (${_allPlayers.length} players)');
        } else {
          print('No Supabase data available, keeping existing data (${_allPlayers.length} players)');
        }
      } else {
        print('No Supabase data found');
      }
    } catch (e) {
      print('Error fetching from Supabase: $e');
    }
  }

  void toggleDataSource() {
    _useLocalData = !_useLocalData;
    _loadPlayers(); // Reload with new data source
  }

  void setUseLocalData(bool useLocal) {
    _useLocalData = useLocal;
    html.window.localStorage['useLocalData'] = useLocal.toString();
    _loadPlayers();
  }

  List<Player> searchPlayers(String query) {
    if (query.isEmpty) return _allPlayers;
    
    final lowercaseQuery = query.toLowerCase();
    return _allPlayers.where((player) {
      return player.fullName.toLowerCase().contains(lowercaseQuery) ||
             player.position.toLowerCase().contains(lowercaseQuery) ||
             (player.team ?? '').toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  List<Player> getPlayersByTeam(String? team) {
    if (team == null) return _allPlayers;
    return _allPlayers.where((player) => player.team == team).toList();
  }

  List<Player> getFreeAgents() {
    return _allPlayers.where((player) => player.isFreeAgent).toList();
  }

  List<Player> getPlayersByPosition(String position) {
    return _allPlayers.where((player) => player.position == position).toList();
  }

  Map<String, List<Player>> getPlayersByTeamGrouped() {
    final Map<String, List<Player>> teams = {};
    for (final player in _allPlayers) {
      if (player.team != null && player.team!.isNotEmpty) {
        teams.putIfAbsent(player.team!, () => []).add(player);
      }
    }
    return teams;
  }

  Player? getPlayerById(String id) {
    try {
      return _allPlayers.firstWhere((player) => player.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> refreshData() async {
    state = const AsyncValue.loading();
    _loadPlayers();
  }
}

// Player provider
final playerProvider = StateNotifierProvider<PlayerNotifier, AsyncValue<List<Player>>>((ref) {
  return PlayerNotifier();
});

// Convenience providers
final allPlayersProvider = Provider<List<Player>>((ref) {
  final playersState = ref.watch(playerProvider);
  return playersState.when(
    data: (players) => players,
    loading: () => [],
    error: (_, __) => [],
  );
});

final freeAgentsProvider = Provider<List<Player>>((ref) {
  final players = ref.watch(allPlayersProvider);
  return players.where((player) => player.isFreeAgent).toList();
});

final teamsProvider = Provider<Map<String, List<Player>>>((ref) {
  final players = ref.watch(allPlayersProvider);
  final Map<String, List<Player>> teams = {};
  for (final player in players) {
    if (player.team != null && player.team!.isNotEmpty) {
      teams.putIfAbsent(player.team!, () => []).add(player);
    }
  }
  return teams;
});

final useLocalDataProvider = Provider<bool>((ref) {
  final stored = html.window.localStorage['useLocalData'];
  return stored == 'true';
});

// Search provider
final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = Provider<List<Player>>((ref) {
  final query = ref.watch(searchQueryProvider);
  final players = ref.watch(allPlayersProvider);
  
  if (query.isEmpty) return players;
  
  final lowercaseQuery = query.toLowerCase();
  return players.where((player) {
    return player.fullName.toLowerCase().contains(lowercaseQuery) ||
           player.position.toLowerCase().contains(lowercaseQuery) ||
           (player.team ?? '').toLowerCase().contains(lowercaseQuery);
  }).toList();
}); 