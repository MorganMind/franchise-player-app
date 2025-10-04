import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  // Initialize Supabase (you'll need to add your credentials)
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );

  final supabase = Supabase.instance.client;

  try {
    // Test 1: Check if the bucket exists
    print('Testing storage bucket access...');
    
    // Try to list buckets (this might not work without proper permissions)
    print('Attempting to access storage...');
    
    // Test 2: Try to upload a small test file
    final testData = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]; // PNG header
    final testFileName = 'test_${DateTime.now().millisecondsSinceEpoch}.png';
    
    print('Attempting to upload test file: $testFileName');
    
    await supabase.storage
        .from('server-assets')
        .uploadBinary(testFileName, testData, fileOptions: const FileOptions(
          contentType: 'image/png',
        ));
    
    print('✅ Upload successful!');
    
    // Test 3: Try to get the public URL
    final publicUrl = supabase.storage
        .from('server-assets')
        .getPublicUrl(testFileName);
    
    print('✅ Public URL generated: $publicUrl');
    
    // Test 4: Try to delete the test file
    await supabase.storage
        .from('server-assets')
        .remove([testFileName]);
    
    print('✅ Test file deleted successfully');
    
  } catch (e) {
    print('❌ Error: $e');
    print('\nPossible solutions:');
    print('1. Make sure the server-assets bucket exists in your Supabase project');
    print('2. Run the migration: backend/create_server_assets_bucket.sql');
    print('3. Check your Supabase credentials');
    print('4. Ensure you have proper RLS policies set up');
  }
}


