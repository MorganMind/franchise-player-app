# 🔧 Update Supabase Redirect URLs for Port 3000

## 🚨 Important: Update Your Supabase Configuration

Since we're now running on port 3000, you need to update your Supabase redirect URLs.

## 📋 Steps to Update:

### 1. Go to Supabase Dashboard
- Navigate to your Supabase project
- Go to **Authentication** → **URL Configuration**

### 2. Update Site URL
Change the **Site URL** to:
```
http://localhost:3000
```

### 3. Update Redirect URLs
Replace all existing redirect URLs with these:
```
http://localhost:3000
http://localhost:3000/
http://localhost:3000/auth/callback
http://127.0.0.1:3000
http://127.0.0.1:3000/
http://127.0.0.1:3000/auth/callback
```

### 4. Save Changes
Click **Save** to apply the changes.

## 🎯 Why This is Needed

- Your Flutter app is now running on `http://localhost:3000`
- Supabase needs to know about this new URL for magic link redirects
- Without updating, magic links will fail with "access_denied" errors

## 🔍 After Updating

1. **Go to**: `http://localhost:3000`
2. **You should see the home page** with your authentication status
3. **If not, try logging in again** with magic link

## 🚨 Firefox-Specific Notes

Firefox sometimes handles redirects differently. If you still have issues:

1. **Clear Firefox cache**: Ctrl+Shift+Delete (or Cmd+Shift+Delete on Mac)
2. **Try Chrome** to test if it's a Firefox-specific issue
3. **Check Firefox console** for any errors (F12 → Console)

**Update the URLs in Supabase first, then try accessing `http://localhost:3000`!** 