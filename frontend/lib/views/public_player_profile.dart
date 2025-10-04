import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/public_data_provider.dart';

class PublicPlayerProfilePage extends ConsumerWidget {
  final String playerId;
  final String? franchiseId;
  
  const PublicPlayerProfilePage({
    super.key, 
    required this.playerId,
    this.franchiseId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playersState = ref.watch(publicDataProvider);
    
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
                onPressed: () => ref.read(publicDataProvider.notifier).refreshData(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (players) {
        // Debug logging
        print('🔍 DEBUG: PublicPlayerProfilePage - Looking for playerId: $playerId');
        print('🔍 DEBUG: PublicPlayerProfilePage - franchiseId: $franchiseId');
        print('🔍 DEBUG: PublicPlayerProfilePage - Total players from provider: ${players.length}');
        
        // Log first few players for debugging
        if (players.isNotEmpty) {
          print('🔍 DEBUG: First 3 players:');
          for (int i = 0; i < players.length && i < 3; i++) {
            final p = players[i];
            print('  Player $i: id=${p.id}, franchiseId=${p.franchiseId}, name=${p.firstName} ${p.lastName}');
          }
        }
        
        try {
          // Filter players by franchise if franchiseId is provided
          final filteredPlayers = franchiseId != null 
              ? players.where((p) => p.franchiseId == franchiseId).toList()
              : players;
          
          print('🔍 DEBUG: After franchise filtering: ${filteredPlayers.length} players');
          if (filteredPlayers.isNotEmpty) {
            print('🔍 DEBUG: First 3 filtered players:');
            for (int i = 0; i < filteredPlayers.length && i < 3; i++) {
              final p = filteredPlayers[i];
              print('  Filtered Player $i: id=${p.id}, franchiseId=${p.franchiseId}, name=${p.firstName} ${p.lastName}');
            }
          }
          
          // Check if player exists in filtered list
          final playerExists = filteredPlayers.any((p) => p.id == playerId);
          print('🔍 DEBUG: Player $playerId exists in filtered list: $playerExists');
          
          if (!playerExists) {
            print('🔍 DEBUG: Available player IDs in filtered list:');
            for (final p in filteredPlayers.take(5)) {
              print('  - ${p.id}');
            }
          }
          
          final player = filteredPlayers.firstWhere(
            (p) => p.id == playerId,
          );
          
          print('🔍 DEBUG: Found player: ${player.firstName} ${player.lastName} (${player.id})');
          return _buildPlayerProfile(context, player);
        } catch (e) {
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
                  Text(
                    franchiseId != null 
                        ? 'This player is not available in ${_getFranchiseName(franchiseId)}'
                        : 'This player data is not available in the public view'
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }

  String _getFranchiseName(String? franchiseId) {
    switch (franchiseId) {
      case 'franchise-1':
        return 'Madden League Alpha';
      case 'franchise-2':
        return 'Franchise 2';
      case 'franchise-3':
        return 'Franchise 3';
      case 'franchise-4':
        return 'Franchise 4';
      case 'franchise-5':
        return 'Franchise 5';
      default:
        return 'this franchise';
    }
  }

  Widget _buildPlayerProfile(BuildContext context, dynamic player) {
    final gold = Theme.of(context).colorScheme.primary;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(player.fullName),
        elevation: 2,
        actions: [
          // Login button for public users
          TextButton.icon(
            onPressed: () => context.go('/login'),
            icon: const Icon(Icons.login),
            label: const Text('Login'),
          ),
        ],
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
                          '${player.firstName} ${player.lastName}',
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${player.position} • ${player.team ?? 'Free Agent'}',
                          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _buildStatChip('OVR', (player.playerBestOvr > 0 ? player.playerBestOvr : player.playerSchemeOvr).toString(), gold),
                            const SizedBox(width: 12),
                            _buildStatChip('Age', player.age.toString(), gold),
                            const SizedBox(width: 12),
                            _buildStatChip('Speed', player.speedRating.toString(), gold),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Player Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Player Information',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('Height', player.height != null ? '${(player.height! / 12).floor()}\'${player.height! % 12}"' : 'N/A'),
                  _buildInfoRow('Weight', player.weight?.toString() ?? 'N/A'),
                  _buildInfoRow('College', player.college ?? 'N/A'),
                  _buildInfoRow('Jersey', player.jerseyNum?.toString() ?? 'N/A'),
                  
                  const SizedBox(height: 24),
                  const Text(
                    'Key Attributes',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildAttributeRow('Throw Power', player.throwPowerRating?.toString() ?? 'N/A'),
                  _buildAttributeRow('Catching', player.catchRating?.toString() ?? 'N/A'),
                  _buildAttributeRow('Strength', player.strengthRating?.toString() ?? 'N/A'),
                  _buildAttributeRow('Agility', player.agilityRating?.toString() ?? 'N/A'),
                  _buildAttributeRow('Awareness', player.awareRating?.toString() ?? 'N/A'),
                  _buildAttributeRow('Tackle', player.tackleRating?.toString() ?? 'N/A'),
                  _buildAttributeRow('Stamina', player.staminaRating?.toString() ?? 'N/A'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: color.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
            ),
          ),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildAttributeRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
