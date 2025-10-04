import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:livekit_client/livekit_client.dart';
import '../../../services/voice_service.dart';
import '../../../providers/voice_service_provider.dart';

class VoiceChannelWidget extends ConsumerStatefulWidget {
  final String channelId;
  final String channelName;

  const VoiceChannelWidget({
    Key? key,
    required this.channelId,
    required this.channelName,
  }) : super(key: key);

  @override
  ConsumerState<VoiceChannelWidget> createState() => _VoiceChannelWidgetState();
}

class _VoiceChannelWidgetState extends ConsumerState<VoiceChannelWidget> {
  late VoiceService _voiceService;
  bool _isJoining = false;
  String? _errorMessage;
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    _voiceService = ref.read(voiceServiceProvider);
    
    // Set up periodic updates for audio levels
    _updateTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_voiceService.isConnected) {
        setState(() {
          // Trigger rebuild to update audio levels
        });
      }
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  Future<void> _joinChannel() async {
    if (_isJoining) return;

    setState(() {
      _isJoining = true;
      _errorMessage = null;
    });

    try {
      await _voiceService.joinChannel(widget.channelId, widget.channelName);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isJoining = false;
      });
    }
  }

  Future<void> _leaveChannel() async {
    await _voiceService.leaveChannel();
  }

  void _openFullVoiceView() {
    context.go('/voice/${widget.channelId}?name=${Uri.encodeComponent(widget.channelName)}');
  }

  @override
  Widget build(BuildContext context) {
    final voiceService = ref.watch(voiceServiceProvider);
    final isConnected = voiceService.isConnected;
    final isConnecting = voiceService.isConnecting || _isJoining;
    final isMuted = voiceService.isMuted;
    final isDeafened = voiceService.isDeafened;
    final participants = voiceService.participants;
    final localParticipant = voiceService.localParticipant;
    final speakingParticipants = voiceService.getSpeakingParticipants();

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.headphones,
                  color: isConnected ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.channelName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (isConnected) ...[
                  // Connection status indicator
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      isDeafened ? Icons.volume_off : Icons.headphones,
                      color: isDeafened ? Colors.red : Colors.grey,
                    ),
                    onPressed: () => _voiceService.toggleDeafen(),
                    tooltip: isDeafened ? 'Undeafen' : 'Deafen',
                  ),
                  IconButton(
                    icon: const Icon(Icons.fullscreen),
                    onPressed: _openFullVoiceView,
                    tooltip: 'Full Voice View',
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red.shade800),
                ),
              ),
            Row(
              children: [
                if (!isConnected)
                  ElevatedButton.icon(
                    onPressed: isConnecting ? null : _joinChannel,
                    icon: isConnecting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.call),
                    label: Text(isConnecting ? 'Joining...' : 'Join Voice'),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: _leaveChannel,
                    icon: const Icon(Icons.call_end),
                    label: const Text('Leave'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                const Spacer(),
                if (isConnected) ...[
                  // Audio level indicator for local participant
                  if (localParticipant != null && !isMuted)
                    _buildAudioLevelIndicator(localParticipant),
                  IconButton(
                    icon: Icon(
                      isMuted ? Icons.mic_off : Icons.mic,
                      color: isMuted ? Colors.red : Colors.grey,
                    ),
                    onPressed: () => _voiceService.toggleMute(),
                    tooltip: isMuted ? 'Unmute' : 'Mute',
                  ),
                  IconButton(
                    icon: const Icon(Icons.screen_share),
                    onPressed: () => _voiceService.startScreenShare(),
                    tooltip: 'Share Screen',
                  ),
                ],
              ],
            ),
            if (isConnected && (participants.isNotEmpty || localParticipant != null)) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    'Participants (${participants.length + 1})',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const Spacer(),
                  if (speakingParticipants.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.record_voice_over, size: 16, color: Colors.orange),
                        const SizedBox(width: 4),
                        Text(
                          '${speakingParticipants.length} speaking',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (localParticipant != null)
                    _buildParticipantChip(
                      localParticipant,
                      isLocal: true,
                      isSpeaking: speakingParticipants.contains(localParticipant),
                    ),
                  ...participants.map((participant) => _buildParticipantChip(
                    participant,
                    isLocal: false,
                    isSpeaking: speakingParticipants.contains(participant),
                  )),
                ],
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: _openFullVoiceView,
                  icon: const Icon(Icons.fullscreen, size: 16),
                  label: const Text('Open Full Voice View'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAudioLevelIndicator(Participant participant) {
    // Get audio level (this is a simplified version - LiveKit provides more detailed audio levels)
    final isSpeaking = participant.isSpeaking;
    
    return Container(
      width: 20,
      height: 20,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: isSpeaking ? Colors.green : Colors.grey.shade300,
        shape: BoxShape.circle,
      ),
      child: isSpeaking
          ? const Icon(Icons.volume_up, size: 12, color: Colors.white)
          : null,
    );
  }

  Widget _buildParticipantChip(Participant participant, {required bool isLocal, required bool isSpeaking}) {
    final isMuted = !participant.isMicrophoneEnabled();
    final name = participant.identity;
    
    return Container(
      decoration: BoxDecoration(
        color: isSpeaking ? Colors.orange.shade100 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: isSpeaking 
            ? Border.all(color: Colors.orange, width: 2)
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Audio level indicator
            if (!isMuted)
              _buildAudioLevelIndicator(participant),
            // Avatar
            CircleAvatar(
              radius: 12,
              backgroundColor: isLocal ? Colors.blue : Colors.grey,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
            const SizedBox(width: 6),
            // Name
            Text(
              isLocal ? '$name (You)' : name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isLocal ? FontWeight.bold : FontWeight.normal,
                color: isSpeaking ? Colors.orange.shade800 : null,
              ),
            ),
            // Mute indicator
            if (isMuted) ...[
              const SizedBox(width: 4),
              const Icon(Icons.mic_off, size: 14, color: Colors.red),
            ],
          ],
        ),
      ),
    );
  }
} 