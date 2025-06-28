import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/player.dart';
import '../providers/player_provider.dart';
import '../providers/auth_provider.dart';
import 'player_profile.dart';

class RostersHomePage extends ConsumerStatefulWidget {
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
    context.go('/player/${player.id}', extra: player);
  }

  Widget _buildPlayersTab() {
    final players = ref.watch(searchResultsProvider);
    final playersState = ref.watch(playerProvider);

    return playersState.when(
      loading: () => Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text('Error loading players: $error'),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(playerProvider.notifier).refreshData(),
              child: Text('Retry'),
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
              decoration: InputDecoration(
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
                        Icon(Icons.search_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No players found'),
                        if (searchController.text.isNotEmpty)
                          Text('Try adjusting your search terms'),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: players.length,
                    itemBuilder: (context, index) {
                      final player = players[index];
                      return Card(
                        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        elevation: 6,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () => _openPlayerProfile(player),
                          child: Padding(
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
                                SizedBox(width: 24),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        player.fullName,
                                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                                      ),
                                      SizedBox(height: 6),
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
      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
    ),
  );

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
      loading: () => Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text('Error loading free agents: $error'),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(playerProvider.notifier).refreshData(),
              child: Text('Retry'),
            ),
          ],
        ),
      ),
      data: (_) => freeAgents.isEmpty
          ? Center(
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
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange.withOpacity(0.15),
                      child: Text(
                        player.position,
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                      ),
                    ),
                    title: Text(player.fullName),
                    subtitle: Text('${player.position} • OVR: ${player.overall} • Age: ${player.age}'),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16),
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
        title: Text('Player Rosters'),
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
            icon: Icon(Icons.refresh),
            tooltip: 'Refresh Data',
            onPressed: () => ref.read(playerProvider.notifier).refreshData(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(48),
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
              tabs: [
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
} 