import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'dart:html' as html;
import 'package:go_router/go_router.dart';

class UploadPage extends StatefulWidget {
  @override
  _UploadPageState createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  bool _isUploading = false;
  String _uploadStatus = '';
  String? _selectedFileName;
  dynamic _uploadedData;
  html.File? _selectedFile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Upload Franchise Data'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.home),
            onPressed: () => context.go('/home'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.upload_file, size: 48, color: Colors.blue),
                    SizedBox(height: 16),
                    Text(
                      'Upload Your Madden Franchise Data',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Select a JSON file from your Madden franchise to analyze your team data',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 24),
            
            // File Selection
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select File',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _selectedFileName ?? 'No file selected',
                              style: TextStyle(
                                color: _selectedFileName != null 
                                  ? Colors.black 
                                  : Colors.grey,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: _isUploading ? null : _selectFile,
                          icon: Icon(Icons.folder_open),
                          label: Text('Browse'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 24),
            
            // Upload Button
            ElevatedButton.icon(
              onPressed: (_selectedFile != null && !_isUploading) 
                ? _uploadFile 
                : null,
              icon: _isUploading 
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.cloud_upload),
              label: Text(_isUploading ? 'Uploading...' : 'Upload File'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
            
            SizedBox(height: 16),
            
            // Status Display
            if (_uploadStatus.isNotEmpty)
              Card(
                color: _uploadStatus.contains('Success') 
                  ? Colors.green.shade50 
                  : Colors.red.shade50,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        _uploadStatus.contains('Success') 
                          ? Icons.check_circle 
                          : Icons.error,
                        color: _uploadStatus.contains('Success') 
                          ? Colors.green 
                          : Colors.red,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _uploadStatus,
                          style: TextStyle(
                            color: _uploadStatus.contains('Success') 
                              ? Colors.green.shade800 
                              : Colors.red.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            SizedBox(height: 24),
            
            // Uploaded Data Preview
            if (_uploadedData != null)
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Uploaded Data Preview',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      SizedBox(height: 8),
                      Container(
                        height: 200,
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: SingleChildScrollView(
                          child: Text(
                            JsonEncoder.withIndent('  ').convert(_uploadedData),
                            style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                          ),
                        ),
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

  void _selectFile() {
    final input = html.FileUploadInputElement()..accept = '.json';
    input.click();

    input.onChange.listen((event) {
      final files = input.files;
      if (files != null && files.isNotEmpty) {
        final file = files.first;
        setState(() {
          _selectedFileName = file.name;
          _selectedFile = file;
          _uploadStatus = '';
          _uploadedData = null;
        });
      }
    });
  }

  Future<void> _uploadFile() async {
    if (_selectedFile == null) return;

    setState(() {
      _isUploading = true;
      _uploadStatus = 'Uploading file...';
    });

    try {
      // Get the current session for authentication
      final session = await Supabase.instance.client.auth.currentSession;
      if (session == null) {
        throw Exception('No active session. Please log in again.');
      }

      final reader = html.FileReader();
      reader.readAsText(_selectedFile!);

      reader.onLoad.listen((event) async {
        try {
          final jsonString = reader.result as String;
          final jsonData = json.decode(jsonString);

          // Accept both Map and List
          if (jsonData is! Map && jsonData is! List) {
            throw Exception('Unsupported JSON root type. Must be object or array.');
          }

          // Upload to backend
          final response = await _uploadToBackend(jsonData, session.accessToken);

          setState(() {
            _isUploading = false;
            _uploadStatus = 'Success! File uploaded successfully.';
            _uploadedData = jsonData;
          });

          // Save to localStorage for local dev/demo
          // TODO: In production, fetch from Supabase instead of localStorage
          try {
            html.window.localStorage['rosters'] = json.encode(jsonData);
          } catch (e) {
            print('Failed to save to localStorage: $e');
          }

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('File uploaded successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } catch (e) {
          setState(() {
            _isUploading = false;
            _uploadStatus = 'Error parsing JSON: $e';
          });
        }
      });
    } catch (e) {
      setState(() {
        _isUploading = false;
        _uploadStatus = 'Upload failed: $e';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<Map<String, dynamic>> _uploadToBackend(
    dynamic data, 
    String token
  ) async {
    const backendUrl = 'http://localhost:3000/upload';
    final request = html.HttpRequest();
    request.open('POST', backendUrl);
    request.setRequestHeader('Content-Type', 'application/json');
    request.setRequestHeader('Authorization', 'Bearer $token');
    request.send(json.encode(data));
    await request.onLoadEnd.first;
    if (request.status == 200) {
      return json.decode(request.responseText!);
    } else {
      throw Exception('Backend error: \\${request.status} - \\${request.responseText}');
    }
  }
} 