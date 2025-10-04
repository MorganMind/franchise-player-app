# Valuation System

This module provides a comprehensive player valuation system for your Franchise Player app, including both backend computation and frontend UI components.

## 🎯 Overview

The valuation system calculates player values based on:
- **OVR (Overall Rating)** - Primary value driver
- **Age** - With configurable curves and cliffs
- **Position** - Position-specific multipliers
- **Development Trait** - Star/Superstar/X-Factor bonuses
- **Youth Buffer** - Development potential for younger players

## 🏗️ Architecture

### Backend (Supabase Edge Function)
- **Endpoint**: `/functions/v1/valuation`
- **Database**: `valuation_settings` table with JSONB configuration
- **Algorithm**: JJ Chart-based draft pick mapping

### Frontend (Flutter)
- **Settings UI**: `ValuationSettingsPage` - Full configuration interface
- **Service**: `ValuationService` - API communication
- **Widget**: `PlayerValuationWidget` - Display player values

## 🚀 Usage

### 1. Access Valuation Settings

Navigate to the valuation settings page:

```dart
// Via router
context.go('/valuation-settings');

// Or directly
Navigator.push(context, MaterialPageRoute(
  builder: (_) => ValuationSettingsPage(
    baseUrl: 'https://your-project.supabase.co/functions/v1/valuation',
    franchiseId: 'optional-franchise-id',
  ),
));
```

### 2. Use the Valuation Service

```dart
final service = ValuationService(
  baseUrl: 'https://your-project.supabase.co/functions/v1/valuation',
  franchiseId: 'optional-franchise-id',
);

// Get current settings
final settings = await service.getSettings();

// Update settings
await service.updateSettings({
  'pos_spread_scalar': 2.0,
  'age': {'gain': 5.0},
});

// Compute player value
final result = await service.computeValue(
  ovr: 85,
  age: 24,
  position: 'QB',
  devTrait: 'Star',
);
```

### 3. Display Player Valuations

Use the `PlayerValuationWidget` in your player cards:

```dart
PlayerValuationWidget(
  ovr: player.overall,
  age: player.age,
  position: player.position,
  devTrait: player.devTrait,
  franchiseId: franchiseId,
)
```

## ⚙️ Configuration

### OVR Curve & Position Spread
- **QB @ 60 OVR**: Base value for 60 OVR QB
- **QB @ 99 OVR**: Base value for 99 OVR QB  
- **Position Spread Scalar**: Multiplier for position differences

### Age Model
- **Base Schedule**: Per-age multipliers (20-40)
- **Age Gain**: Intensity of age effects
- **Cliff Multipliers**: Penalties for 25-27 and 28+ ages
- **Floor Age/Value**: Minimum values for older players

### Youth Buffer
- **Age Bands**: Development potential by age (20-28)
- **Dmax per Position**: Maximum youth bonus per position

### Dev Trait
- **Trait Scores**: Value multipliers for Normal/Star/Superstar/X-Factor
- **Dcap per Position**: Maximum dev trait bonus per position
- **Weights**: XP vs Abilities weighting per position

## 📊 API Endpoints

### GET /settings
Get current valuation settings
```json
{
  "ok": true,
  "settings": { /* full settings object */ }
}
```

### PATCH /settings
Update valuation settings
```json
{
  "franchise_id": "optional",
  "settings": { /* partial settings object */ }
}
```

### POST /compute
Compute player value
```json
{
  "ovr": 85,
  "age": 24,
  "pos": "QB",
  "dev": "Star",
  "franchise_id": "optional"
}
```

Response:
```json
{
  "ok": true,
  "value": 1250.5,
  "nearest_pick": 15,
  "round": 1,
  "pick_in_round": 15,
  "nearest_points": 1250,
  "details": {
    "qb_base_value": 3000,
    "base_after_dividing_qb_mult": 1200,
    "multipliers": {
      "pos": 2.5,
      "age": 1.8,
      "youth": 1.2,
      "dev": 1.64
    }
  }
}
```

## 🎨 UI Components

### ValuationSettingsPage
- **Full-screen settings interface**
- **Real-time preview with sliders**
- **Save/load functionality**
- **Franchise-specific or global settings**

### PlayerValuationWidget
- **Compact valuation display**
- **Auto-updates on player changes**
- **Error handling and loading states**
- **Multiplier breakdown**

## 🔧 Customization

### Adding New Positions
1. Update position lists in the UI components
2. Add position-specific settings in the database
3. Configure Dmax and Dcap values

### Modifying Age Curves
1. Use the age base schedule editor
2. Adjust cliff multipliers
3. Set floor age and values

### Custom Dev Traits
1. Add new trait types to the settings
2. Update the UI dropdown options
3. Configure trait scores

## 🚨 Error Handling

The system includes comprehensive error handling:
- **Network errors**: Retry mechanisms and user feedback
- **Invalid inputs**: Validation and helpful error messages
- **Missing settings**: Fallback to default values
- **API failures**: Graceful degradation

## 📱 Integration Examples

### In Player Cards
```dart
Card(
  child: Column(
    children: [
      PlayerHeader(player: player),
      PlayerValuationWidget(
        ovr: player.overall,
        age: player.age,
        position: player.position,
        devTrait: player.devTrait,
      ),
    ],
  ),
)
```

### In Trade Screens
```dart
// Show both players' values
Row(
  children: [
    Expanded(
      child: PlayerValuationWidget(
        ovr: player1.overall,
        age: player1.age,
        position: player1.position,
        devTrait: player1.devTrait,
      ),
    ),
    Expanded(
      child: PlayerValuationWidget(
        ovr: player2.overall,
        age: player2.age,
        position: player2.position,
        devTrait: player2.devTrait,
      ),
    ),
  ],
)
```

### In Draft Boards
```dart
// Show expected draft position
PlayerValuationWidget(
  ovr: prospect.overall,
  age: prospect.age,
  position: prospect.position,
  devTrait: prospect.devTrait,
)
```

## 🔄 Future Enhancements

- **Historical tracking**: Value changes over time
- **Trade analysis**: Value comparisons and recommendations
- **Draft predictions**: Expected draft positions
- **Team building**: Salary cap integration
- **Analytics**: Value trends and insights

## 🐛 Troubleshooting

### Common Issues

**Settings not loading**
- Check Supabase connection
- Verify function URL is correct
- Ensure database migration was applied

**Computation errors**
- Validate input parameters (OVR 60-99, Age 20-40)
- Check position and dev trait values
- Verify settings are properly configured

**UI not updating**
- Ensure setState() is called after changes
- Check for proper widget lifecycle management
- Verify service calls are awaited

### Debug Mode
Enable debug logging in the ValuationService to see detailed API calls and responses.
