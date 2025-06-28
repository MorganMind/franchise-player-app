import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> debugSupabaseAuth() async {
  print('🔍 Starting Supabase Auth Debug...\n');
  
  try {
    // 1. Check if Supabase is initialized
    print('1️⃣ Checking Supabase initialization...');
    final client = Supabase.instance.client;
    print('✅ Supabase client initialized successfully');
    print('   URL: ${client.supabaseUrl}');
    print('   Anon Key: ${client.supabaseKey.substring(0, 20)}...\n');
    
    // 2. Check current auth state
    print('2️⃣ Checking current auth state...');
    final user = client.auth.currentUser;
    if (user != null) {
      print('✅ User is logged in: ${user.email}');
      print('   User ID: ${user.id}');
      print('   Created: ${user.createdAt}');
    } else {
      print('ℹ️ No user currently logged in\n');
    }
    
    // 3. Test magic link with debug info
    print('3️⃣ Testing magic link (this will send an email)...');
    print('   Enter your email address:');
    // Note: This is a debug script, so we'll use a test email
    const testEmail = 'test@example.com'; // Replace with your actual email
    
    try {
      final response = await client.auth.signInWithOtp(
        email: testEmail,
      );
      
      print('✅ Magic link request successful!');
      print('   Response: $response');
      
      if (response.user != null) {
        print('   User created: ${response.user!.email}');
      }
      
      if (response.session != null) {
        print('   Session created: ${response.session!.accessToken.substring(0, 20)}...');
      }
      
    } catch (e) {
      print('❌ Magic link request failed:');
      print('   Error: $e');
      print('   Error type: ${e.runtimeType}');
      
      if (e.toString().contains('otp_expired')) {
        print('   🔧 This suggests a redirect URL configuration issue');
      } else if (e.toString().contains('access_denied')) {
        print('   🔧 This suggests a redirect URL or site URL configuration issue');
      } else if (e.toString().contains('invalid_email')) {
        print('   🔧 This suggests an email format issue');
      }
    }
    
    // 4. Check auth state listener
    print('\n4️⃣ Setting up auth state listener...');
    client.auth.onAuthStateChange.listen((data) {
      print('🔄 Auth state changed:');
      print('   Event: ${data.event}');
      print('   Session: ${data.session != null ? "Present" : "None"}');
      if (data.user != null) {
        print('   User: ${data.user!.email}');
      }
    });
    
    // 5. Test URL parsing
    print('\n5️⃣ Testing URL parsing...');
    final currentUrl = Uri.base.toString();
    print('   Current URL: $currentUrl');
    print('   Host: ${Uri.base.host}');
    print('   Port: ${Uri.base.port}');
    print('   Path: ${Uri.base.path}');
    print('   Query: ${Uri.base.query}');
    print('   Fragment: ${Uri.base.fragment}');
    
    // 6. Check for auth callback in URL
    if (Uri.base.fragment.contains('access_token') || 
        Uri.base.fragment.contains('error')) {
      print('   ✅ Auth callback detected in URL fragment');
    } else {
      print('   ℹ️ No auth callback in current URL');
    }
    
  } catch (e) {
    print('❌ Debug failed with error: $e');
  }
  
  print('\n🔍 Debug complete!');
  print('\n📋 Next steps:');
  print('1. Check your Supabase dashboard redirect URLs');
  print('2. Verify site URL is set to http://localhost:8080');
  print('3. Make sure magic link is enabled in Auth settings');
  print('4. Check your email for the magic link');
  print('5. Click the link immediately when you receive it');
}

// Run this function to debug
void main() async {
  await debugSupabaseAuth();
} 