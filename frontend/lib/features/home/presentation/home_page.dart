// --- FLOATING NAVIGATION FIX APPLIED ---
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/auth_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../server/data/server_providers.dart';
import '../../server/presentation/widgets/responsive_server_nav.dart';

class HomePage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servers = ref.watch(serversProvider);
    final currentServerId = ref.watch(currentServerIdProvider);
    final navigationState = ref.watch(serverNavigationProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header - spans full width
          Container(
            height: 64,
            padding: EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Color(0xFFE9ECEF), width: 1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 120,
                  height: 40,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/logo.png',
                      width: 120,
                      height: 40,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Spacer(),
                IconButton(
                  icon: Icon(
                    ref.watch(appThemeProvider) == ThemeMode.dark 
                        ? Icons.light_mode 
                        : Icons.dark_mode,
                    color: Color(0xFF6C757D),
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
                  icon: Icon(Icons.more_vert, color: Color(0xFF6C757D), size: 20),
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
                    PopupMenuItem(
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
                // Server navigation (desktop only)
                if (!isMobile) ResponsiveServerNav(),
                // Content
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome to Franchise Player',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -1.0,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Your Madden franchise management hub',
                          style: TextStyle(
                            color: Color(0xFF6C757D),
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        SizedBox(height: 48),
                        Text(
                          'Quick Navigation',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(height: 24),
                        Row(
                          children: [
                            // Franchise Finder
                            Expanded(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Franchise Finder - Coming Soon!')),
                                    );
                                  },
                                  child: Container(
                                    height: 120,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Color(0xFFE9ECEF),
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.08),
                                          blurRadius: 16,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.sports_football,
                                          color: Colors.black,
                                          size: 32,
                                        ),
                                        SizedBox(height: 12),
                                        Text(
                                          'Franchise Finder',
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: -0.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 24),
                            // 1v1 Finder
                            Expanded(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('1v1 Finder - Coming Soon!')),
                                    );
                                  },
                                  child: Container(
                                    height: 120,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Color(0xFFE9ECEF),
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.08),
                                          blurRadius: 16,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.people,
                                          color: Colors.black,
                                          size: 32,
                                        ),
                                        SizedBox(height: 12),
                                        Text(
                                          '1v1 Finder',
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: -0.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 24),
                            // Coach Finder
                            Expanded(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Coach Finder - Coming Soon!')),
                                    );
                                  },
                                  child: Container(
                                    height: 120,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Color(0xFFE9ECEF),
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.08),
                                          blurRadius: 16,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            color: Colors.black,
                                            borderRadius: BorderRadius.circular(24),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(24),
                                            child: Image.asset(
                                              'web/assets/images/tdbarrett.png',
                                              width: 48,
                                              height: 48,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) => Icon(
                                                Icons.person,
                                                color: Colors.white,
                                                size: 24,
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: 12),
                                        Text(
                                          'Coach Finder',
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: -0.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 48),
                        Text(
                          'Recent Servers',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(height: 24),
                        Row(
                          children: servers.take(3).map((server) {
                            final isActive = currentServerId == server['id'];
                            return Expanded(
                              child: Container(
                                margin: EdgeInsets.only(right: servers.indexOf(server) < 2 ? 24 : 0),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(20),
                                    onTap: () async {
                                      ref.read(currentServerIdProvider.notifier).state = server['id'];
                                      await ref.read(serverNavigationProvider.notifier).switchServer(server['id']!);
                                      if (context.mounted) {
                                        context.go('/home/server/${server['id']}');
                                      }
                                    },
                                    child: Container(
                                      height: 100,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: isActive 
                                              ? Color(int.parse(server['color']!.substring(1), radix: 16) + 0xFF000000)
                                              : Color(0xFFE9ECEF),
                                          width: isActive ? 2 : 1,
                                        ),
                                        boxShadow: [
                                          if (isActive)
                                            BoxShadow(
                                              color: Color(int.parse(server['color']!.substring(1), radix: 16) + 0xFF000000).withOpacity(0.2),
                                              blurRadius: 12,
                                              spreadRadius: 1,
                                            ),
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.08),
                                            blurRadius: 16,
                                            offset: Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 60,
                                            height: 60,
                                            margin: EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: Color(int.parse(server['color']!.substring(1), radix: 16) + 0xFF000000),
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            child: Center(
                                              child: Text(
                                                server['icon']!,
                                                style: TextStyle(fontSize: 24),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  server['name']!,
                                                  style: TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    letterSpacing: -0.3,
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                SizedBox(height: 4),
                                                Text(
                                                  'Tap to join',
                                                  style: TextStyle(
                                                    color: Color(0xFF6C757D),
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            margin: EdgeInsets.only(right: 16),
                                            child: Icon(
                                              Icons.arrow_forward_ios,
                                              color: Color(0xFF6C757D),
                                              size: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Mobile bottom navigation
          if (isMobile) ResponsiveServerNav(),
        ],
      ),
    );
  }
} 