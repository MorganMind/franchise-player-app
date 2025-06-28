import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/splash_page.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/server/presentation/server_page.dart';
import '../../features/franchise/presentation/franchise_page.dart';
import '../../features/channel/presentation/channel_page.dart';
import '../../features/dm/presentation/dm_inbox_page.dart';
import '../../features/dm/presentation/dm_thread_page.dart';
import '../../features/friends/presentation/friends_page.dart';
import '../../features/user/presentation/profile_page.dart';
import '../../features/settings/presentation/settings_page.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => SplashPage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => LoginPage(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => HomePage(),
        routes: [
          GoRoute(
            path: 'server/:serverId',
            builder: (context, state) => ServerPage(serverId: state.pathParameters['serverId']!),
            routes: [
              GoRoute(
                path: 'franchise/:franchiseId',
                builder: (context, state) => FranchisePage(
                  serverId: state.pathParameters['serverId']!,
                  franchiseId: state.pathParameters['franchiseId']!,
                ),
                routes: [
                  GoRoute(
                    path: 'channel/:channelId',
                    builder: (context, state) => ChannelPage(
                      serverId: state.pathParameters['serverId']!,
                      franchiseId: state.pathParameters['franchiseId']!,
                      channelId: state.pathParameters['channelId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/dm',
        builder: (context, state) => DMInboxPage(),
        routes: [
          GoRoute(
            path: ':threadId',
            builder: (context, state) => DMThreadPage(threadId: state.pathParameters['threadId']!),
          ),
        ],
      ),
      GoRoute(
        path: '/friends',
        builder: (context, state) => FriendsPage(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => ProfilePage(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => SettingsPage(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: Text('Page Not Found')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('404 - Page Not Found', style: TextStyle(fontSize: 24)),
            SizedBox(height: 16),
            Text('The page "${state.uri.path}" was not found.'),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
} 