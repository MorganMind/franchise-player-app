# Franchise Player App - Routing Documentation

## Overview

This app uses **Navigator 2.0** with `go_router` for declarative routing. All URLs are path-based (no hash fragments) and support deep linking, browser back/forward, and hard refresh.

## Current Routes

### Authentication Routes
- `/` - Home page (redirects to login if not authenticated)
- `/login` - Login page

### DM (Direct Message) Routes
- `/dm/:threadId` - Direct message thread with specific user

### Server Routes
- `/server/:serverId` - Server overview page
- `/server/:serverId/channel/:channelId` - Specific channel within a server

### Franchise Routes
- `/franchise/:franchiseId` - Franchise overview page
- `/franchise/:franchiseId/:channelId` - Specific channel within a franchise
- `/franchise/:franchiseId/player/:playerId` - Player profile within a franchise
- `/server/:serverId/franchise/:franchiseId/player/:playerId` - Player profile within a franchise in a specific server

### Management Routes
- `/franchise-management` - Franchise management dashboard

### Legacy Routes (for backward compatibility)
- `/player/:playerId` - Standalone player profile page

### Error Routes
- `*` - 404 Not Found page (handles all unknown routes)

## URL Structure

### Server URLs
Server URLs support both ID-based and name-based routing:
- `/server/587c945e-048c-40ac-aa15-6b99dd61d4b7` (ID-based)
- `/server/madden-league` (name-based)

### Franchise URLs
Franchise URLs support both ID-based and name-based routing:
- `/franchise/123e4567-e89b-12d3-a456-426614174000` (ID-based)
- `/franchise/my-franchise-name` (name-based)

## Navigation Methods

### Using context.go()
```dart
// Navigate to a route
context.go('/franchise/my-franchise');

// Navigate with parameters
context.go('/franchise/my-franchise/player/123');

// Navigate to home
context.go('/');
```

### Using context.push()
```dart
// Push a new route on top of the stack
context.push('/franchise/new-franchise');
```

### Using context.pop()
```dart
// Go back to previous route
context.pop();
```

## Adding New Routes

### 1. Add the route to the router configuration in `lib/app.dart`:

```dart
GoRoute(
  path: '/new-feature/:id',
  name: 'new-feature', // Optional: for named routes
  builder: (context, state) {
    final id = state.pathParameters['id']!;
    return NewFeaturePage(id: id);
  },
),
```

### 2. Use the route in your navigation:

```dart
// Using path
context.go('/new-feature/123');

// Using named route (if you added a name)
context.goNamed('new-feature', pathParameters: {'id': '123'});
```

### 3. Handle authentication if needed:

Add your route to the redirect logic in `lib/app.dart`:

```dart
redirect: (context, state) {
  final isNewFeatureRoute = state.uri.path.startsWith('/new-feature/');
  
  // Allow public access to new feature routes
  if (isNewFeatureRoute) return null;
  
  // Require authentication for other routes
  if (user == null && !isLoggingIn) return '/login';
  // ... rest of redirect logic
}
```

## Route Parameters

### Path Parameters
Extract path parameters from the route state:

```dart
builder: (context, state) {
  final id = state.pathParameters['id']!;
  final category = state.pathParameters['category'];
  return MyPage(id: id, category: category);
}
```

### Query Parameters
Extract query parameters from the URL:

```dart
builder: (context, state) {
  final search = state.uri.queryParameters['search'];
  final page = state.uri.queryParameters['page'];
  return SearchPage(search: search, page: page);
}
```

## Error Handling

The app includes a custom 404 page (`NotFoundPage`) that:
- Shows a user-friendly error message
- Provides a "Go Home" button
- Provides a "Go Back" button
- Uses the app's theme and styling

## Web Deployment

For web deployment, ensure your hosting configuration includes SPA rewrites:

### Firebase Hosting
```json
{
  "hosting": {
    "public": "build/web",
    "rewrites": [{ "source": "**", "destination": "/index.html" }]
  }
}
```

### Vercel
```json
{
  "rewrites": [{ "source": "/(.*)", "destination": "/index.html" }]
}
```

### Nginx
```nginx
location / {
  try_files $uri $uri/ /index.html;
}
```

## Testing Routes

### Test deep linking:
1. Navigate to a route in the app
2. Copy the URL from the browser
3. Open a new tab and paste the URL
4. Verify the page loads correctly

### Test browser navigation:
1. Navigate through several pages
2. Use browser back/forward buttons
3. Verify the app state updates correctly

### Test 404 handling:
1. Navigate to a non-existent route (e.g., `/nonexistent`)
2. Verify the 404 page appears
3. Test the "Go Home" and "Go Back" buttons

## Migration Notes

This app was migrated from Navigator 1.0 to Navigator 2.0 with go_router. All navigation calls use `context.go()` instead of `Navigator.push()` for route changes.

## Files Modified During Migration

- `lib/main.dart` - Added URL strategy setup
- `lib/app.dart` - Added 404 error handling
- `lib/views/not_found_page.dart` - Created 404 page
- `pubspec.yaml` - Added flutter_web_plugins dependency
- `web/index.html` - Already had correct base href

## Navigation Calls Updated

All navigation calls throughout the app were already using `context.go()` and `context.push()` correctly. No additional updates were needed.
