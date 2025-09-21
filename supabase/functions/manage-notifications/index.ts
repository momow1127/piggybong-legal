import { serve } from "https://deno.land/std@0.224.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, GET, OPTIONS, PUT, DELETE',
}

interface NotificationRequest {
  action: 'subscribe' | 'unsubscribe' | 'update_preferences' | 'get_preferences' | 'register_device'
  // Device registration
  device_token?: string
  platform?: 'ios' | 'android'
  device_info?: {
    app_version?: string
    device_model?: string
    os_version?: string
  }
  // Notification preferences
  preferences?: {
    push_notifications_enabled?: boolean
    concert_notifications?: boolean
    album_notifications?: boolean
    news_notifications?: boolean
    ticket_notifications?: boolean
    quiet_hours_start?: string
    quiet_hours_end?: string
    timezone?: string
  }
  // Artist-specific preferences
  artist_preferences?: {
    artist_name: string
    concert_notifications?: boolean
    album_notifications?: boolean
    news_notifications?: boolean
  }[]
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? ''
    )

    // Get authenticated user
    const authorization = req.headers.get('Authorization')
    if (!authorization) {
      throw new Error('No authorization header')
    }

    const { data: { user }, error: userError } = await supabase.auth.getUser(
      authorization.replace('Bearer ', '')
    )

    if (userError || !user) {
      throw new Error('User not authenticated')
    }

    const {
      action,
      device_token,
      platform,
      device_info,
      preferences,
      artist_preferences
    } = await req.json() as NotificationRequest

    console.log(`🔔 Notification management: ${action} for user ${user.id}`)

    switch (action) {
      case 'register_device':
        return await registerDevice(supabase, user.id, device_token!, platform!, device_info)

      case 'subscribe':
      case 'update_preferences':
        return await updatePreferences(supabase, user.id, preferences, device_token, platform)

      case 'unsubscribe':
        return await unsubscribeUser(supabase, user.id)

      case 'get_preferences':
        return await getPreferences(supabase, user.id)

      default:
        throw new Error('Invalid action')
    }

  } catch (error) {
    console.error('❌ Notification management error:', error)
    return new Response(
      JSON.stringify({
        error: error.message
      }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  }
})

async function registerDevice(
  supabase: any,
  userId: string,
  deviceToken: string,
  platform: string,
  deviceInfo?: any
): Promise<Response> {

  // Register or update device token
  const { data, error } = await supabase
    .from('user_device_tokens')
    .upsert({
      user_id: userId,
      device_token: deviceToken,
      platform,
      app_version: deviceInfo?.app_version,
      device_model: deviceInfo?.device_model,
      os_version: deviceInfo?.os_version,
      active: true,
      last_used_at: new Date().toISOString()
    }, {
      onConflict: 'user_id,device_token'
    })
    .select()
    .single()

  if (error) {
    throw error
  }

  console.log(`📱 Device registered for user ${userId}: ${platform} ${deviceToken.substring(0, 8)}...`)

  return new Response(
    JSON.stringify({
      success: true,
      message: 'Device registered successfully',
      device_id: data.id
    }),
    {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    }
  )
}

async function updatePreferences(
  supabase: any,
  userId: string,
  preferences?: any,
  deviceToken?: string,
  platform?: string
): Promise<Response> {

  // Update global notification preferences
  const preferenceData = {
    user_id: userId,
    push_notifications_enabled: preferences?.push_notifications_enabled ?? true,
    concert_notifications: preferences?.concert_notifications ?? true,
    album_notifications: preferences?.album_notifications ?? true,
    news_notifications: preferences?.news_notifications ?? true,
    ticket_notifications: preferences?.ticket_notifications ?? true,
    quiet_hours_start: preferences?.quiet_hours_start,
    quiet_hours_end: preferences?.quiet_hours_end,
    timezone: preferences?.timezone ?? 'UTC',
    updated_at: new Date().toISOString()
  }

  const { data: prefData, error: prefError } = await supabase
    .from('notification_preferences')
    .upsert(preferenceData, { onConflict: 'user_id' })
    .select()
    .single()

  if (prefError) {
    throw prefError
  }

  // Also register device if provided
  if (deviceToken && platform) {
    await supabase
      .from('user_device_tokens')
      .upsert({
        user_id: userId,
        device_token: deviceToken,
        platform,
        active: true,
        last_used_at: new Date().toISOString()
      }, {
        onConflict: 'user_id,device_token'
      })
  }

  console.log(`⚙️ Preferences updated for user ${userId}`)

  return new Response(
    JSON.stringify({
      success: true,
      message: 'Preferences updated successfully',
      preferences: prefData
    }),
    {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    }
  )
}

async function unsubscribeUser(supabase: any, userId: string): Promise<Response> {

  // Disable all notifications
  const { error: prefError } = await supabase
    .from('notification_preferences')
    .upsert({
      user_id: userId,
      push_notifications_enabled: false,
      concert_notifications: false,
      album_notifications: false,
      news_notifications: false,
      ticket_notifications: false,
      updated_at: new Date().toISOString()
    }, { onConflict: 'user_id' })

  if (prefError) {
    throw prefError
  }

  // Deactivate all device tokens
  const { error: tokenError } = await supabase
    .from('user_device_tokens')
    .update({ active: false })
    .eq('user_id', userId)

  if (tokenError) {
    throw tokenError
  }

  console.log(`🔕 User ${userId} unsubscribed from all notifications`)

  return new Response(
    JSON.stringify({
      success: true,
      message: 'Successfully unsubscribed from all notifications'
    }),
    {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    }
  )
}

async function getPreferences(supabase: any, userId: string): Promise<Response> {

  // Get user preferences
  const { data: preferences, error: prefError } = await supabase
    .from('notification_preferences')
    .select('*')
    .eq('user_id', userId)
    .single()

  // Get device tokens
  const { data: devices, error: deviceError } = await supabase
    .from('user_device_tokens')
    .select('*')
    .eq('user_id', userId)
    .eq('active', true)

  // Get artist preferences
  const { data: artistPrefs, error: artistError } = await supabase
    .from('artist_notification_preferences')
    .select('*')
    .eq('user_id', userId)

  return new Response(
    JSON.stringify({
      success: true,
      preferences: preferences || {
        push_notifications_enabled: true,
        concert_notifications: true,
        album_notifications: true,
        news_notifications: true,
        ticket_notifications: true,
        timezone: 'UTC'
      },
      devices: devices || [],
      artist_preferences: artistPrefs || [],
      has_devices: (devices?.length || 0) > 0
    }),
    {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    }
  )
}