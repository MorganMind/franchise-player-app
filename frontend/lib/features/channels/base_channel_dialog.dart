import 'package:flutter/material.dart';
import '../../core/supabase/supabase_init.dart';

// Shared base class for channel creation dialogs
abstract class BaseChannelDialog extends StatefulWidget {
  final String serverId;

  const BaseChannelDialog({
    Key? key,
    required this.serverId,
  }) : super(key: key);

  // Abstract methods that subclasses must implement
  String get channelType;
  String get dialogTitle;
  IconData get dialogIcon;
  Color get dialogIconColor;
  String get createButtonText;
  String get nameHintText;
  String get successMessage;
  
  // Override this to add additional fields
  List<Widget> get additionalFields => [];
  
  // Override this to add additional data to the insert
  Map<String, dynamic> get additionalData => {};

  @override
  State<BaseChannelDialog> createState() => _BaseChannelDialogState();
}

class _BaseChannelDialogState extends State<BaseChannelDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Shared validation logic
  String? validateChannelName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Channel name is required';
    }
    if (value.trim().length < 2) {
      return 'Channel name must be at least 2 characters';
    }
    if (value.trim().length > 50) {
      return 'Channel name must be less than 50 characters';
    }
    // Check for valid characters (letters, numbers, hyphens, underscores, spaces)
    if (!RegExp(r'^[a-zA-Z0-9_\-\s]+$').hasMatch(value.trim())) {
      return 'Channel name can only contain letters, numbers, hyphens, underscores, and spaces';
    }
    return null;
  }

  // Shared creation logic
  Future<void> createChannel() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isCreating = true;
    });

    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user');
      }

      // Base data for all channels
      final channelData = {
        'name': _nameController.text.trim(),
        'server_id': widget.serverId,
        'type': widget.channelType,
        'created_at': DateTime.now().toIso8601String(),
        ...widget.additionalData, // Add any additional data from subclasses
      };

      await supabase.from('channels').insert(channelData);

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.successMessage.replaceAll('{name}', _nameController.text.trim())),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error creating channel: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create channel: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(widget.dialogIcon, color: widget.dialogIconColor, size: 24),
          const SizedBox(width: 8),
          Text(widget.dialogTitle),
        ],
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Channel Name',
                  hintText: widget.nameHintText,
                  border: const OutlineInputBorder(),
                ),
                validator: validateChannelName,
                textCapitalization: TextCapitalization.words,
                enabled: !_isCreating,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'What is this channel for?',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                maxLength: 200,
                enabled: !_isCreating,
              ),
              ...widget.additionalFields, // Add any additional fields from subclasses
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isCreating ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _isCreating ? null : createChannel,
          icon: _isCreating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(widget.dialogIcon),
          label: Text(_isCreating ? 'Creating...' : widget.createButtonText),
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.dialogIconColor,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
} 