import 'package:flutter/material.dart';
import 'base_channel_dialog.dart';

class CreateChannelDialog extends BaseChannelDialog {
  const CreateChannelDialog({
    Key? key,
    required String serverId,
  }) : super(key: key, serverId: serverId);

  @override
  String get channelType => 'text';

  @override
  String get dialogTitle => 'Create Channel';

  @override
  IconData get dialogIcon => Icons.chat;

  @override
  Color get dialogIconColor => Colors.blue[600]!;

  @override
  String get createButtonText => 'Create Channel';

  @override
  String get nameHintText => 'e.g., general, announcements';

  @override
  String get successMessage => 'Channel "{name}" created successfully!';
} 