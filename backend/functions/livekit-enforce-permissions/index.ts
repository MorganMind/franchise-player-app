import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { RoomServiceClient } from 'https://esm.sh/livekit-server-sdk@1.2.7'

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
    
    const roomService = new RoomServiceClient(
      Deno.env.get('LIVEKIT_HOST') ?? '',
      Deno.env.get('LIVEKIT_API_KEY') ?? '',
      Deno.env.get('LIVEKIT_API_SECRET') ?? ''
    )
    
    // Process sync queue
    const { data: queue } = await supabase
      .from('livekit_sync_queue')
      .select('*')
      .eq('processed', false)
      .order('created_at')
      .limit(100)
    
    let processedCount = 0
    
    for (const item of queue || []) {
      try {
        // Find active sessions
        let query = supabase
          .from('voice_participants')
          .select('*, channels(*), dm_channels(*), franchise_channels(*)')
          .eq('user_id', item.user_id)
        
        if (item.channel_id) {
          query = query.eq('channel_id', item.channel_id)
        } else if (item.franchise_channel_id) {
          query = query.eq('franchise_channel_id', item.franchise_channel_id)
        } else if (item.server_id) {
          query = query.eq('channels.server_id', item.server_id)
        }
        
        const { data: participants } = await query
        
        for (const participant of participants || []) {
          const roomName = participant.channels?.livekit_room_id || 
                          participant.dm_channels?.livekit_room_id ||
                          participant.franchise_channels?.livekit_room_id
          
          if (!roomName || participant.livekit_participant_sid === 'pending') continue
          
          switch (item.action) {
            case 'remove':
              try {
                await roomService.removeParticipant(
                  roomName,
                  participant.livekit_participant_sid
                )
              } catch (error) {
                console.log(`Failed to remove participant: ${error.message}`)
              }
              break
              
            case 'mute':
              try {
                await roomService.mutePublishedTrack(
                  roomName,
                  participant.livekit_participant_sid,
                  'audio',
                  true
                )
              } catch (error) {
                console.log(`Failed to mute participant: ${error.message}`)
              }
              break
              
            case 'unmute':
              try {
                await roomService.mutePublishedTrack(
                  roomName,
                  participant.livekit_participant_sid,
                  'audio',
                  false
                )
              } catch (error) {
                console.log(`Failed to unmute participant: ${error.message}`)
              }
              break
              
            case 'update_permissions':
              // Re-check permissions and update
              if (item.channel_id) {
                const { data: perms } = await supabase
                  .rpc('check_voice_permissions', {
                    p_user_id: item.user_id,
                    p_channel_id: item.channel_id
                  })
                  .single()
                
                if (!perms?.can_connect) {
                  try {
                    await roomService.removeParticipant(
                      roomName,
                      participant.livekit_participant_sid
                    )
                  } catch (error) {
                    console.log(`Failed to remove participant: ${error.message}`)
                  }
                } else {
                  try {
                    await roomService.updateParticipant(
                      roomName,
                      participant.livekit_participant_sid,
                      {
                        permission: {
                          canPublish: perms.can_speak,
                          canPublishVideo: perms.can_video,
                          canPublishScreenshare: perms.can_share_screen,
                        }
                      }
                    )
                  } catch (error) {
                    console.log(`Failed to update participant permissions: ${error.message}`)
                  }
                }
              } else if (item.franchise_channel_id) {
                const { data: perms } = await supabase
                  .rpc('check_franchise_voice_permissions', {
                    p_user_id: item.user_id,
                    p_franchise_channel_id: item.franchise_channel_id
                  })
                  .single()
                
                if (!perms?.can_connect) {
                  try {
                    await roomService.removeParticipant(
                      roomName,
                      participant.livekit_participant_sid
                    )
                  } catch (error) {
                    console.log(`Failed to remove participant: ${error.message}`)
                  }
                } else {
                  try {
                    await roomService.updateParticipant(
                      roomName,
                      participant.livekit_participant_sid,
                      {
                        permission: {
                          canPublish: perms.can_speak,
                          canPublishVideo: perms.can_video,
                          canPublishScreenshare: perms.can_share_screen,
                        }
                      }
                    )
                  } catch (error) {
                    console.log(`Failed to update participant permissions: ${error.message}`)
                  }
                }
              }
              break
          }
        }
        
        // Mark as processed
        await supabase
          .from('livekit_sync_queue')
          .update({ 
            processed: true, 
            processed_at: new Date().toISOString() 
          })
          .eq('id', item.id)
        
        processedCount++
        
      } catch (error) {
        console.error(`Error processing sync item ${item.id}:`, error)
        await supabase
          .from('livekit_sync_queue')
          .update({ 
            error: error.message 
          })
          .eq('id', item.id)
      }
    }
    
    return new Response(
      JSON.stringify({ 
        processed: processedCount,
        message: `Processed ${processedCount} sync queue items`
      }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200 
      }
    )
    
  } catch (error) {
    console.error('Error in permission enforcement:', error)
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500 
      }
    )
  }
}) 