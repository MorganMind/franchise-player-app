import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:typed_data';
import 'dart:html' as html;
import 'package:image/image.dart' as img;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/server_providers.dart';
import '../../data/server_repository.dart';
import 'server_icon_widget.dart';
import 'delete_server_dialog.dart';

class ServerSettingsDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic> server;

  const ServerSettingsDialog({
    super.key,
    required this.server,
  });

  @override
  ConsumerState<ServerSettingsDialog> createState() => _ServerSettingsDialogState();
}

class _ServerSettingsDialogState extends ConsumerState<ServerSettingsDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isSaving = false;
  bool _isUploadingImage = false;
  Uint8List? _selectedImageBytes;
  String? _uploadedImageUrl;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.server['name'] ?? '';
    _uploadedImageUrl = widget.server['icon_url'];
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      // Create a file input element
      final html.FileUploadInputElement input = html.FileUploadInputElement();
      input.accept = 'image/*';
      input.click();

      // Wait for file selection
      await input.onChange.first;
      
      if (input.files != null && input.files!.isNotEmpty) {
        final html.File file = input.files!.first;
        final reader = html.FileReader();
        
        reader.onLoad.listen((event) {
          final Uint8List bytes = reader.result as Uint8List;
          setState(() {
            _selectedImageBytes = bytes;
          });
        });
        
        reader.readAsArrayBuffer(file);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImageBytes == null) return;

    setState(() {
      _isUploadingImage = true;
    });

    try {
      // Decode and resize the image to 150x150
      final img.Image? originalImage = img.decodeImage(_selectedImageBytes!);
      if (originalImage == null) throw Exception('Failed to decode image');
      
      final img.Image resizedImage = img.copyResize(
        originalImage,
        width: 150,
        height: 150,
        interpolation: img.Interpolation.linear,
      );
      
      // Encode the resized image as PNG
      final Uint8List resizedBytes = Uint8List.fromList(img.encodePng(resizedImage));
      
      // Generate a unique filename
      final String fileName = 'server_icons/${DateTime.now().millisecondsSinceEpoch}_icon.png';
      
      // Upload to Supabase Storage
      final supabase = Supabase.instance.client;
      await supabase.storage
          .from('server-assets')
          .uploadBinary(fileName, resizedBytes, fileOptions: const FileOptions(
            contentType: 'image/png',
          ));
      
      // Get the public URL
      final String imageUrl = supabase.storage
          .from('server-assets')
          .getPublicUrl(fileName);
      
      setState(() {
        _uploadedImageUrl = imageUrl;
        _isUploadingImage = false;
      });
      
    } catch (e) {
      setState(() {
        _isUploadingImage = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    // Upload image first if selected
    if (_selectedImageBytes != null && _uploadedImageUrl == null) {
      await _uploadImage();
      if (_uploadedImageUrl == null) return; // Upload failed
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final repository = ServerRepository();
      final success = await repository.updateServer(
        widget.server['id'],
        name: _nameController.text.trim(),
        iconUrl: _uploadedImageUrl,
      );

      if (success) {
        // Invalidate providers to refresh the list
        ref.invalidate(serversProvider);
        ref.invalidate(userServersProvider);
      } else {
        throw Exception('Failed to update server');
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Server settings updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update server settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return DeleteServerDialog(server: widget.server);
      },
    ).then((deleted) {
      if (deleted == true) {
        // Server was deleted, close the settings dialog
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Server Settings'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Server Icon Section
              const Text(
                'Server Icon',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: GestureDetector(
                  onTap: _isUploadingImage ? null : _pickImage,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(
                        color: Colors.grey[300]!,
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(38),
                      child: _isUploadingImage
                          ? const Center(
                              child: CircularProgressIndicator(),
                            )
                          : _uploadedImageUrl != null
                              ? Image.network(
                                  _uploadedImageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return ServerIconWidget(
                                      iconUrl: null,
                                      emojiIcon: widget.server['icon'],
                                      color: widget.server['color'],
                                      size: 80,
                                      showBorder: false,
                                    );
                                  },
                                )
                              : ServerIconWidget(
                                  iconUrl: widget.server['icon_url'],
                                  emojiIcon: widget.server['icon'],
                                  color: widget.server['color'],
                                  size: 80,
                                  showBorder: false,
                                ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: _isUploadingImage ? null : _pickImage,
                  icon: const Icon(Icons.photo_camera, size: 16),
                  label: const Text('Change Icon'),
                ),
              ),
              const SizedBox(height: 24),
              
              // Server Name Section
              const Text(
                'Server Name',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'Enter server name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Server name is required';
                  }
                  if (value.trim().length < 2) {
                    return 'Server name must be at least 2 characters';
                  }
                  if (value.trim().length > 50) {
                    return 'Server name must be less than 50 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              
              // Server Info Section
              const Text(
                'Server Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Type: ${widget.server['server_type'] ?? 'General'}'),
                    const SizedBox(height: 4),
                    Text('Visibility: ${widget.server['visibility'] ?? 'Public'}'),
                    const SizedBox(height: 4),
                    Text('Created: ${widget.server['created_at'] != null ? DateTime.parse(widget.server['created_at']).toString().split(' ')[0] : 'Unknown'}'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Danger Zone Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning,
                          color: Colors.red[600],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Danger Zone',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.red[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Deleting this server will permanently remove all data including channels, messages, and member information. This action cannot be undone.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.red[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _showDeleteConfirmation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.delete_forever, size: 18),
                        label: const Text('Delete Server'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveSettings,
          child: _isSaving
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save Changes'),
        ),
      ],
    );
  }
}
