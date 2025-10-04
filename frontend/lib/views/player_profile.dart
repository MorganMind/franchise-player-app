import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/player.dart';
import '../providers/player_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/public_data_provider.dart';
import 'public_player_profile.dart';

class PlayerProfilePage extends ConsumerWidget {
  final String playerId;
  
  const PlayerProfilePage({super.key, required this.playerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    
    // Get franchise context from URL if available
    final uri = GoRouterState.of(context).uri;
    final routeState = GoRouterState.of(context);
    String? franchiseId;
    
    print('🔍 DEBUG: PlayerProfilePage - Full URI: ${uri.toString()}');
    print('🔍 DEBUG: PlayerProfilePage - URI path: ${uri.path}');
    print('🔍 DEBUG: PlayerProfilePage - URI fragment: ${uri.fragment}');
    print('🔍 DEBUG: PlayerProfilePage - Route path parameters: ${routeState.pathParameters}');
    
    // Check if we're in a franchise player route (e.g., /franchise/franchise-2/player/123)
    if (routeState.pathParameters.containsKey('franchiseId')) {
      franchiseId = routeState.pathParameters['franchiseId'];
      print('🔍 DEBUG: PlayerProfilePage - Extracted franchiseId from route params: $franchiseId');
    } else if (uri.path.startsWith('/franchise/')) {
      // Fallback: parse from URL path (e.g., /franchise/franchise-2#/player/...)
      final pathSegments = uri.path.split('/');
      print('🔍 DEBUG: PlayerProfilePage - Path segments: $pathSegments');
      if (pathSegments.length >= 3) {
        franchiseId = pathSegments[2]; // Get franchise ID from /franchise/franchise-X
        print('🔍 DEBUG: PlayerProfilePage - Extracted franchiseId from path: $franchiseId');
      }
    } else {
      print('🔍 DEBUG: PlayerProfilePage - Not in franchise context');
    }
    
    // Show public view for player routes (router handles authentication)
    if (!isAuthenticated) {
      return PublicPlayerProfilePage(
        playerId: playerId,
        franchiseId: franchiseId,
      );
    }
    
    // Show full player profile with server features for authenticated users
    final player = ref.watch(playerProvider.notifier).getPlayerById(playerId);
    final playersState = ref.watch(playerProvider);

    return playersState.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading player: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(playerProvider.notifier).refreshData(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (_) {
        if (player == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Player Not Found')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Player not found'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.go('/rosters'),
                    child: const Text('Back to Rosters'),
                  ),
                ],
              ),
            ),
          );
        }

        return _PlayerProfileContent(player: player);
      },
    );
  }
}

class _PlayerProfileContent extends StatelessWidget {
  final Player player;
  
  const _PlayerProfileContent({required this.player});

  @override
  Widget build(BuildContext context) {
    final gold = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(
        title: SelectableText(player.fullName),
        elevation: 2,
      ),
      body: SingleChildScrollView(
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
                    child: SelectableText(
                      player.position,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 32, color: gold),
                    ),
                  ),
                  const SizedBox(width: 32),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SelectableText(
                          player.fullName,
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _bioItem('Team', player.team ?? 'FA'),
                            _bioItem('Jersey #', player.jerseyNum?.toString() ?? '-'),
                            _bioItem('Position', player.position),
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
                      _bioItem('Age', player.age.toString()),
                      _bioItem('Height', player.height?.toString() ?? '-'),
                      _bioItem('Weight', player.weight?.toString() ?? '-'),
                      _bioItem('College', player.college ?? '-'),
                      _bioItem('Draft', player.draftRound != null ? 'R${player.draftRound} P${player.draftPick}' : '-'),
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
                          _statItem('Overall', player.overall.toString()),
                          _statItem('Speed', player.speedRating.toString()),
                          _statItem('Strength', player.strengthRating?.toString() ?? '-'),
                          _statItem('Agility', player.agilityRating?.toString() ?? '-'),
                          _statItem('Awareness', player.awareRating?.toString() ?? '-'),
                          _statItem('Catching', player.catchRating?.toString() ?? '-'),
                          _statItem('Tackle', player.tackleRating?.toString() ?? '-'),
                          _statItem('Throw Power', player.throwPowerRating?.toString() ?? '-'),
                          _statItem('Stamina', player.staminaRating?.toString() ?? '-'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // TODO: Add more sections (season stats, career highlights, abilities, etc.)
          ],
        ),
      ),
    );
  }

  Widget _bioItem(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8.0),
    child: Column(
      children: [
        SelectableText(label, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700], fontSize: 13)),
        const SizedBox(height: 4),
        SelectableText(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      ],
    ),
  );

  Widget _statItem(String label, String value) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      SelectableText(label, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700], fontSize: 13)),
      const SizedBox(height: 4),
      SelectableText(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
    ],
  );
} 