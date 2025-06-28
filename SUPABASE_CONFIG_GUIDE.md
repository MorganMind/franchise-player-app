# 🎯 Supabase Configuration: Which URLs to Use Where

## 📍 Main Site URL Configuration

### ✅ Use `localhost` for Main Site URL
In your Supabase project settings, set the **Site URL** to:
```
http://localhost:8080
```

**Why localhost?**
- It's the standard for local development
- Most documentation and examples use `localhost`
- It's more readable and professional
- It's the primary URL you'll use in your browser

## 🔗 Redirect URLs Configuration

### ✅ Include BOTH URLs in Redirect URLs
In the **Redirect URLs** section, add:
```
http://localhost:8080
http://localhost:8080/
http://localhost:8080/auth/callback
http://127.0.0.1:8080
http://127.0.0.1:8080/
http://127.0.0.1:8080/auth/callback
```

**Why both?**
- Covers browser redirect variations
- Handles edge cases and different environments
- Ensures magic links work reliably

## 🎯 Configuration Strategy

### Main Site URL: `localhost`
```
Site URL: http://localhost:8080
```
- **Primary development URL**
- **What you type in your browser**
- **What your Flutter app uses by default**

### Redirect URLs: Both
```
Redirect URLs:
http://localhost:8080
http://localhost:8080/
http://localhost:8080/auth/callback
http://127.0.0.1:8080
http://127.0.0.1:8080/
http://127.0.0.1:8080/auth/callback
```
- **Safety net for browser redirects**
- **Handles different browser behaviors**
- **Covers all possible redirect scenarios**

## 🔧 Flutter App Configuration

### Keep Using `localhost` in Your App
In your Flutter app's Supabase client configuration:
```dart
final supabaseUrl = 'https://your-project.supabase.co';
final supabaseAnonKey = 'your-anon-key';
```

The app will use `localhost` as the primary URL, but the redirect URLs in Supabase will handle any IP-based redirects that might occur.

## 🎉 Best Practice Summary

1. **Site URL**: `http://localhost:8080` (primary, clean, standard)
2. **Redirect URLs**: Include both `localhost` and `127.0.0.1` variants (safety net)
3. **Flutter App**: Continue using `localhost` URLs
4. **Result**: Reliable authentication regardless of browser behavior

## 🚨 What NOT to Do

❌ **Don't change your main site URL to IP-based**
- Keep it as `localhost` for consistency
- IP-based URLs are only needed in redirect URLs

❌ **Don't remove localhost from redirect URLs**
- Always keep both for maximum compatibility

## ✅ What TO Do

✅ **Keep main site URL as `localhost`**
✅ **Add both URL types to redirect URLs**
✅ **Test magic link authentication**
✅ **Verify it works in different browsers**

**The key is: `localhost` for primary use, both URLs for redirect safety!** 🎯 