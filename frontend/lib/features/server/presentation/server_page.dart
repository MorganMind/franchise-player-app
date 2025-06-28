// --- FLOATING NAVIGATION FIX APPLIED ---
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/auth_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../data/server_providers.dart';
import 'widgets/responsive_server_nav.dart';
import 'widgets/channel_sidebar.dart';
import 'widgets/mock_channel.dart';
import '../../../views/rosters_home.dart';
import '../../../providers/player_provider.dart';
import '../../../models/player.dart';
import 'dart:convert';
import 'dart:html' as html;

class ServerPage extends ConsumerStatefulWidget {
  final String serverId;
  const ServerPage({required this.serverId});

  @override
  _ServerPageState createState() => _ServerPageState();
}

class _ServerPageState extends ConsumerState<ServerPage> {
  String? selectedFranchiseId;
  String? selectedChannelId;
  String? selectedSubcategoryId;
  String selectedFranchiseSection = 'Franchise';

  @override
  Widget build(BuildContext context) {
    final currentServer = ref.watch(currentServerProvider);
    final navigationState = ref.watch(serverNavigationProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final themeMode = ref.watch(appThemeProvider);
    final isDark = themeMode == ThemeMode.dark;
    
    // Dummy channels
    final channels = [
      {'id': 'general', 'name': 'general', 'type': 'text'},
      {'id': 'announcements', 'name': 'announcements', 'type': 'text'},
      {'id': 'trades', 'name': 'trades', 'type': 'text'},
      {'id': 'draft', 'name': 'draft', 'type': 'text'},
    ];
    
    // Dummy franchises
    final franchises = [
      {'id': 'f1', 'name': '2027 Season', 'status': 'active'},
      {'id': 'f2', 'name': '2026 Season', 'status': 'archived'},
      {'id': 'f3', 'name': '2025 Season', 'status': 'archived'},
    ];
    // Dummy franchise sections
    final franchiseSections = [
      'Roster', 'Schedule', 'Stats', 'Chat', 'Trades', 'Draft', 'Awards'
    ];

    // Determine current context (channel or franchise section)
    String? contextLabel;
    if (selectedChannelId != null) {
      final channel = channels.firstWhere(
        (c) => c['id'] == selectedChannelId,
        orElse: () => <String, String>{},
      );
      if (channel.isNotEmpty) {
        contextLabel = '# ${channel['name']}';
      }
    } else if (selectedFranchiseId != null) {
      contextLabel = selectedFranchiseSection;
    } else {
      contextLabel = currentServer != null ? currentServer['name'] : '';
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // Header - spans full width
          Container(
            height: 64,
            padding: EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: Theme.of(context).appBarTheme.backgroundColor ?? (isDark ? Color(0xFF18191C) : Colors.white),
              border: Border(
                bottom: BorderSide(color: isDark ? Color(0xFF232428) : Color(0xFFE9ECEF), width: 1),
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Left: Franchise Player logo
                Align(
                  alignment: Alignment.centerLeft,
                  child: Image.asset(
                    'assets/logo.png',
                    height: 36,
                    width: 36,
                    fit: BoxFit.contain,
                  ),
                ),
                // Center: Context label
                Center(
                  child: Text(
                    contextLabel ?? '',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Color(0xFF232428),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Right: Dark mode toggle and menu
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Toggle Light/Dark Mode',
                        icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode, color: isDark ? Colors.white : Colors.black),
                        onPressed: () {
                          ref.read(appThemeProvider.notifier).state = isDark ? ThemeMode.light : ThemeMode.dark;
                        },
                      ),
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert, color: isDark ? Colors.white70 : Color(0xFF6C757D), size: 20),
                        onSelected: (value) async {
                          if (value == 'logout') {
                            try {
                              await ref.read(authProvider.notifier).signOut();
                              if (context.mounted) {
                                context.go('/login');
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Logout failed: $e')),
                                );
                              }
                            }
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'logout',
                            child: Row(
                              children: [
                                Icon(Icons.logout, color: isDark ? Colors.white70 : Color(0xFF6C757D), size: 18),
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
              ],
            ),
          ),
          // Main content area with nav
          Expanded(
            child: Row(
              children: [
                // Server navigation (desktop only)
                if (!isMobile) ResponsiveServerNav(),
                // Channel sidebar (desktop only)
                if (!isMobile)
                  ChannelSidebar(
                    serverId: widget.serverId,
                    currentFranchiseId: selectedFranchiseId,
                    currentChannelId: selectedChannelId,
                    currentSubcategoryId: selectedSubcategoryId,
                    onSelect: (franchiseId, channelId, subcategoryId) {
                      setState(() {
                        selectedFranchiseId = franchiseId;
                        selectedChannelId = channelId;
                        selectedSubcategoryId = subcategoryId;
                        if (franchiseId != null && channelId == null && subcategoryId == null) {
                          selectedFranchiseSection = 'Franchise';
                        }
                      });
                    },
                  ),
                // Content area
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(24),
                    child: _buildMainPanel(),
                  ),
                ),
              ],
            ),
          ),
          // Mobile bottom navigation
          if (isMobile) ResponsiveServerNav(),
        ],
      ),
    );
  }

  Widget _buildMainPanel() {
    // If a text channel is selected (no franchise)
    if (selectedFranchiseId == null && selectedChannelId != null) {
      return _buildChannelContent();
    }
    
    // If a franchise is selected (but not a channel/subcategory), show the full franchise dashboard
    if (selectedFranchiseId != null && selectedChannelId == null && selectedSubcategoryId == null) {
      // TODO: Replace with your real franchise dashboard widget
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Franchise navigation (horizontal menu)
          _buildFranchiseNav(),
          SizedBox(height: 24),
          // Franchise section content (real data)
          Expanded(
            child: _buildFranchiseSection(selectedFranchiseSection),
          ),
        ],
      );
    }
    // If a channel or subcategory is selected, show franchise nav at top and channel content below
    if (selectedFranchiseId != null && (selectedChannelId != null || selectedSubcategoryId != null)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFranchiseNav(),
          SizedBox(height: 24),
          Expanded(
            child: _buildChannelContent(),
          ),
        ],
      );
    }
    // Default welcome panel
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome to ${ref.watch(currentServerProvider)?['name'] ?? 'Server'}!',
          style: TextStyle(
            color: Colors.black,
            fontSize: 32,
            fontWeight: FontWeight.w700,
            letterSpacing: -1.0,
          ),
        ),
        SizedBox(height: 12),
        Text(
          'This is the general channel for discussing all things Madden and franchise management.',
          style: TextStyle(
            color: Color(0xFF6C757D),
            fontSize: 18,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildFranchiseNav() {
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
      padding: EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
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
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: selectedFranchiseSection == (section['name'] as String)
                        ? Color(0xFF1A1A1A) 
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selectedFranchiseSection == (section['name'] as String)
                          ? Color(0xFF1A1A1A) 
                          : Color(0xFFE9ECEF),
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
                            : Color(0xFF6C757D),
                      ),
                      SizedBox(width: 6),
                      Text(
                        section['name'] as String,
                        style: TextStyle(
                          color: selectedFranchiseSection == (section['name'] as String)
                              ? Colors.white 
                              : Color(0xFF6C757D),
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

  Widget _buildFranchiseSection(String section) {
    // Only show real data for the "Madden X Launch" franchise (f1)
    if (selectedFranchiseId == 'f1') {
      switch (section) {
        case 'Franchise':
          return _buildPlaceholderSection('Franchise Overview', 'Franchise settings, season info, and general management will be displayed here');
        case 'Players':
          // Use the real rosters widget
          return Column(
            children: [
              // Debug section
              Container(
                margin: EdgeInsets.only(bottom: 16),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Color(0xFFE9ECEF), width: 1),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Color(0xFF6C757D)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Debug: Check browser console for data loading logs',
                        style: TextStyle(color: Color(0xFF6C757D)),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => ref.read(playerProvider.notifier).refreshData(),
                      child: Text('Refresh Data'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF1A1A1A),
                        foregroundColor: Colors.white,
                      ),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _loadSampleData(),
                      child: Text('Load Sample Data'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF28A745),
                        foregroundColor: Colors.white,
                      ),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => context.go('/upload'),
                      child: Text('Upload Data'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF007BFF),
                        foregroundColor: Colors.white,
                      ),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _clearData(),
                      child: Text('Clear Data'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFDC3545),
                        foregroundColor: Colors.white,
                      ),
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
                    border: Border.all(color: Color(0xFFE9ECEF), width: 1),
                  ),
                  child: RostersHomePage(),
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
              border: Border.all(color: Color(0xFFE9ECEF), width: 1),
            ),
            child: _buildTeamsTab(),
          );
        case 'Stats':
          return _buildPlaceholderSection('Statistics', 'Player and team statistics, rankings, and performance metrics will be displayed here');
        case 'Schedule':
          return _buildPlaceholderSection('Schedule', 'Game schedule, results, and upcoming matchups will be displayed here');
        case 'Standings':
          return _buildPlaceholderSection('Standings', 'Division and conference standings, playoff picture, and team records will be displayed here');
        case 'Trades':
          return _buildPlaceholderSection('Trades', 'Trade history, pending trades, and trade block will be displayed here');
        case 'Awards':
          return _buildPlaceholderSection('Awards', 'Season awards, player achievements, and recognition will be displayed here');
        case 'Rules':
          return _buildPlaceholderSection('Rules', 'League rules, settings, and guidelines will be displayed here');
        default:
          return _buildPlaceholderSection('Section', 'Content for $section will be displayed here');
      }
    } else {
      // For other franchises, show placeholder content
      return _buildPlaceholderSection(
        'Franchise: $selectedFranchiseId', 
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
        border: Border.all(color: Color(0xFFE9ECEF), width: 1),
      ),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isError ? Icons.sports_football : Icons.analytics,
                size: 64, 
                color: isError ? Colors.grey : Color(0xFF1A1A1A),
              ),
              SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
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
      loading: () => Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text('Error loading teams: $error'),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(playerProvider.notifier).refreshData(),
              child: Text('Retry'),
            ),
          ],
        ),
      ),
      data: (_) => teams.isEmpty
          ? Center(
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
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
                    trailing: Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      context.go('/player/${player.id}', extra: player);
                    },
                  )).toList(),
                );
              },
            ),
    );
  }

  Widget _buildChannelContent() {
    // Get channel and subcategory names from the sidebar data
    String channelName = selectedChannelId ?? 'general';
    String? subcategoryName = selectedSubcategoryId;
    
    // For text channels (when selectedFranchiseId is null)
    if (selectedFranchiseId == null) {
      return MockChannel(channelName: channelName);
    }
    
    // For franchise channels and subcategories
    return MockChannel(
      channelName: channelName,
      subcategoryName: subcategoryName,
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
          content: Text('Sample data loaded successfully! ${samplePlayers.length} players added.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading sample data: $e'),
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
        SnackBar(
          content: Text('Data cleared successfully!'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error clearing data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
} 