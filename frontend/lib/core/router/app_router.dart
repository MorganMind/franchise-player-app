import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/splash_page.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/server/presentation/server_page.dart';
import '../../features/franchise/presentation/franchise_page.dart' as fpage;
import '../../features/franchise/presentation/franchise_page.dart' as fpage;
import '../../features/channel/presentation/channel_page.dart';
import '../../features/dm/presentation/dm_page.dart';
import '../../features/friends/presentation/friends_page.dart';
import '../../features/user/presentation/profile_page.dart';
import '../../features/settings/presentation/settings_page.dart';
import '../../features/home/presentation/home_welcome_page.dart';
import '../../features/voice/presentation/voice_channel_page.dart';
import '../../features/valuation/presentation/valuation_settings_page.dart';
import '../../debug_oauth.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => HomePage(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeWelcomePage(),
            routes: [
              GoRoute(
                path: 'dm',
                builder: (context, state) => const DMPage(),
                routes: [
                  GoRoute(
                    path: ':threadId',
                    builder: (context, state) => const DMPage(),
                  ),
                ],
              ),
              GoRoute(
                path: 'server/:serverId',
                builder: (context, state) => ServerPage(
                  serverId: state.pathParameters['serverId']!,
                ),
                routes: [
                  GoRoute(
                    path: 'channel/:channelId',
                    builder: (context, state) => ServerPage(
                      serverId: state.pathParameters['serverId']!,
                    ),
                  ),
                  GoRoute(
                    path: 'franchise/:franchiseId',
                builder: (context, state) => fpage.FranchiseHeaderNav(
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
        ],
      ),
      GoRoute(
        path: '/friends',
        builder: (context, state) => const FriendsPage(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: '/valuation-settings',
        builder: (context, state) {
          final franchiseId = state.uri.queryParameters['franchise_id'];
          return ValuationSettingsPage(
            baseUrl: 'https://fxbpsuisqzffyggihvin.supabase.co/functions/v1/valuation',
            franchiseId: franchiseId,
          );
        },
      ),
      GoRoute(
        path: '/debug-oauth',
        builder: (context, state) => const DebugOAuthPage(),
      ),
      GoRoute(
        path: '/voice/:channelId',
        builder: (context, state) {
          final channelId = state.pathParameters['channelId']!;
          final channelName = state.uri.queryParameters['name'] ?? 'Voice Channel';
          return VoiceChannelPage(
            channelId: channelId,
            channelName: channelName,
          );
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Page Not Found')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('404 - Page Not Found', style: TextStyle(fontSize: 24)),
            const SizedBox(height: 16),
            Text('The page "${state.uri.path}" was not found.'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
}