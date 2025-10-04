import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/server_providers.dart';
import '../../data/server_repository.dart';

class DeleteServerDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic> server;

  const DeleteServerDialog({
    super.key,
    required this.server,
  });

  @override
  ConsumerState<DeleteServerDialog> createState() => _DeleteServerDialogState();
}

class _DeleteServerDialogState extends ConsumerState<DeleteServerDialog> {
  final _confirmationController = TextEditingController();
  bool _isDeleting = false;
  bool _canDelete = false;

  @override
  void initState() {
    super.initState();
    _confirmationController.addListener(_checkConfirmation);
  }

  @override
  void dispose() {
    _confirmationController.dispose();
    super.dispose();
  }

  void _checkConfirmation() {
    setState(() {
      _canDelete = _confirmationController.text.trim() == widget.server['name'];
    });
  }

  Future<void> _deleteServer() async {
    if (!_canDelete) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      final repository = ServerRepository();
      final success = await repository.deleteServer(widget.server['id']);
      
      if (success) {
        // Invalidate providers to refresh the list
        ref.invalidate(serversProvider);
        ref.invalidate(userServersProvider);
        
        // Clear current server selection
        ref.read(serverNavigationProvider.notifier).clearCurrentServer();
        
        if (mounted) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Server "${widget.server['name']}" deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Redirect to home page
          context.go('/');
        }
      } else {
        throw Exception('Failed to delete server');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete server: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.warning,
            color: Colors.red[600],
            size: 24,
          ),
          const SizedBox(width: 8),
          const Text('Delete Server'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Are you sure you want to delete the server "${widget.server['name']}"?',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          const Text(
            'This action cannot be undone. All channels, messages, and server data will be permanently deleted.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'To confirm deletion, please type the server name exactly:',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _confirmationController,
            decoration: InputDecoration(
              hintText: 'Enter server name to confirm',
              border: const OutlineInputBorder(),
              suffixIcon: _canDelete
                  ? Icon(
                      Icons.check_circle,
                      color: Colors.green[600],
                    )
                  : Icon(
                      Icons.cancel,
                      color: Colors.grey[400],
                    ),
            ),
            onChanged: (value) => _checkConfirmation(),
          ),
          const SizedBox(height: 8),
          Text(
            'Server name: "${widget.server['name']}"',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isDeleting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: (_canDelete && !_isDeleting) ? _deleteServer : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[600],
            foregroundColor: Colors.white,
          ),
          child: _isDeleting
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Delete Server'),
        ),
      ],
    );
  }
}
