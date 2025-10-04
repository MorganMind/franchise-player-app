import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'server_nav_bar.dart';
import 'server_side_nav.dart';
import '../../data/server_providers.dart';

class ResponsiveServerNav extends ConsumerWidget {
  final VoidCallback onDmSelected;
  final ValueChanged<String> onServerSelected;
  final VoidCallback onToggleTheme;
  final bool isDark;

  const ResponsiveServerNav({
    Key? key,
    required this.onDmSelected,
    required this.onServerSelected,
    required this.onToggleTheme,
    required this.isDark,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final serversAsync = ref.watch(serversProvider);
    final iconSize = isMobile ? 48.0 : 40.0;
    final navWidth = isMobile ? 72.0 : 72.0;
    const navPadding = 16.0;
    
    return serversAsync.when(
      data: (servers) {
        final navHeight = (servers.length * (iconSize + navPadding)) + (iconSize + navPadding) + 24; // +1 for add button, +24 for top/bottom margin

        if (isMobile) {
          return Container(
            width: navWidth,
            height: navHeight,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(12),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const ServerNavBar(),
          );
        } else {
          return Container(
            width: navWidth,
            height: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                right: BorderSide(color: Color(0xFFE9ECEF), width: 1),
              ),
            ),
            child: ServerSideNav(
              onDmSelected: onDmSelected,
              onServerSelected: onServerSelected,
              onToggleTheme: onToggleTheme,
              isDark: isDark,
              iconSize: 40.0,
            ),
          );
        }
      },
      loading: () => SizedBox(
        width: navWidth,
        height: double.infinity,
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => SizedBox(
        width: navWidth,
        height: double.infinity,
        child: const Center(child: Text('Error loading servers')),
      ),
    );
  }
} 