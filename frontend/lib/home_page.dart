import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/player_provider.dart';

class HomePage extends ConsumerWidget {
  final VoidCallback? onToggleTheme;
  final ThemeMode? themeMode;
  
  HomePage({this.onToggleTheme, this.themeMode});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    final useLocalData = ref.watch(useLocalDataProvider);
    final playersState = ref.watch(playerProvider);
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo in drawer
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Image.asset(
                      'assets/logo.png',
                      height: 40,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Icon(Icons.sports_football, size: 40),
                    ),
                  ),
                  Text('MADDEN X', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
                  SizedBox(height: 4),
                  Text('2027 Regular Season', style: TextStyle(fontSize: 15)),
                  Text('Week 13', style: TextStyle(fontSize: 15)),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.shield, size: 32, color: Theme.of(context).colorScheme.primary),
                      SizedBox(width: 8),
                      Text('Raiders', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Theme.of(context).colorScheme.primary)),
                    ],
                  ),
                ],
              ),
            ),
            _drawerItem(context, Icons.home, 'Home', '/home'),
            _drawerItem(context, Icons.gavel, 'Rules', '/rules'),
            _drawerItem(context, Icons.article, 'News', '/news'),
            _drawerItem(context, Icons.groups, 'Teams', '/teams'),
            _drawerItem(context, Icons.person, 'Players', '/rosters'),
            _drawerItem(context, Icons.event, 'Games', '/games'),
            _drawerItem(context, Icons.bar_chart, 'Statistics', '/statistics'),
            _drawerItem(context, Icons.format_list_numbered, 'Standings', '/standings'),
            _drawerItem(context, Icons.attach_money, 'Transactions', '/transactions'),
            _drawerItem(context, Icons.edit, 'Draft', '/draft'),
            _drawerItem(context, Icons.star, 'Rankings', '/rankings'),
            _drawerItem(context, Icons.swap_horiz, 'Trades', '/trades'),
            _drawerItem(context, Icons.download, 'Export CSV', '/export'),
            _drawerItem(context, Icons.emoji_events, 'Awards', '/awards'),
            _drawerItem(context, Icons.admin_panel_settings, 'Administration', '/admin'),
          ],
        ),
      ),
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Image.asset(
              'assets/logo.png',
              height: 36,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Icon(Icons.sports_football, size: 32),
            ),
            SizedBox(width: 12),
            Text('Franchise Player Dashboard'),
          ],
        ),
        actions: [
          // Theme toggle
          IconButton(
            icon: Icon(Icons.brightness_6),
            tooltip: 'Toggle Light/Dark Mode',
            onPressed: () => ref.read(themeProvider.notifier).toggleTheme(),
          ),
          // Data source toggle (only for specific user)
          if (user?.email == 'nashabramsx@gmail.com')
            IconButton(
              icon: Icon(useLocalData ? Icons.storage : Icons.cloud),
              tooltip: 'Toggle Data Source (${useLocalData ? 'Local' : 'Supabase'})',
              onPressed: () {
                ref.read(playerProvider.notifier).setUseLocalData(!useLocalData);
              },
            ),
          // Sign out
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authProvider.notifier).signOut();
              context.go('/login');
            },
          ),
        ],
      ),
      body: Row(
        children: [
          // Optionally, NavigationRail for wide screens
          if (MediaQuery.of(context).size.width > 900)
            NavigationRail(
              selectedIndex: 0,
              onDestinationSelected: (int idx) {
                final routes = [
                  '/home','/rules','/news','/teams','/rosters','/games','/statistics','/standings','/transactions','/draft','/rankings','/trades','/export','/awards','/admin'
                ];
                context.go(routes[idx]);
              },
              labelType: NavigationRailLabelType.all,
              destinations: [
                NavigationRailDestination(icon: Icon(Icons.home), label: Text('Home')),
                NavigationRailDestination(icon: Icon(Icons.gavel), label: Text('Rules')),
                NavigationRailDestination(icon: Icon(Icons.article), label: Text('News')),
                NavigationRailDestination(icon: Icon(Icons.groups), label: Text('Teams')),
                NavigationRailDestination(icon: Icon(Icons.person), label: Text('Players')),
                NavigationRailDestination(icon: Icon(Icons.event), label: Text('Games')),
                NavigationRailDestination(icon: Icon(Icons.bar_chart), label: Text('Statistics')),
                NavigationRailDestination(icon: Icon(Icons.format_list_numbered), label: Text('Standings')),
                NavigationRailDestination(icon: Icon(Icons.attach_money), label: Text('Transactions')),
                NavigationRailDestination(icon: Icon(Icons.edit), label: Text('Draft')),
                NavigationRailDestination(icon: Icon(Icons.star), label: Text('Rankings')),
                NavigationRailDestination(icon: Icon(Icons.swap_horiz), label: Text('Trades')),
                NavigationRailDestination(icon: Icon(Icons.download), label: Text('Export CSV')),
                NavigationRailDestination(icon: Icon(Icons.emoji_events), label: Text('Awards')),
                NavigationRailDestination(icon: Icon(Icons.admin_panel_settings), label: Text('Admin')),
              ],
            ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo on home page
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 24.0),
                        child: Image.asset(
                          'assets/logo.png',
                          height: 64,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Icon(Icons.sports_football, size: 48),
                        ),
                      ),
                    ),
                    Text('Welcome to Franchise Player', style: Theme.of(context).textTheme.headlineMedium),
                    SizedBox(height: 16),
                    
                    // User info card
                    if (user != null)
                      Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            children: [
                              CircleAvatar(
                                child: Text(user.email?.substring(0, 1).toUpperCase() ?? 'U'),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Welcome back!', style: Theme.of(context).textTheme.titleMedium),
                                    Text(user.email ?? 'Unknown user', style: Theme.of(context).textTheme.bodyMedium),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    
                    SizedBox(height: 24),
                    
                    // Dashboard cards
                    Wrap(
                      spacing: 24,
                      runSpacing: 24,
                      children: [
                        _dashboardCard(context, 'Upload Franchise Data', Icons.upload_file, Colors.blue, '/upload'),
                        _dashboardCard(context, 'View Rosters', Icons.people, Colors.deepPurple, '/rosters'),
                        _dashboardCard(context, 'Standings', Icons.format_list_numbered, Colors.orange, '/standings'),
                        _dashboardCard(context, 'Statistics', Icons.bar_chart, Colors.green, '/statistics'),
                        _dashboardCard(context, 'Draft', Icons.edit, Colors.red, '/draft'),
                        _dashboardCard(context, 'Awards', Icons.emoji_events, Colors.amber, '/awards'),
                      ],
                    ),
                    
                    SizedBox(height: 32),
                    
                    // Data source info
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Data Source', style: Theme.of(context).textTheme.titleMedium),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  useLocalData ? Icons.storage : Icons.cloud,
                                  color: useLocalData ? Colors.orange : Colors.blue,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Using ${useLocalData ? 'Local Storage' : 'Supabase Live Data'}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                            if (playersState.when(
                              data: (players) => players.isNotEmpty,
                              loading: () => false,
                              error: (_, __) => false,
                            ))
                              Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Text(
                                  '${playersState.when(
                                    data: (players) => players.length,
                                    loading: () => 0,
                                    error: (_, __) => 0,
                                  )} players loaded',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerItem(BuildContext context, IconData icon, String title, String route) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        Navigator.of(context).pop(); // Close drawer
        context.go(route);
      },
    );
  }

  Widget _dashboardCard(BuildContext context, String title, IconData icon, Color color, String route) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: () => context.go(route),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 200,
          height: 120,
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              SizedBox(height: 8),
              Text(title, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
} 