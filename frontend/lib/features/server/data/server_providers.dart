import 'package:flutter_riverpod/flutter_riverpod.dart';

// Mock server data
final mockServers = [
  {'id': '1', 'name': 'Madden League Alpha', 'icon': '🏈', 'color': '#5865F2'},
  {'id': '2', 'name': 'Franchise Player Support', 'icon': '🛠️', 'color': '#57F287'},
  {'id': '3', 'name': 'NFL Fans United', 'icon': '🏆', 'color': '#FEE75C'},
  {'id': '4', 'name': 'Draft Day', 'icon': '📋', 'color': '#EB459E'},
  {'id': '5', 'name': 'Pro Bowl League', 'icon': '⭐', 'color': '#ED4245'},
  {'id': '6', 'name': 'Rookie Season', 'icon': '🌱', 'color': '#3BA55C'},
];

// Current active server ID provider
final currentServerIdProvider = StateProvider<String?>((ref) => null);

// Server list provider
final serversProvider = Provider<List<Map<String, String>>>((ref) => mockServers);

// Current active server provider
final currentServerProvider = Provider<Map<String, String>?>((ref) {
  final currentId = ref.watch(currentServerIdProvider);
  final servers = ref.watch(serversProvider);
  if (currentId == null) return null;
  return servers.firstWhere((server) => server['id'] == currentId);
});

// Server navigation state provider
final serverNavigationProvider = StateNotifierProvider<ServerNavigationNotifier, ServerNavigationState>((ref) {
  return ServerNavigationNotifier();
});

class ServerNavigationState {
  final String? currentServerId;
  final bool isLoading;
  final String? error;

  ServerNavigationState({
    this.currentServerId,
    this.isLoading = false,
    this.error,
  });

  ServerNavigationState copyWith({
    String? currentServerId,
    bool? isLoading,
    String? error,
  }) {
    return ServerNavigationState(
      currentServerId: currentServerId ?? this.currentServerId,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class ServerNavigationNotifier extends StateNotifier<ServerNavigationState> {
  ServerNavigationNotifier() : super(ServerNavigationState());

  Future<void> switchServer(String serverId) async {
    state = state.copyWith(isLoading: true, error: null);
    
    // Simulate loading delay
    await Future.delayed(Duration(milliseconds: 300));
    
    state = state.copyWith(
      currentServerId: serverId,
      isLoading: false,
    );
  }

  void setError(String error) {
    state = state.copyWith(error: error, isLoading: false);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
} 