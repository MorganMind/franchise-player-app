import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/player.dart';
import '../providers/player_provider.dart';

class PlayerProfilePage extends ConsumerWidget {
  final String playerId;
  
  const PlayerProfilePage({required this.playerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(playerProvider.notifier).getPlayerById(playerId);
    final playersState = ref.watch(playerProvider);

    return playersState.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text('Loading...')),
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text('Error loading player: $error'),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(playerProvider.notifier).refreshData(),
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (_) {
        if (player == null) {
          return Scaffold(
            appBar: AppBar(title: Text('Player Not Found')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Player not found'),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.go('/rosters'),
                    child: Text('Back to Rosters'),
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
        title: Text(player.fullName),
        elevation: 2,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              color: gold.withOpacity(0.12),
              padding: EdgeInsets.symmetric(vertical: 32, horizontal: 16),
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
                  SizedBox(width: 32),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          player.fullName,
                          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
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
                      Text('Key Ratings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                      SizedBox(height: 12),
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
        Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700], fontSize: 13)),
        SizedBox(height: 4),
        Text(value, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      ],
    ),
  );

  Widget _statItem(String label, String value) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700], fontSize: 13)),
      SizedBox(height: 4),
      Text(value, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
    ],
  );
} 