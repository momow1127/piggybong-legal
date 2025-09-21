import { serve } from "https://deno.land/std@0.224.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS'
}

interface PushNotificationRequest {
  user_id?: string
  device_tokens?: string[]
  title: string
  body: string
  data?: Record<string, any>
  badge?: number
  sound?: string
  category?: string
  artist_name?: string
  notification_type?: 'concert' | 'album' | 'news' | 'ticket' | 'general'
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  if (req.method !== 'POST') {
    return new Response(
      JSON.stringify({ error: 'Method not allowed' }),
      {
        status: 405,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  }

  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const {
      user_id,
      device_tokens,
      title,
      body,
      data,
      badge = 1,
      sound = 'default',
      category,
      artist_name,
      notification_type = 'general'
    } = await req.json() as PushNotificationRequest

    console.log('🔔 Push notification request:', {
      user_id,
      device_tokens: device_tokens?.length || 0,
      title,
      notification_type
    })

    let targetTokens: string[] = []

    // Get device tokens based on user_id or use provided tokens
    if (user_id && !device_tokens) {
      const { data: userTokens, error } = await supabase
        .from('user_device_tokens')
        .select('device_token, platform')
        .eq('user_id', user_id)
        .eq('active', true)

      if (error) {
        console.error('❌ Error fetching user tokens:', error)
        throw error
      }

      targetTokens = userTokens?.map(t => t.device_token) || []
    } else if (device_tokens) {
      targetTokens = device_tokens
    }

    if (targetTokens.length === 0) {
      return new Response(
        JSON.stringify({
          success: true,
          message: 'No device tokens found',
          sent_count: 0
        }),
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    // Send notifications using our apn-service function
    const supabaseUrl = Deno.env.get('SUPABASE_URL')
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')

    const apnResponse = await fetch(`${supabaseUrl}/functions/v1/apn-service`, {
      method: 'POST',
      headers: {
        'apikey': Deno.env.get('SUPABASE_ANON_KEY') ?? '',
        'Authorization': `Bearer ${supabaseServiceKey}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        device_tokens: targetTokens,
        title,
        body,
        badge,
        sound,
        category,
        data: {
          ...data,
          artist_name,
          notification_type
        }
      })
    })

    let successful = 0
    let failed = 0

    if (apnResponse.ok) {
      const result = await apnResponse.json()
      successful = result.sent_count || 0
      failed = result.failed_count || 0
      console.log(`📊 APN service results: ${successful} sent, ${failed} failed`)
    } else {
      console.error('❌ APN service request failed:', await apnResponse.text())
      failed = targetTokens.length
    }

    // Log notification for analytics
    if (user_id) {
      await supabase
        .from('notification_logs')
        .insert({
          user_id,
          title,
          body,
          notification_type,
          artist_name,
          sent_at: new Date().toISOString(),
          success_count: successful,
          fail_count: failed
        })
    }

    return new Response(
      JSON.stringify({
        success: true,
        sent_count: successful,
        failed_count: failed,
        total_tokens: targetTokens.length
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )

  } catch (error) {
    console.error('❌ Push notification error:', error)
    return new Response(
      JSON.stringify({
        error: 'Failed to send push notification',
        details: error.message
      }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  }
})