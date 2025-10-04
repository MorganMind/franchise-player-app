import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'dart:html' as html;
import '../providers/auth_provider.dart';
import '../providers/public_data_provider.dart';
import 'public_franchise_page.dart';

class FranchisePage extends ConsumerWidget {
  final String franchiseId;
  
  const FranchisePage({super.key, required this.franchiseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    
    // Show public view for franchise routes (router handles authentication)
    if (!isAuthenticated) {
      return PublicFranchisePage(franchiseId: franchiseId);
    }
    
    // Show full franchise view with server features for authenticated users
    return _AuthenticatedFranchiseView(franchiseId: franchiseId);
  }
}

class _AuthenticatedFranchiseView extends ConsumerStatefulWidget {
  final String franchiseId;
  
  const _AuthenticatedFranchiseView({required this.franchiseId});

  @override
  ConsumerState<_AuthenticatedFranchiseView> createState() => _AuthenticatedFranchiseViewState();
}

class _AuthenticatedFranchiseViewState extends ConsumerState<_AuthenticatedFranchiseView> {
  String selectedTab = 'players';
  String currentFranchiseId = 'franchise-server-1';
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text('Franchise: '),
            DropdownButton<String>(
              value: currentFranchiseId,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    currentFranchiseId = newValue;
                  });
                }
              },
              items: [
                DropdownMenuItem(
                  value: 'franchise-server-1',
                  child: Text('Madden League Alpha'),
                ),
                DropdownMenuItem(
                  value: 'franchise-server-2',
                  child: Text('Casual Gaming League'),
                ),
                DropdownMenuItem(
                  value: 'franchise-server-3',
                  child: Text('Support Server League'),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.business),
            onPressed: () {
              context.go('/franchise-management');
            },
            tooltip: 'Franchise Management',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Open franchise settings
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab navigation
          Container(
            color: Theme.of(context).colorScheme.surface,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildTabButton('News', 'news'),
                  _buildTabButton('Players', 'players'),
                  _buildTabButton('Games', 'games'),
                  _buildTabButton('Standings', 'standings'),
                  _buildTabButton('Statistics', 'statistics'),
                  _buildTabButton('Trades', 'trades'),
                  _buildTabButton('Awards', 'awards'),
                  _buildTabButton('Rules', 'rules'),
                ],
              ),
            ),
          ),
          // Content area
          Expanded(
            child: _buildTabContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, String tabId) {
    final isSelected = selectedTab == tabId;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: ElevatedButton(
        onPressed: () => setState(() => selectedTab = tabId),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected 
            ? Theme.of(context).colorScheme.primary 
            : Theme.of(context).colorScheme.surface,
          foregroundColor: isSelected 
            ? Theme.of(context).colorScheme.onPrimary 
            : Theme.of(context).colorScheme.onSurface,
        ),
        child: Text(label),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (selectedTab) {
      case 'players':
        return _buildPlayersTab();
      case 'teams':
        return _buildTeamsTab();
      case 'statistics':
        return _buildStatisticsTab();
      case 'standings':
        return _buildStandingsTab();
      case 'trades':
        return _buildTradesTab();
      case 'awards':
        return _buildAwardsTab();
      case 'news':
        return _buildNewsTab();
      case 'games':
        return _buildGamesTab();
      case 'rules':
        return _buildRulesTab();
      default:
        return _buildPlayersTab();
    }
  }

  String _getFranchiseName() {
    switch (currentFranchiseId) {
      case 'franchise-server-1':
        return 'Madden League Alpha';
      case 'franchise-server-2':
        return 'Casual Gaming League';
      case 'franchise-server-3':
        return 'Support Server League';
      default:
        return 'Unknown Franchise';
    }
  }

  String _getFranchiseUrlSafeName() {
    final franchiseName = _getFranchiseName();
    return franchiseName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9-]'), '-');
  }

  Widget _buildPlayersTab() {
    final publicData = ref.watch(publicDataProvider);
    
    return publicData.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (data) {
        print('🔍 DEBUG: Total players from provider: ${data.length}');
        print('🔍 DEBUG: Looking for franchise: $currentFranchiseId');
        final players = data.where((p) => p.franchiseId == currentFranchiseId).toList();
        print('🔍 DEBUG: Found ${players.length} players for franchise: $currentFranchiseId');
        
        return Column(
          children: [
            // Header with upload button
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Players (${players.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _uploadPlayerData(),
                    icon: const Icon(Icons.upload_file, size: 16),
                    label: const Text('Upload JSON'),
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
            ),
            // Content area
            Expanded(
              child: players.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.people_outline, size: 64, color: Colors.grey),
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
                          const Text(
                            'Upload franchise data to see players',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: players.length,
                      itemBuilder: (context, index) {
                        final player = players[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text(player.position),
                            ),
                            title: Text('${player.firstName} ${player.lastName}'),
                            subtitle: Text('${player.position} • ${player.teamId ?? 'Free Agent'}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('OVR: ${player.playerBestOvr > 0 ? player.playerBestOvr : player.playerSchemeOvr}'),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.visibility),
                                  onPressed: () => context.go('/franchise/${_getFranchiseUrlSafeName()}/player/${player.id}'),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTeamsTab() {
    // TODO: Implement teams tab for authenticated users
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.groups, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('Teams Management'),
          SizedBox(height: 8),
          Text('Coming soon for authenticated users'),
        ],
      ),
    );
  }

  Widget _buildStatisticsTab() {
    // TODO: Implement statistics tab for authenticated users
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('Advanced Statistics'),
          SizedBox(height: 8),
          Text('Coming soon for authenticated users'),
        ],
      ),
    );
  }

  Widget _buildStandingsTab() {
    // TODO: Implement standings tab for authenticated users
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.format_list_numbered, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('Advanced Standings'),
          SizedBox(height: 8),
          Text('Coming soon for authenticated users'),
        ],
      ),
    );
  }

  Widget _buildTradesTab() {
    // TODO: Implement trades tab for authenticated users
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.swap_horiz, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('Trade Management'),
          SizedBox(height: 8),
          Text('Coming soon for authenticated users'),
        ],
      ),
    );
  }

  Widget _buildAwardsTab() {
    // TODO: Implement awards tab for authenticated users
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('Awards Management'),
          SizedBox(height: 8),
          Text('Coming soon for authenticated users'),
        ],
      ),
    );
  }

  Widget _buildNewsTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.article, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('Franchise News'),
          SizedBox(height: 8),
          Text('Coming soon'),
        ],
      ),
    );
  }

  Widget _buildGamesTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sports_soccer, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('Games & Schedule'),
          SizedBox(height: 8),
          Text('Coming soon'),
        ],
      ),
    );
  }

  Widget _buildRulesTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.gavel, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('Franchise Rules'),
          SizedBox(height: 8),
          Text('Coming soon'),
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
              print('🔍 DEBUG: Uploading to franchise: $currentFranchiseId');
              final processedData = jsonData.map<Map<String, dynamic>>((player) {
                final playerMap = Map<String, dynamic>.from(player);
                
                // Ensure franchiseId is set correctly
                playerMap['franchiseId'] = currentFranchiseId;
                print('🔍 DEBUG: Set player franchiseId to: ${playerMap['franchiseId']}');
                
                // Generate unique IDs for players that don't have them
                if (playerMap['id'] == null || 
                    playerMap['id'].toString().length < 9 ||
                    playerMap['id'].toString().contains(' ')) {
                  final timestamp = DateTime.now().millisecondsSinceEpoch;
                  // Extract server number from franchise ID (e.g., "franchise-server-1" -> "1")
                  final serverMatch = RegExp(r'server-(\d+)').firstMatch(currentFranchiseId);
                  final serverNum = serverMatch?.group(1) ?? '1';
                  final randomSuffix = (timestamp % 1000).toString().padLeft(3, '0');
                  playerMap['id'] = '${serverNum}${randomSuffix}${timestamp.toString().substring(timestamp.toString().length - 3)}';
                }
                
                return playerMap;
              }).toList();
              
              // Upload to Supabase
              print('🔍 DEBUG: About to upload ${processedData.length} players to Supabase');
              await _uploadToSupabase(processedData);
              print('🔍 DEBUG: Upload completed successfully');
              
              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Successfully uploaded ${processedData.length} players to ${_getFranchiseName()}'),
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
      print('🔍 DEBUG: Starting Supabase upload for ${players.length} players');
      // Import the Supabase client
      final supabase = Supabase.instance.client;
      
      // Get the current user
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      print('🔍 DEBUG: User authenticated: ${user.id}');
      
      // First, delete any existing data for this user (we'll replace all their data)
      print('🔍 DEBUG: Deleting existing data for user');
      await supabase
          .from('json_uploads')
          .delete()
          .eq('user_id', user.id);
      
      // Insert the new player data
      print('🔍 DEBUG: Inserting ${players.length} players into database');
      await supabase
          .from('json_uploads')
          .insert({
            'user_id': user.id,
            'payload': players,
            'uploaded_at': DateTime.now().toIso8601String(),
          });
      print('🔍 DEBUG: Database insert completed');
      
    } catch (e) {
      throw Exception('Failed to upload to Supabase: $e');
    }
  }
}
