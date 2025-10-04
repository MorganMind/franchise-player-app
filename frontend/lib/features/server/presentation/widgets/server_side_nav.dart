import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/server_providers.dart';
import 'create_server_dialog.dart';
import 'server_icon_widget.dart';
import '../../data/server_repository.dart';

class ServerSideNav extends ConsumerStatefulWidget {
  final Function() onDmSelected;
  final Function(String) onServerSelected;
  final VoidCallback onToggleTheme;
  final bool isDark;
  final double iconSize;

  const ServerSideNav({
    Key? key,
    required this.onDmSelected,
    required this.onServerSelected,
    required this.onToggleTheme,
    required this.isDark,
    this.iconSize = 48,
  }) : super(key: key);

  @override
  ConsumerState<ServerSideNav> createState() => _ServerSideNavState();
}

class _ServerSideNavState extends ConsumerState<ServerSideNav> {
  String? hoveredServerId;

  @override
  Widget build(BuildContext context) {
    final serversAsync = ref.watch(serversProvider);
    final currentServerId = ref.watch(currentServerIdProvider);

    return Container(
      width: 80,
      color: const Color(0xFFF8F9FA),
      child: Column(
        children: [
          // DM button
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Center(
              child: Container(
                width: widget.iconSize,
                height: widget.iconSize,
                child: IconButton(
                  icon: const Icon(Icons.chat_bubble_outline),
                  tooltip: 'Direct Messages',
                  onPressed: widget.onDmSelected,
                  color: Colors.black,
                  iconSize: widget.iconSize * 0.6,
                ),
              ),
            ),
          ),
          // Server list
          Expanded(
            child: serversAsync.when(
              data: (servers) {
                return ReorderableListView.builder(
                  buildDefaultDragHandles: false,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: servers.length,
                  itemBuilder: (context, index) {
                    final server = servers[index];
                    final isActive = currentServerId == server['id'];
                    final isHovered = hoveredServerId == server['id'];
                    
                    return ReorderableDragStartListener(
                      index: index,
                      key: ValueKey(server['id']),
                      child: Center(
                        child: Container(
                          width: widget.iconSize,
                          height: widget.iconSize,
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Tooltip(
                            message: server['name'] ?? 'Unknown Server',
                            child: MouseRegion(
                              onEnter: (_) {
                                setState(() {
                                  hoveredServerId = server['id'];
                                });
                              },
                              onExit: (_) {
                                setState(() {
                                  hoveredServerId = null;
                                });
                              },
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(widget.iconSize / 3.5),
                                  onTap: () async {
                                    final serverId = server['id'];
                                    if (serverId != null) {
                                      // Track server access
                                      final repository = ServerRepository();
                                      await repository.trackServerAccess(serverId);
                                      
                                      // Navigate to server
                                      widget.onServerSelected(serverId);
                                    }
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(widget.iconSize / 3.5),
                                      border: Border.all(
                                        color: isActive 
                                            ? _parseColor(server['color'] ?? '#7289DA')
                                            : const Color(0xFFE9ECEF),
                                        width: isActive ? 2 : 1,
                                      ),
                                      boxShadow: [
                                        if (isActive)
                                          BoxShadow(
                                            color: _parseColor(server['color'] ?? '#7289DA').withOpacity(0.3),
                                            blurRadius: 8,
                                            spreadRadius: 1,
                                          ),
                                        if (isHovered)
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                      ],
                                    ),
                                    child: ServerIconWidget(
                                      iconUrl: server['icon_url'],
                                      emojiIcon: server['icon'],
                                      color: server['color'],
                                      size: widget.iconSize * 0.8,
                                      isActive: isActive,
                                      showBorder: false,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  onReorder: (oldIndex, newIndex) {
                    if (oldIndex < newIndex) {
                      newIndex -= 1;
                    }
                    final newServers = [...servers];
                    final movedServer = newServers.removeAt(oldIndex);
                    newServers.insert(newIndex, movedServer);

                    ref.read(serversProvider.notifier).reorderServers(newServers);

                    final serverIds = newServers.map((s) => s['id'] as String).toList();
                    ref.read(serverNavigationProvider.notifier).reorderServers(serverIds);
                  },
                );
              },
              loading: () => Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[600]!),
                ),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: widget.iconSize * 0.8,
                      color: Colors.red[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Error loading servers',
                      style: TextStyle(
                        color: Colors.red[600],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: () {
                        ref.invalidate(serversProvider);
                      },
                      child: const Text(
                        'Retry',
                        style: TextStyle(fontSize: 10),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Dark mode toggle
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: IconButton(
              icon: Icon(widget.isDark ? Icons.light_mode : Icons.dark_mode),
              tooltip: 'Toggle Light/Dark Mode',
              onPressed: widget.onToggleTheme,
              color: Colors.black,
              iconSize: widget.iconSize * 0.6,
            ),
          ),
          // Add server button
          Center(
            child: Container(
              width: widget.iconSize,
              height: widget.iconSize,
              margin: const EdgeInsets.only(bottom: 12),
              child: MouseRegion(
                onEnter: (_) {
                  setState(() {
                    hoveredServerId = 'add';
                  });
                },
                onExit: (_) {
                  setState(() {
                    hoveredServerId = null;
                  });
                },
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(widget.iconSize / 2.5),
                    onTap: () {
                      _showCreateServerDialog(context);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(widget.iconSize / 2.5),
                        border: Border.all(
                          color: const Color(0xFFE9ECEF),
                          width: 1,
                        ),
                        boxShadow: [
                          if (hoveredServerId == 'add')
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          Icons.add,
                          size: widget.iconSize * 0.5,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
  }

  void _showCreateServerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const CreateServerDialog(),
    );
  }
} 