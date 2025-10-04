import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const { data: { user } } = await supabaseClient.auth.getUser(
      req.headers.get('Authorization')?.replace('Bearer ', '') ?? ''
    )

    if (!user) {
      throw new Error('Unauthorized')
    }

    const { roomName, participantName } = await req.json()

    if (!roomName || !participantName) {
      throw new Error('Missing roomName or participantName')
    }

    // Check if user has permission to join this voice channel
    const { data: channel, error: channelError } = await supabaseClient
      .from('channels')
      .select('id, server_id, livekit_room_id')
      .eq('livekit_room_id', roomName)
      .single()

    if (channelError || !channel) {
      throw new Error('Voice channel not found')
    }

    // Check if user is a member of the server
    const { data: member, error: memberError } = await supabaseClient
      .from('server_members')
      .select('id')
      .eq('server_id', channel.server_id)
      .eq('user_id', user.id)
      .single()

    if (memberError || !member) {
      throw new Error('Not a member of this server')
    }

    // Check if user is muted in this channel
    const { data: voiceParticipant, error: voiceError } = await supabaseClient
      .from('voice_participants')
      .select('is_muted')
      .eq('channel_id', channel.id)
      .eq('user_id', user.id)
      .single()

    const isMuted = voiceParticipant?.is_muted ?? false

    return new Response(
      JSON.stringify({ 
        canJoin: true, 
        isMuted,
        channelId: channel.id,
        serverId: channel.server_id
      }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      },
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      },
    )
  }
}) 