import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../server/data/server_providers.dart';
import '../../server/presentation/widgets/server_icon_widget.dart';

class HomeWelcomePage extends ConsumerWidget {
  const HomeWelcomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Placeholder mentions data
    final mentions = [
      'You were mentioned by @coach in #general',
      'You were mentioned by @admin in #announcements',
      'You were mentioned by @teammate in #trades',
    ];
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText('Welcome to Franchise Player', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            SelectableText('Your Madden franchise management hub', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 32),
            SelectableText('Quick Navigation', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 2,
                    child: InkWell(
                      onTap: () {
                        context.go('/franchise-finder');
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Column(
                          children: [
                            const Icon(Icons.sports_football, size: 40),
                            const SizedBox(height: 12),
                            Text('Franchise Finder', style: Theme.of(context).textTheme.titleMedium),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 2,
                    child: InkWell(
                      onTap: () {},
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Column(
                          children: [
                            const Icon(Icons.people, size: 40),
                            const SizedBox(height: 12),
                            Text('1v1 Finder', style: Theme.of(context).textTheme.titleMedium),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text('Recent Servers', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Consumer(
              builder: (context, ref, child) {
                final recentServersAsync = ref.watch(recentServersProvider);
                
                return recentServersAsync.when(
                  data: (recentServers) {
                    if (recentServers.isEmpty) {
                      return const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'No recent servers. Create or join a server to get started!',
                            style: TextStyle(fontStyle: FontStyle.italic),
                          ),
                        ),
                      );
                    }
                    
                    final serversToShow = recentServers.take(2).toList();
                    return Row(
                      children: serversToShow.asMap().entries.map((entry) {
                        final index = entry.key;
                        final server = entry.value;
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: index < serversToShow.length - 1 ? 12.0 : 0.0,
                            ),
                            child: Card(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 2,
                              child: ListTile(
                                leading: ServerIconWidget(
                                  iconUrl: server['icon_url'],
                                  emojiIcon: server['icon'],
                                  color: server['color'],
                                  size: 40,
                                  showBorder: false,
                                ),
                                title: Text(server['name'] ?? 'Unknown Server'),
                                subtitle: Text('Last accessed: ${_formatLastAccessed(server['last_accessed_at'])}'),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () {
                                  context.go('/server/${server['id']}');
                                },
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const Row(
                    children: [
                      Expanded(child: Card(child: ListTile(title: Text('Loading recent servers...')))),
                      SizedBox(width: 24),
                      Expanded(child: Card(child: ListTile(title: Text('Loading...')))),
                    ],
                  ),
                  error: (error, stack) => Card(
                    child: ListTile(
                      title: const Text('Error loading recent servers'),
                      subtitle: Text('$error'),
                      leading: const Icon(Icons.error, color: Colors.red),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            // Mentions ticker section
            Text('Latest Mentions', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: mentions.length,
                separatorBuilder: (context, index) => const SizedBox(width: 24),
                itemBuilder: (context, index) => Chip(
                  label: Text(mentions[index]),
                  backgroundColor: Colors.yellow[100],
                  labelStyle: const TextStyle(color: Colors.black87),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatLastAccessed(String? lastAccessedAt) {
    if (lastAccessedAt == null) return 'Never';
    
    try {
      final dateTime = DateTime.parse(lastAccessedAt);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inDays > 0) {
        return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Unknown';
    }
  }
} 