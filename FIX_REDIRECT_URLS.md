# 🔧 Fix Supabase Redirect URL Configuration

The "otp_expired" error is happening because the redirect URLs in your Supabase project aren't configured correctly.

## 🎯 Step-by-Step Fix

### Step 1: Go to Supabase Dashboard
1. Open: https://supabase.com/dashboard/project/fxbpsuisqzffyggihvin
2. Sign in if needed

### Step 2: Navigate to URL Configuration
1. In the left sidebar, click **Authentication**
2. Click **URL Configuration**

### Step 3: Update Site URL
Set **Site URL** to:
```
http://localhost:8080
```

### Step 4: Add Redirect URLs
In the **Redirect URLs** section, add these URLs (one per line):
```
http://localhost:8080
http://localhost:8080/
http://localhost:8080/auth/callback
http://localhost:8080/#/auth/callback
http://127.0.0.1:8080
http://127.0.0.1:8080/
http://127.0.0.1:8080/auth/callback
```

### Step 5: Save Changes
1. Click **Save** at the bottom of the page
2. Wait for the changes to apply (may take a few seconds)

## 🔍 Alternative: Check Email Template

### Go to Authentication → Email Templates
1. Click on **Magic Link** template
2. Check the **Content** section
3. Make sure the redirect URL in the template matches your site URL

## 🧪 Test the Fix

### Step 1: Restart Flutter App
```bash
# Stop the current app
pkill -f "flutter run"

# Start it again
cd frontend
export PATH="$PATH:$PWD/../flutter/bin"
flutter run -d web-server --web-port 8080
```

### Step 2: Test Magic Link
1. Go to http://localhost:8080
2. Enter your email
3. Click "Send Magic Link"
4. Check your email immediately
5. Click the magic link right away

## 🚨 If Still Not Working

### Check Browser Console
1. Open browser console (F12)
2. Look for any error messages
3. Check the Network tab for failed requests

### Try Different Approach
If redirect URLs still don't work, try:
1. **Clear browser cache**
2. **Use incognito/private window**
3. **Try a different browser**

### Manual URL Test
1. Copy the magic link from your email
2. Open it in a new tab
3. See what error you get

## 🎯 What Should Happen

After fixing redirect URLs:
- ✅ Magic link email received
- ✅ Clicking link redirects to http://localhost:8080
- ✅ No "otp_expired" error
- ✅ You see the dashboard with green "Get JWT Token" button

## 📞 Still Having Issues?

If it still doesn't work:
1. **Check Supabase logs** in the dashboard
2. **Try with a different email address**
3. **Contact Supabase support**

**The key is getting the redirect URLs configured correctly in your Supabase project settings!** 