// --- FLOATING NAVIGATION FIX APPLIED ---
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/auth_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../server/presentation/widgets/responsive_server_nav.dart';
import '../../server/presentation/widgets/channel_sidebar.dart';

class HomePage extends ConsumerWidget {
  final Widget child;
  const HomePage({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final state = GoRouterState.of(context);
    // Check if the current route is a server route
    final uri = Uri.parse(state.uri.toString());
    final segments = uri.pathSegments;
    String? serverId;
    if (segments.length >= 3 && segments[0] == 'home' && segments[1] == 'server') {
      serverId = segments[2];
    }
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Color(0xFFE9ECEF), width: 1),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  height: 40,
                  child: InkWell(
                    onTap: () => context.go('/home'),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'assets/logo.png',
                        height: 40,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    ref.watch(appThemeProvider) == ThemeMode.dark 
                        ? Icons.light_mode 
                        : Icons.dark_mode,
                    color: const Color(0xFF6C757D),
                    size: 20,
                  ),
                  onPressed: () {
                    final currentTheme = ref.read(appThemeProvider);
                    ref.read(appThemeProvider.notifier).state = 
                        currentTheme == ThemeMode.dark 
                            ? ThemeMode.light 
                            : ThemeMode.dark;
                  },
                  tooltip: 'Toggle theme',
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Color(0xFF6C757D), size: 20),
                  onSelected: (value) async {
                    if (value == 'logout') {
                      try {
                        await ref.read(authProvider.notifier).signOut();
                        if (context.mounted) {
                          context.go('/login');
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Logout failed: $e')),
                          );
                        }
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout, color: Color(0xFF6C757D), size: 18),
                          SizedBox(width: 8),
                          Text('Logout'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Main content area with nav
          Expanded(
            child: Row(
              children: [
                if (!isMobile) ...[
                  ResponsiveServerNav(
                    onDmSelected: () => context.go('/home/dm'),
                    onServerSelected: (serverId) => context.go('/server/$serverId'),
                    onToggleTheme: () {
                      final currentTheme = ref.read(appThemeProvider);
                      ref.read(appThemeProvider.notifier).state = 
                          currentTheme == ThemeMode.dark 
                              ? ThemeMode.light 
                              : ThemeMode.dark;
                    },
                    isDark: ref.watch(appThemeProvider) == ThemeMode.dark,
                  ),
                  if (serverId != null)
                    ChannelSidebar(
                      serverId: serverId,
                      onSelect: (franchiseId, channelId, subcategoryId) {
                        // Build the new route based on selection
                        String route = '/server/$serverId';
                        if (franchiseId != null) {
                          route += '/franchise/$franchiseId';
                          if (channelId != null) {
                            route += '/channel/$channelId';
                          }
                        } else if (channelId != null) {
                          route += '/channel/$channelId';
                        }
                        if (subcategoryId != null) {
                          route += '?subcategory=$subcategoryId';
                        }
                        context.go(route);
                      },
                    ),
                ],
                // Render the child route here
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 