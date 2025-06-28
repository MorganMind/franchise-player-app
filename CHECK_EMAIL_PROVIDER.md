# 📧 Check Email Provider Settings

## 🎯 Default Supabase Email Provider

By default, Supabase uses **Resend** as their email provider. Here's how to check and configure it:

## 📋 Step 1: Check Current Email Provider

### Go to Your Supabase Dashboard
1. Open: https://supabase.com/dashboard/project/fxbpsuisqzffyggihvin
2. Navigate to **Authentication** → **Settings**
3. Look for **SMTP Settings** or **Email Provider**

## 📋 Step 2: Default Configuration

### Supabase Default Email Provider
- **Provider**: Resend (handled by Supabase)
- **From Email**: `noreply@supabase.co` or similar
- **No SMTP configuration needed** (handled automatically)

## 📋 Step 3: Check Email Template

### Go to Authentication → Email Templates
1. Click on **Magic Link** template
2. Check the **Subject** and **Content**
3. Make sure it looks like this:

**Subject**: `Confirm your signup`
**Content**: Should contain a magic link that looks like:
```
https://fxbpsuisqzffyggihvin.supabase.co/auth/v1/verify?token=...
```

## 📋 Step 4: Test Email Delivery

### Check Your Email
1. **Look in your inbox** for emails from `noreply@supabase.co`
2. **Check spam/junk folder** - Supabase emails sometimes go there
3. **Check all email folders** - Gmail, Outlook, etc.

## 🚨 Common Email Issues

### Issue: No email received
- **Check spam folder**
- **Wait 1-2 minutes** (sometimes there's a delay)
- **Try a different email address** (Gmail, Outlook, etc.)

### Issue: Email in spam
- **Mark as "Not Spam"** in your email client
- **Add `noreply@supabase.co` to contacts**

### Issue: Wrong email template
- **Check the Magic Link template** in Supabase dashboard
- **Make sure the redirect URL is correct**

## 🔧 Alternative: Configure Custom SMTP

If you want to use your own email provider:

### Go to Authentication → Settings → SMTP
1. **Enable SMTP**
2. **Configure your email provider** (Gmail, SendGrid, etc.)
3. **Test the configuration**

## 🎯 Quick Test

1. **Go to your Flutter app**: http://localhost:8080
2. **Enter your email** and click "Send Magic Link"
3. **Check your email immediately** (within 1-2 minutes)
4. **Look for email from**: `noreply@supabase.co`

## 📞 Need Help?

If you're still not receiving emails:
1. **Check Supabase logs** in the dashboard
2. **Try with a different email address**
3. **Contact Supabase support** if needed

Let me know what you find in your Supabase email settings! 