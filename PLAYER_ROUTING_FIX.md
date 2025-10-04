# Player Routing Fix Documentation

## Issue Description

When clicking on players in the franchise pages, users were being redirected to "Unknown Franchise" instead of the correct franchise. This was happening because the navigation URLs were using internal franchise IDs (like "franchise-server-1") instead of URL-safe franchise names (like "madden-league-alpha").

## Root Cause

The problem was in the URL generation for player navigation. The code was using internal franchise IDs directly in the URL, but the routing system expects URL-safe franchise names.

Additionally, there was a mismatch between the franchise ID formats being used:
- The `_getFranchiseIdFromName` function was returning old hardcoded IDs like `franchise-server-1`
- But the actual franchise IDs being generated were like `franchise-660e8400-e29b-41d4-a716-446655440001`
- This caused the `_getFranchiseDisplayName()` function to return "Unknown Franchise"

### Before (Broken):
```dart
// Using internal ID directly
context.go('/franchise/${currentFranchiseId}/player/${player.id}');
// Results in: /franchise/franchise-server-1/player/123
```

### After (Fixed):
```dart
// Convert to URL-safe name first
final franchiseName = _getFranchiseName();
final urlSafeName = franchiseName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9-]'), '-');
context.go('/franchise/$urlSafeName/player/${player.id}');
// Results in: /franchise/madden-league-alpha/player/123
```

## Files Fixed

### 1. `frontend/lib/app.dart`
**Issue**: Franchise ID mapping mismatch between URL parsing and display functions
**Fix**: Updated both `_getFranchiseIdFromName` and `_getFranchiseDisplayName` to use consistent franchise IDs

```dart
// Updated _getFranchiseIdFromName to return correct franchise IDs
case 'madden league alpha':
  return 'franchise-660e8400-e29b-41d4-a716-446655440001';

// Updated _getFranchiseDisplayName to handle both old and new franchise ID formats
case 'franchise-660e8400-e29b-41d4-a716-446655440001':
  return 'Madden League Alpha';
```

### 2. `frontend/lib/views/franchise_page.dart`
**Issue**: Line 282 was using `currentFranchiseId` directly in URL
**Fix**: Added `_getFranchiseUrlSafeName()` helper function and updated navigation

```dart
// Added helper function
String _getFranchiseUrlSafeName() {
  final franchiseName = _getFranchiseName();
  return franchiseName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9-]'), '-');
}

// Updated navigation
onPressed: () => context.go('/franchise/${_getFranchiseUrlSafeName()}/player/${player.id}'),
```

### 2. `frontend/lib/views/rosters_home.dart`
**Issue**: Line 44 was using `widget.franchiseId` directly in URL
**Fix**: Added URL-safe name conversion

```dart
void _openPlayerProfile(Player player) {
  if (widget.franchiseId != null) {
    final franchiseName = _getFranchiseName();
    final urlSafeName = franchiseName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9-]'), '-');
    context.go('/franchise/$urlSafeName/player/${player.id}', extra: player);
  } else {
    context.go('/player/${player.id}', extra: player);
  }
}
```

### 3. `frontend/lib/views/public_franchise_page.dart`
**Issue**: Lines 316 and 486 were using `widget.franchiseId` directly in URLs
**Fix**: Added URL-safe name conversion for both instances

```dart
// Fixed player card navigation
onTap: () {
  final franchiseName = _getFranchiseName();
  final urlSafeName = franchiseName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9-]'), '-');
  context.go('/franchise/$urlSafeName/player/${player.id}');
},

// Fixed player list navigation
onTap: () {
  final franchiseName = _getFranchiseName();
  final urlSafeName = franchiseName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9-]'), '-');
  context.go('/franchise/$urlSafeName/player/${player['name']}');
},
```

## URL Conversion Pattern

### Internal ID to URL-Safe Name Mapping

| Internal ID | Franchise Name | URL-Safe Name |
|-------------|----------------|---------------|
| `franchise-660e8400-e29b-41d4-a716-446655440001` | `Madden League Alpha` | `madden-league-alpha` |
| `franchise-660e8400-e29b-41d4-a716-446655440002` | `Casual Gaming League` | `casual-gaming-league` |
| `franchise-660e8400-e29b-41d4-a716-446655440003` | `Support Server League` | `support-server-league` |

### Conversion Function Pattern

```dart
String _getFranchiseUrlSafeName() {
  final franchiseName = _getFranchiseName();
  return franchiseName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9-]'), '-');
}
```

## Routing Resolution

The `_getFranchiseIdFromName()` function in `app.dart` handles the reverse conversion:

```dart
static String _getFranchiseIdFromName(String franchiseNameOrId) {
  if (franchiseNameOrId.contains('-') && franchiseNameOrId.length > 20) {
    return franchiseNameOrId; // Already an ID
  }
  
  final readableName = franchiseNameOrId.replaceAll('-', ' ');
  
  switch (readableName.toLowerCase()) {
    case 'madden league alpha':
      return 'franchise-660e8400-e29b-41d4-a716-446655440001';
    case 'casual gaming league':
      return 'franchise-660e8400-e29b-41d4-a716-446655440002';
    case 'support server league':
      return 'franchise-660e8400-e29b-41d4-a716-446655440003';
    default:
      return franchiseNameOrId;
  }
}
```

## Testing the Fix

1. **Navigate to a franchise page**
2. **Click on any player card**
3. **Verify the URL shows the correct franchise name** (e.g., `/franchise/madden-league-alpha/player/123`)
4. **Verify the player profile loads correctly**

## Prevention

To prevent this issue in the future:

1. **Always use URL-safe names** in navigation URLs
2. **Never use internal IDs directly** in URLs
3. **Create helper functions** for URL-safe name conversion
4. **Test navigation** after implementing new features
5. **Follow the established pattern** of ID ↔ Name conversion

## Related Documentation

- See `ROUTING_QUICK_REFERENCE.md` for general routing patterns
- See `FRANCHISE_TABS_DOCUMENTATION.md` for franchise-specific routing
- See `FRANCHISE_MANAGEMENT.md` for franchise management features

This fix ensures that player navigation works correctly across all franchise contexts and maintains consistency with the URL structure.
