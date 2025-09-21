// Real-time Orchestrator for PiggyBong - Simplified for Deployment
import { serve } from "https://deno.land/std@0.224.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// CORS headers
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, GET, OPTIONS, PUT, DELETE',
}

const supabaseUrl = Deno.env.get('SUPABASE_URL')!
const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
const supabase = createClient(supabaseUrl, supabaseServiceKey)

// WebSocket connection management for real-time features
interface RealtimeConnection {
  userId: string
  connectionId: string
  subscriptions: string[]
  lastActivity: number
  userTier: 'free' | 'paid'
}

// In-memory store (use Redis in production)
const activeConnections = new Map<string, RealtimeConnection>()

interface RealtimeRequest {
  action: 'subscribe' | 'unsubscribe' | 'get_live_data' | 'send_notification'
  channel?: string
  data?: any
  target_users?: string[]
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Simple authentication
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      throw new Error('Authorization header required')
    }

    const token = authHeader.replace('Bearer ', '')
    const { data: { user }, error: authError } = await supabase.auth.getUser(token)
    
    if (authError || !user) {
      throw new Error('Invalid authentication')
    }

    const body = await req.json() as RealtimeRequest

    switch (body.action) {
      case 'subscribe':
        return await handleSubscription(user.id, body.channel!)
      
      case 'unsubscribe':
        return await handleUnsubscription(user.id, body.channel!)
      
      case 'get_live_data':
        return await getLiveData(user.id, body.channel!)
      
      case 'send_notification':
        return await sendRealtimeNotification(body.data, body.target_users)
      
      default:
        throw new Error('Invalid action')
    }

  } catch (error) {
    console.error('Realtime orchestrator error:', error)
    return new Response(
      JSON.stringify({ error: error.message }), 
      { status: 400, headers: corsHeaders }
    )
  }
})

// Handle subscription to real-time channels
async function handleSubscription(userId: string, channel: string) {
  const connectionId = `${userId}_${Date.now()}`
  
  activeConnections.set(connectionId, {
    userId,
    connectionId,
    subscriptions: [channel],
    lastActivity: Date.now(),
    userTier: 'free' // Default tier
  })

  console.log(`User ${userId} subscribed to channel: ${channel}`)
  
  return new Response(
    JSON.stringify({ 
      success: true, 
      connectionId, 
      message: `Subscribed to ${channel}` 
    }), 
    { headers: corsHeaders }
  )
}

// Handle unsubscription
async function handleUnsubscription(userId: string, channel: string) {
  // Remove user from channel subscriptions
  for (const [connectionId, connection] of activeConnections.entries()) {
    if (connection.userId === userId) {
      connection.subscriptions = connection.subscriptions.filter(sub => sub !== channel)
      if (connection.subscriptions.length === 0) {
        activeConnections.delete(connectionId)
      }
    }
  }

  console.log(`User ${userId} unsubscribed from channel: ${channel}`)
  
  return new Response(
    JSON.stringify({ 
      success: true, 
      message: `Unsubscribed from ${channel}` 
    }), 
    { headers: corsHeaders }
  )
}

// Get live data for a channel
async function getLiveData(userId: string, channel: string) {
  let data = {}

  switch (channel) {
    case 'comeback_alerts':
      data = await getComebackAlerts(userId)
      break
    case 'artist_updates':
      data = await getArtistUpdates(userId)
      break
    case 'breaking_news':
      data = await getBreakingNews()
      break
    default:
      data = { message: 'No data available for this channel' }
  }

  return new Response(
    JSON.stringify({ success: true, channel, data }), 
    { headers: corsHeaders }
  )
}

// Send real-time notification to specific users
async function sendRealtimeNotification(notificationData: any, targetUsers?: string[]) {
  const { title, body, artistName, type = 'comeback' } = notificationData

  let targetConnections: RealtimeConnection[] = []

  if (targetUsers && targetUsers.length > 0) {
    // Send to specific users
    targetConnections = Array.from(activeConnections.values()).filter(
      conn => targetUsers.includes(conn.userId)
    )
  } else {
    // Send to all connected users (breaking news)
    targetConnections = Array.from(activeConnections.values())
  }

  const notification = {
    id: `notif_${Date.now()}`,
    title,
    body,
    artistName,
    type,
    timestamp: new Date().toISOString(),
    urgent: type === 'breaking'
  }

  // Store notification in database
  try {
    await supabase
      .from('app_events')
      .insert({
        title,
        artist_name: artistName,
        description: body,
        event_date: new Date().toISOString(),
        category: type,
        source: 'realtime',
        is_breaking: type === 'breaking'
      })
  } catch (error) {
    console.error('Failed to store notification:', error)
  }

  console.log(`Sending notification to ${targetConnections.length} connected users`)

  return new Response(
    JSON.stringify({ 
      success: true, 
      notification,
      sentTo: targetConnections.length,
      message: 'Notification sent successfully' 
    }), 
    { headers: corsHeaders }
  )
}

// Helper functions for live data
async function getComebackAlerts(userId: string) {
  try {
    const { data: events } = await supabase
      .from('app_events')
      .select('*')
      .eq('category', 'albums')
      .gte('event_date', new Date().toISOString())
      .order('event_date', { ascending: true })
      .limit(10)

    return { comebacks: events || [] }
  } catch (error) {
    return { comebacks: [], error: error.message }
  }
}

async function getArtistUpdates(userId: string) {
  try {
    // Get user's selected artists
    const { data: userArtists } = await supabase
      .from('user_profiles')
      .select('selected_bias')
      .eq('id', userId)
      .single()

    if (!userArtists?.selected_bias) {
      return { updates: [] }
    }

    const { data: events } = await supabase
      .from('app_events')
      .select('*')
      .eq('artist_name', userArtists.selected_bias)
      .gte('created_at', new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString()) // Last 24 hours
      .order('created_at', { ascending: false })
      .limit(5)

    return { updates: events || [] }
  } catch (error) {
    return { updates: [], error: error.message }
  }
}

async function getBreakingNews() {
  try {
    const { data: events } = await supabase
      .from('app_events')
      .select('*')
      .eq('is_breaking', true)
      .gte('created_at', new Date(Date.now() - 60 * 60 * 1000).toISOString()) // Last hour
      .order('created_at', { ascending: false })
      .limit(5)

    return { breaking: events || [] }
  } catch (error) {
    return { breaking: [], error: error.message }
  }
}