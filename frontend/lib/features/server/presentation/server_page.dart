// --- FLOATING NAVIGATION FIX APPLIED ---
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/server_providers.dart';
import '../../channels/server_channel_content.dart';
import '../../channels/franchise_channel_content.dart';
import '../../../views/rosters_home.dart';
import '../../../providers/player_provider.dart';
import '../../../providers/public_data_provider.dart';
import '../../../models/player.dart';
import '../../franchise/presentation/widgets/franchise_sidebar.dart';
import '../../../providers/franchise_providers.dart';
import 'dart:convert';
import 'dart:html' as html;

final divisions = [
  {'name': 'AFC East', 'teams': [
    {'name': 'Bills', 'record': '9-3'},
    {'name': 'Dolphins', 'record': '8-4'},
    {'name': 'Jets', 'record': '6-6'},
    {'name': 'Patriots', 'record': '3-9'},
  ]},
  {'name': 'AFC North', 'teams': [
    {'name': 'Steelers', 'record': '9-3'},
    {'name': 'Browns', 'record': '9-3'},
    {'name': 'Ravens', 'record': '7-5'},
    {'name': 'Bengals', 'record': '4-8'},
  ]},
  {'name': 'AFC South', 'teams': [
    {'name': 'Jaguars', 'record': '8-4'},
    {'name': 'Colts', 'record': '7-5'},
    {'name': 'Texans', 'record': '6-6'},
    {'name': 'Titans', 'record': '4-8'},
  ]},
  {'name': 'AFC West', 'teams': [
    {'name': 'Chiefs', 'record': '8-4'},
    {'name': 'Broncos', 'record': '6-6'},
    {'name': 'Raiders', 'record': '5-7'},
    {'name': 'Chargers', 'record': '4-8'},
  ]},
  {'name': 'NFC East', 'teams': [
    {'name': 'Eagles', 'record': '10-2'},
    {'name': 'Cowboys', 'record': '9-3'},
    {'name': 'Giants', 'record': '4-8'},
    {'name': 'Commanders', 'record': '3-9'},
  ]},
  {'name': 'NFC North', 'teams': [
    {'name': 'Lions', 'record': '9-3'},
    {'name': 'Packers', 'record': '6-6'},
    {'name': 'Vikings', 'record': '6-6'},
    {'name': 'Bears', 'record': '4-8'},
  ]},
  {'name': 'NFC South', 'teams': [
    {'name': 'Falcons', 'record': '7-5'},
    {'name': 'Buccaneers', 'record': '6-6'},
    {'name': 'Saints', 'record': '5-7'},
    {'name': 'Panthers', 'record': '1-11'},
  ]},
  {'name': 'NFC West', 'teams': [
    {'name': '49ers', 'record': '9-3'},
    {'name': 'Seahawks', 'record': '6-6'},
    {'name': 'Rams', 'record': '6-6'},
    {'name': 'Cardinals', 'record': '2-10'},
  ]},
];

class ServerPage extends ConsumerStatefulWidget {
  final String serverId;
  const ServerPage({super.key, required this.serverId});

  @override
  _ServerPageState createState() => _ServerPageState();
}

class _ServerPageState extends ConsumerState<ServerPage> {
  String? selectedFranchiseId;
  String? selectedChannelId;
  String? selectedSubcategoryId;
  String selectedFranchiseSection = 'Franchise';
  int _standingsTabIndex = 0; // 0: Division, 1: Conference, 2: League

  @override
  Widget build(BuildContext context) {
    final state = GoRouterState.of(context);
    final serverId = state.pathParameters['serverId'];
    final franchiseId = state.pathParameters['franchiseId'];
    final channelId = state.pathParameters['channelId'];
    final subcategoryId = state.uri.queryParameters['subcategory'];
    
    print('DEBUG: ServerPage build - serverId=$serverId, franchiseId=$franchiseId, channelId=$channelId');
    
    // Use these IDs to drive the UI
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _buildMainPanel(
        serverId: serverId,
        franchiseId: franchiseId,
        channelId: channelId,
        subcategoryId: subcategoryId,
      ),
    );
  }

  Widget _buildMainPanel({String? serverId, String? franchiseId, String? channelId, String? subcategoryId}) {
    // Debug output
    print('ServerPage Debug: serverId=$serverId, franchiseId=$franchiseId, channelId=$channelId, subcategoryId=$subcategoryId');
    // If a text channel is selected (no franchise)
    if (franchiseId == null && channelId != null) {
      return _buildChannelContent(franchiseId: franchiseId, channelId: channelId, subcategoryId: subcategoryId);
    }
    // If a franchise is selected (but not a channel/subcategory), show the full franchise dashboard
    if (franchiseId != null && channelId == null && subcategoryId == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFranchiseNav(franchiseId: franchiseId),
          const SizedBox(height: 24),
          Expanded(
            child: _buildFranchiseSection(franchiseId: franchiseId),
          ),
        ],
      );
    }
    // If a channel or subcategory is selected, show franchise nav at top and channel content below
    if (franchiseId != null && (channelId != null || subcategoryId != null)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFranchiseNav(franchiseId: franchiseId),
          const SizedBox(height: 24),
          Expanded(
            child: _buildChannelContent(franchiseId: franchiseId, channelId: channelId, subcategoryId: subcategoryId),
          ),
        ],
      );
    }
    // Franchise browser - show available franchises
    return _buildFranchiseBrowser(serverId: serverId);
  }

  Widget _buildFranchiseBrowser({String? serverId}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Available Franchises',
          style: TextStyle(
            color: Colors.black,
            fontSize: 32,
            fontWeight: FontWeight.w700,
            letterSpacing: -1.0,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Select a franchise to view players, teams, and statistics.',
          style: TextStyle(
            color: Color(0xFF6C757D),
            fontSize: 18,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 32),
        Expanded(
          child: _buildMockFranchiseList(serverId: serverId),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: () {
              _showCreateFranchiseDialog(context, serverId!);
            },
            child: const Text('Create Franchise'),
          ),
        ),
      ],
    );
  }

  Widget _buildMockFranchiseList({String? serverId}) {
    // Different franchises for different servers
    Map<String, List<Map<String, String>>> serverFranchises = {
      'server-1': [
        {'id': 'franchise-1', 'name': 'Madden League Alpha', 'description': 'Main competitive league'},
        {'id': 'franchise-2', 'name': 'Casual Franchise', 'description': 'Relaxed gameplay league'},
        {'id': 'franchise-3', 'name': 'Pro League', 'description': 'Professional level competition'},
      ],
      'server-2': [
        {'id': 'support-1', 'name': 'Help & Support', 'description': 'Get help with the app'},
        {'id': 'support-2', 'name': 'Bug Reports', 'description': 'Report issues and bugs'},
        {'id': 'support-3', 'name': 'Feature Requests', 'description': 'Suggest new features'},
      ],
      'server-3': [
        {'id': 'casual-1', 'name': 'Weekend Warriors', 'description': 'Casual weekend games'},
        {'id': 'casual-2', 'name': 'Friendly Matches', 'description': 'Non-competitive play'},
      ],
    };
    
    final mockFranchises = serverFranchises[serverId] ?? [
      {'id': 'default-1', 'name': 'Default Franchise', 'description': 'Default league'},
    ];

    return ListView.builder(
      itemCount: mockFranchises.length,
      itemBuilder: (context, index) {
        final franchise = mockFranchises[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.sports_football,
                color: Colors.orange[700],
                size: 24,
              ),
            ),
            title: Text(
              franchise['name']!,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              franchise['description']!,
              style: const TextStyle(
                color: Color(0xFF6C757D),
                fontSize: 14,
              ),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                 onTap: () {
                       // Use state-based navigation instead of router
                       ref.read(currentServerIdProvider.notifier).state = serverId;
                       // Set the franchise ID in the app state
                       setState(() {
                         selectedFranchiseId = franchise['id'];
                       });
                     },
          ),
        );
      },
    );
  }

  Widget _buildFranchiseNav({String? franchiseId}) {
    final sections = [
      {'name': 'Franchise', 'icon': Icons.sports_football},
      {'name': 'Players', 'icon': Icons.people},
      {'name': 'Teams', 'icon': Icons.groups},
      {'name': 'Stats', 'icon': Icons.bar_chart},
      {'name': 'Schedule', 'icon': Icons.calendar_today},
      {'name': 'Standings', 'icon': Icons.format_list_numbered},
      {'name': 'Trades', 'icon': Icons.swap_horiz},
      {'name': 'Awards', 'icon': Icons.emoji_events},
      {'name': 'Rules', 'icon': Icons.gavel},
    ];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE9ECEF), width: 1)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ...sections.map((section) => Padding(
              padding: const EdgeInsets.only(right: 16.0, left: 16.0),
              child: InkWell(
                onTap: () {
                  setState(() {
                    selectedFranchiseSection = section['name'] as String;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: selectedFranchiseSection == (section['name'] as String)
                        ? const Color(0xFF1A1A1A) 
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selectedFranchiseSection == (section['name'] as String)
                          ? const Color(0xFF1A1A1A) 
                          : const Color(0xFFE9ECEF),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        section['icon'] as IconData,
                        size: 16,
                        color: selectedFranchiseSection == (section['name'] as String)
                            ? Colors.white 
                            : const Color(0xFF6C757D),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        section['name'] as String,
                        style: TextStyle(
                          color: selectedFranchiseSection == (section['name'] as String)
                              ? Colors.white 
                              : const Color(0xFF6C757D),
                          fontWeight: selectedFranchiseSection == (section['name'] as String)
                              ? FontWeight.w600 
                              : FontWeight.w400,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildFranchiseSection({String? franchiseId}) {
    // Only show real data for the "Madden X Launch" franchise (f1)
    if (franchiseId == 'f1') {
      switch (selectedFranchiseSection) {
        case 'Franchise':
          return _buildFranchiseHomePage();
        case 'Players':
          // Use the real rosters widget
          return Column(
            children: [
              // Debug section
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE9ECEF), width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFF6C757D)),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Debug: Check browser console for data loading logs',
                        style: TextStyle(color: Color(0xFF6C757D)),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => ref.read(playerProvider.notifier).refreshData(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A1A1A),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Refresh Data'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _loadSampleData(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF28A745),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Load Sample Data'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => context.go('/upload'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF007BFF),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Upload Data'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _clearData(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC3545),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Clear Data'),
                    ),
                  ],
                ),
              ),
              // Players content
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE9ECEF), width: 1),
                  ),
                  child: const RostersHomePage(franchiseId: 'f1'),
                ),
              ),
            ],
          );
        case 'Teams':
          // Use the real teams tab from RostersHomePage
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE9ECEF), width: 1),
            ),
            child: _buildTeamsTab(),
          );
        case 'Stats':
          return _buildStatsMuseStyleStats();
        case 'Schedule':
          return _buildPlaceholderSection('Schedule', 'Game schedule, results, and upcoming matchups will be displayed here');
        case 'Standings':
          return _buildPowerRankingsAndStandings();
        case 'Trades':
          return _buildTradesTab();
        case 'Awards':
          return _buildAwardsTab();
        case 'Rules':
          return _buildPlaceholderSection('Rules', 'League rules, settings, and guidelines will be displayed here');
        default:
          return _buildPlaceholderSection('Section', 'Content for $selectedFranchiseSection will be displayed here');
      }
    } else {
      // For other franchises, show placeholder content
      return _buildPlaceholderSection(
        'Franchise: $franchiseId', 
        'This franchise doesn\'t have data yet.\nOnly "Madden X Launch" has real player data.',
        isError: true,
      );
    }
  }

  Widget _buildPlaceholderSection(String title, String message, {bool isError = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9ECEF), width: 1),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isError ? Icons.sports_football : Icons.analytics,
                size: 64, 
                color: isError ? Colors.grey : const Color(0xFF1A1A1A),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF6C757D),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Copy the teams tab logic from RostersHomePage
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
                    onTap: () {
                      context.go('/player/${player.id}', extra: player);
                    },
                  )).toList(),
                );
              },
            ),
    );
  }

  Widget _buildChannelContent({String? franchiseId, String? channelId, String? subcategoryId}) {
    // Handle special navigation tabs first
    if (subcategoryId != null) {
      switch (subcategoryId) {
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

    if (channelId == null) {
      return const Center(child: Text('Select a channel to start chatting'));
    }

    // For franchise channels, use the franchise channel content
    if (franchiseId != null) {
      return FranchiseChannelContent(
        franchiseId: franchiseId,
        channelId: channelId,
      );
    }

    // For server channels, use the regular channel content
    return ServerChannelContent(
      channelId: channelId,
    );
  }

  Widget _buildPlayersTab() {
    return Consumer(
      builder: (context, ref, child) {
        final playersState = ref.watch(publicDataProvider);
        
        return playersState.when(
          data: (allPlayers) {
            // Filter players by current franchise ID
            final currentFranchiseId = selectedFranchiseId;
            if (currentFranchiseId == null) {
              return const Center(child: Text('No franchise selected'));
            }
            
            final players = allPlayers.where((player) => player.franchiseId == currentFranchiseId).toList();
            
            if (players.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No players found'),
                    SizedBox(height: 8),
                    Text('Upload franchise data to see players', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              );
            }
            
            return ListView.builder(
              itemCount: players.length,
              itemBuilder: (context, index) {
                final player = players[index];
                return ListTile(
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
                  onTap: () {
                    context.go('/player/${player.id}', extra: player);
                  },
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error loading players: $error')),
        );
      },
    );
  }

  Widget _buildAwardsTab() {
    // Dummy data
    final awards = [
      {'year': 2024, 'player': 'Patrick Mahomes', 'coach': 'Andy Reid'},
      {'year': 2023, 'player': 'Joe Burrow', 'coach': 'Zac Taylor'},
    ];
    final superbowls = [
      {'year': 2024, 'winner': 'Chiefs', 'loser': '49ers', 'score': '31-20'},
      {'year': 2023, 'winner': 'Rams', 'loser': 'Bengals', 'score': '23-20'},
    ];
    return Row(
      children: [
        // Annual Awards
        Expanded(
          child: Card(
            margin: const EdgeInsets.all(8),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Annual Awards', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 12),
                  ...awards.map((a) => ListTile(
                    title: Text('${a['year']}'),
                    subtitle: Text('Player: ${a['player']}\nCoach: ${a['coach']}'),
                  )),
                ],
              ),
            ),
          ),
        ),
        // Super Bowl History
        Expanded(
          child: Card(
            margin: const EdgeInsets.all(8),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Super Bowl History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 12),
                  ...superbowls.map((sb) => ListTile(
                    title: Text('${sb['year']}'),
                    subtitle: Text('Winner: ${sb['winner']}\nLoser: ${sb['loser']}\nScore: ${sb['score']}'),
                  )),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _loadSampleData() {
    final samplePlayers = [
      {
        "id": "1",
        "firstName": "Patrick",
        "lastName": "Mahomes",
        "age": 28,
        "playerBestOvr": 99,
        "playerSchemeOvr": 99,
        "speedRating": 84,
        "position": "QB",
        "team": "Kansas City Chiefs",
        "isFreeAgent": false,
        "teamId": 1,
        "jerseyNum": 15,
        "height": 75,
        "weight": 225,
        "college": "Texas Tech",
        "draftRound": 1,
        "draftPick": 10,
        "strengthRating": 75,
        "agilityRating": 88,
        "awareRating": 99,
        "catchRating": 65,
        "tackleRating": 45,
        "throwPowerRating": 99,
        "staminaRating": 95
      },
      {
        "id": "2",
        "firstName": "Travis",
        "lastName": "Kelce",
        "age": 34,
        "playerBestOvr": 98,
        "playerSchemeOvr": 98,
        "speedRating": 82,
        "position": "TE",
        "team": "Kansas City Chiefs",
        "isFreeAgent": false,
        "teamId": 1,
        "jerseyNum": 87,
        "height": 77,
        "weight": 260,
        "college": "Cincinnati",
        "draftRound": 3,
        "draftPick": 63,
        "strengthRating": 85,
        "agilityRating": 88,
        "awareRating": 95,
        "catchRating": 95,
        "tackleRating": 45,
        "throwPowerRating": 45,
        "staminaRating": 90
      },
      {
        "id": "3",
        "firstName": "Tyreek",
        "lastName": "Hill",
        "age": 30,
        "playerBestOvr": 97,
        "playerSchemeOvr": 97,
        "speedRating": 99,
        "position": "WR",
        "team": "Miami Dolphins",
        "isFreeAgent": false,
        "teamId": 2,
        "jerseyNum": 10,
        "height": 70,
        "weight": 185,
        "college": "West Alabama",
        "draftRound": 5,
        "draftPick": 165,
        "strengthRating": 65,
        "agilityRating": 95,
        "awareRating": 90,
        "catchRating": 90,
        "tackleRating": 45,
        "throwPowerRating": 45,
        "staminaRating": 95
      },
      {
        "id": "4",
        "firstName": "Aaron",
        "lastName": "Donald",
        "age": 32,
        "playerBestOvr": 99,
        "playerSchemeOvr": 99,
        "speedRating": 82,
        "position": "DT",
        "team": "Los Angeles Rams",
        "isFreeAgent": false,
        "teamId": 3,
        "jerseyNum": 99,
        "height": 73,
        "weight": 280,
        "college": "Pittsburgh",
        "draftRound": 1,
        "draftPick": 13,
        "strengthRating": 99,
        "agilityRating": 88,
        "awareRating": 95,
        "catchRating": 45,
        "tackleRating": 95,
        "throwPowerRating": 45,
        "staminaRating": 90
      },
      {
        "id": "5",
        "firstName": "Josh",
        "lastName": "Allen",
        "age": 27,
        "playerBestOvr": 96,
        "playerSchemeOvr": 96,
        "speedRating": 88,
        "position": "QB",
        "team": "Buffalo Bills",
        "isFreeAgent": false,
        "teamId": 4,
        "jerseyNum": 17,
        "height": 77,
        "weight": 237,
        "college": "Wyoming",
        "draftRound": 1,
        "draftPick": 7,
        "strengthRating": 85,
        "agilityRating": 82,
        "awareRating": 90,
        "catchRating": 65,
        "tackleRating": 45,
        "throwPowerRating": 95,
        "staminaRating": 95
      },
      {
        "id": "6",
        "firstName": "Christian",
        "lastName": "McCaffrey",
        "age": 27,
        "playerBestOvr": 96,
        "playerSchemeOvr": 96,
        "speedRating": 90,
        "position": "HB",
        "team": "San Francisco 49ers",
        "isFreeAgent": false,
        "teamId": 5,
        "jerseyNum": 23,
        "height": 71,
        "weight": 205,
        "college": "Stanford",
        "draftRound": 1,
        "draftPick": 8,
        "strengthRating": 75,
        "agilityRating": 95,
        "awareRating": 90,
        "catchRating": 85,
        "tackleRating": 45,
        "throwPowerRating": 45,
        "staminaRating": 95
      },
      {
        "id": "7",
        "firstName": "T.J.",
        "lastName": "Watt",
        "age": 29,
        "playerBestOvr": 96,
        "playerSchemeOvr": 96,
        "speedRating": 85,
        "position": "LOLB",
        "team": "Pittsburgh Steelers",
        "isFreeAgent": false,
        "teamId": 6,
        "jerseyNum": 90,
        "height": 76,
        "weight": 252,
        "college": "Wisconsin",
        "draftRound": 1,
        "draftPick": 30,
        "strengthRating": 85,
        "agilityRating": 82,
        "awareRating": 90,
        "catchRating": 45,
        "tackleRating": 95,
        "throwPowerRating": 45,
        "staminaRating": 90
      },
      {
        "id": "8",
        "firstName": "Jalen",
        "lastName": "Hurts",
        "age": 25,
        "playerBestOvr": 94,
        "playerSchemeOvr": 94,
        "speedRating": 87,
        "position": "QB",
        "team": "Philadelphia Eagles",
        "isFreeAgent": false,
        "teamId": 7,
        "jerseyNum": 1,
        "height": 73,
        "weight": 223,
        "college": "Oklahoma",
        "draftRound": 2,
        "draftPick": 53,
        "strengthRating": 85,
        "agilityRating": 88,
        "awareRating": 85,
        "catchRating": 65,
        "tackleRating": 45,
        "throwPowerRating": 90,
        "staminaRating": 95
      },
      {
        "id": "9",
        "firstName": "Justin",
        "lastName": "Jefferson",
        "age": 24,
        "playerBestOvr": 95,
        "playerSchemeOvr": 95,
        "speedRating": 88,
        "position": "WR",
        "team": "Minnesota Vikings",
        "isFreeAgent": false,
        "teamId": 8,
        "jerseyNum": 18,
        "height": 75,
        "weight": 195,
        "college": "LSU",
        "draftRound": 1,
        "draftPick": 22,
        "strengthRating": 70,
        "agilityRating": 92,
        "awareRating": 90,
        "catchRating": 95,
        "tackleRating": 45,
        "throwPowerRating": 45,
        "staminaRating": 90
      },
      {
        "id": "10",
        "firstName": "Micah",
        "lastName": "Parsons",
        "age": 24,
        "playerBestOvr": 95,
        "playerSchemeOvr": 95,
        "speedRating": 90,
        "position": "ROLB",
        "team": "Dallas Cowboys",
        "isFreeAgent": false,
        "teamId": 9,
        "jerseyNum": 11,
        "height": 75,
        "weight": 245,
        "college": "Penn State",
        "draftRound": 1,
        "draftPick": 12,
        "strengthRating": 85,
        "agilityRating": 90,
        "awareRating": 85,
        "catchRating": 45,
        "tackleRating": 95,
        "throwPowerRating": 45,
        "staminaRating": 95
      }
    ];

    // Save to localStorage
    try {
      html.window.localStorage['rosters'] = json.encode(samplePlayers);
      html.window.localStorage['useLocalData'] = 'true';
      
      // Refresh the data
      ref.read(playerProvider.notifier).setUseLocalData(true);
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: SelectableText('Sample data loaded successfully! ${samplePlayers.length} players added.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: SelectableText('Error loading sample data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _clearData() {
    try {
      // Clear localStorage
      html.window.localStorage.remove('rosters');
      html.window.localStorage.remove('useLocalData');
      
      // Refresh the data provider
      ref.read(playerProvider.notifier).refreshData();
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: SelectableText('Data cleared successfully!'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: SelectableText('Error clearing data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildFranchiseHomePage() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Banner
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              'https://images.pexels.com/photos/399187/pexels-photo-399187.jpeg?auto=compress&w=900&q=80',
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 24),
          // League Summary
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('2027 Regular Season', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
                  SizedBox(height: 4),
                  Text('Week 13 • 32 Teams', style: TextStyle(fontSize: 16, color: Color(0xFF6C757D))),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('LIVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 32),
          // Top Teams
          const Text('Top Teams', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildTeamCard('Raiders', '11-2', 'https://images.pexels.com/photos/161820/soccer-american-football-football-american-football-161820.jpeg?auto=compress&w=100&q=80'),
              const SizedBox(width: 16),
              _buildTeamCard('Cowboys', '10-3', 'https://images.pexels.com/photos/209954/pexels-photo-209954.jpeg?auto=compress&w=100&q=80'),
              const SizedBox(width: 16),
              _buildTeamCard('Eagles', '10-3', 'https://images.pexels.com/photos/163209/sport-american-football-player-american-football-163209.jpeg?auto=compress&w=100&q=80'),
            ],
          ),
          const SizedBox(height: 32),
          // Recent Results
          const Text('Recent Results', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
          const SizedBox(height: 12),
          _buildResultRow('Raiders', 27, 'Cowboys', 24),
          _buildResultRow('Eagles', 31, 'Giants', 17),
          _buildResultRow('Packers', 21, 'Bears', 20),
          const SizedBox(height: 32),
          // Trending Topics
          const Text('What people are talking about', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
          const SizedBox(height: 12),
          _buildTrendingTopic('Are the Raiders unstoppable this season?'),
          _buildTrendingTopic('MVP race: Mahomes vs. Hurts'),
          _buildTrendingTopic('Biggest upsets of the week'),
          _buildTrendingTopic('Trade rumors: Who is on the move?'),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildTeamCard(String name, String record, String imageUrl) {
    return Container(
      width: 110,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9ECEF), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(imageUrl, height: 48, width: 80, fit: BoxFit.cover),
          ),
          const SizedBox(height: 8),
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 2),
          Text(record, style: const TextStyle(color: Color(0xFF6C757D), fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildResultRow(String teamA, int scoreA, String teamB, int scoreB) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(child: Text(teamA, style: const TextStyle(fontWeight: FontWeight.w500))),
          Text('$scoreA', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          const Text('vs'),
          const SizedBox(width: 8),
          Text('$scoreB', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Align(alignment: Alignment.centerRight, child: Text(teamB, style: const TextStyle(fontWeight: FontWeight.w500)))),
        ],
      ),
    );
  }

  Widget _buildTrendingTopic(String topic) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          const Icon(Icons.trending_up, color: Color(0xFF1A1A1A), size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(topic, style: const TextStyle(fontSize: 15))),
        ],
      ),
    );
  }

  Widget _buildStatsMuseStyleStats() {
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
      {
        'title': 'Receiving Yards',
        'leaders': [
          {'name': "Ja'Marr Chase", 'team': 'Bengals', 'stat': '1,708', 'avatar': 'https://static.www.nfl.com/image/private/t_headshot_desktop/league/api/player/2566176/profile'},
          {'name': 'Justin Jefferson', 'team': 'Vikings', 'stat': '1,533', 'avatar': 'https://static.www.nfl.com/image/private/t_headshot_desktop/league/api/player/2566175/profile'},
          {'name': 'Brian Thomas Jr.', 'team': 'Saints', 'stat': '1,282', 'avatar': 'https://static.www.nfl.com/image/private/t_headshot_desktop/league/api/player/2570001/profile'},
        ],
      },
      {
        'title': 'Sacks',
        'leaders': [
          {'name': 'Trey Hendrickson', 'team': 'Bengals', 'stat': '17.5', 'avatar': 'https://static.www.nfl.com/image/private/t_headshot_desktop/league/api/player/2557848/profile'},
          {'name': 'Myles Garrett', 'team': 'Browns', 'stat': '14.0', 'avatar': 'https://static.www.nfl.com/image/private/t_headshot_desktop/league/api/player/2557972/profile'},
          {'name': 'Nik Bonitto', 'team': 'Broncos', 'stat': '13.5', 'avatar': 'https://static.www.nfl.com/image/private/t_headshot_desktop/league/api/player/2570002/profile'},
        ],
      },
      {
        'title': 'Fantasy Points',
        'leaders': [
          {'name': 'Lamar Jackson', 'team': 'Ravens', 'stat': '434.4', 'avatar': 'https://static.www.nfl.com/image/private/t_headshot_desktop/league/api/player/2560954/profile'},
          {'name': 'Josh Allen', 'team': 'Bills', 'stat': '385', 'avatar': 'https://static.www.nfl.com/image/private/t_headshot_desktop/league/api/player/2560955/profile'},
          {'name': 'Joe Burrow', 'team': 'Bengals', 'stat': '381.8', 'avatar': 'https://static.www.nfl.com/image/private/t_headshot_desktop/league/api/player/2543468/profile'},
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

  Widget _buildPowerRankingsAndStandings() {
    final powerRankings = List.generate(32, (i) => {
      'rank': i + 1,
      'team': mockTeams[i % mockTeams.length]['team'],
      'logo': mockTeams[i % mockTeams.length]['logo'],
      'blurb': mockTeams[i % mockTeams.length]['blurb'],
    });
    final afcDivisions = divisions.sublist(0, 4);
    final nfcDivisions = divisions.sublist(4, 8);
    final afcConference = afcDivisions.expand((div) => div['teams'] as List).toList();
    final nfcConference = nfcDivisions.expand((div) => div['teams'] as List).toList();
    final league = [...afcConference, ...nfcConference];

    return Column(
      children: [
        // Tab bar centered over columns
        Container(
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _standingsTab('Division', 0),
              _standingsTab('Conference', 1),
              _standingsTab('League', 2),
            ],
          ),
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Power Rankings (left 30%)
              Container(
                width: 320,
                color: Colors.white,
                padding: const EdgeInsets.only(right: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12.0, top: 8.0),
                      child: SelectableText(
                        'Power Rankings',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF1A1A1A)),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: powerRankings.length,
                        itemBuilder: (context, idx) {
                          final team = powerRankings[idx];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 18.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SelectableText('${team['rank']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
                                const SizedBox(width: 10),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: Image.network(
                                    team['logo'] as String,
                                    width: 36,
                                    height: 36,
                                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.sports_football, size: 36, color: Color(0xFF6C757D)),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SelectableText(team['team'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A1A1A))),
                                      const SizedBox(height: 2),
                                      SelectableText(team['blurb'] as String, style: const TextStyle(color: Color(0xFF6C757D), fontSize: 13)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              // Standings Grid (right 70%)
              Expanded(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.only(left: 8.0),
                  child: _standingsTabIndex == 0
                    ? Row(
                        children: [
                          // AFC (left column)
                          Expanded(
                            child: Column(
                              children: afcDivisions.map((div) => Expanded(
                                child: Card(
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFE9ECEF), width: 1)),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(div['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                        const SizedBox(height: 8),
                                        ...((div['teams'] as List).map((team) => Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                                          child: Row(
                                            children: [
                                              Expanded(child: Text(team['name'] as String, style: const TextStyle(fontWeight: FontWeight.w500))),
                                              Text(team['record'] as String, style: const TextStyle(color: Color(0xFF6C757D))),
                                            ],
                                          ),
                                        ))),
                                      ],
                                    ),
                                  ),
                                ),
                              )).toList(),
                            ),
                          ),
                          // NFC (right column)
                          Expanded(
                            child: Column(
                              children: nfcDivisions.map((div) => Expanded(
                                child: Card(
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFE9ECEF), width: 1)),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(div['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                        const SizedBox(height: 8),
                                        ...((div['teams'] as List).map((team) => Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                                          child: Row(
                                            children: [
                                              Expanded(child: Text(team['name'] as String, style: const TextStyle(fontWeight: FontWeight.w500))),
                                              Text(team['record'] as String, style: const TextStyle(color: Color(0xFF6C757D))),
                                            ],
                                          ),
                                        ))),
                                      ],
                                    ),
                                  ),
                                ),
                              )).toList(),
                            ),
                          ),
                        ],
                      )
                    : _standingsTabIndex == 1
                      ? _buildConferenceStandings(afcConference, nfcConference)
                      : _buildLeagueStandings(league),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _standingsTab(String label, int index) {
    return InkWell(
      onTap: () => setState(() => _standingsTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: _standingsTabIndex == index ? const Color(0xFF1A1A1A) : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: _standingsTabIndex == index ? const Color(0xFF1A1A1A) : const Color(0xFF6C757D),
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildConferenceStandings(List afc, List nfc) {
    return Row(
      children: [
        // AFC Conference
        Expanded(
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFE9ECEF), width: 1)),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('AFC Conference', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 8),
                  ...afc.map((team) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Row(
                      children: [
                        Expanded(child: Text(team['name'] as String, style: const TextStyle(fontWeight: FontWeight.w500))),
                        Text(team['record'] as String, style: const TextStyle(color: Color(0xFF6C757D))),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ),
        ),
        // NFC Conference
        Expanded(
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFE9ECEF), width: 1)),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('NFC Conference', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 8),
                  ...nfc.map((team) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Row(
                      children: [
                        Expanded(child: Text(team['name'] as String, style: const TextStyle(fontWeight: FontWeight.w500))),
                        Text(team['record'] as String, style: const TextStyle(color: Color(0xFF6C757D))),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLeagueStandings(List league) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFE9ECEF), width: 1)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('League Standings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            ...league.map((team) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Row(
                children: [
                  Expanded(child: Text(team['name'] as String, style: const TextStyle(fontWeight: FontWeight.w500))),
                  Text(team['record'] as String, style: const TextStyle(color: Color(0xFF6C757D))),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  // --- TRADES TAB ---
  Widget _buildTradesTab() {
    // Dummy data for teams, players, and picks
    final teamA = {
      'name': 'Raiders',
      'user': '@nashx9',
      'logo': 'https://a.espncdn.com/i/teamlogos/nfl/500/lv.png',
      'cap': 42.57,
      'players': [
        {'name': 'Maxx Crosby', 'pos': 'RE', 'dev': 'X-Factor', 'ovr': 99, 'age': 30, 'hgt': "6'5\"", 'cap': 29.28},
        {'name': 'Brock Bowers', 'pos': 'TE', 'dev': 'X-Factor', 'ovr': 94, 'age': 24, 'hgt': "6'3\"", 'cap': 5.14},
        {'name': 'Isaiah Neyor', 'pos': 'WR', 'dev': 'X-Factor', 'ovr': 94, 'age': 25, 'hgt': "6'4\"", 'cap': 1.08},
      ],
      'draftPicks': [],
    };
    final teamB = {
      'name': '49ers',
      'user': '@hbkfireking21',
      'logo': 'https://a.espncdn.com/i/teamlogos/nfl/500/sf.png',
      'cap': 2.9,
      'players': [
        {'name': 'Nick Bosa', 'pos': 'LE', 'dev': 'X-Factor', 'ovr': 98, 'age': 29, 'hgt': "6'4\"", 'cap': 52.28},
        {'name': 'Fred Warner', 'pos': 'MLB', 'dev': 'X-Factor', 'ovr': 98, 'age': 30, 'hgt': "6'3\"", 'cap': 19.52},
        {'name': 'George Kittle', 'pos': 'TE', 'dev': 'X-Factor', 'ovr': 95, 'age': 33, 'hgt': "6'4\"", 'cap': 10.46},
      ],
      'draftPicks': [],
    };
    Widget teamPanel(Map team) {
      return Expanded(
        child: Card(
          margin: const EdgeInsets.all(8),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Image.network(team['logo'], width: 40, height: 40),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(team['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        Text(team['user'], style: const TextStyle(color: Colors.blue)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('CAP AVAILABLE:   24${team['cap']}M'),
                Text('CAP AFTER TRADE:   24${team['cap']}M'),
                const SizedBox(height: 8),
                const Text('TOTAL VALUE: 0', style: TextStyle(fontWeight: FontWeight.bold)),
                const Divider(),
                const Text('Draft Picks', style: TextStyle(fontWeight: FontWeight.bold)),
                team['draftPicks'].isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('No draft picks added', style: TextStyle(color: Colors.grey)),
                    )
                  : Column(
                      children: (team['draftPicks'] as List).map((pick) => Text(pick.toString())).toList(),
                    ),
                const Divider(),
                const Text('Players', style: TextStyle(fontWeight: FontWeight.bold)),
                Expanded(
                  child: ListView.builder(
                    itemCount: (team['players'] as List).length,
                    itemBuilder: (context, idx) {
                      final p = team['players'][idx];
                      return ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(p['name']),
                        subtitle: Text('${p['pos']} | ${p['dev']} | OVR: ${p['ovr']} | Age: ${p['age']} | HGT: ${p['hgt']} | CAP:  24${p['cap']}M'),
                        trailing: const Icon(Icons.add_box_outlined),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    // Dummy chat data
    final chatMessages = [
      {'fromUser': false, 'text': 'Hi! Enter your trade proposal or ask for player suggestions.'},
      {'fromUser': true, 'text': 'Trade Maxx Crosby for Nick Bosa.'},
      {'fromUser': false, 'text': 'That trade is unlikely to be approved. Would you like to add a draft pick?'},
    ];
    Widget chatPanel() {
      return Expanded(
        flex: 1,
        child: Card(
          margin: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Team A Value', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('0', style: TextStyle(fontSize: 18)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Team B Value', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('0', style: TextStyle(fontSize: 18)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text('Likelihood of Approval: ', style: TextStyle(fontWeight: FontWeight.bold)),
                        Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(
                            color: Colors.yellow, // Change to green/yellow/red based on logic
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(),
              // Chat bubbles
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: chatMessages.length,
                  itemBuilder: (context, idx) {
                    final msg = chatMessages[idx];
                    final bool fromUser = msg['fromUser'] as bool;
                    final String text = msg['text'] as String;
                    return Align(
                      alignment: fromUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: fromUser ? const Color(0xFFDCF8C6) : const Color(0xFFF1F3F4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(text),
                      ),
                    );
                  },
                ),
              ),
              // Input field
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Type your trade or question...'
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Row(
      children: [
        Expanded(flex: 2, child: Row(children: [teamPanel(teamA), teamPanel(teamB)])),
        chatPanel(),
      ],
    );
  }


  void _showCreateFranchiseDialog(BuildContext context, String serverId) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Franchise'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Franchise Name',
                hintText: 'Enter franchise name',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                context.pop();
                await FranchiseRepository.createFranchise(
                  serverId: serverId,
                  name: nameController.text.trim(),
                );
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

// Mock teams for power rankings
final mockTeams = [
  {'team': 'Eagles', 'logo': 'https://a.espncdn.com/i/teamlogos/nfl/500/phi.png', 'blurb': 'The Eagles are flying high with a dominant defense.'},
  {'team': 'Ravens', 'logo': 'https://a.espncdn.com/i/teamlogos/nfl/500/bal.png', 'blurb': 'Lamar Jackson keeps the Ravens in every game.'},
  {'team': '49ers', 'logo': 'https://a.espncdn.com/i/teamlogos/nfl/500/sf.png', 'blurb': 'Elite playmakers on both sides of the ball.'},
  {'team': 'Chiefs', 'logo': 'https://a.espncdn.com/i/teamlogos/nfl/500/kc.png', 'blurb': 'Mahomes magic is always a threat.'},
  {'team': 'Cowboys', 'logo': 'https://a.espncdn.com/i/teamlogos/nfl/500/dal.png', 'blurb': 'Defense and Dak keep Dallas in the hunt.'},
  {'team': 'Bills', 'logo': 'https://a.espncdn.com/i/teamlogos/nfl/500/buf.png', 'blurb': 'Josh Allen is a force in the AFC East.'},
  {'team': 'Lions', 'logo': 'https://a.espncdn.com/i/teamlogos/nfl/500/det.png', 'blurb': 'Detroit is roaring back to relevance.'},
  {'team': 'Dolphins', 'logo': 'https://a.espncdn.com/i/teamlogos/nfl/500/mia.png', 'blurb': 'Speed kills, and Miami has plenty.'},
]; 