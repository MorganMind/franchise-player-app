# Franchise Tabs and Sections Documentation

This document provides comprehensive information about all tabs, sections, and routing in the Franchise Player application to help CURSOR understand the structure for future development.

## Overview

The application has two main navigation structures:
1. **Main Navigation** (Drawer/Sidebar) - Global app sections
2. **Franchise Tabs** - Franchise-specific sections within a franchise context

## Main Navigation Structure

### Current Routes and Pages

| Route | Page File | Icon | Description | Status |
|-------|-----------|------|-------------|---------|
| `/` | `home_page.dart` | `Icons.home` | Main dashboard | ✅ Implemented |
| `/home/dm` | `dm_inbox_page.dart` | `Icons.chat_bubble` | Direct messages | ✅ Implemented |
| `/rules` | `rules_page.dart` | `Icons.gavel` | League rules | 🚧 Placeholder |
| `/news` | `news_page.dart` | `Icons.article` | League news | 🚧 Placeholder |
| `/teams` | `teams_page.dart` | `Icons.groups` | Team management | 🚧 Placeholder |
| `/rosters` | `rosters_home.dart` | `Icons.person` | Player rosters | ✅ Implemented |
| `/games` | `games_page.dart` | `Icons.event` | Game schedule/results | 🚧 Placeholder |
| `/statistics` | `statistics_page.dart` | `Icons.bar_chart` | Player/team stats | 🚧 Placeholder |
| `/standings` | `standings_page.dart` | `Icons.format_list_numbered` | League standings | 🚧 Placeholder |
| `/transactions` | `transactions_page.dart` | `Icons.attach_money` | Financial transactions | 🚧 Placeholder |
| `/draft` | `draft_page.dart` | `Icons.edit` | Draft management | 🚧 Placeholder |
| `/rankings` | `rankings_page.dart` | `Icons.star` | Player rankings | 🚧 Placeholder |
| `/trades` | `trades_page.dart` | `Icons.swap_horiz` | Trade management | 🚧 Placeholder |
| `/export` | `export_csv_page.dart` | `Icons.download` | Data export | 🚧 Placeholder |
| `/awards` | `awards_page.dart` | `Icons.emoji_events` | Awards/honors | 🚧 Placeholder |
| `/admin` | `admin_page.dart` | `Icons.admin_panel_settings` | Administration | 🚧 Placeholder |
| `/franchise-management` | `franchise_management_page.dart` | `Icons.business` | Franchise management | ✅ Implemented |

## Franchise Tab Structure

### Current Franchise Tabs

The franchise page (`franchise_page.dart`) contains the following tabs:

| Tab ID | Tab Name | Description | Status | Implementation |
|--------|----------|-------------|---------|----------------|
| `news` | News | Franchise-specific news and announcements | 🚧 Placeholder | `_buildNewsTab()` |
| `players` | Players | Player roster and management | ✅ Implemented | `_buildPlayersTab()` |
| `games` | Games | Game schedule and results | 🚧 Placeholder | `_buildGamesTab()` |
| `standings` | Standings | Franchise standings | 🚧 Placeholder | `_buildStandingsTab()` |
| `statistics` | Statistics | Player and team statistics | 🚧 Placeholder | `_buildStatisticsTab()` |
| `trades` | Trades | Trade management | 🚧 Placeholder | `_buildTradesTab()` |
| `awards` | Awards | Awards and honors | 🚧 Placeholder | `_buildAwardsTab()` |
| `rules` | Rules | Franchise rules | 🚧 Placeholder | `_buildRulesTab()` |

## Detailed Section Documentation

### 1. Players Tab (`players`)
**File**: `franchise_page.dart` - `_buildPlayersTab()`
**Status**: ✅ Fully Implemented

**Features**:
- Display all players in the current franchise
- Player search and filtering
- Player card display with stats
- Upload player data functionality
- Click to view detailed player profile
- Real-time data from Supabase

**Routing**:
- Player cards link to: `/franchise/{franchiseName}/player/{playerId}`
- Uses `PlayerProfilePage` for detailed view

**Data Sources**:
- `publicDataProvider` for player data
- Filtered by `currentFranchiseId`

### 2. Franchise Management (`franchise-management`)
**File**: `franchise_management_page.dart`
**Status**: ✅ Fully Implemented

**Features**:
- Create new franchises
- Edit franchise names
- Add/edit/delete channels
- Real-time database operations
- Channel type management (text/voice/video)

**Routing**:
- Accessible from drawer menu and franchise page header
- Route: `/franchise-management`

### 3. Player Profile (`/player/{playerId}`)
**File**: `player_profile.dart`
**Status**: ✅ Fully Implemented

**Features**:
- Detailed player information
- Player statistics
- Bio information
- Responsive design
- Public/authenticated views

**Routing**:
- Direct: `/player/{playerId}`
- Franchise context: `/franchise/{franchiseName}/player/{playerId}`

### 4. Rosters (`/rosters`)
**File**: `rosters_home.dart`
**Status**: ✅ Fully Implemented

**Features**:
- Global player roster view
- Player search and filtering
- Upload functionality
- Player management

## Placeholder Pages

### Current Placeholder Structure

All placeholder pages follow this pattern:
```dart
class PageName extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Page Name')),
      body: Center(
        child: Text('Page Name - Coming Soon'),
      ),
    );
  }
}
```

### Placeholder Pages to Implement

1. **News Tab** (`news_page.dart`)
   - Franchise announcements
   - League updates
   - News feed
   - Notification system

2. **Games Tab** (`games_page.dart`)
   - Game schedule
   - Match results
   - Game statistics
   - Head-to-head records

3. **Standings Tab** (`standings_page.dart`)
   - League standings
   - Division rankings
   - Playoff picture
   - Season statistics

4. **Statistics Tab** (`statistics_page.dart`)
   - Player statistics
   - Team statistics
   - League leaders
   - Historical data

5. **Trades Tab** (`trades_page.dart`)
   - Trade proposals
   - Trade history
   - Trade analysis
   - Trade approval system

6. **Awards Tab** (`awards_page.dart`)
   - Player awards
   - Team awards
   - Hall of fame
   - Achievement system

7. **Rules Tab** (`rules_page.dart`)
   - League rules
   - Franchise rules
   - Rule updates
   - Rule enforcement

8. **Teams Tab** (`teams_page.dart`)
   - Team management
   - Team rosters
   - Team statistics
   - Team settings

9. **Transactions Tab** (`transactions_page.dart`)
   - Financial transactions
   - Salary cap management
   - Contract management
   - Budget tracking

10. **Draft Tab** (`draft_page.dart`)
    - Draft board
    - Draft order
    - Player scouting
    - Draft history

11. **Rankings Tab** (`rankings_page.dart`)
    - Player rankings
    - Position rankings
    - Team rankings
    - Power rankings

12. **Export Tab** (`export_csv_page.dart`)
    - Data export
    - Report generation
    - Backup functionality
    - Data analysis

13. **Admin Tab** (`admin_page.dart`)
    - User management
    - System settings
    - Data management
    - Administrative tools

## Routing Architecture

### URL Structure

```
/                           # Main dashboard
/home                       # Home page
/home/dm                    # Direct messages
/franchise/{franchiseName}  # Franchise page with tabs
/franchise/{franchiseName}/player/{playerId}  # Player in franchise context
/player/{playerId}          # Player profile (legacy)
/franchise-management       # Franchise management
/{section}                  # Other sections (rules, news, etc.)
```

### Route Parameters

- `franchiseName`: URL-safe franchise name (e.g., "madden-league-alpha")
- `playerId`: Unique player identifier
- `franchiseId`: Internal franchise ID (e.g., "franchise-server-1")

### Navigation Patterns

1. **Franchise Context**: Most operations happen within a franchise context
2. **Player Context**: Players can be viewed globally or within a franchise
3. **Server Context**: Some operations are server-wide
4. **Global Context**: Some sections are app-wide

## Data Models

### Key Models

1. **Player** (`models/player.dart`)
   - Player information and statistics
   - Franchise association
   - Team association

2. **Franchise** (`models/franchise.dart`)
   - Franchise information
   - Server association
   - Channel management

3. **FranchiseChannel** (`models/franchise.dart`)
   - Channel information
   - Type (text/voice/video)
   - Permissions and settings

4. **User** (`models/user.dart`)
   - User profile information
   - Authentication data

## State Management

### Providers

1. **Franchise Providers** (`providers/franchise_providers.dart`)
   - Franchise data management
   - Channel management
   - Real-time updates

2. **Player Providers** (`providers/player_provider.dart`)
   - Player data management
   - Search and filtering

3. **Public Data Provider** (`providers/public_data_provider.dart`)
   - Public player data
   - Upload management

4. **Auth Provider** (`providers/auth_provider.dart`)
   - Authentication state
   - User management

## Implementation Guidelines

### For New Tab Implementation

1. **Create the page file** in `lib/views/`
2. **Add routing** in `lib/app.dart`
3. **Add navigation** in `lib/home_page.dart` drawer
4. **Implement the tab content** in `lib/views/franchise_page.dart`
5. **Add data providers** if needed
6. **Update documentation**

### For Franchise Tab Implementation

1. **Add tab button** in `_buildTabContent()` switch statement
2. **Implement tab content method** (e.g., `_buildNewsTab()`)
3. **Add data providers** for the tab
4. **Update routing** if needed
5. **Add to documentation**

### Best Practices

1. **Consistent UI**: Follow existing design patterns
2. **Real-time Data**: Use Supabase for real-time updates
3. **Error Handling**: Implement proper error states
4. **Loading States**: Show loading indicators
5. **Responsive Design**: Support mobile and desktop
6. **Accessibility**: Follow accessibility guidelines

## Future Development Roadmap

### Phase 1: Core Functionality
- [ ] Implement News tab with announcements
- [ ] Implement Games tab with schedule
- [ ] Implement Standings tab with rankings

### Phase 2: Advanced Features
- [ ] Implement Statistics tab with analytics
- [ ] Implement Trades tab with trade system
- [ ] Implement Awards tab with recognition system

### Phase 3: Management Features
- [ ] Implement Teams tab with team management
- [ ] Implement Transactions tab with financial tracking
- [ ] Implement Draft tab with draft system

### Phase 4: Administrative Features
- [ ] Implement Admin tab with user management
- [ ] Implement Export tab with data export
- [ ] Implement Rules tab with rule management

## Database Schema References

### Key Tables

1. **franchises**: Franchise information
2. **franchise_channels**: Channel management
3. **versioned_uploads**: Player data uploads
4. **user_profiles**: User information
5. **servers**: Server information

### Relationships

- Franchises belong to Servers
- Channels belong to Franchises
- Players are associated with Franchises
- Users can belong to multiple Servers

## Security Considerations

1. **Row Level Security (RLS)**: All tables have RLS enabled
2. **Authentication**: Most features require authentication
3. **Authorization**: Server membership required for operations
4. **Data Validation**: Input validation on all forms
5. **Error Handling**: Secure error messages

This documentation should provide CURSOR with a comprehensive understanding of the application structure for future development and routing implementation.
