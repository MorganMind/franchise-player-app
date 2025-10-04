# Routing Quick Reference Guide

This document provides a quick reference for implementing routing in the Franchise Player application.

## Route Patterns

### Basic Route Structure
```dart
GoRoute(
  path: '/route-name',
  builder: (context, state) => PageWidget(),
),
```

### Route with Parameters
```dart
GoRoute(
  path: '/section/:paramId',
  builder: (context, state) {
    final paramId = state.pathParameters['paramId']!;
    return PageWidget(paramId: paramId);
  },
),
```

### Nested Routes
```dart
GoRoute(
  path: '/franchise/:franchiseId',
  builder: (context, state) {
    final franchiseId = state.pathParameters['franchiseId']!;
    return FranchisePage(franchiseId: franchiseId);
  },
  routes: [
    GoRoute(
      path: 'player/:playerId',
      builder: (context, state) {
        final playerId = state.pathParameters['playerId']!;
        return PlayerProfilePage(playerId: playerId);
      },
    ),
  ],
),
```

## Current Route Patterns

### Main Routes
```dart
// Home
GoRoute(path: '/', builder: (context, state) => HomePage()),

// Authentication
GoRoute(path: '/login', builder: (context, state) => LoginPage()),

// Direct Messages
GoRoute(path: '/dm/:threadId', builder: (context, state) => HomePage(initialDmThreadId: threadId)),
```

### Server Routes
```dart
// Server with optional channel
GoRoute(
  path: '/server/:serverId',
  builder: (context, state) {
    final serverId = _getServerIdFromName(state.pathParameters['serverId']!);
    return HomePage(initialServerId: serverId);
  },
),

// Server with specific channel
GoRoute(
  path: '/server/:serverId/channel/:channelId',
  builder: (context, state) {
    final serverId = _getServerIdFromName(state.pathParameters['serverId']!);
    final channelId = state.pathParameters['channelId']!;
    return HomePage(initialServerId: serverId, initialChannelId: channelId);
  },
),
```

### Franchise Routes
```dart
// Franchise main page
GoRoute(
  path: '/franchise/:franchiseId',
  builder: (context, state) {
    final franchiseId = _getFranchiseIdFromName(state.pathParameters['franchiseId']!);
    return HomePage(initialFranchiseId: franchiseId);
  },
),

// Franchise with channel
GoRoute(
  path: '/franchise/:franchiseId/:channelId',
  builder: (context, state) {
    final franchiseId = _getFranchiseIdFromName(state.pathParameters['franchiseId']!);
    final channelId = state.pathParameters['channelId']!;
    return HomePage(initialFranchiseId: franchiseId, initialChannelId: channelId);
  },
),

// Franchise with player
GoRoute(
  path: '/franchise/:franchiseId/player/:playerId',
  builder: (context, state) {
    final franchiseId = _getFranchiseIdFromName(state.pathParameters['franchiseId']!);
    final playerId = state.pathParameters['playerId']!;
    return HomePage(initialFranchiseId: franchiseId, initialPlayerId: playerId);
  },
),
```

### Section Routes
```dart
// Simple section pages
GoRoute(path: '/news', builder: (context, state) => NewsPage()),
GoRoute(path: '/teams', builder: (context, state) => TeamsPage()),
GoRoute(path: '/rosters', builder: (context, state) => RostersPage()),
GoRoute(path: '/games', builder: (context, state) => GamesPage()),
GoRoute(path: '/statistics', builder: (context, state) => StatisticsPage()),
GoRoute(path: '/standings', builder: (context, state) => StandingsPage()),
GoRoute(path: '/trades', builder: (context, state) => TradesPage()),
GoRoute(path: '/awards', builder: (context, state) => AwardsPage()),
GoRoute(path: '/rules', builder: (context, state) => RulesPage()),
GoRoute(path: '/transactions', builder: (context, state) => TransactionsPage()),
GoRoute(path: '/draft', builder: (context, state) => DraftPage()),
GoRoute(path: '/rankings', builder: (context, state) => RankingsPage()),
GoRoute(path: '/export', builder: (context, state) => ExportPage()),
GoRoute(path: '/admin', builder: (context, state) => AdminPage()),
```

## Navigation Patterns

### Programmatic Navigation
```dart
// Basic navigation
context.go('/route-name');

// Navigation with parameters
context.go('/franchise/$franchiseName/player/$playerId');

// Navigation with extra data
context.go('/player/$playerId', extra: playerData);
```

### URL Generation
```dart
// Generate URL-safe names
final urlSafeName = franchiseName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9-]'), '-');
context.go('/franchise/$urlSafeName');
```

## Helper Functions

### Server ID Resolution
```dart
static String _getServerIdFromName(String serverNameOrId) {
  if (serverNameOrId.contains('-') && serverNameOrId.length > 20) {
    return serverNameOrId; // Already an ID
  }
  
  final readableName = serverNameOrId.replaceAll('-', ' ');
  
  switch (readableName.toLowerCase()) {
    case 'tech team':
      return '660e8400-e29b-41d4-a716-446655440002';
    case 'another server':
      return 'another-server-id';
    default:
      return serverNameOrId;
  }
}
```

### Franchise ID Resolution
```dart
static String _getFranchiseIdFromName(String franchiseNameOrId) {
  if (franchiseNameOrId.contains('-') && franchiseNameOrId.length > 20) {
    return franchiseNameOrId; // Already an ID
  }
  
  final readableName = franchiseNameOrId.replaceAll('-', ' ');
  
  switch (readableName.toLowerCase()) {
    case 'madden league alpha':
      return 'franchise-server-1';
    case 'casual gaming league':
      return 'franchise-server-2';
    case 'support server league':
      return 'franchise-server-3';
    default:
      return franchiseNameOrId;
  }
}
```

## Adding New Routes

### Step 1: Create the Page
```dart
// lib/views/new_page.dart
class NewPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('New Page')),
      body: Center(child: Text('New Page Content')),
    );
  }
}
```

### Step 2: Add Route to Router
```dart
// In lib/app.dart
GoRoute(
  path: '/new-page',
  builder: (context, state) => NewPage(),
),
```

### Step 3: Add Navigation
```dart
// In lib/home_page.dart drawer
_drawerItem(context, Icons.new_icon, 'New Page', '/new-page'),
```

### Step 4: Add Import
```dart
// In lib/app.dart
import 'views/new_page.dart';
```

## Route Guards and Redirects

### Authentication Redirect
```dart
redirect: (context, state) {
  final isLoggingIn = state.uri.toString() == '/login';
  final user = ref.read(currentUserProvider);
  
  if (user == null && !isLoggingIn) return '/login';
  if (user != null && isLoggingIn) return '/';
  return null;
},
```

### Public Routes
```dart
// Allow franchise and player routes without authentication
final isFranchiseRoute = state.uri.path.startsWith('/franchise/');
final isPlayerRoute = state.uri.path.startsWith('/player/');

if (isFranchiseRoute || isPlayerRoute) return null;
```

## Common Patterns

### Tab Navigation
```dart
// In franchise_page.dart
Widget _buildTabContent() {
  switch (selectedTab) {
    case 'news':
      return _buildNewsTab();
    case 'players':
      return _buildPlayersTab();
    // Add new tabs here
    default:
      return _buildPlayersTab();
  }
}
```

### Parameter Extraction
```dart
// From route parameters
final playerId = state.pathParameters['playerId']!;

// From query parameters
final queryParams = state.uri.queryParameters;
final filter = queryParams['filter'];

// From extra data
final playerData = state.extra as Player?;
```

### URL Building
```dart
// Build franchise URL
final franchiseName = _getFranchiseName(franchiseId);
final urlSafeName = franchiseName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9-]'), '-');
final url = '/franchise/$urlSafeName/player/$playerId';
```

## Best Practices

1. **Consistent Naming**: Use kebab-case for URLs
2. **Parameter Validation**: Always validate route parameters
3. **Error Handling**: Provide fallbacks for invalid routes
4. **Deep Linking**: Support direct URL access
5. **State Management**: Use providers for shared state
6. **Loading States**: Show loading indicators during navigation

## Common Issues and Solutions

### Issue: Route not found
**Solution**: Check route path and ensure it's added to the router

### Issue: Parameters not working
**Solution**: Verify parameter extraction and validation

### Issue: Navigation not working
**Solution**: Check context and ensure proper widget tree

### Issue: Deep linking broken
**Solution**: Verify route guards and authentication logic

This quick reference should help CURSOR implement new routes and navigation patterns effectively.
