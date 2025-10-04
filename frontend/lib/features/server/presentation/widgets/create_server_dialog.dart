import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:html' as html;
import 'package:image/image.dart' as img;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/server_providers.dart';

class CreateServerDialog extends ConsumerStatefulWidget {
  const CreateServerDialog({super.key});

  @override
  ConsumerState<CreateServerDialog> createState() => _CreateServerDialogState();
}

class _CreateServerDialogState extends ConsumerState<CreateServerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  
  String _selectedServerType = 'Madden';
  String _selectedVisibility = 'Public';
  bool _isCreating = false;
  bool _isUploadingImage = false;
  Uint8List? _selectedImageBytes;
  String? _uploadedImageUrl;

  final List<String> _serverTypes = ['Madden', 'CFB', 'General'];
  final List<String> _visibilityOptions = ['Public', 'Private'];

  @override
  void initState() {
    super.initState();
    print('CreateServerDialog: _selectedServerType initialized to: $_selectedServerType');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
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

  Future<void> _createServer() async {
    if (!_formKey.currentState!.validate()) return;

    // Upload image first if selected
    if (_selectedImageBytes != null && _uploadedImageUrl == null) {
      await _uploadImage();
      if (_uploadedImageUrl == null) return; // Upload failed
    }

    setState(() {
      _isCreating = true;
    });

    try {
      print('Creating server with data:');
      print('Name: ${_nameController.text.trim()}');
      print('Description: ${_descriptionController.text.trim()}');
      print('Server Type: $_selectedServerType');
      print('Visibility: $_selectedVisibility');
      print('Icon URL: $_uploadedImageUrl');

      await ref.read(serverNavigationProvider.notifier).createServer(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        serverType: _selectedServerType,
        visibility: _selectedVisibility,
        iconUrl: _uploadedImageUrl,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Server created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error creating server: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create server: $e'),
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
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.add_circle_outline,
                    color: Theme.of(context).primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Create Server',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Server Icon Upload
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _isUploadingImage ? null : _pickImage,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 2,
                          ),
                        ),
                        child: _isUploadingImage
                            ? const Center(
                                child: CircularProgressIndicator(),
                              )
                            : _selectedImageBytes != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(48),
                                    child: Image.memory(
                                      _selectedImageBytes!,
                                      width: 96,
                                      height: 96,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_a_photo,
                                        size: 32,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Upload Icon',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap to upload server icon (150x150px)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Server Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Server Name',
                  hintText: 'Enter server name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.tag),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Server name is required';
                  }
                  if (value.trim().length < 3) {
                    return 'Server name must be at least 3 characters';
                  }
                  if (value.trim().length > 50) {
                    return 'Server name must be less than 50 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Server Type
              DropdownButtonFormField<String>(
                value: _selectedServerType,
                // Debug: Print the current value

                decoration: const InputDecoration(
                  labelText: 'Server Type',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: _serverTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  print('CreateServerDialog: Server type changed to: $value');
                  setState(() {
                    _selectedServerType = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Visibility
              DropdownButtonFormField<String>(
                value: _selectedVisibility,
                decoration: const InputDecoration(
                  labelText: 'Visibility',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.visibility),
                ),
                items: _visibilityOptions.map((visibility) {
                  return DropdownMenuItem(
                    value: visibility,
                    child: Row(
                      children: [
                        Icon(
                          visibility == 'Public' 
                              ? Icons.public 
                              : Icons.lock,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(visibility),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedVisibility = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Brief description of your server',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                maxLength: 200,
                validator: (value) {
                  if (value != null && value.trim().length > 200) {
                    return 'Description must be less than 200 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: (_isCreating || _isUploadingImage) ? null : () {
                        Navigator.of(context).pop();
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: (_isCreating || _isUploadingImage) ? null : _createServer,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: (_isCreating || _isUploadingImage)
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Create'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
