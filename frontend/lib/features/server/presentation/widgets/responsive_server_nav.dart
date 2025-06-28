import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'server_nav_bar.dart';
import 'server_side_nav.dart';
import '../../data/server_providers.dart';

class ResponsiveServerNav extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final servers = ref.watch(serversProvider);
    final iconSize = isMobile ? 48.0 : 40.0;
    final navWidth = isMobile ? 72.0 : 72.0;
    final navPadding = 16.0;
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
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: ServerNavBar(),
      );
    } else {
      return Container(
        width: navWidth,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            right: BorderSide(color: Color(0xFFE9ECEF), width: 1),
          ),
        ),
        child: ServerSideNav(
          iconSize: 40.0,
          navWidth: 72.0,
        ),
      );
    }
  }
} 