import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/player_provider.dart';

class HomePage extends ConsumerWidget {
  final VoidCallback? onToggleTheme;
  final ThemeMode? themeMode;
  
  const HomePage({super.key, this.onToggleTheme, this.themeMode});
  
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
                    child: InkWell(
                      onTap: () => context.go('/home'),
                      child: Image.asset(
                        'assets/logo.png',
                        height: 40,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.sports_football, size: 40),
                      ),
                    ),
                  ),
                  const Text('MADDEN X', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
                  const SizedBox(height: 4),
                  const Text('2027 Regular Season', style: TextStyle(fontSize: 15)),
                  const Text('Week 13', style: TextStyle(fontSize: 15)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.shield, size: 32, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text('Raiders', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Theme.of(context).colorScheme.primary)),
                    ],
                  ),
                ],
              ),
            ),
            _drawerItem(context, Icons.home, 'Home', '/home'),
            _drawerItem(context, Icons.chat_bubble, 'Direct Messages', '/home/dm'),
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
            _drawerItem(context, Icons.business, 'Franchise Management', '/franchise-management'),
          ],
        ),
      ),
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => context.go('/home'),
              child: Image.asset(
                'assets/logo.png',
                height: 36,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.sports_football, size: 32),
              ),
            ),
            const SizedBox(width: 12),
            const Text('Franchise Player Dashboard'),
          ],
        ),
        actions: [
          // Theme toggle
          IconButton(
            icon: const Icon(Icons.brightness_6),
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
            icon: const Icon(Icons.logout),
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
                  '/home','/home/dm','/rules','/news','/teams','/rosters','/games','/statistics','/standings','/transactions','/draft','/rankings','/trades','/export','/awards','/admin'
                ];
                context.go(routes[idx]);
              },
              labelType: NavigationRailLabelType.all,
              destinations: const [
                NavigationRailDestination(icon: Icon(Icons.home), label: Text('Home')),
                NavigationRailDestination(icon: Icon(Icons.chat_bubble), label: Text('DM')),
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
                        child: InkWell(
                          onTap: () => context.go('/home'),
                          child: Image.asset(
                            'assets/logo.png',
                            height: 64,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.sports_football, size: 48),
                          ),
                        ),
                      ),
                    ),
                    SelectableText('Welcome to Franchise Player', style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 16),
                    
                    // User info card
                    if (user != null)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              CircleAvatar(
                                child: Text(user.email?.substring(0, 1).toUpperCase() ?? 'U'),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SelectableText('Welcome back!', style: Theme.of(context).textTheme.titleMedium),
                                    SelectableText(user.email ?? 'Unknown user', style: Theme.of(context).textTheme.bodyMedium),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: 24),
                    
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
                    
                    const SizedBox(height: 32),
                    
                    // Data source info
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Data Source', style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  useLocalData ? Icons.storage : Icons.cloud,
                                  color: useLocalData ? Colors.orange : Colors.blue,
                                ),
                                const SizedBox(width: 8),
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
                                padding: const EdgeInsets.only(top: 8),
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
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPublicLandingPage(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Image.asset(
              'assets/logo.png',
              height: 36,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.sports_football, size: 32),
            ),
            const SizedBox(width: 12),
            const Text('Franchise Player'),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => context.go('/login'),
            icon: const Icon(Icons.login),
            label: const Text('Login'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero section
              Center(
                child: Column(
                  children: [
                    Image.asset(
                      'assets/logo.png',
                      height: 120,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.sports_football, size: 80),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Welcome to Franchise Player',
                      style: Theme.of(context).textTheme.headlineLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Your ultimate Madden franchise management platform',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 48),
              
              // Available franchises
              Text(
                'Available Franchises',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 24),
              
              Wrap(
                spacing: 24,
                runSpacing: 24,
                children: [
                  _buildFranchiseCard(context, 'Madden League Alpha', 'franchise-1', Icons.sports_football, Colors.blue),
                  _buildFranchiseCard(context, 'Franchise Beta', 'franchise-2', Icons.sports_football, Colors.green),
                  _buildFranchiseCard(context, 'Franchise Gamma', 'franchise-3', Icons.sports_football, Colors.orange),
                ],
              ),
              
              const SizedBox(height: 48),
              
              // Features section
              Text(
                'Features',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 24),
              
              Row(
                children: [
                  Expanded(
                    child: _buildFeatureCard(
                      context,
                      'Player Rosters',
                      'View detailed player information, stats, and ratings',
                      Icons.people,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildFeatureCard(
                      context,
                      'Team Statistics',
                      'Comprehensive team and player statistics',
                      Icons.bar_chart,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildFeatureCard(
                      context,
                      'Standings',
                      'Current league standings and rankings',
                      Icons.format_list_numbered,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFranchiseCard(BuildContext context, String name, String franchiseId, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: () => context.go('/franchise/$franchiseId'),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 280,
          height: 160,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 16),
              Text(
                name,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'View Players, Stats & More',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(BuildContext context, String title, String description, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
} 