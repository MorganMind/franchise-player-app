import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TestRoutingPage extends StatelessWidget {
  const TestRoutingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Routing Test'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Server Routing Test',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('Test the server routing with different URLs:'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () => context.go('/server/madden-league'),
                  child: const Text('Madden League (Name)'),
                ),
                ElevatedButton(
                  onPressed: () => context.go('/server/587c945e-048c-40ac-aa15-6b99dd61d4b7'),
                  child: const Text('Madden League (ID)'),
                ),
                ElevatedButton(
                  onPressed: () => context.go('/server/tech-team'),
                  child: const Text('Tech Team (Name)'),
                ),
                ElevatedButton(
                  onPressed: () => context.go('/server/660e8400-e29b-41d4-a716-446655440002'),
                  child: const Text('Tech Team (ID)'),
                ),
                ElevatedButton(
                  onPressed: () => context.go('/server/unknown-server'),
                  child: const Text('Unknown Server'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Current URL:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${Uri.base}',
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}
