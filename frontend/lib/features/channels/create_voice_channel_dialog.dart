import 'package:flutter/material.dart';
import 'base_channel_dialog.dart';

class CreateVoiceChannelDialog extends BaseChannelDialog {
  const CreateVoiceChannelDialog({
    Key? key,
    required String serverId,
  }) : super(key: key, serverId: serverId);

  @override
  String get channelType => 'voice';

  @override
  String get dialogTitle => 'Create Voice Channel';

  @override
  IconData get dialogIcon => Icons.headphones;

  @override
  Color get dialogIconColor => Colors.green[600]!;

  @override
  String get createButtonText => 'Create Voice Channel';

  @override
  String get nameHintText => 'e.g., General Voice, Gaming';

  @override
  String get successMessage => 'Voice channel "{name}" created successfully!';

  @override
  List<Widget> get additionalFields => [
    const SizedBox(height: 16),
    // Voice-specific settings
    Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Voice Settings',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            const SwitchListTile(
              title: Text('Voice Enabled'),
              subtitle: Text('Allow voice chat in this channel'),
              value: true, // Default for voice channels
              onChanged: null, // Disabled since this is a voice channel
              secondary: Icon(Icons.mic, color: Colors.green),
            ),
            const SwitchListTile(
              title: Text('Video Enabled'),
              subtitle: Text('Allow video chat in this channel'),
              value: false, // Default to false for voice channels
              onChanged: null, // Can be enabled later if needed
              secondary: Icon(Icons.videocam, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Max Participants (0 = unlimited)',
                border: OutlineInputBorder(),
                helperText: 'Maximum number of participants allowed',
              ),
              keyboardType: TextInputType.number,
              initialValue: '0',
              enabled: false, // Can be enabled later if needed
            ),
          ],
        ),
      ),
    ),
  ];

  @override
  Map<String, dynamic> get additionalData => {
    // Voice-specific fields (if they exist in your schema)
    'voice_enabled': true,
    'video_enabled': false,
    'max_participants': 0,
  };
} 