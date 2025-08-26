import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'dart:html' as html;
import 'features/theme/app_theme.dart';
import 'features/discovery/user_search_page.dart';
import 'features/channels/channel_sidebar.dart';
import 'features/dm/dm_thread_page.dart';
import 'features/channels/channel_content_page.dart';
import 'features/home/presentation/home_welcome_page.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'features/server/presentation/widgets/server_side_nav.dart';
import 'features/server/presentation/widgets/server_icon_widget.dart';
import 'features/server/presentation/widgets/server_settings_dialog.dart';
import 'features/server/presentation/server_page.dart';
import 'features/dm/presentation/dm_inbox_page.dart';
import 'login_page.dart';
import 'features/franchise/presentation/widgets/franchise_sidebar.dart';
import 'features/franchise/presentation/pages/franchise_player_page.dart';
import 'features/franchise/presentation/pages/franchise_finder_page.dart';
import 'views/rosters_home.dart';
import 'views/player_profile.dart';
import 'views/franchise_page.dart';
import 'views/public_franchise_page.dart';
import 'views/public_player_profile.dart';
import 'views/franchise_management_page.dart';
import 'views/not_found_page.dart';
import 'views/test_routing.dart';
import 'features/server/data/server_providers.dart';
import 'providers/public_data_provider.dart';
import 'providers/franchise_providers.dart';
import 'models/player.dart';
import 'models/franchise.dart';
import 'features/channels/server_channel_content.dart';
import 'features/channels/franchise_channel_content.dart';
// import 'features/franchise/presentation/pages/franchise_content_page.dart';



class FranchisePlayerApp extends ConsumerWidget {
  const FranchisePlayerApp({super.key});

  // Helper methods for URL routing
  static String _getServerIdFromName(String serverNameOrId) {
    // Check if it's already an ID (contains dashes and is long)
    if (serverNameOrId.contains('-') && serverNameOrId.length > 20) {
      return serverNameOrId; // It's already an ID
    }
    
    // Map friendly names to server IDs
    switch (serverNameOrId.toLowerCase()) {
      case 'madden-league':
        return '587c945e-048c-40ac-aa15-6b99dd61d4b7';
      case 'tech-team':
        return '660e8400-e29b-41d4-a716-446655440002';
      default:
        return serverNameOrId; // Fallback to original if not found
    }
  }

  static String _getFranchiseIdFromName(String franchiseNameOrId) {
    // Check if it's already an ID (contains dashes and is long)
    if (franchiseNameOrId.contains('-') && franchiseNameOrId.length > 20) {
      return franchiseNameOrId; // It's already an ID
    }
    
    // Convert URL-safe name back to readable name
    final readableName = franchiseNameOrId.replaceAll('-', ' ');
    
    // For now, return the original name as fallback
    // This function is static and can't access the database directly
    // The real implementation would need to be non-static or use a different approach
    return franchiseNameOrId;
  }

  static String _getServerNameFromId(String serverId) {
    // Map server IDs to friendly names
    switch (serverId) {
      case '587c945e-048c-40ac-aa15-6b99dd61d4b7':
        return 'madden-league';
      case '660e8400-e29b-41d4-a716-446655440002':
        return 'tech-team';
      default:
        return serverId; // Fallback to ID if no mapping found
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final themeMode = ref.watch(themeProvider);

    final GoRouter router = GoRouter(
      initialLocation: '/',
      routes: [
        // Home route
        GoRoute(
          path: '/',
          builder: (context, state) => const HomePage(initialServerId: null),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: '/test-routing',
          builder: (context, state) => const TestRoutingPage(),
        ),
        // DM routes
        GoRoute(
          path: '/dm/:threadId',
          builder: (context, state) {
            final threadId = state.pathParameters['threadId']!;
            return HomePage(initialServerId: null, initialDmThreadId: threadId);
          },
        ),
        // Server routes (support both ID and name-based URLs)
        GoRoute(
          path: '/server/:serverId',
          builder: (context, state) {
            final serverIdOrName = state.pathParameters['serverId']!;
            final serverId = FranchisePlayerApp._getServerIdFromName(serverIdOrName);
            print('🔍 DEBUG: Server route builder - serverIdOrName: $serverIdOrName, resolved serverId: $serverId');
            return HomePage(initialServerId: serverId);
          },
        ),
        GoRoute(
          path: '/server/:serverId/channel/:channelId',
          builder: (context, state) {
            final serverIdOrName = state.pathParameters['serverId']!;
            final channelId = state.pathParameters['channelId']!;
            final serverId = FranchisePlayerApp._getServerIdFromName(serverIdOrName);
            return HomePage(initialServerId: serverId, initialChannelId: channelId);
          },
        ),
        // Franchise routes (support both ID and name-based URLs)
        GoRoute(
          path: '/franchise/:franchiseId',
          builder: (context, state) {
            final franchiseIdOrName = state.pathParameters['franchiseId']!;
            // For now, use the name directly as the franchise ID
            // In a real implementation, this would search the database for the franchise by name
            return HomePage(initialFranchiseId: franchiseIdOrName);
          },
        ),
        GoRoute(
          path: '/franchise/:franchiseId/:channelId',
          builder: (context, state) {
            final franchiseIdOrName = state.pathParameters['franchiseId']!;
            final channelId = state.pathParameters['channelId']!;
            // For now, use the name directly as the franchise ID
            // In a real implementation, this would search the database for the franchise by name
            return HomePage(initialFranchiseId: franchiseIdOrName, initialChannelId: channelId);
          },
        ),
        GoRoute(
          path: '/franchise/:franchiseId/player/:playerId',
          builder: (context, state) {
            final franchiseIdOrName = state.pathParameters['franchiseId']!;
            final playerId = state.pathParameters['playerId']!;
            return HomePage(
              initialFranchiseId: franchiseIdOrName,
              initialPlayerId: playerId,
            );
          },
        ),
        GoRoute(
          path: '/server/:serverId/franchise/:franchiseId/player/:playerId',
          builder: (context, state) {
            final serverIdOrName = state.pathParameters['serverId']!;
            final franchiseIdOrName = state.pathParameters['franchiseId']!;
            final playerId = state.pathParameters['playerId']!;
            final serverId = FranchisePlayerApp._getServerIdFromName(serverIdOrName);
            return HomePage(
              initialServerId: serverId,
              initialFranchiseId: franchiseIdOrName,
              initialPlayerId: playerId,
            );
          },
        ),

        // Franchise management route
        GoRoute(
          path: '/franchise-management',
          builder: (context, state) => const FranchiseManagementPage(),
        ),
        // Franchise finder route
        GoRoute(
          path: '/franchise-finder',
          builder: (context, state) => const FranchiseFinderPage(),
        ),
        // Legacy routes for backward compatibility
        GoRoute(
          path: '/player/:playerId',
          builder: (context, state) {
            final playerId = state.pathParameters['playerId']!;
            return PlayerProfilePage(playerId: playerId);
          },
        ),
      ],
      errorBuilder: (context, state) => const NotFoundPage(),
      redirect: (context, state) {
        final isLoggingIn = state.uri.toString() == '/login';
        final isTestRoute = state.uri.path == '/test-routing';
        final isFranchiseRoute = state.uri.path.startsWith('/franchise/');
        final isPlayerRoute = state.uri.path.startsWith('/player/');
        final isServerRoute = state.uri.path.startsWith('/server/');
        final isFranchisePlayerRoute = state.uri.path.contains('/franchise/') && state.uri.path.contains('/player/');
        final isServerFranchisePlayerRoute = state.uri.path.startsWith('/server/') && state.uri.path.contains('/franchise/') && state.uri.path.contains('/player/');
        
        // Debug logging
        print('🔍 DEBUG: Redirect check for path: ${state.uri.path}');
        print('🔍 DEBUG: User is null: ${user == null}');
        print('🔍 DEBUG: Is test route: $isTestRoute');
        print('🔍 DEBUG: Is server route: $isServerRoute');
        print('🔍 DEBUG: Is franchise route: $isFranchiseRoute');
        print('🔍 DEBUG: Is player route: $isPlayerRoute');
        
        // Allow franchise, player, server, and test routes without authentication
        if (isTestRoute || isFranchiseRoute || isPlayerRoute || isServerRoute || isFranchisePlayerRoute || isServerFranchisePlayerRoute) {
          print('🔍 DEBUG: Allowing public route access');
          return null;
        }
        
        // Redirect to login for all other routes if not authenticated
        if (user == null && !isLoggingIn) {
          print('🔍 DEBUG: Redirecting to login - user is null');
          return '/login';
        }
        if (user != null && isLoggingIn) {
          print('🔍 DEBUG: Redirecting to home - user is authenticated');
          return '/';
        }
        print('🔍 DEBUG: No redirect needed');
        return null;
      },
    );
    // refreshListenable: GoRouterRefreshStream(ref.watch(currentUserProvider.notifier).stream),

    return MaterialApp.router(
      title: 'Franchise Player',
      theme: appTheme,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}

class HomePage extends ConsumerStatefulWidget {
  final String? initialServerId;
  final String? initialChannelId;
  final String? initialFranchiseId;
  final String? initialPlayerId;
  final String? initialDmThreadId;
  
  const HomePage({
    super.key,
    this.initialServerId,
    this.initialChannelId,
    this.initialFranchiseId,
    this.initialPlayerId,
    this.initialDmThreadId,
  });

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  String? _activeDmThreadId;
  String? _activeChannelId;
  String? _activeChannelName;
  String? _activeChannelType;
  String? _activeFranchiseId;
  String? _activeFranchiseChannelId;
  String? _activeFranchiseChannelName;
  bool _showDmInbox = false;
  String? _currentServerId;
  
  // Search and player card functionality
  final TextEditingController _playerSearchController = TextEditingController();
  Player? _selectedPlayer;
  String _currentView = 'default';
  bool _isInitialized = false;
  
  // Pagination state
  int _currentPage = 1;
  int _pageSize = 50;
  final List<int> _pageSizeOptions = [50, 100, 200];

  void _openDm(String threadId) {
    setState(() {
      _activeDmThreadId = threadId;
      _activeChannelId = null;
      _activeChannelName = null;
      _activeChannelType = null;
      _activeFranchiseId = null;
      _activeFranchiseChannelId = null;
      _activeFranchiseChannelName = null;
      _showDmInbox = false;
    });
    // Update URL for DM thread
    context.go('/dm/$threadId');
  }

  void _openChannel(String channelId, String channelName, String? channelType) {
    setState(() {
      _activeChannelId = channelId;
      _activeChannelName = channelName;
      _activeChannelType = channelType;
      _activeDmThreadId = null;
      _activeFranchiseId = null;
      _activeFranchiseChannelId = null;
      _activeFranchiseChannelName = null;
      _showDmInbox = false;
    });
    // Update URL for channel with server name
    if (_currentServerId != null) {
      final serverName = _getServerName(_currentServerId!);
      final urlSafeName = serverName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9-]'), '-');
      context.go('/server/$urlSafeName/channel/$channelId');
    }
  }

  void _openFranchise(String franchiseId) {
    print('🔍 DEBUG: ===== OPENING FRANCHISE =====');
    print('🔍 DEBUG: _openFranchise called with franchiseId: $franchiseId');
    print('🔍 DEBUG: Current franchise ID before: $_activeFranchiseId');
    print('🔍 DEBUG: Initial player ID: ${widget.initialPlayerId}');
    
    // Check if franchiseId is a UUID or a name
    final isUuid = franchiseId.contains('-') && franchiseId.length > 20;
    print('🔍 DEBUG: Is UUID: $isUuid');
    
    if (!isUuid) {
      print('🔍 DEBUG: Franchise ID is not a UUID, skipping franchise context');
      return;
    }
    
    setState(() {
      _activeFranchiseId = franchiseId;
      _activeFranchiseChannelId = null;
      _activeFranchiseChannelName = null;
      _activeDmThreadId = null;
      _activeChannelId = null;
      _activeChannelName = null;
      _activeChannelType = null;
      _showDmInbox = false;
    });
    
    print('🔍 DEBUG: _activeFranchiseId set to: $_activeFranchiseId');
    print('🔍 DEBUG: Current server ID: $_currentServerId');
    
    // Only update URL if we're not in a player context
    if (widget.initialPlayerId == null) {
      print('🔍 DEBUG: Updating franchise URL...');
      _updateFranchiseUrl(franchiseId);
    } else {
      print('🔍 DEBUG: Skipping URL update due to player context');
    }
  }

  // Update franchise URL with franchise name
  void _updateFranchiseUrl(String franchiseId) {
    // Only update URL if franchiseId is a UUID
    final isUuid = franchiseId.contains('-') && franchiseId.length > 20;
    if (!isUuid) {
      print('🔍 DEBUG: Skipping URL update - franchiseId is not a UUID: $franchiseId');
      return;
    }
    
    final franchiseName = _getFranchiseName(franchiseId);
    final urlSafeName = franchiseName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9-]'), '-');
    print('🔍 DEBUG: Updating franchise URL to: /franchise/$urlSafeName');
    context.go('/franchise/$urlSafeName');
  }

  void _openFranchiseChannel(String franchiseId, String channelId, String channelName) {
    setState(() {
      _activeFranchiseId = franchiseId;
      _activeFranchiseChannelId = channelId;
      _activeFranchiseChannelName = channelName;
      _activeDmThreadId = null;
      _activeChannelId = null;
      _activeChannelName = null;
      _activeChannelType = null;
      _showDmInbox = false;
    });
    // Update URL for franchise channel with franchise name
    final franchiseName = _getFranchiseName(franchiseId);
    final urlSafeName = franchiseName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9-]'), '-');
    context.go('/franchise/$urlSafeName/$channelId');
  }

  void _goHome() {
    setState(() {
      _currentServerId = null;
      _activeChannelId = null;
      _activeChannelName = null;
      _activeChannelType = null;
      _activeFranchiseId = null;
      _activeFranchiseChannelId = null;
      _activeFranchiseChannelName = null;
      _showDmInbox = true;
      // Auto-select the most recent DM conversation
      _activeDmThreadId = 'dm-1'; // This would be the most recent conversation
    });
    // Update URL for home
    context.go('/');
  }

  void _openServer(String serverId) {
    print('🔍 DEBUG: _openServer called with serverId: $serverId');
    print('🔍 DEBUG: Current server ID before: $_currentServerId');
    print('🔍 DEBUG: Initial player ID: ${widget.initialPlayerId}');
    
    setState(() {
      _currentServerId = serverId;
      _activeChannelId = null;
      _activeChannelName = null;
      _activeChannelType = null;
      _activeDmThreadId = null;
      _activeFranchiseId = null; // Will be set after fetching franchises
      _activeFranchiseChannelId = null;
      _activeFranchiseChannelName = null;
      _showDmInbox = false;
    });
    
    print('🔍 DEBUG: Current server ID after setState: $_currentServerId');
    
    // Get server name and update URL
    _updateServerUrl(serverId);
    
    // Only load first franchise if we're not in a player context AND we have initial franchise ID
    // This prevents auto-navigation to franchise when just clicking on a server
    if (widget.initialPlayerId == null && widget.initialFranchiseId != null) {
      print('🔍 DEBUG: Loading first franchise from server due to initial franchise ID');
      _loadFirstFranchiseFromServer(serverId);
    } else {
      print('🔍 DEBUG: Skipping first franchise load - staying on server route');
    }
  }

  // Update server URL with server name
  void _updateServerUrl(String serverId) {
    print('🔍 DEBUG: _updateServerUrl called with serverId: $serverId');
    
    // Don't update URL if we're in a player context to avoid hash fragments
    if (widget.initialPlayerId != null) {
      print('🔍 DEBUG: Skipping URL update due to player context');
      return;
    }
    
    // Get the friendly name for the URL
    final serverName = _getServerName(serverId);
    final urlSafeName = serverName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9-]'), '-');
    print('🔍 DEBUG: Updating URL to: /server/$urlSafeName');
    context.go('/server/$urlSafeName');
  }

  // Get server name from serverId
  String _getServerName(String serverId) {
    // Use the static mapping function to get the friendly name
    return FranchisePlayerApp._getServerNameFromId(serverId);
  }

  // Get franchise name from franchiseId
  String _getFranchiseName(String franchiseId) {
    // Check if franchiseId is a UUID
    final isUuid = franchiseId.contains('-') && franchiseId.length > 20;
    if (!isUuid) {
      print('🔍 DEBUG: _getFranchiseName called with non-UUID: $franchiseId');
      return franchiseId; // Return the original value if not a UUID
    }
    
    // Extract the actual UUID from the franchise ID
    final actualFranchiseId = _extractFranchiseId(franchiseId);
    
    // Get the franchise data from the provider
    final franchiseAsync = ref.read(franchiseProvider(actualFranchiseId));
    
    return franchiseAsync.when(
      loading: () => franchiseId,
      error: (error, stack) => franchiseId,
      data: (franchise) => franchise?.name ?? franchiseId,
    );
  }

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Only initialize if not already initialized or if we have new initial parameters
      if (!_isInitialized || 
          widget.initialDmThreadId != null ||
          widget.initialServerId != null ||
          widget.initialFranchiseId != null ||
          widget.initialPlayerId != null ||
          widget.initialChannelId != null) {
        
        // Handle initial state based on URL parameters
        if (widget.initialDmThreadId != null) {
          _openDm(widget.initialDmThreadId!);
        } else if (widget.initialServerId != null && widget.initialChannelId != null) {
          _openServer(widget.initialServerId!);
          // Open the specific channel after server is set
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _openChannel(widget.initialChannelId!, 'Channel', null);
          });
        } else if (widget.initialServerId != null && widget.initialFranchiseId != null && widget.initialPlayerId != null) {
          print('🔍 DEBUG: Setting server context: ${widget.initialServerId}');
          print('🔍 DEBUG: Setting franchise context: ${widget.initialFranchiseId}');
          print('🔍 DEBUG: Player ID: ${widget.initialPlayerId}');
          _openServer(widget.initialServerId!);
          // Open the franchise after server is set
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _openFranchise(widget.initialFranchiseId!);
            // Load the specific player after franchise is set
            WidgetsBinding.instance.addPostFrameCallback((_) {
              print('🔍 DEBUG: Loading player: ${widget.initialPlayerId}');
              // Find the player in the current data and set it
              final playersState = ref.read(publicDataProvider);
              playersState.when(
                data: (players) {
                  final player = players.firstWhere(
                    (p) => p.id == widget.initialPlayerId,
                    orElse: () => throw Exception('Player not found: ${widget.initialPlayerId}'),
                  );
                  setState(() {
                    _selectedPlayer = player;
                    _currentView = 'player_card';
                  });
                },
                loading: () {
                  print('🔍 DEBUG: Players still loading, cannot load specific player');
                },
                error: (error, stack) {
                  print('🔍 DEBUG: Error loading players: $error');
                },
              );
            });
          });
        } else if (widget.initialServerId != null) {
          _openServer(widget.initialServerId!);
        } else if (widget.initialFranchiseId != null && widget.initialPlayerId != null) {
          print('🔍 DEBUG: Setting franchise context: ${widget.initialFranchiseId}');
          print('🔍 DEBUG: Franchise ID format check: ${widget.initialFranchiseId}');
          print('🔍 DEBUG: Player ID: ${widget.initialPlayerId}');
          _openFranchise(widget.initialFranchiseId!);
          // Load the specific player after franchise is set
          WidgetsBinding.instance.addPostFrameCallback((_) {
            print('🔍 DEBUG: Loading player: ${widget.initialPlayerId}');
            // Find the player in the current data and set it
            final playersState = ref.read(publicDataProvider);
            playersState.when(
              data: (players) {
                final player = players.firstWhere(
                  (p) => p.id == widget.initialPlayerId,
                  orElse: () => throw Exception('Player not found: ${widget.initialPlayerId}'),
                );
                setState(() {
                  _selectedPlayer = player;
                  _currentView = 'player_card';
                });
              },
              loading: () {
                print('🔍 DEBUG: Players still loading, cannot load specific player');
              },
              error: (error, stack) {
                print('🔍 DEBUG: Error loading players: $error');
              },
            );
          });
        } else if (widget.initialFranchiseId != null && widget.initialChannelId != null) {
          _openFranchise(widget.initialFranchiseId!);
          // Open the specific channel after franchise is set
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _openFranchiseChannel(widget.initialFranchiseId!, widget.initialChannelId!, 'Channel');
          });
        } else if (widget.initialFranchiseId != null) {
          _openFranchise(widget.initialFranchiseId!);
        }
        
        _isInitialized = true;
      }
    });
  }

  @override
  void dispose() {
    _playerSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    
    // Check if we're on a public route (for non-authenticated users)
    final isPublicRoute = GoRouterState.of(context).uri.path.startsWith('/franchise/') || 
                         GoRouterState.of(context).uri.path.startsWith('/server/') ||
                         GoRouterState.of(context).uri.path.startsWith('/player/');
    
    // For non-authenticated users on public routes, show simplified layout
    if (user == null && isPublicRoute) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          titleSpacing: 0,
          title: Row(
            children: [
              InkWell(
                onTap: () => context.go('/'),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: Text('Franchise Player', style: Theme.of(context).textTheme.titleLarge),
                ),
              ),
              if (widget.initialServerId != null) ...[
                const SizedBox(width: 16),
                Text(
                  '• ${FranchisePlayerApp._getServerNameFromId(widget.initialServerId!)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                                            ],
        ],
      ),
      ),
      body: _buildPublicContent(),
      );
    }
    
    // Full layout for authenticated users
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            InkWell(
              onTap: () => context.go('/'),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0, right: 12.0),
                child: Image.asset(
                  'assets/logo.png',
                  height: 36,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.sports_football, size: 32),
                ),
              ),
            ),
            if (_currentServerId != null && !_showDmInbox)
              Flexible(
                flex: 99,
                child: Container(
                  decoration: const BoxDecoration(),
                  child: Consumer(
                    builder: (context, ref, child) {
                      final serversAsync = ref.watch(serversProvider);
                      return serversAsync.when(
                        data: (servers) {
                          final currentServer = servers.firstWhere(
                            (server) => server['id'] == _currentServerId,
                            orElse: () => {'name': 'Unknown Server', 'icon': '🏠', 'color': '#7289DA'},
                          );
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ServerIconWidget(
                                iconUrl: currentServer['icon_url'],
                                emojiIcon: currentServer['icon'],
                                color: currentServer['color'],
                                size: 21, // Reduced by 33% from 32
                                showBorder: true, // Enable border for rounded border effect
                              ),
                              const SizedBox(width: 8), // Reduced spacing
                              Text(
                                currentServer['name'] ?? 'Unknown Server',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontSize: Theme.of(context).textTheme.titleLarge!.fontSize! * 0.67, // Reduced by 33%
                                ),
                              ),
                              const SizedBox(width: 12),
                              Builder(
                                builder: (context) {
                                  final currentUser = ref.watch(currentUserProvider);
                                  final isOwner = currentServer['owner_id'] == currentUser?.id;
                                  
                                  if (isOwner) {
                                    return IconButton(
                                      icon: const Icon(Icons.settings, size: 20, color: Colors.grey),
                                      onPressed: () => _showServerSettingsDialog(currentServer),
                                      tooltip: 'Server Settings',
                                      padding: const EdgeInsets.all(4),
                                      constraints: const BoxConstraints(),
                                    );
                                  } else {
                                    return const SizedBox.shrink();
                                  }
                                },
                              ),
                            ],
                          );
                        },
                        loading: () => const Row(
                          children: [
                            SizedBox(width: 32, height: 32, child: CircularProgressIndicator(strokeWidth: 2)),
                            SizedBox(width: 12),
                            Text('Loading...'),
                          ],
                        ),
                        error: (error, stack) => const Row(
                          children: [
                            Icon(Icons.error_outline, size: 32),
                            SizedBox(width: 12),
                            Text('Error'),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              )
            else
              const SizedBox.shrink(),
            const Spacer(flex: 1),
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: 'Search Users',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const Dialog(
                    child: SizedBox(
                      width: 400,
                      height: 600,
                      child: UserSearchPage(),
                    ),
                  ),
                );
              },
            ),
            if (user != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: CircleAvatar(
                  radius: 18,
                  child: Text(user.email?.isNotEmpty == true ? user.email![0].toUpperCase() : 'U'),
                ),
              ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) async {
                if (value == 'logout') {
                  try {
                    await ref.read(authProvider.notifier).signOut();
                    if (mounted) {
                      context.go('/login');
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Logout failed: $e')),
                      );
                    }
                  }
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, size: 18),
                      SizedBox(width: 8),
                      Text('Logout'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Row(
        children: [
          ServerSideNav(
            onDmSelected: _goHome,
            onServerSelected: _openServer,
            onToggleTheme: () => ref.read(themeProvider.notifier).toggleTheme(),
            isDark: isDark,
          ),
          if (_showDmInbox)
            _buildDmSidebar(),
          if ((_currentServerId != null && !_showDmInbox) || _activeFranchiseId != null || (_selectedPlayer != null && _currentView == 'player_card'))
            _buildFranchiseSidebar(),
          Expanded(
            child: _buildMainContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildDmSidebar() {
    return Container(
      width: 240,
      color: const Color(0xFFF8F9FA),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE9ECEF), width: 1)),
            ),
            child: Row(
              children: [
                const Icon(Icons.chat_bubble_outline, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Direct Messages',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // DM list
          Expanded(
            child: _buildDmList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDmList() {
    // TODO: Replace with real DM conversations from database
    return const Center(
      child: Text('DM conversations will be implemented with real database data.'),
    );
  }

  Widget _buildFranchiseSidebar() {
    if (_currentServerId == null) {
      return Container(
        width: 240,
        color: const Color(0xFFF8F9FA),
        child: const Center(
          child: Text('Select a server to view franchises'),
        ),
      );
    }
    
    return Consumer(
      builder: (context, ref, child) {
        return FranchiseSidebar(
          serverId: _currentServerId!,
          onFranchiseSelected: (franchiseId) {
            setState(() {
              _activeFranchiseId = franchiseId;
              _activeFranchiseChannelId = null;
              _activeFranchiseChannelName = null;
            });
          },
          onFranchiseChannelSelected: (franchiseId, channelId, channelName) {
            setState(() {
              _activeFranchiseId = franchiseId;
              _activeFranchiseChannelId = channelId;
              _activeFranchiseChannelName = channelName;
            });
          },
          selectedFranchiseId: _activeFranchiseId,
          selectedChannelId: _activeFranchiseChannelId,
        );
      },
    );
  }

  Widget _buildFranchiseList() {
    // Different franchises for different servers with their channels
    Map<String, List<Map<String, dynamic>>> serverFranchises = {
      'server-1': [
        {
          'id': 'franchise-1', 
          'name': 'Madden League Alpha', 
          'description': 'Main competitive league',
          'channels': [
            {
              'category': 'General',
              'channels': [
                {'id': 'general', 'name': 'general', 'type': 'text'},
                {'id': 'announcements', 'name': 'announcements', 'type': 'text'},
                {'id': 'rules', 'name': 'rules', 'type': 'text'},
              ]
            },
            {
              'category': 'Game Discussion',
              'channels': [
                {'id': 'strategy', 'name': 'strategy', 'type': 'text'},
                {'id': 'trades', 'name': 'trades', 'type': 'text'},
                {'id': 'free-agency', 'name': 'free-agency', 'type': 'text'},
              ]
            },
            {
              'category': 'Voice Channels',
              'channels': [
                {'id': 'lobby', 'name': 'Lobby', 'type': 'voice'},
                {'id': 'game-1', 'name': 'Game Room 1', 'type': 'voice'},
                {'id': 'game-2', 'name': 'Game Room 2', 'type': 'voice'},
              ]
            }
          ]
        },
        {
          'id': 'franchise-2', 
          'name': 'Casual Franchise', 
          'description': 'Relaxed gameplay league',
          'channels': [
            {
              'category': 'General',
              'channels': [
                {'id': 'general', 'name': 'general', 'type': 'text'},
                {'id': 'casual-chat', 'name': 'casual-chat', 'type': 'text'},
              ]
            },
            {
              'category': 'Voice Channels',
              'channels': [
                {'id': 'casual-lobby', 'name': 'Casual Lobby', 'type': 'voice'},
              ]
            }
          ]
        },
        {
          'id': 'franchise-3', 
          'name': 'Pro League', 
          'description': 'Professional level competition',
          'channels': [
            {
              'category': 'General',
              'channels': [
                {'id': 'general', 'name': 'general', 'type': 'text'},
                {'id': 'pro-announcements', 'name': 'pro-announcements', 'type': 'text'},
              ]
            },
            {
              'category': 'Competitive',
              'channels': [
                {'id': 'tournaments', 'name': 'tournaments', 'type': 'text'},
                {'id': 'rankings', 'name': 'rankings', 'type': 'text'},
              ]
            },
            {
              'category': 'Voice Channels',
              'channels': [
                {'id': 'pro-lobby', 'name': 'Pro Lobby', 'type': 'voice'},
                {'id': 'tournament-room', 'name': 'Tournament Room', 'type': 'voice'},
              ]
            }
          ]
        },
      ],
      'server-2': [
        {
          'id': 'support-1', 
          'name': 'Help & Support', 
          'description': 'Get help with the app',
          'channels': [
            {
              'category': 'Support',
              'channels': [
                {'id': 'general-help', 'name': 'general-help', 'type': 'text'},
                {'id': 'technical-support', 'name': 'technical-support', 'type': 'text'},
              ]
            }
          ]
        },
        {
          'id': 'support-2', 
          'name': 'Bug Reports', 
          'description': 'Report issues and bugs',
          'channels': [
            {
              'category': 'Bug Reports',
              'channels': [
                {'id': 'bug-reports', 'name': 'bug-reports', 'type': 'text'},
                {'id': 'bug-status', 'name': 'bug-status', 'type': 'text'},
              ]
            }
          ]
        },
        {
          'id': 'support-3', 
          'name': 'Feature Requests', 
          'description': 'Suggest new features',
          'channels': [
            {
              'category': 'Feature Requests',
              'channels': [
                {'id': 'feature-requests', 'name': 'feature-requests', 'type': 'text'},
                {'id': 'feature-status', 'name': 'feature-status', 'type': 'text'},
              ]
            }
          ]
        },
      ],
      'server-3': [
        {
          'id': 'casual-1', 
          'name': 'Weekend Warriors', 
          'description': 'Casual weekend games',
          'channels': [
            {
              'category': 'General',
              'channels': [
                {'id': 'weekend-chat', 'name': 'weekend-chat', 'type': 'text'},
              ]
            }
          ]
        },
        {
          'id': 'casual-2', 
          'name': 'Friendly Matches', 
          'description': 'Non-competitive play',
          'channels': [
            {
              'category': 'General',
              'channels': [
                {'id': 'friendly-chat', 'name': 'friendly-chat', 'type': 'text'},
              ]
            }
          ]
        },
      ],
    };
    
    // Use real franchise data from the database
    final franchisesAsync = ref.watch(franchisesProvider(_currentServerId ?? ''));
    
    return franchisesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (franchises) {
        if (franchises.isEmpty) {
          return const Center(
            child: Text('No franchises found in this server.'),
          );
        }
        
        return ListView.builder(
          itemCount: franchises.length,
          itemBuilder: (context, index) {
            final franchise = franchises[index];
            final isSelected = _activeFranchiseId == franchise.id;
            final isExpanded = _activeFranchiseId == franchise.id;
            
            return ExpansionTile(
              leading: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.sports_football,
                  color: Colors.orange[700],
                  size: 18,
                ),
              ),
              title: Text(
                franchise.name,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? Colors.black : Colors.black87,
                ),
              ),
              subtitle: Text(
                'Franchise',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              initiallyExpanded: isExpanded,
              onExpansionChanged: (expanded) {
                if (expanded) {
                  setState(() {
                    _activeFranchiseId = franchise.id;
                    _activeFranchiseChannelId = null;
                    _activeFranchiseChannelName = null;
                  });
                  
                  // Update the URL to show the franchise
                  _updateFranchiseUrl(franchise.id);
                }
              },
              children: _buildFranchiseChannelsFromDatabase(franchise.id),
            );
          },
        );
      },
    );
  }

  List<Widget> _buildFranchiseChannels(List<Map<String, dynamic>> channelCategories) {
    List<Widget> widgets = [];
    
    for (final category in channelCategories) {
      final categoryName = category['category'] as String;
      final channels = category['channels'] as List<Map<String, dynamic>>;
      
      // Add category header
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(left: 48, top: 8, bottom: 4),
          child: Text(
            categoryName.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
              letterSpacing: 0.5,
            ),
          ),
        ),
      );
      
      // Add channels in this category
      for (final channel in channels) {
        final isSelected = _activeFranchiseChannelId == channel['id'] && _activeFranchiseId == _activeFranchiseId;
        
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 48),
            child: ListTile(
              dense: true,
              leading: Icon(
                channel['type'] == 'voice' ? Icons.volume_up : Icons.tag,
                size: 16,
                color: isSelected ? Colors.blue[600] : Colors.grey[600],
              ),
              title: Text(
                '# ${channel['name']}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? Colors.blue[600] : Colors.grey[700],
                ),
              ),
              selected: isSelected,
              onTap: () {
                setState(() {
                  _activeFranchiseChannelId = channel['id'];
                  _activeFranchiseChannelName = channel['name'];
                });
              },
            ),
          ),
        );
      }
      
      // Add spacing between categories
      if (channelCategories.indexOf(category) < channelCategories.length - 1) {
        widgets.add(const SizedBox(height: 8));
      }
    }
    
    return widgets;
  }

  List<Widget> _buildFranchiseChannelsFromDatabase(String franchiseId) {
    final channelsAsync = ref.watch(franchiseChannelsProvider(franchiseId));
    
    return channelsAsync.when(
      loading: () => [const Center(child: CircularProgressIndicator())],
      error: (error, stack) => [Center(child: Text('Error: $error'))],
      data: (channels) {
        if (channels.isEmpty) {
          return [const Center(child: Text('No channels found.'))];
        }
        
        List<Widget> widgets = [];
        
        // Group channels by type
        final textChannels = channels.where((c) => c.type == 'text').toList();
        final voiceChannels = channels.where((c) => c.type == 'voice').toList();
        final videoChannels = channels.where((c) => c.type == 'video').toList();
        
        // Add text channels
        if (textChannels.isNotEmpty) {
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(left: 48, top: 8, bottom: 4),
              child: Text(
                'TEXT CHANNELS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                  letterSpacing: 0.5,
                ),
              ),
            ),
          );
          
          for (final channel in textChannels) {
            final isSelected = _activeFranchiseChannelId == channel.id;
            
            widgets.add(
              Padding(
                padding: const EdgeInsets.only(left: 48),
                child: ListTile(
                  dense: true,
                  leading: Icon(
                    Icons.chat_bubble_outline,
                    size: 16,
                    color: isSelected ? Colors.blue[600] : Colors.grey[600],
                  ),
                  title: Text(
                    '# ${channel.name}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? Colors.blue[600] : Colors.grey[700],
                    ),
                  ),
                  selected: isSelected,
                  onTap: () {
                    setState(() {
                      _activeFranchiseChannelId = channel.id;
                      _activeFranchiseChannelName = channel.name;
                    });
                    
                    // Update URL for franchise channel
                    final franchiseName = _getFranchiseName(_activeFranchiseId!);
                    final urlSafeName = franchiseName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9-]'), '-');
                    context.go('/franchise/$urlSafeName/${channel.id}');
                  },
                ),
              ),
            );
          }
        }
        
        // Add voice channels
        if (voiceChannels.isNotEmpty) {
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(left: 48, top: 8, bottom: 4),
              child: Text(
                'VOICE CHANNELS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                  letterSpacing: 0.5,
                ),
              ),
            ),
          );
          
          for (final channel in voiceChannels) {
            final isSelected = _activeFranchiseChannelId == channel.id;
            
            widgets.add(
              Padding(
                padding: const EdgeInsets.only(left: 48),
                child: ListTile(
                  dense: true,
                  leading: Icon(
                    Icons.mic,
                    size: 16,
                    color: isSelected ? Colors.blue[600] : Colors.grey[600],
                  ),
                  title: Text(
                    '# ${channel.name}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? Colors.blue[600] : Colors.grey[700],
                    ),
                  ),
                  selected: isSelected,
                  onTap: () {
                    setState(() {
                      _activeFranchiseChannelId = channel.id;
                      _activeFranchiseChannelName = channel.name;
                    });
                    
                    // Update URL for franchise channel
                    final franchiseName = _getFranchiseName(_activeFranchiseId!);
                    final urlSafeName = franchiseName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9-]'), '-');
                    context.go('/franchise/$urlSafeName/${channel.id}');
                  },
                ),
              ),
            );
          }
        }
        
        return widgets;
      },
    );
  }

    Widget _buildPublicContent() {
    // For non-authenticated users, show simplified content
    if (widget.initialPlayerId != null) {
      // Show player profile
      return Consumer(
        builder: (context, ref, child) {
          final playersState = ref.watch(publicDataProvider);
          return playersState.when(
            data: (players) {
              try {
                final player = players.firstWhere(
                  (p) => p.id == widget.initialPlayerId,
                  orElse: () => throw Exception('Player not found: ${widget.initialPlayerId}'),
                );
                return SingleChildScrollView(
                  child: _buildSimplePlayerProfile(player),
                );
              } catch (e) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.person_off, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text('Player not found', style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 8),
                      Text('The requested player could not be found.', style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                );
              }
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error loading player', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text('Failed to load player data.', style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          );
        },
      );
    }
    
    // Show server info for non-authenticated users
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.sports_football, size: 80, color: Colors.orange),
          const SizedBox(height: 24),
          Text(
            'Welcome to ${widget.initialServerId != null ? FranchisePlayerApp._getServerNameFromId(widget.initialServerId!) : 'this server'}',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Sign in to access full server features',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => context.go('/login'),
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    // DM Thread
    if (_activeDmThreadId != null && _showDmInbox) {
      return _buildDmConversation();
    }

    // Franchise Content (includes player profile when selected)
    if (_activeFranchiseId != null) {
      return _buildFranchiseContent();
    }

    // Check if we're in a server but no franchise is selected
    if (_currentServerId != null && !_showDmInbox) {
      return _buildServerEmptyState();
    }

    // Default to Home Welcome Page
    return const HomeWelcomePage();
  }

  // Build simple player profile content without scaffold
  Widget _buildSimplePlayerProfile(Player player) {
    final gold = Theme.of(context).colorScheme.primary;
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            color: gold.withOpacity(0.12),
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: gold.withOpacity(0.25),
                  child: Text(
                    player.position,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 32, color: gold),
                  ),
                ),
                const SizedBox(width: 32),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player.fullName,
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildBioItem('Team', player.team ?? 'FA'),
                          _buildBioItem('Jersey #', player.jerseyNum?.toString() ?? '-'),
                          _buildBioItem('Position', player.position),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Bio Row
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildBioItem('Age', player.age.toString()),
                    _buildBioItem('Height', player.height?.toString() ?? '-'),
                    _buildBioItem('Weight', player.weight?.toString() ?? '-'),
                    _buildBioItem('College', player.college ?? '-'),
                    _buildBioItem('Draft', player.draftRound != null ? 'R${player.draftRound} P${player.draftPick}' : '-'),
                  ],
                ),
              ),
            ),
          ),
          // Stats Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Key Ratings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 24,
                      runSpacing: 12,
                      children: [
                        _buildRatingItem('Overall', player.overall, _getOverallColor(player.overall)),
                        _buildRatingItem('Speed', player.speedRating, _getOverallColor(player.speedRating)),
                        _buildRatingItem('Strength', player.strengthRating ?? 0, _getOverallColor(player.strengthRating ?? 0)),
                        _buildRatingItem('Agility', player.agilityRating ?? 0, _getOverallColor(player.agilityRating ?? 0)),
                        _buildRatingItem('Awareness', player.awareRating ?? 0, _getOverallColor(player.awareRating ?? 0)),
                        _buildRatingItem('Catch', player.catchRating ?? 0, _getOverallColor(player.catchRating ?? 0)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method for bio items
  Widget _buildBioItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // Helper method for rating items
  Widget _buildRatingItem(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value.toString(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDmConversation() {
    // TODO: Replace with real DM conversation data from database
    return const Center(
      child: Text('DM conversations will be implemented with real database data.'),
    );

    return const Center(
      child: Text('DM conversations will be implemented with real database data.'),
    );
  }

  Widget _buildServerEmptyState() {
    return Consumer(
      builder: (context, ref, child) {
        final franchisesAsync = ref.watch(franchisesProvider(_currentServerId ?? ''));
        
        return franchisesAsync.when(
          loading: () => const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading franchises...'),
              ],
            ),
          ),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red[300],
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading franchises',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          data: (franchises) {
            if (franchises.isNotEmpty) {
              // If there are franchises but none selected, show a selection prompt
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.sports_football,
                      size: 64,
                      color: Colors.orange[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Select a Franchise',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choose a franchise from the sidebar to get started',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            } else {
              // No franchises in this server
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(60),
                      ),
                      child: Icon(
                        Icons.sports_football,
                        size: 60,
                        color: Colors.orange[300],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No Franchises Yet',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 48),
                      child: Text(
                        'This server doesn\'t have any franchises yet. Franchises are the core gameplay experience where you can manage teams, play games, and compete with other players.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Navigate to franchise creation page
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Franchise creation coming soon!'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Create First Franchise'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: () {
                        // TODO: Navigate to franchise management page
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Franchise management coming soon!'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.settings),
                      label: const Text('Manage Franchises'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.orange[600],
                      ),
                    ),
                  ],
                ),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isMe = message['isMe'] as bool;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue[100],
              child: Text(
                message['sender']![0],
                style: TextStyle(
                  color: Colors.blue[700],
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isMe ? Colors.blue[500] : Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message['message']!,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message['time']!,
                    style: TextStyle(
                      fontSize: 10,
                      color: isMe ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildFranchiseContent() {
    return Column(
      children: [
        // Franchise header with navigation
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFE9ECEF), width: 1)),
          ),
          child: Row(
            children: [
              const Icon(Icons.sports_football, size: 24),
              const SizedBox(width: 12),
              Text(
                _getFranchiseDisplayName(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(), // Push everything to the right
              // Channel navigation buttons - make scrollable to prevent overflow
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildChannelButton('News', 'news'),
                    const SizedBox(width: 8),
                    _buildChannelButton('Players', 'players'),
                    const SizedBox(width: 8),
                    _buildChannelButton('Teams', 'teams'),
                    const SizedBox(width: 8),
                    _buildChannelButton('Games', 'games'),
                    const SizedBox(width: 8),
                    _buildChannelButton('Standings', 'standings'),
                    const SizedBox(width: 8),
                    _buildChannelButton('Statistics', 'statistics'),
                    const SizedBox(width: 8),
                    _buildChannelButton('Trades', 'trades'),
                    const SizedBox(width: 8),
                    _buildChannelButton('Awards', 'awards'),
                    const SizedBox(width: 8),
                    _buildChannelButton('Rules', 'rules'),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Main content area
        Expanded(
          child: _buildChannelContent(),
        ),
      ],
    );
  }

  Widget _buildChannelButton(String name, String channelId) {
    final isSelected = _activeFranchiseChannelId == channelId;
    return InkWell(
      onTap: () {
        // If we're already in a franchise, just switch the channel without URL change
        if (_activeFranchiseId != null) {
          setState(() {
            _activeFranchiseChannelId = channelId;
            _activeFranchiseChannelName = name;
          });
          // Don't update URL for simple tab switches to avoid page reload
          // Only update URL for major navigation changes
        } else {
          // If no franchise is selected, this shouldn't happen but handle gracefully
          setState(() {
            _activeFranchiseChannelId = channelId;
            _activeFranchiseChannelName = name;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[50] : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.blue[300]! : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Text(
          name,
          style: TextStyle(
            color: isSelected ? Colors.blue[700] : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildChannelContent() {
    // Handle player card view
    if (_currentView == 'player_card' && _selectedPlayer != null) {
      return _buildPlayerCardView();
    }
    
    // Handle special navigation tabs first
    if (_activeFranchiseId != null && _activeFranchiseChannelId != null) {
      // Check if this is a special navigation tab (not a real channel)
      final specialTabs = ['news', 'players', 'teams', 'games', 'standings', 'statistics', 'trades', 'awards', 'rules'];
      if (specialTabs.contains(_activeFranchiseChannelId)) {
        switch (_activeFranchiseChannelId) {
          case 'news':
            return const Center(child: Text('News content will be shown here'));
          case 'players':
            return _buildPlayersTab();
          case 'teams':
            return _buildTeamsTab();
          case 'games':
            return const Center(child: Text('Games content will be shown here'));
          case 'standings':
            return _buildPowerRankingsAndStandings();
          case 'statistics':
            return _buildStatsMuseStyleStats();
          case 'trades':
            return _buildTradesTab();
          case 'awards':
            return _buildAwardsTab();
          case 'rules':
            return const Center(child: Text('Rules content will be shown here'));
        }
      }
      
      // Handle real franchise channels
      return FranchiseChannelContent(
        franchiseId: _activeFranchiseId!,
        channelId: _activeFranchiseChannelId!,
      );
    }
    
    // Handle server channels
    if (_activeChannelId != null) {
      return ServerChannelContent(
        channelId: _activeChannelId!,
      );
    }
    
    // Default
    return const Center(child: Text('Select a channel to start chatting'));
  }



  // --- TRADES TAB ---
  Widget _buildTradesTab() {
    // Always show upload interface for all servers - no hardcoded data
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.swap_horiz, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No Trade Data Available',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Upload franchise data to see trades',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // --- STATISTICS TAB ---
  Widget _buildStatsMuseStyleStats() {
    // Always show upload interface for all servers - no hardcoded data
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No Statistics Available',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Upload franchise data to see statistics',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // --- PLAYERS TAB ---
  Widget _buildPlayersTab() {
    return Consumer(
      builder: (context, ref, child) {
        final playersState = ref.watch(publicDataProvider);
        
        return playersState.when(
          data: (allPlayers) {
            // CRITICAL: Filter players by current franchise ID
            final currentFranchiseId = _activeFranchiseId;
            if (currentFranchiseId == null) {
              return const Center(
                child: Text('No franchise selected'),
              );
            }
            
            // Filter players to only show current franchise
            final allFranchisePlayers = allPlayers.where((player) => player.franchiseId == currentFranchiseId).toList();
            
            // Filter players to only show current franchise
            final players = allPlayers.where((player) => player.franchiseId == currentFranchiseId).toList();
            
            if (players.isEmpty) {
              // Show upload interface if no data for this franchise
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.people, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Sync your Franchise',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: () => _uploadPlayerData(),
                          icon: const Icon(Icons.upload_file, size: 16),
                          label: const Text('Upload'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Upload franchise data to see players for ${_getFranchiseDisplayName()}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              );
            }
            
            // Show player data for current franchise only
            return Column(
              children: [
                // Header with upload button and search
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Color(0xFFE9ECEF), width: 1)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            '${_getFranchiseDisplayName()} Players (${players.length})',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          ElevatedButton.icon(
                            onPressed: () => _uploadPlayerData(),
                            icon: const Icon(Icons.upload_file, size: 16),
                            label: const Text('Upload New'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Search field
                      TextField(
                        controller: _playerSearchController,
                        decoration: InputDecoration(
                          hintText: 'Search players by name, position, or team...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _playerSearchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _playerSearchController.clear();
                                    setState(() {});
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFE9ECEF)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.blue, width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        onChanged: (value) {
                          setState(() {
                            _currentPage = 1; // Reset to first page when searching
                          });
                        },
                      ),
                    ],
                  ),
                ),
                // Player list with search filtering
                Expanded(
                  child: _buildFilteredPlayerList(players),
                ),
              ],
            );
          },
          loading: () => const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading players...'),
              ],
            ),
          ),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error loading players: $error',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.refresh(publicDataProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Build filtered player list with search functionality
  Widget _buildFilteredPlayerList(List<Player> players) {
    final searchQuery = _playerSearchController.text.toLowerCase();
    
    // Filter players based on search query
    final filteredPlayers = players.where((player) {
      if (searchQuery.isEmpty) return true;
      
      final fullName = '${player.firstName} ${player.lastName}'.toLowerCase();
      final position = player.position.toLowerCase();
      final team = player.team?.toLowerCase() ?? '';
      
      return fullName.contains(searchQuery) ||
             position.contains(searchQuery) ||
             team.contains(searchQuery);
    }).toList();

    if (filteredPlayers.isEmpty && searchQuery.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No players found for "$searchQuery"',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching by name, position, or team',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Sort players by overall rating (highest first)
    filteredPlayers.sort((a, b) => b.overall.compareTo(a.overall));

    // Calculate pagination
    final totalPlayers = filteredPlayers.length;
    final totalPages = (totalPlayers / _pageSize).ceil();
    
    // Reset to page 1 if current page is out of bounds
    if (_currentPage > totalPages && totalPages > 0) {
      _currentPage = 1;
    }
    
    // Get players for current page
    final startIndex = (_currentPage - 1) * _pageSize;
    final endIndex = (startIndex + _pageSize).clamp(0, totalPlayers);
    final paginatedPlayers = filteredPlayers.sublist(startIndex, endIndex);

    return Column(
      children: [
        // Pagination controls
        if (totalPlayers > _pageSize) _buildPaginationControls(totalPlayers, totalPages),
        
        // Player list
        Expanded(
          child: ListView.builder(
            itemCount: paginatedPlayers.length,
            itemBuilder: (context, index) {
              final player = paginatedPlayers[index];
              final globalIndex = startIndex + index + 1; // +1 for 1-based ranking
              
              return ListTile(
                leading: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 30,
                      alignment: Alignment.center,
                      child: Text(
                        '#$globalIndex',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      backgroundColor: Colors.blue[100],
                      child: Text(
                        player.firstName[0] + player.lastName[0],
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                title: Text('${player.firstName} ${player.lastName}'),
                subtitle: Text('${player.position} • ${player.team} • OVR: ${player.overall}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getOverallColor(player.overall),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${player.overall}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${player.age}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                onTap: () => _showPlayerCard(player),
              );
            },
          ),
        ),
      ],
    );
  }

  // Show detailed player card in content section
  void _showPlayerCard(Player player) {
    setState(() {
      _selectedPlayer = player;
      _currentView = 'player_card';
    });
    
    // Debug: Show the external URL for this player
    if (_activeFranchiseId != null && _currentServerId != null) {
      // Get the franchise name directly from the provider to avoid UUID conversion
      final franchiseAsync = ref.read(franchiseProvider(_activeFranchiseId!));
      final franchiseName = franchiseAsync.when(
        loading: () => 'franchise',
        error: (error, stack) => 'franchise',
        data: (franchise) => franchise?.name ?? 'franchise',
      );
      final urlSafeName = franchiseName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9-]'), '-');
      final serverName = FranchisePlayerApp._getServerNameFromId(_currentServerId!);
      final externalUrl = '${Uri.base.origin}/server/$serverName/franchise/$urlSafeName/player/${player.id}';
      print('🔗 EXTERNAL URL: $externalUrl');
    } else if (_activeFranchiseId != null) {
      // Get the franchise name directly from the provider to avoid UUID conversion
      final franchiseAsync = ref.read(franchiseProvider(_activeFranchiseId!));
      final franchiseName = franchiseAsync.when(
        loading: () => 'franchise',
        error: (error, stack) => 'franchise',
        data: (franchise) => franchise?.name ?? 'franchise',
      );
      final urlSafeName = franchiseName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9-]'), '-');
      final externalUrl = '${Uri.base.origin}/franchise/$urlSafeName/player/${player.id}';
      print('🔗 EXTERNAL URL: $externalUrl');
    } else {
      print('🔗 EXTERNAL URL: ${Uri.base.origin}/player/${player.id}');
    }
  }

  // Build player profile with back button
  Widget _buildPlayerProfile() {
    if (_selectedPlayer == null) return const Center(child: Text('No player selected'));
    
    return Column(
      children: [
        // Back button header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _selectedPlayer = null;
                    _currentView = 'default';
                  });
                },
              ),
              const SizedBox(width: 8),
              Text(
                'Back to Players',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
        // Player profile content - use a simple content widget instead of full page
        Expanded(
          child: _buildSimplePlayerProfile(_selectedPlayer!),
        ),
      ],
    );
  }

  // Build pagination controls
  Widget _buildPaginationControls(int totalPlayers, int totalPages) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        children: [
          // Page size selector
          Row(
            children: [
              const Text('Show: '),
              DropdownButton<int>(
                value: _pageSize,
                items: _pageSizeOptions.map((size) {
                  return DropdownMenuItem(
                    value: size,
                    child: Text('$size'),
                  );
                }).toList(),
                onChanged: (newSize) {
                  if (newSize != null) {
                    setState(() {
                      _pageSize = newSize;
                      _currentPage = 1; // Reset to first page
                    });
                  }
                },
              ),
            ],
          ),
          const SizedBox(width: 16),
          
          // Player count info
          Text(
            'Showing ${((_currentPage - 1) * _pageSize) + 1}-${(_currentPage * _pageSize).clamp(0, totalPlayers)} of $totalPlayers players',
            style: TextStyle(color: Colors.grey[600]),
          ),
          
          const Spacer(),
          
          // Pagination buttons
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _currentPage > 1 ? () {
                  setState(() {
                    _currentPage--;
                  });
                } : null,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$_currentPage / $totalPages',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _currentPage < totalPages ? () {
                  setState(() {
                    _currentPage++;
                  });
                } : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Get color based on overall rating
  Color _getOverallColor(int overall) {
    if (overall >= 95) return Colors.purple[700]!;
    if (overall >= 90) return Colors.red[600]!;
    if (overall >= 85) return Colors.orange[600]!;
    if (overall >= 80) return Colors.yellow[700]!;
    if (overall >= 75) return Colors.green[600]!;
    if (overall >= 70) return Colors.blue[600]!;
    return Colors.grey[600]!;
  }



  // Build detailed player card view
  Widget _buildPlayerCardView() {
    if (_selectedPlayer == null) {
      return const Center(child: Text('No player selected'));
    }

    final player = _selectedPlayer!;
    
    return Column(
      children: [
        // Header with back button
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFE9ECEF), width: 1)),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _currentView = 'default';
                    _selectedPlayer = null;
                    // Set the active channel back to 'players' to show the player list
                    _activeFranchiseChannelId = 'players';
                    _activeFranchiseChannelName = 'Players';
                  });
                },
              ),
              const SizedBox(width: 8),
              Text(
                'Player Profile',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        // Player card content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Player header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.blue[100],
                      child: Text(
                        player.firstName[0] + player.lastName[0],
                        style: TextStyle(
                          fontSize: 24,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${player.firstName} ${player.lastName}',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${player.position} • ${player.team}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.blue[200]!),
                                ),
                                child: Text(
                                  'OVR: ${player.playerBestOvr}',
                                  style: TextStyle(
                                    color: Colors.blue[700],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: Text(
                                  'Age: ${player.age}',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                
                // Player details grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 2.5,
                  children: [
                                         _buildDetailCard('Height', player.height?.toString() ?? 'N/A', Icons.height),
                     _buildDetailCard('Weight', player.weight?.toString() ?? 'N/A', Icons.monitor_weight),
                     _buildDetailCard('College', player.college ?? 'N/A', Icons.school),
                     _buildDetailCard('Experience', '${player.draftRound ?? 0} years', Icons.work),
                     _buildDetailCard('Contract', '${player.draftPick ?? 0} years', Icons.description),
                     _buildDetailCard('Salary', '\$${(player.jerseyNum ?? 0).toStringAsFixed(0)}', Icons.attach_money),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Player stats section
                Text(
                  'Player Statistics',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Stats grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2,
                  children: [
                                         _buildStatCard('Speed', player.speedRating, Icons.speed),
                     _buildStatCard('Strength', player.strengthRating ?? 0, Icons.fitness_center),
                     _buildStatCard('Agility', player.agilityRating ?? 0, Icons.directions_run),
                     _buildStatCard('Catch', player.catchRating ?? 0, Icons.handshake),
                     _buildStatCard('Tackle', player.tackleRating ?? 0, Icons.sports_football),
                     _buildStatCard('Awareness', player.awareRating ?? 0, Icons.psychology),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Build detail card widget
  Widget _buildDetailCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Build stat card widget
  Widget _buildStatCard(String title, int value, IconData icon) {
    final percentage = value / 100;
    final color = percentage > 0.8 ? Colors.green : 
                  percentage > 0.6 ? Colors.orange : 
                  percentage > 0.4 ? Colors.yellow : Colors.red;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // --- TEAMS TAB ---
  Widget _buildTeamsTab() {
    // Always show upload interface for all servers - no hardcoded data
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.groups, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No Team Data Available',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Upload franchise data to see teams',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // --- STANDINGS TAB ---
  Widget _buildPowerRankingsAndStandings() {
    // Always show upload interface for all servers - no hardcoded data
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.format_list_numbered, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No Standings Available',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Upload franchise data to see standings',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // --- AWARDS TAB ---
  Widget _buildAwardsTab() {
    // Always show upload interface for all servers - no hardcoded data
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No Awards Available',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Upload franchise data to see awards',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _uploadPlayerData() async {
    // Create a file input element
    final input = html.FileUploadInputElement()
      ..accept = '.json'
      ..click();

    input.onChange.listen((event) async {
      final file = input.files?.first;
      if (file != null) {
        final reader = html.FileReader();
        reader.onLoad.listen((event) async {
          try {
            final jsonString = reader.result as String;
            final jsonData = json.decode(jsonString) as List;
            
            // Validate that it's a list of player objects
            if (jsonData.isNotEmpty && jsonData.first is Map) {
              // Process the data to ensure it has the correct franchise ID
              final processedData = jsonData.map<Map<String, dynamic>>((player) {
                final playerMap = Map<String, dynamic>.from(player);
                
                // Ensure franchiseId is set correctly
                playerMap['franchiseId'] = _activeFranchiseId;
                
                // Generate unique IDs for players that don't have them
                if (playerMap['id'] == null || 
                    playerMap['id'].toString().length < 9 ||
                    playerMap['id'].toString().contains(' ')) {
                  final timestamp = DateTime.now().millisecondsSinceEpoch;
                  // Extract server number from franchise ID (e.g., "franchise-server-1" -> "1")
                  final serverMatch = RegExp(r'server-(\d+)').firstMatch(_activeFranchiseId ?? '');
                  final serverNum = serverMatch?.group(1) ?? '0';
                  final randomSuffix = (timestamp % 1000).toString().padLeft(3, '0');
                  playerMap['id'] = '${serverNum}${randomSuffix}${timestamp.toString().substring(timestamp.toString().length - 3)}';
                }
                
                return playerMap;
              }).toList();
              
              // Upload to Supabase
              await _uploadToSupabase(processedData);
              
              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Successfully uploaded ${processedData.length} players to ${_getFranchiseDisplayName()}'),
                  backgroundColor: Colors.green,
                ),
              );
              
              // Refresh the data
              ref.invalidate(publicDataProvider);
              
            } else {
              throw Exception('Invalid JSON format - expected array of player objects');
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error uploading data: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        });
        reader.readAsText(file);
      }
    });
  }

  Future<void> _uploadToSupabase(List<Map<String, dynamic>> players) async {
    try {
      // Import the Supabase client
      final supabase = Supabase.instance.client;
      
      // Get the current user
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      
      // Determine franchise ID from the current context
      final franchiseId = _activeFranchiseId ?? 'unknown-franchise';
      
      // Insert the new player data as a live version
      // The database trigger will automatically move the previous live version to rollback
      await supabase
          .from('versioned_uploads')
          .insert({
            'user_id': user.id,
            'franchise_id': franchiseId,
            'upload_type': 'roster',
            'version_status': 'live',
            'payload': players,
            'uploaded_at': DateTime.now().toIso8601String(),
          });
      
    } catch (e) {
      throw Exception('Failed to upload to Supabase: $e');
    }
  }

  String _getFranchiseDisplayName() {
    print('🔍 DEBUG: _getFranchiseDisplayName() called with _activeFranchiseId: $_activeFranchiseId');
    if (_activeFranchiseId == null) {
      // When no franchise is selected, show server info or "Select a Franchise"
      if (_currentServerId != null) {
        return 'Select a Franchise';
      }
      return 'Select a Server';
    }
    
    // Extract the actual UUID from the franchise ID
    final actualFranchiseId = _extractFranchiseId(_activeFranchiseId!);
    print('🔍 DEBUG: Extracted franchise ID: $actualFranchiseId');
    
    // Get the franchise data from the provider
    final franchiseAsync = ref.watch(franchiseProvider(actualFranchiseId));
    
    return franchiseAsync.when(
      loading: () => 'Loading...',
      error: (error, stack) => 'Error: $error',
      data: (franchise) {
        if (franchise == null) {
          print('🔍 DEBUG: Franchise not found for ID: $actualFranchiseId');
          return 'Unknown Franchise';
        }
        print('🔍 DEBUG: Found franchise: ${franchise.name}');
        return franchise.name;
      },
    );
  }

  // Extract the actual UUID from a franchise ID
  String _extractFranchiseId(String franchiseId) {
    // If it starts with 'franchise-', extract the UUID part
    if (franchiseId.startsWith('franchise-')) {
      return franchiseId.substring('franchise-'.length);
    }
    // If it ends with '-franchise', extract the UUID part
    if (franchiseId.endsWith('-franchise')) {
      return franchiseId.substring(0, franchiseId.length - '-franchise'.length);
    }
    // Otherwise, assume it's already a UUID
    return franchiseId;
  }

  // Show server settings dialog
  void _showServerSettingsDialog(Map<String, dynamic> server) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ServerSettingsDialog(server: server);
      },
    );
  }





  // Load the first franchise from a server and set it as active
  void _loadFirstFranchiseFromServer(String serverId) async {
    try {
      print('🔍 DEBUG: Loading first franchise from server: $serverId');
      
      // Fetch franchises from the server
      final franchisesAsync = ref.read(franchisesProvider(serverId));
      
      franchisesAsync.when(
        loading: () {
          print('🔍 DEBUG: Loading franchises...');
        },
        error: (error, stack) {
          print('🔍 DEBUG: Error loading franchises: $error');
        },
        data: (franchises) {
          if (franchises.isNotEmpty) {
            final firstFranchise = franchises.first;
            print('🔍 DEBUG: Found first franchise: ${firstFranchise.name} (${firstFranchise.id})');
            
            setState(() {
              _activeFranchiseId = firstFranchise.id;
              _activeFranchiseChannelId = null;
              _activeFranchiseChannelName = null;
            });
            
            // Update the URL to show the franchise
            _updateFranchiseUrl(firstFranchise.id);
          } else {
            print('🔍 DEBUG: No franchises found in server: $serverId');
          }
        },
      );
    } catch (e) {
      print('🔍 DEBUG: Exception loading first franchise: $e');
    }
  }

  Color _parseColor(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
  }
} 