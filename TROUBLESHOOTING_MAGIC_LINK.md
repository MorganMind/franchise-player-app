# 🔧 Magic Link Troubleshooting Guide

## 🚨 Current Issue: Magic Link Still Not Working

Let's systematically debug this step by step.

## 📋 Step 1: Verify Supabase Configuration

### 1.1 Check Site URL
Go to your Supabase dashboard → Settings → API
- **Site URL should be**: `http://localhost:8080`
- **NOT**: `http://127.0.0.1:8080`

### 1.2 Check Redirect URLs
Go to Authentication → URL Configuration
Add **ALL** of these URLs:
```
http://localhost:8080
http://localhost:8080/
http://localhost:8080/auth/callback
http://127.0.0.1:8080
http://127.0.0.1:8080/
http://127.0.0.1:8080/auth/callback
```

### 1.3 Check Magic Link Settings
Go to Authentication → Providers → Email
- ✅ **Enable magic links**: Should be ON
- ✅ **Enable email confirmations**: Should be ON
- ✅ **Secure email change**: Should be ON

## 📋 Step 2: Check Email Provider

### 2.1 Verify Email Provider
Go to Settings → Auth → SMTP Settings
- **Default**: Supabase uses Resend
- **Check**: No custom SMTP configuration that might interfere

### 2.2 Check Email Templates
Go to Authentication → Templates
- **Magic Link template**: Should be enabled
- **Check**: Template content looks correct

## 📋 Step 3: Test the Process

### 3.1 Clear Browser Data
1. Open Chrome DevTools (F12)
2. Right-click refresh button → "Empty Cache and Hard Reload"
3. Or go to Settings → Privacy → Clear browsing data

### 3.2 Test Magic Link Flow
1. Go to `http://localhost:8080`
2. Enter your email
3. Click "Send Magic Link"
4. **Immediately** check your email
5. Click the link **within 30 seconds**

### 3.3 Check Browser Console
1. Open DevTools (F12)
2. Go to Console tab
3. Look for any error messages
4. Look for Supabase-related logs

## 📋 Step 4: Debug Information

### 4.1 What Error Are You Getting?
- **"otp_expired"**: Redirect URL issue
- **"access_denied"**: Site URL or redirect URL issue
- **"invalid_email"**: Email format issue
- **No error but no login**: Auth state listener issue

### 4.2 Check URL After Clicking Magic Link
When you click the magic link, what URL do you see in your browser?
- Should be: `http://localhost:8080/#access_token=...`
- Or: `http://127.0.0.1:8080/#access_token=...`

## 📋 Step 5: Alternative Solutions

### 5.1 Try Different Browser
- Test in Chrome, Firefox, Safari
- Some browsers handle redirects differently

### 5.2 Try Different Port
Change your Flutter app to run on a different port:
```bash
flutter run -d web-server --web-port 3000
```
Then update Supabase URLs to use port 3000.

### 5.3 Check Network Issues
- Disable VPN if using one
- Try on different network
- Check firewall settings

## 📋 Step 6: Advanced Debugging

### 6.1 Enable Supabase Debug Logs
Add this to your Flutter app:
```dart
// In main.dart before Supabase.initialize()
Supabase.instance.client.auth.onAuthStateChange.listen((data) {
  print('Auth state changed: ${data.event}');
  print('Session: ${data.session}');
  print('User: ${data.user}');
});
```

### 6.2 Check Supabase Logs
Go to your Supabase dashboard → Logs
- Look for authentication events
- Check for any errors

## 🎯 Most Common Fixes

### Fix 1: Redirect URLs
**Problem**: Missing redirect URLs
**Solution**: Add all 6 URLs listed above

### Fix 2: Site URL
**Problem**: Wrong site URL
**Solution**: Set to `http://localhost:8080`

### Fix 3: Timing
**Problem**: Magic link expires too quickly
**Solution**: Click link immediately, check email right away

### Fix 4: Browser Cache
**Problem**: Old cached data
**Solution**: Clear browser cache and cookies

## 🆘 Still Not Working?

If none of the above works:

1. **Check Supabase project status**: Go to dashboard → Status
2. **Try creating a new Supabase project**: Sometimes projects get corrupted
3. **Check your email spam folder**: Magic links might be filtered
4. **Try a different email address**: Some email providers block magic links

## 📞 Need More Help?

Provide these details:
1. **Exact error message** you're seeing
2. **URL in browser** after clicking magic link
3. **Browser console errors** (if any)
4. **Supabase project URL** (the fxbpsuisqzffyggihvin part)
5. **Email provider** you're using

**Let's get this working! 🚀** 