import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../home_page.dart';
import '../login_page.dart';
import '../upload_page.dart';
import '../views/rosters_home.dart';
import '../views/rules_page.dart';
import '../views/news_page.dart';
import '../views/teams_page.dart';
import '../views/games_page.dart';
import '../views/statistics_page.dart';
import '../views/standings_page.dart';
import '../views/transactions_page.dart';
import '../views/draft_page.dart';
import '../views/rankings_page.dart';
import '../views/trades_page.dart';
import '../views/export_csv_page.dart';
import '../views/awards_page.dart';
import '../views/admin_page.dart';
import '../views/player_profile.dart';
import '../models/player.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    routes: [
      // Auth routes
      GoRoute(
        path: '/login',
        builder: (context, state) => LoginPage(),
      ),
      
      // Main app routes
      GoRoute(
        path: '/home',
        builder: (context, state) => HomePage(
          onToggleTheme: () {}, // Fixed: VoidCallback with no parameters
          themeMode: ThemeMode.system,
        ),
      ),
      
      // Upload route
      GoRoute(
        path: '/upload',
        builder: (context, state) => UploadPage(),
      ),
      
      // Rosters route
      GoRoute(
        path: '/rosters',
        builder: (context, state) => RostersHomePage(),
      ),
      
      // Player profile route
      GoRoute(
        path: '/player/:id',
        builder: (context, state) {
          final playerId = state.pathParameters['id']!;
          return PlayerProfilePage(playerId: playerId);
        },
      ),
      
      // League management routes
      GoRoute(
        path: '/rules',
        builder: (context, state) => RulesPage(),
      ),
      
      GoRoute(
        path: '/news',
        builder: (context, state) => NewsPage(),
      ),
      
      GoRoute(
        path: '/teams',
        builder: (context, state) => TeamsPage(),
      ),
      
      GoRoute(
        path: '/games',
        builder: (context, state) => GamesPage(),
      ),
      
      GoRoute(
        path: '/statistics',
        builder: (context, state) => StatisticsPage(),
      ),
      
      GoRoute(
        path: '/standings',
        builder: (context, state) => StandingsPage(),
      ),
      
      GoRoute(
        path: '/transactions',
        builder: (context, state) => TransactionsPage(),
      ),
      
      GoRoute(
        path: '/draft',
        builder: (context, state) => DraftPage(),
      ),
      
      GoRoute(
        path: '/rankings',
        builder: (context, state) => RankingsPage(),
      ),
      
      GoRoute(
        path: '/trades',
        builder: (context, state) => TradesPage(),
      ),
      
      GoRoute(
        path: '/export',
        builder: (context, state) => ExportCsvPage(),
      ),
      
      GoRoute(
        path: '/awards',
        builder: (context, state) => AwardsPage(),
      ),
      
      GoRoute(
        path: '/admin',
        builder: (context, state) => AdminPage(),
      ),
    ],
    
    // Error handling
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: Text('Page Not Found')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('404 - Page Not Found', style: TextStyle(fontSize: 24)),
            SizedBox(height: 16),
            Text('The page "${state.uri.path}" was not found.'),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
} 