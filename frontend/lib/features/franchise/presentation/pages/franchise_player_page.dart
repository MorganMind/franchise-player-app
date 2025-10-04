import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../providers/franchise_providers.dart';
import '../../../../views/player_profile.dart';

class FranchisePlayerPage extends ConsumerWidget {
  final String franchiseNameOrId;
  final String playerId;

  const FranchisePlayerPage({
    Key? key,
    required this.franchiseNameOrId,
    required this.playerId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // If it looks like a UUID, use it directly
    if (franchiseNameOrId.contains('-') && franchiseNameOrId.length > 20) {
      return PlayerProfilePage(playerId: playerId);
    }

    // Otherwise, look up the franchise by name
    final franchiseAsync = ref.watch(franchiseByNameProvider(franchiseNameOrId));

    return franchiseAsync.when(
      data: (franchise) {
        if (franchise == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Franchise Not Found'),
            ),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'Franchise not found',
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'The franchise you are looking for does not exist.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        // Franchise found, show player profile
        return PlayerProfilePage(playerId: playerId);
      },
      loading: () => const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading franchise...'),
            ],
          ),
        ),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error loading franchise',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
