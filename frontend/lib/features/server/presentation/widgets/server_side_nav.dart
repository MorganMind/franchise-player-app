import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/server_providers.dart';

class ServerSideNav extends ConsumerStatefulWidget {
  final double navWidth;
  final double iconSize;
  const ServerSideNav({Key? key, this.navWidth = 72.0, this.iconSize = 40.0}) : super(key: key);
  @override
  ConsumerState<ServerSideNav> createState() => _ServerSideNavState();
}

class _ServerSideNavState extends ConsumerState<ServerSideNav> with TickerProviderStateMixin {
  String? hoveredServerId;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final servers = ref.watch(serversProvider);
    final currentServerId = ref.watch(currentServerIdProvider);
    final navigationState = ref.watch(serverNavigationProvider);

    return Container(
      width: widget.navWidth,
      child: Column(
        children: [
          // Home button
          Container(
            width: widget.iconSize,
            height: widget.iconSize,
            margin: EdgeInsets.only(top: 12, bottom: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(widget.iconSize / 2.5),
                onTap: () => context.go('/dms'),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(widget.iconSize / 2.5),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.chat_bubble_outline,
                      color: Colors.white,
                      size: widget.iconSize * 0.6,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Separator
          Container(
            width: widget.iconSize * 0.8,
            height: 1,
            margin: EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Color(0xFFE9ECEF),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          // Server list
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(vertical: 8),
              itemCount: servers.length,
              itemBuilder: (context, index) {
                final server = servers[index];
                final isActive = currentServerId == server['id'];
                final isHovered = hoveredServerId == server['id'];
                
                return Center(
                  child: Container(
                    width: widget.iconSize,
                    height: widget.iconSize,
                    margin: EdgeInsets.only(bottom: 8),
                    child: MouseRegion(
                      onEnter: (_) {
                        setState(() {
                          hoveredServerId = server['id'];
                        });
                        _scaleController.forward();
                      },
                      onExit: (_) {
                        setState(() {
                          hoveredServerId = null;
                        });
                        _scaleController.reverse();
                      },
                      child: AnimatedScale(
                        scale: isHovered ? 1.1 : 1.0,
                        duration: Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(widget.iconSize / 2.5),
                            onTap: () async {
                              ref.read(currentServerIdProvider.notifier).state = server['id'];
                              await ref.read(serverNavigationProvider.notifier).switchServer(server['id']!);
                              if (context.mounted) {
                                context.go('/home/server/${server['id']}');
                              }
                            },
                            child: AnimatedContainer(
                              duration: Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(widget.iconSize / 2.5),
                                border: Border.all(
                                  color: isActive 
                                      ? Color(int.parse(server['color']!.substring(1), radix: 16) + 0xFF000000)
                                      : Color(0xFFE9ECEF),
                                  width: isActive ? 2 : 1,
                                ),
                                boxShadow: [
                                  if (isActive)
                                    BoxShadow(
                                      color: Color(int.parse(server['color']!.substring(1), radix: 16) + 0xFF000000).withOpacity(0.3),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  if (isHovered)
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  server['icon']!,
                                  style: TextStyle(fontSize: widget.iconSize * 0.5),
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
            ),
          ),
          // Add server button
          Center(
            child: Container(
              width: widget.iconSize,
              height: widget.iconSize,
              margin: EdgeInsets.only(bottom: 12),
              child: MouseRegion(
                onEnter: (_) => _scaleController.forward(),
                onExit: (_) => _scaleController.reverse(),
                child: AnimatedScale(
                  scale: hoveredServerId == 'add' ? 1.1 : 1.0,
                  duration: Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(widget.iconSize / 2.5),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Create Server - Coming Soon!')),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(widget.iconSize / 2.5),
                          border: Border.all(
                            color: Color(0xFFE9ECEF),
                            width: 1,
                          ),
                          boxShadow: [
                            if (hoveredServerId == 'add')
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                          ],
                        ),
                        child: Icon(
                          Icons.add,
                          color: Colors.black,
                          size: widget.iconSize * 0.5,
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
} 