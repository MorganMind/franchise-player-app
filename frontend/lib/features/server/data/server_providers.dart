import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'server_repository.dart';

// Repository provider
final serverRepositoryProvider = Provider<ServerRepository>((ref) {
  return ServerRepository();
});

// Current active server ID provider
final currentServerIdProvider = StateProvider<String?>((ref) => null);

// Server list provider - now fetches from Supabase
final serversProvider = StateNotifierProvider<ServerListNotifier, AsyncValue<List<Map<String, dynamic>>>>((ref) {
  return ServerListNotifier(ref);
});

class ServerListNotifier extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  final Ref _ref;

  ServerListNotifier(this._ref) : super(const AsyncValue.loading()) {
    _fetchServers();
  }

  Future<void> _fetchServers() async {
    try {
      final repository = _ref.read(serverRepositoryProvider);
      final servers = await repository.getServers();
      state = AsyncValue.data(servers);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void reorderServers(List<Map<String, dynamic>> servers) {
    state = AsyncValue.data(servers);
  }
}

// User's servers provider - fetches servers the user is a member of
final userServersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(serverRepositoryProvider);
  return await repository.getUserServers();
});

// Recent servers provider - fetches recently accessed servers
final recentServersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(serverRepositoryProvider);
  return await repository.getRecentServers(limit: 3);
});

// Current active server provider
final currentServerProvider = Provider<Map<String, dynamic>?>((ref) {
  final currentId = ref.watch(currentServerIdProvider);
  final serversAsync = ref.watch(serversProvider);
  
  if (currentId == null || serversAsync.isLoading || serversAsync.hasError) {
    return null;
  }
  
  final servers = serversAsync.value ?? [];
  try {
    return servers.firstWhere((server) => server['id'] == currentId);
  } catch (e) {
    return null;
  }
});

// Server navigation state provider
final serverNavigationProvider = StateNotifierProvider<ServerNavigationNotifier, ServerNavigationState>((ref) {
  return ServerNavigationNotifier(ref);
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
  final Ref _ref;
  
  ServerNavigationNotifier(this._ref) : super(ServerNavigationState());

  Future<void> switchServer(String serverId) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // Validate that the server exists
      final repository = _ref.read(serverRepositoryProvider);
      final server = await repository.getServerById(serverId);
      
      if (server != null) {
        state = state.copyWith(
          currentServerId: serverId,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          error: 'Server not found',
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to switch server: $e',
        isLoading: false,
      );
    }
  }

  Future<void> createServer({
    required String name,
    String? description,
    String? icon,
    String? color,
    String? serverType,
    String? visibility,
    String? iconUrl,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final repository = _ref.read(serverRepositoryProvider);
      final newServer = await repository.createServer(
        name: name,
        description: description,
        icon: icon,
        color: color,
        serverType: serverType,
        visibility: visibility,
        iconUrl: iconUrl,
      );
      
      if (newServer != null) {
        print('Server created successfully, invalidating providers...');
        // Invalidate the servers provider to refresh the list
        _ref.invalidate(serversProvider);
        _ref.invalidate(userServersProvider);
        
        print('Switching to new server: ${newServer['id']}');
        // Switch to the new server
        await switchServer(newServer['id']);
        
        print('Server creation completed successfully');
      } else {
        print('Failed to create server - newServer is null');
        state = state.copyWith(
          error: 'Failed to create server',
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to create server: $e',
        isLoading: false,
      );
    }
  }

  Future<void> joinServer(String serverId) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final repository = _ref.read(serverRepositoryProvider);
      final success = await repository.joinServer(serverId);
      
      if (success) {
        // Invalidate the user servers provider to refresh the list
        _ref.invalidate(userServersProvider);
        state = state.copyWith(isLoading: false);
      } else {
        state = state.copyWith(
          error: 'Failed to join server',
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to join server: $e',
        isLoading: false,
      );
    }
  }

  Future<void> leaveServer(String serverId) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final repository = _ref.read(serverRepositoryProvider);
      final success = await repository.leaveServer(serverId);
      
      if (success) {
        // Invalidate the user servers provider to refresh the list
        _ref.invalidate(userServersProvider);
        
        // If we're leaving the current server, clear the selection
        if (state.currentServerId == serverId) {
          state = state.copyWith(
            currentServerId: null,
            isLoading: false,
          );
        } else {
          state = state.copyWith(isLoading: false);
        }
      } else {
        state = state.copyWith(
          error: 'Failed to leave server',
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to leave server: $e',
        isLoading: false,
      );
    }
  }

  void setError(String error) {
    state = state.copyWith(error: error, isLoading: false);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void clearCurrentServer() {
    state = state.copyWith(currentServerId: null);
  }

  void refreshServers() {
    _ref.invalidate(serversProvider);
    _ref.invalidate(userServersProvider);
  }

  Future<void> reorderServers(List<String> serverIds) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final repository = _ref.read(serverRepositoryProvider);
      final success = await repository.reorderServers(serverIds);
      
      if (success) {
        // Invalidate all server-related providers to refresh the lists
        _ref.invalidate(serversProvider);
        _ref.invalidate(userServersProvider);
        _ref.invalidate(recentServersProvider);
        state = state.copyWith(isLoading: false);
      } else {
        state = state.copyWith(
          error: 'Failed to reorder servers',
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to reorder servers: $e',
        isLoading: false,
      );
    }
  }

  Future<void> deleteServer(String serverId) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final repository = _ref.read(serverRepositoryProvider);
      final success = await repository.deleteServer(serverId);
      
      if (success) {
        // Invalidate all server-related providers to refresh the lists
        _ref.invalidate(serversProvider);
        _ref.invalidate(userServersProvider);
        _ref.invalidate(recentServersProvider);
        
        // If we're deleting the current server, clear the selection
        if (state.currentServerId == serverId) {
          state = state.copyWith(
            currentServerId: null,
            isLoading: false,
          );
        } else {
          state = state.copyWith(isLoading: false);
        }
      } else {
        state = state.copyWith(
          error: 'Failed to delete server',
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to delete server: $e',
        isLoading: false,
      );
    }
  }
} 