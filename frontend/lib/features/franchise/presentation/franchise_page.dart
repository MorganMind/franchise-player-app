import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../views/rosters_home.dart';

class FranchiseHeaderNav extends StatefulWidget {
  final String serverId;
  final String franchiseId;
  const FranchiseHeaderNav({super.key, required this.serverId, required this.franchiseId});

  @override
  State<FranchiseHeaderNav> createState() => _FranchiseHeaderNavState();
}

class _FranchiseHeaderNavState extends State<FranchiseHeaderNav> {
  String selectedSection = 'Franchise';
  final int _standingsTabIndex = 0; // For Standings tab

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // If the section is in the route, update selectedSection
    final state = GoRouterState.of(context);
    final sectionFromRoute = state.uri.queryParameters['section'];
    if (sectionFromRoute != null && sectionFromRoute != selectedSection) {
      setState(() {
        selectedSection = sectionFromRoute;
      });
    }
  }

  void _onSectionTap(String section) {
    setState(() {
      selectedSection = section;
    });
    // Update the route with the selected section as a query parameter
    context.go('/franchise/${widget.franchiseId}?section=$section');
  }

  @override
  Widget build(BuildContext context) {
    Widget sectionContent;
    switch (selectedSection) {
      case 'Franchise':
        sectionContent = _buildFranchiseHomePage();
        break;
      case 'Players':
        sectionContent = RostersHomePage(franchiseId: widget.franchiseId);
        break;
      case 'Teams':
        sectionContent = _buildTeamsTab();
        break;
      case 'Stats':
        sectionContent = _buildStatsMuseStyleStats();
        break;
      case 'Schedule':
        sectionContent = _buildPlaceholderSection('Schedule', 'Game schedule, results, and upcoming matchups will be displayed here');
        break;
      case 'Standings':
        sectionContent = _buildPowerRankingsAndStandings();
        break;
      case 'Trades':
        sectionContent = _buildTradesTab();
        break;
      case 'Awards':
        sectionContent = _buildAwardsTab();
        break;
      case 'Rules':
        sectionContent = _buildPlaceholderSection('Rules', 'League rules, settings, and guidelines will be displayed here');
        break;
      default:
        sectionContent = const Center(child: Text('Unknown section'));
    }
    return Scaffold(
      appBar: AppBar(title: Text('Franchise ${widget.franchiseId}')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Horizontal navigation bar
          Container(
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
                      onTap: () => _onSectionTap(section['name'] as String),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: selectedSection == (section['name'] as String)
                              ? const Color(0xFF1A1A1A)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selectedSection == (section['name'] as String)
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
                              color: selectedSection == (section['name'] as String)
                                  ? Colors.white
                                  : const Color(0xFF6C757D),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              section['name'] as String,
                              style: TextStyle(
                                color: selectedSection == (section['name'] as String)
                                    ? Colors.white
                                    : const Color(0xFF6C757D),
                                fontWeight: selectedSection == (section['name'] as String)
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
          ),
          // Main content area for the selected section
          Expanded(
            child: sectionContent,
          ),
        ],
      ),
    );
  }

  // --- Real tab implementations moved from ServerPage ---
  Widget _buildFranchiseHomePage() {
    // TODO: Move your real Franchise Home content here
    return const Center(child: Text('Franchise Home Content'));
  }

  Widget _buildTeamsTab() {
    // TODO: Move your real Teams tab content here
    return const Center(child: Text('Teams Content'));
  }

  Widget _buildStatsMuseStyleStats() {
    // TODO: Move your real Stats tab content here
    return const Center(child: Text('Stats Content'));
  }

  Widget _buildPowerRankingsAndStandings() {
    // TODO: Move your real Standings tab content here
    return const Center(child: Text('Standings Content'));
  }

  Widget _buildTradesTab() {
    // TODO: Move your real Trades tab content here
    return const Center(child: Text('Trades Content'));
  }

  Widget _buildAwardsTab() {
    // TODO: Move your real Awards tab content here
    return const Center(child: Text('Awards Content'));
  }

  Widget _buildPlaceholderSection(String title, String message) => Center(child: Text('$title: $message'));
} 