import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'lib/services/voice_service.dart';
import 'lib/providers/voice_service_provider.dart';

void main() {
  runApp(
    const ProviderScope(
      child: VoiceTestApp(),
    ),
  );
}

class VoiceTestApp extends StatelessWidget {
  const VoiceTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voice Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const VoiceTestPage(),
    );
  }
}

class VoiceTestPage extends ConsumerStatefulWidget {
  const VoiceTestPage({super.key});

  @override
  ConsumerState<VoiceTestPage> createState() => _VoiceTestPageState();
}

class _VoiceTestPageState extends ConsumerState<VoiceTestPage> {
  late VoiceService _voiceService;
  String _status = 'Ready to test';
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    _voiceService = ref.read(voiceServiceProvider);
  }

  Future<void> _testVoiceConnection() async {
    setState(() {
      _isTesting = true;
      _status = 'Testing voice connection...';
    });

    try {
      // Test with a sample channel ID (you'll need to replace this with a real one)
      const testChannelId = '660e8400-e29b-41d4-a716-446655440001'; // Replace with actual channel ID
      const testChannelName = 'Test Voice Channel';
      
      await _voiceService.joinChannel(testChannelId, testChannelName);
      
      setState(() {
        _status = '✅ Voice connection successful!';
      });
      
      // Wait a bit then disconnect
      await Future.delayed(const Duration(seconds: 5));
      await _voiceService.leaveChannel();
      
      setState(() {
        _status = '✅ Test completed successfully!';
      });
      
    } catch (e) {
      setState(() {
        _status = '❌ Test failed: $e';
      });
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final voiceService = ref.watch(voiceServiceProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Functionality Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Voice Service Status',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text('Connected: ${voiceService.isConnected}'),
                    Text('Connecting: ${voiceService.isConnecting}'),
                    Text('Muted: ${voiceService.isMuted}'),
                    Text('Deafened: ${voiceService.isDeafened}'),
                    Text('Participants: ${voiceService.participants.length}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Test Results',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(_status),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isTesting ? null : _testVoiceConnection,
                      child: Text(_isTesting ? 'Testing...' : 'Run Voice Test'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Voice Controls',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: voiceService.isConnected ? () => voiceService.toggleMute() : null,
                          icon: Icon(voiceService.isMuted ? Icons.mic_off : Icons.mic),
                          label: Text(voiceService.isMuted ? 'Unmute' : 'Mute'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: voiceService.isConnected ? () => voiceService.toggleDeafen() : null,
                          icon: Icon(voiceService.isDeafened ? Icons.volume_off : Icons.headphones),
                          label: Text(voiceService.isDeafened ? 'Undeafen' : 'Deafen'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 