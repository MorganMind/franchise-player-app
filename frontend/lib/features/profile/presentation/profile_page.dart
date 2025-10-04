import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/auth_providers.dart';
import '../../../core/theme/app_theme.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Dummy user data
    final userStats = {
      'games_played': 156,
      'games_won': 89,
      'win_percentage': 57.1,
      'bowls_won': 3,
      'awards': 12,
      'seasons_completed': 8,
    };

    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // Server sidebar (Discord-style layout, soft styling)
          Container(
            width: 72,
            color: const Color(0xFFF8F9FA),
            child: Column(
              children: [
                // Home button
                Container(
                  width: 48,
                  height: 48,
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => context.go('/home'),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            'web/assets/images/logo.png',
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Separator
                Container(
                  width: 32,
                  height: 1,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9ECEF),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ],
            ),
          ),
          // Main content area
          Expanded(
            child: Container(
              color: Colors.white,
              child: Column(
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
                        const Icon(Icons.arrow_back, color: Colors.black, size: 24),
                        const SizedBox(width: 12),
                        const Text(
                          'Profile',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const Spacer(),
                        // Theme toggle
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
                        // User avatar and logout
                        SizedBox(
                          width: 36,
                          height: 36,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: () => context.go('/profile'),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: const Center(
                                  child: Text(
                                    'U',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
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
                                    SnackBar(content: SelectableText('Logout failed: $e')),
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
                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // User Info Section
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFE9ECEF), width: 1),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(40),
                                  ),
                                  child: const Center(
                                    child: SelectableText(
                                      'U',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 32,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 24),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SelectableText(
                                        'User',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 24,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      SelectableText(
                                        'user@example.com',
                                        style: TextStyle(
                                          color: Color(0xFF6C757D),
                                          fontSize: 16,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      SelectableText(
                                        'Member since 2023',
                                        style: TextStyle(
                                          color: Color(0xFF6C757D),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Color(0xFF6C757D)),
                                  onPressed: () {
                                    // TODO: Edit profile
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: SelectableText('Edit Profile - Coming Soon!')),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          // Statistics Section
                          const Text(
                            'Statistics',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 3,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.5,
                            children: [
                              _buildStatCard('Games Played', '${userStats['games_played']}', Icons.sports_football),
                              _buildStatCard('Games Won', '${userStats['games_won']}', Icons.emoji_events),
                              _buildStatCard('Win %', '${userStats['win_percentage']}%', Icons.trending_up),
                              _buildStatCard('Bowls Won', '${userStats['bowls_won']}', Icons.workspace_premium),
                              _buildStatCard('Awards', '${userStats['awards']}', Icons.star),
                              _buildStatCard('Seasons', '${userStats['seasons_completed']}', Icons.calendar_today),
                            ],
                          ),
                          const SizedBox(height: 32),
                          // Settings Section
                          const Text(
                            'Settings',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFE9ECEF), width: 1),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                _buildSettingTile(
                                  'Account Settings',
                                  'Manage your account preferences',
                                  Icons.person,
                                  () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: SelectableText('Account Settings - Coming Soon!')),
                                    );
                                  },
                                ),
                                const Divider(height: 1, color: Color(0xFFE9ECEF)),
                                _buildSettingTile(
                                  'Notifications',
                                  'Configure notification preferences',
                                  Icons.notifications,
                                  () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: SelectableText('Notifications - Coming Soon!')),
                                    );
                                  },
                                ),
                                const Divider(height: 1, color: Color(0xFFE9ECEF)),
                                _buildSettingTile(
                                  'Privacy',
                                  'Manage your privacy settings',
                                  Icons.security,
                                  () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: SelectableText('Privacy Settings - Coming Soon!')),
                                    );
                                  },
                                ),
                                const Divider(height: 1, color: Color(0xFFE9ECEF)),
                                _buildSettingTile(
                                  'Help & Support',
                                  'Get help and contact support',
                                  Icons.help,
                                  () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: SelectableText('Help & Support - Coming Soon!')),
                                    );
                                  },
                                ),
                                const Divider(height: 1, color: Color(0xFFE9ECEF)),
                                _buildSettingTile(
                                  'About',
                                  'App version and information',
                                  Icons.info,
                                  () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: SelectableText('About - Coming Soon!')),
                                    );
                                  },
                                ),
                              ],
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
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9ECEF), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.black, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF6C757D),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.black, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF6C757D),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Color(0xFF6C757D), size: 16),
            ],
          ),
        ),
      ),
    );
  }
} 