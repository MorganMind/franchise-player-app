import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livekit_client/livekit_client.dart';
import '../../../services/voice_service.dart';
import '../../../providers/voice_service_provider.dart';
import 'voice_channel_widget.dart';

class VoiceChannelPage extends ConsumerStatefulWidget {
  final String channelId;
  final String channelName;

  const VoiceChannelPage({
    Key? key,
    required this.channelId,
    required this.channelName,
  }) : super(key: key);

  @override
  ConsumerState<VoiceChannelPage> createState() => _VoiceChannelPageState();
}

class _VoiceChannelPageState extends ConsumerState<VoiceChannelPage> {
  late VoiceService _voiceService;
  List<MediaDevice> _audioDevices = [];
  String? _selectedAudioDevice;
  bool _showDeviceSettings = false;

  @override
  void initState() {
    super.initState();
    _voiceService = ref.read(voiceServiceProvider);
    _loadAudioDevices();
  }

  Future<void> _loadAudioDevices() async {
    try {
      final devices = await _voiceService.getAudioDevices();
      setState(() {
        _audioDevices = devices.where((d) => d.kind == 'audioinput').toList();
        if (_audioDevices.isNotEmpty && _selectedAudioDevice == null) {
          _selectedAudioDevice = _audioDevices.first.deviceId;
        }
      });
    } catch (e) {
      debugPrint('Error loading audio devices: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final voiceService = ref.watch(voiceServiceProvider);
    final isConnected = voiceService.isConnected;
    final participants = voiceService.participants;
    final localParticipant = voiceService.localParticipant;

    return Scaffold(
      appBar: AppBar(
        title: Text('Voice Channel: ${widget.channelName}'),
        actions: [
          if (isConnected) ...[
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => setState(() => _showDeviceSettings = !_showDeviceSettings),
              tooltip: 'Audio Settings',
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Main voice channel widget
          VoiceChannelWidget(
            channelId: widget.channelId,
            channelName: widget.channelName,
          ),
          
          // Audio device settings panel
          if (_showDeviceSettings && isConnected)
            _buildAudioSettingsPanel(),
          
          // Participants list
          if (isConnected)
            Expanded(
              child: _buildParticipantsList(participants, localParticipant),
            ),
        ],
      ),
    );
  }

  Widget _buildAudioSettingsPanel() {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.settings, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Audio Settings',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 16),
                  onPressed: _loadAudioDevices,
                  tooltip: 'Refresh Devices',
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Microphone selection
            if (_audioDevices.isNotEmpty) ...[
              Text(
                'Microphone',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              DropdownButtonFormField<String>(
                value: _selectedAudioDevice,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: _audioDevices.map((device) {
                  return DropdownMenuItem(
                    value: device.deviceId,
                    child: Text(
                      device.label.isNotEmpty ? device.label : 'Unknown Device',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (deviceId) {
                  if (deviceId != null) {
                    setState(() => _selectedAudioDevice = deviceId);
                    _voiceService.switchAudioDevice(deviceId);
                  }
                },
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Audio device management is not available in this version. Your default microphone will be used.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Audio controls
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _voiceService.toggleMute(),
                    icon: Icon(
                      _voiceService.isMuted ? Icons.mic_off : Icons.mic,
                    ),
                    label: Text(_voiceService.isMuted ? 'Unmute' : 'Mute'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _voiceService.isMuted ? Colors.red : null,
                      foregroundColor: _voiceService.isMuted ? Colors.white : null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _voiceService.toggleDeafen(),
                    icon: Icon(
                      _voiceService.isDeafened ? Icons.volume_off : Icons.headphones,
                    ),
                    label: Text(_voiceService.isDeafened ? 'Undeafen' : 'Deafen'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _voiceService.isDeafened ? Colors.red : null,
                      foregroundColor: _voiceService.isDeafened ? Colors.white : null,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantsList(List<RemoteParticipant> participants, LocalParticipant? localParticipant) {
    final allParticipants = <Widget>[];
    
    // Add local participant first
    if (localParticipant != null) {
      allParticipants.add(_buildParticipantTile(localParticipant, isLocal: true));
    }
    
    // Add remote participants
    for (final participant in participants) {
      allParticipants.add(_buildParticipantTile(participant, isLocal: false));
    }
    
    if (allParticipants.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No participants yet',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }
    
    return ListView(
      padding: const EdgeInsets.all(8.0),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Participants (${allParticipants.length})',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        ...allParticipants,
      ],
    );
  }

  Widget _buildParticipantTile(Participant participant, {required bool isLocal}) {
    final isMuted = !participant.isMicrophoneEnabled();
    final isSpeaking = participant.isSpeaking;
    final name = participant.identity;
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: isLocal ? Colors.blue : Colors.grey,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            if (isSpeaking)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                isLocal ? '$name (You)' : name,
                style: TextStyle(
                  fontWeight: isLocal ? FontWeight.bold : FontWeight.normal,
                  color: isSpeaking ? Colors.orange.shade800 : null,
                ),
              ),
            ),
            if (isMuted)
              const Icon(Icons.mic_off, color: Colors.red, size: 16),
          ],
        ),
        subtitle: Text(
          isLocal ? 'Local Participant' : 'Remote Participant',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        trailing: isSpeaking
            ? Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.volume_up, size: 12, color: Colors.white),
              )
            : null,
      ),
    );
  }
} 