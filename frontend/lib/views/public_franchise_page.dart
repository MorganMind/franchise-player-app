import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'dart:html' as html;
import '../providers/public_data_provider.dart';

class PublicFranchisePage extends ConsumerStatefulWidget {
  final String franchiseId;
  final String? initialTab;
  
  const PublicFranchisePage({
    super.key, 
    required this.franchiseId, 
    this.initialTab,
  });

  @override
  ConsumerState<PublicFranchisePage> createState() => _PublicFranchisePageState();
}

class _PublicFranchisePageState extends ConsumerState<PublicFranchisePage> {
  late String selectedTab;

  @override
  void initState() {
    super.initState();
    selectedTab = widget.initialTab ?? 'players';
  }

  String _getFranchiseName() {
    switch (widget.franchiseId) {
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

  void _onTabChanged(String tab) {
    setState(() {
      selectedTab = tab;
    });
    // Update URL
    context.go('/public/franchise/${widget.franchiseId}/$tab');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Update selected tab based on URL if not already set
    final state = GoRouterState.of(context);
    final pathSegments = state.uri.pathSegments;
    
    if (pathSegments.length > 3) {
      final tabFromUrl = pathSegments[3];
      if (tabFromUrl != selectedTab) {
        setState(() {
          selectedTab = tabFromUrl;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getFranchiseName()),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          // Login button for public users
          TextButton.icon(
            onPressed: () => context.go('/login'),
            icon: const Icon(Icons.login),
            label: const Text('Login'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab navigation
          Container(
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTabButton('players', 'Players', Icons.people),
                  _buildTabButton('teams', 'Teams', Icons.groups),
                  _buildTabButton('statistics', 'Statistics', Icons.bar_chart),
                  _buildTabButton('standings', 'Standings', Icons.format_list_numbered),
                  _buildTabButton('trades', 'Trades', Icons.swap_horiz),
                  _buildTabButton('awards', 'Awards', Icons.emoji_events),
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

  Widget _buildTabButton(String tab, String label, IconData icon) {
    final isSelected = selectedTab == tab;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
      child: InkWell(
        onTap: () => _onTabChanged(tab),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[600],
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    // Reuse the existing tab implementations from app.dart
    switch (selectedTab) {
      case 'players':
        return _buildPlayersTab();
      case 'teams':
        return _buildTeamsTab();
      case 'statistics':
        return _buildStatsTab();
      case 'standings':
        return _buildStandingsTab();
      case 'trades':
        return _buildTradesTab();
      case 'awards':
        return _buildAwardsTab();
      default:
        return const Center(child: Text('Select a tab to view content'));
    }
  }

  Widget _buildPlayersTab() {
    // Check if this is Madden League Alpha franchise
    if (widget.franchiseId != 'franchise-server-1') {
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
            const Text(
              'Upload franchise data to see players',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Use the public data provider
    final playersState = ref.watch(publicDataProvider);

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
              onPressed: () => ref.read(publicDataProvider.notifier).refreshData(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (players) => Column(
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
                        const Text(
                          'Upload franchise data to see players',
                          style: TextStyle(color: Colors.grey),
                        ),
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
                    onTap: () {
                      final franchiseName = _getFranchiseName();
                      final urlSafeName = franchiseName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9-]'), '-');
                      context.go('/franchise/$urlSafeName/player/${player.id}');
                    },
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
                                    Text(
                                      '${player.firstName} ${player.lastName}',
                                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        _statLabel('Age'),
                                        _statValue(player.age.toString()),
                                        _statLabel('OVR'),
                                        _statValue((player.playerBestOvr > 0 ? player.playerBestOvr : player.playerSchemeOvr).toString()),
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
    child: Text(
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

  // Reuse the tab implementations from app.dart
  Widget _buildTeamsTab() {
    // Check if this is Madden League Alpha franchise
    if (widget.franchiseId != 'franchise-server-1') {
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

    // Madden League Alpha data
    final teams = {
      'Kansas City Chiefs': [
        {'name': 'Patrick Mahomes', 'pos': 'QB', 'ovr': 99, 'age': 28},
        {'name': 'Travis Kelce', 'pos': 'TE', 'ovr': 98, 'age': 34},
        {'name': 'Chris Jones', 'pos': 'DT', 'ovr': 96, 'age': 29},
      ],
      'San Francisco 49ers': [
        {'name': 'Brock Purdy', 'pos': 'QB', 'ovr': 87, 'age': 24},
        {'name': 'Christian McCaffrey', 'pos': 'RB', 'ovr': 97, 'age': 27},
        {'name': 'Nick Bosa', 'pos': 'DE', 'ovr': 98, 'age': 26},
      ],
      'Philadelphia Eagles': [
        {'name': 'Jalen Hurts', 'pos': 'QB', 'ovr': 88, 'age': 25},
        {'name': 'A.J. Brown', 'pos': 'WR', 'ovr': 94, 'age': 26},
        {'name': 'Haason Reddick', 'pos': 'OLB', 'ovr': 89, 'age': 29},
      ],
    };

    return ListView.builder(
      itemCount: teams.length,
      itemBuilder: (context, index) {
        final teamName = teams.keys.elementAt(index);
        final teamPlayers = teams[teamName]!;
        return Card(
          margin: const EdgeInsets.all(8),
          child: ExpansionTile(
            title: Text(
              teamName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            subtitle: Text('${teamPlayers.length} players'),
            children: teamPlayers.map((player) => ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue.withOpacity(0.15),
                child: Text(
                  player['pos'] as String,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                ),
              ),
              title: Text(player['name'] as String),
              subtitle: Text('${player['pos']} • OVR: ${player['ovr']} • Age: ${player['age']}'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // Navigate to franchise-specific player page
                final franchiseName = _getFranchiseName();
                final urlSafeName = franchiseName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9-]'), '-');
                context.go('/franchise/$urlSafeName/player/${player['name']}');
              },
            )).toList(),
          ),
        );
      },
    );
  }

  Widget _buildStatsTab() {
    // Check if this is Madden League Alpha franchise
    if (widget.franchiseId != 'franchise-server-1') {
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

    // Madden League Alpha data
    final statCategories = [
      {
        'title': 'Passing Yards',
        'leaders': [
          {'name': 'Joe Burrow', 'team': 'Bengals', 'stat': '4,918', 'avatar': 'https://static.www.nfl.com/image/private/t_headshot_desktop/league/api/player/2543468/profile'},
          {'name': 'Jared Goff', 'team': 'Lions', 'stat': '4,629', 'avatar': 'https://static.www.nfl.com/image/private/t_headshot_desktop/league/api/player/2558147/profile'},
          {'name': 'Baker Mayfield', 'team': 'Buccaneers', 'stat': '4,500', 'avatar': 'https://static.www.nfl.com/image/private/t_headshot_desktop/league/api/player/2558145/profile'},
        ],
      },
      {
        'title': 'Rushing Yards',
        'leaders': [
          {'name': 'Saquon Barkley', 'team': 'Giants', 'stat': '2,005', 'avatar': 'https://static.www.nfl.com/image/private/t_headshot_desktop/league/api/player/2560953/profile'},
          {'name': 'Derrick Henry', 'team': 'Titans', 'stat': '1,921', 'avatar': 'https://static.www.nfl.com/image/private/t_headshot_desktop/league/api/player/2558144/profile'},
          {'name': 'Bijan Robinson', 'team': 'Falcons', 'stat': '1,456', 'avatar': 'https://static.www.nfl.com/image/private/t_headshot_desktop/league/api/player/2570000/profile'},
        ],
      },
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...statCategories.map((cat) => Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFE9ECEF), width: 1)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cat['title'] as String, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    ...((cat['leaders'] as List).map((leader) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundImage: NetworkImage(leader['avatar'] as String),
                            radius: 22,
                          ),
                          const SizedBox(width: 16),
                          Expanded(child: Text(leader['name'] as String, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16))),
                          Text(leader['stat'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(width: 8),
                          Text(leader['team'] as String, style: const TextStyle(color: Color(0xFF6C757D))),
                        ],
                      ),
                    ))),
                  ],
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildStandingsTab() {
    // Check if this is Madden League Alpha franchise
    if (widget.franchiseId != 'franchise-server-1') {
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

    // Simplified standings for public view
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.format_list_numbered, size: 64, color: Colors.blue),
          SizedBox(height: 16),
          Text(
            'Standings',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Power rankings and division standings',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildTradesTab() {
    // Check if this is Madden League Alpha franchise
    if (widget.franchiseId != 'franchise-server-1') {
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

    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.swap_horiz, size: 64, color: Colors.blue),
          SizedBox(height: 16),
          Text(
            'Trade Center',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Trade proposals and negotiations',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildAwardsTab() {
    // Check if this is Madden League Alpha franchise
    if (widget.franchiseId != 'franchise-server-1') {
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

    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events, size: 64, color: Colors.blue),
          SizedBox(height: 16),
          Text(
            'Awards',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Annual awards and Super Bowl history',
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
                playerMap['franchiseId'] = widget.franchiseId;
                
                // Generate unique IDs for players that don't have them
                if (playerMap['id'] == null || 
                    playerMap['id'].toString().length < 9 ||
                    playerMap['id'].toString().contains(' ')) {
                  final timestamp = DateTime.now().millisecondsSinceEpoch;
                  // Extract server number from franchise ID (e.g., "franchise-server-1" -> "1")
                  final serverMatch = RegExp(r'server-(\d+)').firstMatch(widget.franchiseId);
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
