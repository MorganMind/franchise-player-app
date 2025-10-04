import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'dart:html' as html;
import '../models/player.dart';
import '../providers/player_provider.dart';
import '../providers/auth_provider.dart';

class RostersHomePage extends ConsumerStatefulWidget {
  final String? franchiseId;
  
  const RostersHomePage({super.key, this.franchiseId});

  @override
  ConsumerState<RostersHomePage> createState() => _RostersHomePageState();
}

class _RostersHomePageState extends ConsumerState<RostersHomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    ref.read(searchQueryProvider.notifier).state = searchController.text;
  }

  void _openPlayerProfile(Player player) {
    // Always use franchise context for player navigation
    if (widget.franchiseId != null) {
      final franchiseName = _getFranchiseName();
      final urlSafeName = franchiseName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9-]'), '-');
      context.go('/franchise/$urlSafeName/player/${player.id}', extra: player);
    } else {
      // Fallback for cases without franchise context
      context.go('/player/${player.id}', extra: player);
    }
  }

  String _getFranchiseName() {
    if (widget.franchiseId == null) return '';
    
    // Map franchise IDs to names
    switch (widget.franchiseId) {
      case 'franchise-1':
        return 'Madden League Alpha';
      case 'franchise-2':
        return 'Casual Franchise';
      case 'franchise-3':
        return 'Pro League';
      default:
        return 'Unknown Franchise';
    }
  }

  Widget _buildPlayersTab() {
    final players = ref.watch(searchResultsProvider);
    final playersState = ref.watch(playerProvider);

    return playersState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error loading players: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(playerProvider.notifier).refreshData(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (_) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: const InputDecoration(
                labelText: 'Search Players',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: players.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off, size: 64, color: Colors.grey),
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
                        if (searchController.text.isNotEmpty)
                          const Text('Try adjusting your search terms'),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: players.length,
                    itemBuilder: (context, index) {
                      final player = players[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        elevation: 6,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () => _openPlayerProfile(player),
                          child: Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    CircleAvatar(
                                      radius: 32,
                                      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                                      child: Text(
                                        player.position,
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Theme.of(context).colorScheme.primary),
                                      ),
                                    ),
                                    const SizedBox(width: 24),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          SelectableText(
                                            player.fullName,
                                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              _statLabel('Age'),
                                              _statValue(player.age.toString()),
                                              _statLabel('OVR'),
                                              _statValue(player.overall.toString()),
                                              _statLabel('SPD'),
                                              _statValue(player.speedRating.toString()),
                                              _statLabel('Team'),
                                              _statValue(player.team ?? 'FA'),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(Icons.arrow_forward_ios, size: 20, color: Theme.of(context).colorScheme.primary),
                                  ],
                                ),
                              ),
                              // Franchise label in upper right corner
                              if (widget.franchiseId != null)
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      _getFranchiseName(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _statLabel(String label) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4.0),
    child: SelectableText(
      label,
      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700], fontSize: 13),
    ),
  );

  Widget _statValue(String value) => Padding(
    padding: const EdgeInsets.only(right: 10.0),
    child: Text(
      value,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
    ),
  );

  Widget _buildTeamsTab() {
    final teams = ref.watch(teamsProvider);
    final teamsState = ref.watch(playerProvider);

    return teamsState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error loading teams: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(playerProvider.notifier).refreshData(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (_) => teams.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.groups, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No teams found'),
                ],
              ),
            )
          : ListView.builder(
              itemCount: teams.length,
              itemBuilder: (context, index) {
                final teamName = teams.keys.elementAt(index);
                final teamPlayers = teams[teamName]!;
                
                return ExpansionTile(
                  title: Text(
                    teamName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  subtitle: Text('${teamPlayers.length} players'),
                  children: teamPlayers.map((player) => ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                      child: Text(
                        player.position,
                        style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                    title: Text(player.fullName),
                    subtitle: Text('${player.position} • OVR: ${player.overall} • Age: ${player.age}'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _openPlayerProfile(player),
                  )).toList(),
                );
              },
            ),
    );
  }

  Widget _buildFreeAgentsTab() {
    final freeAgents = ref.watch(freeAgentsProvider);
    final playersState = ref.watch(playerProvider);

    return playersState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error loading free agents: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(playerProvider.notifier).refreshData(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (_) => freeAgents.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No free agents found'),
                ],
              ),
            )
          : ListView.builder(
              itemCount: freeAgents.length,
              itemBuilder: (context, index) {
                final player = freeAgents[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange.withOpacity(0.15),
                      child: Text(
                        player.position,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                      ),
                    ),
                    title: Text(player.fullName),
                    subtitle: Text('${player.position} • OVR: ${player.overall} • Age: ${player.age}'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _openPlayerProfile(player),
                  ),
                );
              },
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final useLocalData = ref.watch(useLocalDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Player Rosters'),
        actions: [
          // Data source toggle (only for specific user)
          if (user?.email == 'nashabramsx@gmail.com')
            IconButton(
              icon: Icon(useLocalData ? Icons.storage : Icons.cloud),
              tooltip: 'Toggle Data Source (${useLocalData ? 'Local' : 'Supabase'})',
              onPressed: () {
                ref.read(playerProvider.notifier).setUseLocalData(!useLocalData);
              },
            ),
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Data',
            onPressed: () => ref.read(playerProvider.notifier).refreshData(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Theme(
            data: Theme.of(context).copyWith(
              tabBarTheme: TabBarThemeData(
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                indicator: UnderlineTabIndicator(
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'All Players'),
                Tab(text: 'Teams'),
                Tab(text: 'Free Agents'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPlayersTab(),
          _buildTeamsTab(),
          _buildFreeAgentsTab(),
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
                if (widget.franchiseId != null) {
                  playerMap['franchiseId'] = widget.franchiseId;
                }
                
                // Generate unique IDs for players that don't have them
                if (playerMap['id'] == null || 
                    playerMap['id'].toString().length < 9 ||
                    playerMap['id'].toString().contains(' ')) {
                  final timestamp = DateTime.now().millisecondsSinceEpoch;
                  // Extract server number from franchise ID (e.g., "franchise-server-1" -> "1")
                  final serverMatch = RegExp(r'server-(\d+)').firstMatch(widget.franchiseId ?? '');
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
                  content: Text('Successfully uploaded ${processedData.length} players to ${_getFranchiseName()}'),
                  backgroundColor: Colors.green,
                ),
              );
              
              // Refresh the data
              ref.read(playerProvider.notifier).refreshData();
              
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
      
      // First, delete any existing data for this user (we'll replace all their data)
      await supabase
          .from('json_uploads')
          .delete()
          .eq('user_id', user.id);
      
      // Insert the new player data
      await supabase
          .from('json_uploads')
          .insert({
            'user_id': user.id,
            'payload': players,
            'uploaded_at': DateTime.now().toIso8601String(),
          });
      
    } catch (e) {
      throw Exception('Failed to upload to Supabase: $e');
    }
  }
} 