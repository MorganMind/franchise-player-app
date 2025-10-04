import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/discord_service.dart';
import '../../../providers/user_profile_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserAsync = ref.watch(currentUserProfileProvider);
    final supabase = Supabase.instance.client;
    final authUser = supabase.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: currentUserAsync.when(
        data: (userProfile) {
          final isDiscordUser = DiscordService.isDiscordUser(authUser);
          final discordInfo = DiscordService.getDiscordUserInfo(authUser);
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Header
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: userProfile?.avatarUrl != null 
                            ? NetworkImage(userProfile!.avatarUrl!) 
                            : null,
                        child: userProfile?.avatarUrl == null 
                            ? Text(
                                userProfile?.displayName[0].toUpperCase() ?? 'U',
                                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                              )
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        userProfile?.displayName ?? 'Unknown User',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (userProfile?.username != null)
                        Text(
                          '@${userProfile!.username}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // User Information Section
                _buildSection(
                  context,
                  'Account Information',
                  [
                    _buildInfoRow('Email', userProfile?.email ?? 'Not provided'),
                    _buildInfoRow('User ID', userProfile?.id ?? 'Not available'),
                    _buildInfoRow('Member Since', _formatDate(userProfile?.createdAt)),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Discord Information Section
                if (isDiscordUser || userProfile?.discordId != null)
                  _buildSection(
                    context,
                    'Discord Account',
                    [
                      if (discordInfo?['discord_id'] != null)
                        _buildInfoRow('Discord ID', discordInfo!['discord_id']),
                      if (discordInfo?['username'] != null)
                        _buildInfoRow('Discord Username', discordInfo!['username']),
                      if (discordInfo?['full_name'] != null)
                        _buildInfoRow('Discord Name', discordInfo!['full_name']),
                      _buildInfoRow('Linked', isDiscordUser ? 'Yes' : 'No'),
                    ],
                    icon: Icons.discord,
                    iconColor: const Color(0xFF5865F2),
                  ),
                
                const SizedBox(height: 24),
                
                // Actions Section
                _buildSection(
                  context,
                  'Actions',
                  [],
                  customContent: Column(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          // TODO: Implement edit profile functionality
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Edit profile coming soon!')),
                          );
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit Profile'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (!isDiscordUser)
                        OutlinedButton.icon(
                          onPressed: () async {
                            try {
                              await supabase.auth.signInWithOAuth(
                                OAuthProvider.discord,
                                authScreenLaunchMode: LaunchMode.externalApplication,
                              );
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to link Discord: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.discord, color: Color(0xFF5865F2)),
                          label: const Text('Link Discord Account'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                            side: const BorderSide(color: Color(0xFF5865F2)),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading profile: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(currentUserProfileProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<Widget> children, {
    IconData? icon,
    Color? iconColor,
    Widget? customContent,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: iconColor ?? Colors.grey[600], size: 20),
                  const SizedBox(width: 8),
                ],
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (customContent != null)
              customContent
            else
              ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Unknown';
    try {
      final dateTime = date is String ? DateTime.parse(date) : date as DateTime;
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return 'Unknown';
    }
  }
} 