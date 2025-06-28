import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_providers.dart';
import 'package:go_router/go_router.dart';

class SplashPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    authState.when(
      data: (user) {
        if (user != null) {
          Future.microtask(() => context.go('/home'));
        } else {
          Future.microtask(() => context.go('/login'));
        }
      },
      loading: () {},
      error: (e, st) {
        Future.microtask(() => context.go('/login'));
      },
    );
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 24),
            Text('Checking session...'),
          ],
        ),
      ),
    );
  }
} 