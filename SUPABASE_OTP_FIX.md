# 🔧 Fix OTP Expiration Issue

The "otp_expired" error means the magic link is expiring too quickly. Here's how to fix it:

## 🎯 Step 1: Update Supabase Project Settings

### Go to Your Supabase Dashboard
1. Open: https://supabase.com/dashboard/project/fxbpsuisqzffyggihvin
2. Navigate to **Authentication** → **Settings**

### Update Email Template Settings
1. Find **Email Templates** section
2. Click on **Magic Link** template
3. Make sure the **Subject** and **Content** are properly configured

### Update URL Configuration
1. Go to **Authentication** → **URL Configuration**
2. Set **Site URL** to: `http://localhost:8080`
3. Add these **Redirect URLs**:
   ```
   http://localhost:8080
   http://localhost:8080/
   http://localhost:8080/auth/callback
   http://localhost:8080/#/auth/callback
   ```

## 🎯 Step 2: Check Email Provider Settings

### Go to Authentication → Settings
1. Find **SMTP Settings** or **Email Provider**
2. Make sure your email provider is configured correctly
3. Test the email delivery

## 🎯 Step 3: Update Magic Link Settings

### In Authentication → Settings
1. Find **Magic Link** settings
2. Increase the **Token Expiry** time (if available)
3. Make sure **Enable Magic Link** is turned ON

## 🎯 Step 4: Test the Fix

1. **Go back to your Flutter app**: http://localhost:8080
2. **Enter your email** and click "Send Magic Link"
3. **Check your email immediately** (within 1-2 minutes)
4. **Click the magic link right away** (don't wait)
5. **Use the same browser window** where you sent the magic link

## 🚨 Common Issues & Solutions

### Issue: "otp_expired"
- **Solution**: Click the magic link immediately after receiving it
- **Solution**: Send a new magic link if the old one expired

### Issue: "access_denied"
- **Solution**: Make sure redirect URLs are configured correctly
- **Solution**: Use the same browser window

### Issue: Email not received
- **Solution**: Check spam folder
- **Solution**: Verify email provider settings in Supabase

## 🎉 Success Indicators

When it works, you should see:
1. ✅ Magic link email received quickly
2. ✅ Clicking the link redirects you back to the app
3. ✅ You see the dashboard with the green "Get JWT Token" button
4. ✅ No more "otp_expired" or "access_denied" errors

## 🔍 Debug Steps

If it still doesn't work:
1. Check browser console (F12) for errors
2. Check Supabase logs in the dashboard
3. Try with a different email address
4. Clear browser cache and try again

Let me know when you've updated the Supabase settings and we can test again! 