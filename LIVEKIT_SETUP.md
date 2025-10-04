# LiveKit Integration Setup Guide

This guide will help you set up LiveKit voice and video functionality for your Franchise Player app.

## Prerequisites

1. **LiveKit Cloud Account** - [Sign up at LiveKit Cloud](https://cloud.livekit.io/)
2. **Supabase Project** - Your existing Supabase project
3. **Flutter Development Environment** - Your existing Flutter setup

## Step 1: LiveKit Cloud Setup

### 1.1 Create LiveKit Project

1. Go to [LiveKit Cloud](https://cloud.livekit.io/) and sign up/login
2. Create a new project
3. Note down your project details:
   - **Project ID**
   - **API Key**
   - **API Secret**
   - **WebSocket URL** (e.g., `wss://your-project.livekit.cloud`)

### 1.2 Configure LiveKit Project

1. In your LiveKit Cloud dashboard, go to **Settings**
2. Configure the following:
   - **Webhook URL**: `https://your-supabase-project.supabase.co/functions/v1/livekit-webhook`
   - **Webhook Secret**: Generate a secure secret (you'll need this for the webhook)

## Step 2: Database Schema Setup

### 2.1 Run the LiveKit Schema

1. Go to your Supabase Dashboard → SQL Editor
2. Copy and paste the contents of `backend/livekit_schema.sql`
3. Run the script

This will:
- Add `livekit_room_id` columns to existing tables
- Create voice participant tracking tables
- Create permission sync queue
- Set up RLS policies
- Create permission checking functions

### 2.2 Verify Schema

Run this query to verify the setup:

```sql
SELECT 
  'channels' as table_name,
  COUNT(*) as total_channels,
  COUNT(livekit_room_id) as channels_with_voice
FROM channels
UNION ALL
SELECT 
  'dm_channels' as table_name,
  COUNT(*) as total_channels,
  COUNT(livekit_room_id) as channels_with_voice
FROM dm_channels
UNION ALL
SELECT 
  'franchise_channels' as table_name,
  COUNT(*) as total_channels,
  COUNT(livekit_room_id) as channels_with_voice
FROM franchise_channels;
```

## Step 3: Supabase Edge Functions Setup

### 3.1 Deploy Token Generation Function

1. In your Supabase Dashboard, go to **Edge Functions**
2. Create a new function called `generate-livekit-token`
3. Copy the contents of `backend/functions/generate-livekit-token/index.ts`
4. Deploy the function

### 3.2 Deploy Permission Enforcement Function

1. Create another function called `livekit-enforce-permissions`
2. Copy the contents of `backend/functions/livekit-enforce-permissions/index.ts`
3. Deploy the function

### 3.3 Set Environment Variables

In your Supabase Dashboard → Settings → Edge Functions, add these environment variables:

```bash
LIVEKIT_API_KEY=your_livekit_api_key
LIVEKIT_API_SECRET=your_livekit_api_secret
LIVEKIT_URL=wss://your-project.livekit.cloud
LIVEKIT_HOST=https://your-project.livekit.cloud
```

## Step 4: Flutter Setup

### 4.1 Install Dependencies

Run this command in your `frontend` directory:

```bash
flutter pub get
```

### 4.2 Update Supabase Client

Make sure your `frontend/lib/supabase_client.dart` has the correct URL and anon key.

### 4.3 Test the Integration

1. Start your Flutter app:
```bash
cd frontend
flutter run -d web-server --web-port 3000 --web-hostname 0.0.0.0
```

2. Navigate to a voice channel
3. Click "Join" to test voice functionality

## Step 5: Webhook Setup (Optional)

For advanced features like participant tracking and permission enforcement:

### 5.1 Create Webhook Function

Create a new edge function called `livekit-webhook`:

```typescript
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { WebhookReceiver } from 'https://esm.sh/livekit-server-sdk@1.2.7'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    )

    const receiver = new WebhookReceiver(
      Deno.env.get('LIVEKIT_API_KEY') ?? '',
      Deno.env.get('LIVEKIT_API_SECRET') ?? ''
    )

    const body = await req.text()
    const event = receiver.receive(body, req.headers.get('Authorization') ?? '')

    switch (event.event) {
      case 'participant_joined':
        await supabase
          .from('voice_participants')
          .update({ livekit_participant_sid: event.participant.sid })
          .eq('connection_id', event.participant.metadata?.connection_id)
        break

      case 'participant_left':
        await supabase
          .from('voice_participants')
          .delete()
          .eq('livekit_participant_sid', event.participant.sid)
        break
    }

    return new Response('OK', { status: 200 })
  } catch (error) {
    console.error('Webhook error:', error)
    return new Response('Error', { status: 500 })
  }
})
```

### 5.2 Configure Webhook in LiveKit

1. In LiveKit Cloud, go to your project settings
2. Set the webhook URL to: `https://your-supabase-project.supabase.co/functions/v1/livekit-webhook`
3. Add the webhook secret to your Supabase environment variables

## Step 6: Testing

### 6.1 Basic Voice Test

1. Create a voice channel in your app
2. Join the voice channel
3. Test microphone and audio

### 6.2 Permission Test

1. Create a test user with restricted permissions
2. Try to join a voice channel
3. Verify permissions are enforced

### 6.3 Multi-user Test

1. Open multiple browser tabs/windows
2. Join the same voice channel with different users
3. Test voice communication between participants

## Troubleshooting

### Common Issues

1. **"Failed to join voice" error**
   - Check LiveKit credentials in environment variables
   - Verify the edge function is deployed correctly
   - Check browser console for detailed errors

2. **No audio/video**
   - Ensure browser permissions are granted
   - Check if microphone/camera are working in other apps
   - Verify LiveKit room connection status

3. **Permission denied errors**
   - Check database permissions
   - Verify user is a member of the server
   - Check RLS policies

### Debug Commands

Test the token generation function:

```bash
curl -X POST https://your-supabase-project.supabase.co/functions/v1/generate-livekit-token \
  -H "Authorization: Bearer YOUR_USER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"channelId": "your-channel-id"}'
```

Test permission enforcement:

```bash
curl -X POST https://your-supabase-project.supabase.co/functions/v1/livekit-enforce-permissions
```

## Environment Variables Summary

### Supabase Edge Functions
```bash
LIVEKIT_API_KEY=your_livekit_api_key
LIVEKIT_API_SECRET=your_livekit_api_secret
LIVEKIT_URL=wss://your-project.livekit.cloud
LIVEKIT_HOST=https://your-project.livekit.cloud
```

### LiveKit Cloud
- Project ID: `your-project-id`
- WebSocket URL: `wss://your-project.livekit.cloud`
- Webhook URL: `https://your-supabase-project.supabase.co/functions/v1/livekit-webhook`

## Next Steps

1. **Add video support** - Implement video UI components
2. **Screen sharing** - Add screen sharing functionality
3. **Recording** - Implement call recording features
4. **Analytics** - Add voice usage analytics
5. **Mobile support** - Test and optimize for mobile devices

## Support

- [LiveKit Documentation](https://docs.livekit.io/)
- [LiveKit Flutter SDK](https://pub.dev/packages/livekit_client)
- [Supabase Edge Functions](https://supabase.com/docs/guides/functions)
- [WebRTC Browser Support](https://webrtc.github.io/samples/)

## Security Notes

- Never expose API secrets in client-side code
- Use RLS policies to control access
- Validate all user permissions server-side
- Monitor webhook events for security
- Regularly rotate API keys 