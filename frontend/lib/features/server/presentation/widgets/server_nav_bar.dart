import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/server_providers.dart';

class ServerNavBar extends ConsumerStatefulWidget {
  @override
  ConsumerState<ServerNavBar> createState() => _ServerNavBarState();
}

class _ServerNavBarState extends ConsumerState<ServerNavBar> with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  String? pressedServerId;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
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
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Home button (now DM/chat icon)
            Container(
              width: 48,
              height: 48,
              margin: const EdgeInsets.only(left: 16, right: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => context.go('/dm'),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Icon(
                      Icons.chat_bubble_outline,
                      color: Colors.black,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
            // Separator
            Container(
              width: 1,
              height: 32,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFE9ECEF),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            // Server carousel
            Expanded(
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: servers.length + 1, // +1 for add button
                itemBuilder: (context, index) {
                  if (index == servers.length) {
                    // Add server button
                    return Container(
                      width: 48,
                      height: 48,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Create Server - Coming Soon!')),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: const Color(0xFFE9ECEF),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              Icons.add,
                              color: Colors.black,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  final server = servers[index];
                  final isActive = currentServerId == server['id'];
                  final isPressed = pressedServerId == server['id'];
                  
                  return Container(
                    width: 48,
                    height: 48,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTapDown: (_) {
                        setState(() {
                          pressedServerId = server['id'];
                        });
                        _scaleController.forward();
                      },
                      onTapUp: (_) {
                        setState(() {
                          pressedServerId = null;
                        });
                        _scaleController.reverse();
                      },
                      onTapCancel: () {
                        setState(() {
                          pressedServerId = null;
                        });
                        _scaleController.reverse();
                      },
                      onTap: () async {
                        ref.read(currentServerIdProvider.notifier).state = server['id'];
                        await ref.read(serverNavigationProvider.notifier).switchServer(server['id']!);
                        if (context.mounted) {
                          context.go('/home/server/${server['id']}');
                        }
                      },
                      child: AnimatedScale(
                        scale: isPressed ? 1.2 : (isActive ? 1.1 : 1.0),
                        duration: const Duration(milliseconds: 150),
                        curve: Curves.easeInOut,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isActive 
                                  ? Color(int.parse(server['color']!.substring(1), radix: 16) + 0xFF000000)
                                  : const Color(0xFFE9ECEF),
                              width: isActive ? 2 : 1,
                            ),
                            boxShadow: [
                              if (isActive)
                                BoxShadow(
                                  color: Color(int.parse(server['color']!.substring(1), radix: 16) + 0xFF000000).withOpacity(0.3),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              if (isPressed)
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              server['icon']!,
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
} 