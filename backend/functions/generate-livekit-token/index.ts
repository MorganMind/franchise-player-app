import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { AccessToken, VideoGrant } from 'https://esm.sh/livekit-server-sdk@1.2.7'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface TokenRequest {
  channelId?: string
  dmChannelId?: string
  franchiseChannelId?: string
  roomName?: string // Optional override
}

interface VoicePermissions {
  can_connect: boolean
  can_speak: boolean
  can_video: boolean
  can_share_screen: boolean
  can_priority_speaker: boolean
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  if (!req.headers.get('Authorization')) {
    return new Response(
      JSON.stringify({ error: 'Missing Authorization header' }),
      { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        global: {
          headers: { Authorization: req.headers.get('Authorization')! },
        },
      }
    )

    // Get user
    const {
      data: { user },
      error: userError,
    } = await supabaseClient.auth.getUser()

    if (userError || !user) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Parse request
    const { channelId, dmChannelId, franchiseChannelId, roomName } = await req.json() as TokenRequest

    if (!channelId && !dmChannelId && !franchiseChannelId) {
      return new Response(
        JSON.stringify({ error: 'Missing channelId, dmChannelId, or franchiseChannelId' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    let permissions: VoicePermissions
    let roomNameToUse: string
    let connectionId: string

    if (channelId) {
      // Server channel
      console.log(`Checking permissions for channel: ${channelId}, user: ${user.id}`)
      
      const { data: channelData, error: channelError } = await supabaseClient
        .rpc('check_voice_permissions', {
          p_user_id: user.id,
          p_channel_id: channelId
        })
        .single()

      if (channelError) {
        console.error('Permission check error:', channelError)
        return new Response(
          JSON.stringify({ error: `Permission check failed: ${channelError.message}` }),
          { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }

      if (!channelData) {
        console.error('No permission data returned for channel:', channelId)
        return new Response(
          JSON.stringify({ error: 'Channel not found or access denied' }),
          { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }

      permissions = channelData as VoicePermissions

      if (!permissions.can_connect) {
        return new Response(
          JSON.stringify({ error: 'No voice connect permission' }),
          { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }

      // Get channel details for room ID
      console.log(`Fetching channel details for: ${channelId}`)
      const { data: channel, error: channelDetailError } = await supabaseClient
        .from('channels')
        .select('livekit_room_id, name, server_id, type')
        .eq('id', channelId)
        .single()

      if (channelDetailError) {
        console.error('Channel detail error:', channelDetailError)
        return new Response(
          JSON.stringify({ error: `Channel not found: ${channelDetailError.message}` }),
          { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }

      if (!channel) {
        console.error('Channel not found in database:', channelId)
        return new Response(
          JSON.stringify({ error: 'Channel not found' }),
          { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }

      console.log('Channel found:', { id: channelId, name: channel.name, type: channel.type, livekit_room_id: channel.livekit_room_id })

      if (channel.type === 'text') {
        return new Response(
          JSON.stringify({ error: 'Channel does not support voice' }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }

      // Generate or use existing LiveKit room ID
      if (!channel.livekit_room_id) {
        roomNameToUse = `channel_${channelId}`
        console.log(`Generating new livekit_room_id: ${roomNameToUse}`)
        await supabaseClient
          .from('channels')
          .update({ livekit_room_id: roomNameToUse })
          .eq('id', channelId)
      } else {
        roomNameToUse = channel.livekit_room_id
        console.log(`Using existing livekit_room_id: ${roomNameToUse}`)
      }

    } else if (dmChannelId) {
      // DM channel
      const { data: participant } = await supabaseClient
        .from('dm_participants')
        .select('*')
        .eq('dm_channel_id', dmChannelId)
        .eq('user_id', user.id)
        .single()

      if (!participant) {
        return new Response(
          JSON.stringify({ error: 'Not a participant in this DM' }),
          { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }

      // DMs have all permissions
      permissions = {
        can_connect: true,
        can_speak: true,
        can_video: true,
        can_share_screen: true,
        can_priority_speaker: false
      }

      // Get or create DM channel room
      const { data: dmChannel } = await supabaseClient
        .from('dm_channels')
        .select('livekit_room_id')
        .eq('id', dmChannelId)
        .single()

      if (!dmChannel?.livekit_room_id) {
        roomNameToUse = `dm_${dmChannelId}`
        await supabaseClient
          .from('dm_channels')
          .update({ 
            livekit_room_id: roomNameToUse,
            call_active: true 
          })
          .eq('id', dmChannelId)
      } else {
        roomNameToUse = dmChannel.livekit_room_id
      }

    } else if (franchiseChannelId) {
      // Franchise channel
      const { data: channelData, error: channelError } = await supabaseClient
        .rpc('check_franchise_voice_permissions', {
          p_user_id: user.id,
          p_franchise_channel_id: franchiseChannelId
        })
        .single()

      if (channelError || !channelData) {
        return new Response(
          JSON.stringify({ error: 'Franchise channel not found or access denied' }),
          { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }

      permissions = channelData as VoicePermissions

      if (!permissions.can_connect) {
        return new Response(
          JSON.stringify({ error: 'No voice connect permission' }),
          { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }

      // Get franchise channel details
      const { data: franchiseChannel, error: channelDetailError } = await supabaseClient
        .from('franchise_channels')
        .select('livekit_room_id, name, type')
        .eq('id', franchiseChannelId)
        .single()

      if (channelDetailError || !franchiseChannel) {
        return new Response(
          JSON.stringify({ error: 'Franchise channel not found' }),
          { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }

      if (franchiseChannel.type === 'text') {
        return new Response(
          JSON.stringify({ error: 'Franchise channel does not support voice' }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }

      // Generate or use existing LiveKit room ID
      if (!franchiseChannel.livekit_room_id) {
        roomNameToUse = `franchise_${franchiseChannelId}`
        await supabaseClient
          .from('franchise_channels')
          .update({ livekit_room_id: roomNameToUse })
          .eq('id', franchiseChannelId)
      } else {
        roomNameToUse = franchiseChannel.livekit_room_id
      }

    } else {
      throw new Error('No channel specified')
    }

    // Get user profile for display name
    const { data: profile } = await supabaseClient
      .from('user_profiles')
      .select('username, display_name, avatar_url')
      .eq('id', user.id)
      .single()

    // Create LiveKit access token
    const apiKey = Deno.env.get('LIVEKIT_API_KEY')
    const apiSecret = Deno.env.get('LIVEKIT_API_SECRET')

    if (!apiKey || !apiSecret) {
      throw new Error('LiveKit credentials not configured')
    }

    const at = new AccessToken(apiKey, apiSecret, {
      identity: user.id,
      name: profile?.display_name || profile?.username || 'Anonymous',
      metadata: JSON.stringify({
        user_id: user.id,
        username: profile?.username,
        avatar_url: profile?.avatar_url,
        channel_id: channelId,
        dm_channel_id: dmChannelId,
        franchise_channel_id: franchiseChannelId,
      }),
    })

    const grant: VideoGrant = {
      roomJoin: true,
      room: roomName || roomNameToUse,
      canPublish: permissions.can_speak,
      canPublishData: true,
      canSubscribe: true,
      canUpdateOwnMetadata: true,
    }

    // Set initial publish permissions based on channel perms
    if (!permissions.can_speak) {
      grant.canPublishAudio = false
    }
    if (!permissions.can_video) {
      grant.canPublishVideo = false
    }
    if (!permissions.can_share_screen) {
      grant.canPublishScreenshare = false
    }

    at.addGrant(grant)

    // Generate connection ID
    connectionId = crypto.randomUUID()

    // Record participant join
    await supabaseClient.from('voice_participants').insert({
      channel_id: channelId,
      dm_channel_id: dmChannelId,
      franchise_channel_id: franchiseChannelId,
      user_id: user.id,
      livekit_participant_sid: 'pending', // Will be updated by webhook
      connection_id: connectionId,
    })

    return new Response(
      JSON.stringify({
        token: at.toJwt(),
        url: Deno.env.get('LIVEKIT_URL') ?? '',
        roomId: roomName || roomNameToUse,
        connectionId,
        permissions: {
          canSpeak: permissions.can_speak,
          canVideo: permissions.can_video,
          canShareScreen: permissions.can_share_screen,
          isPrioritySpeaker: permissions.can_priority_speaker,
        },
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error('Error generating LiveKit token:', error)
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})