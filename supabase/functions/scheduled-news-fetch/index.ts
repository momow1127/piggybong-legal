import { serve } from 'https://deno.land/std@0.224.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    const supabase = createClient(supabaseUrl, supabaseKey)

    // Get all unique artists that users are following (leveraging 3-artist constraint)
    const { data: userArtists, error: userArtistsError } = await supabase
      .from('user_artists')
      .select(`
        artist_id,
        artists (id, name, priority_level, keywords),
        COUNT(*) OVER (PARTITION BY artist_id) as follower_count
      `)
      .eq('is_active', true)
      .order('priority_rank', { ascending: true })
      .limit(150) // Max 50 users × 3 artists = 150 entries
    
    if (userArtistsError) {
      throw userArtistsError
    }
    
    // Group by artist and prioritize by follower count and artist priority
    const artistMap = new Map()
    userArtists?.forEach(ua => {
      const artist = ua.artists
      if (!artistMap.has(artist.id)) {
        artistMap.set(artist.id, {
          ...artist,
          follower_count: ua.follower_count,
          priority_weight: (ua.follower_count * 10) + (4 - artist.priority_level) // Higher priority = lower number
        })
      }
    })
    
    // Sort artists by priority weight for optimal processing order
    const artists = Array.from(artistMap.values())
      .sort((a, b) => b.priority_weight - a.priority_weight)
      .slice(0, 30) // Process top 30 most important artists

    if (artistsError) {
      throw artistsError
    }

    const results = []

    // Fetch news for each artist
    for (const artist of artists || []) {
      try {
        // HIGH PRIORITY: Always fetch Spotify releases and high-priority RSS
        const highPriorityResponse = await fetch(`${supabaseUrl}/functions/v1/fetch-idol-news`, {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${supabaseKey}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            artistName: artist.name,
            artistId: artist.id,
            sources: ['spotify', 'rss'],
            priorityFilter: 'high',
            useCache: true
          })
        })

        // MEDIUM PRIORITY: Fetch concerts with smart scheduling (less frequent)
        const mediumPriorityResponse = await fetch(`${supabaseUrl}/functions/v1/fetch-idol-news`, {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${supabaseKey}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            artistName: artist.name,
            artistId: artist.id,
            sources: ['ticketmaster'],
            priorityFilter: 'medium_high',
            useCache: true
          })
        })

        const highResult = await highPriorityResponse.json()
        const mediumResult = await mediumPriorityResponse.json()
        
        results.push({
          artist: artist.name,
          high_priority: {
            success: highResult.success,
            count: highResult.count || 0
          },
          medium_priority: {
            success: mediumResult.success,
            count: mediumResult.count || 0
          },
          total_count: (highResult.count || 0) + (mediumResult.count || 0)
        })

        // Dynamic delay based on artist priority and follower count
        const delay = artist.priority_level === 1 ? 500 : 1500 // High priority artists processed faster
        await new Promise(resolve => setTimeout(resolve, delay))
      } catch (error) {
        console.error(`Error fetching news for ${artist.name}:`, error)
        results.push({
          artist: artist.name,
          success: false,
          error: error.message
        })
      }
    }

    // Intelligent cleanup with priority preservation
    const cleanupResults = await performIntelligentCleanup(supabase)
    
    // Cleanup expired cache entries
    const cacheCleanupCount = await supabase.rpc('cleanup_expired_cache')

    // Send notifications for priority news
    const notificationResults = await sendUrgentNotifications(supabase)

    return new Response(
      JSON.stringify({
        success: true,
        processed: results.length,
        results: results,
        cleanup: cleanupResults,
        cache_cleaned: cacheCleanupCount,
        notifications: notificationResults,
        total_artists_processed: artists.length,
        artists_by_priority: artists.reduce((acc, artist) => {
          acc[`priority_${artist.priority_level}`] = (acc[`priority_${artist.priority_level}`] || 0) + 1
          return acc
        }, {} as Record<string, number>)
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      }
    )
  }
})

async function performIntelligentCleanup(supabase: any) {
  try {
    // Keep high priority news for 60 days, normal for 30 days, low for 7 days
    const cleanupResults = {
      urgent: 0,
      high: 0,
      normal: 0,
      low: 0
    }
    
    // Clean low priority news older than 7 days
    const sevenDaysAgo = new Date()
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7)
    
    const { error: lowCleanError, count: lowCount } = await supabase
      .from('idol_news')
      .delete({ count: 'exact' })
      .eq('priority', 'low')
      .lt('created_at', sevenDaysAgo.toISOString())
    
    if (!lowCleanError) cleanupResults.low = lowCount || 0
    
    // Clean normal priority news older than 30 days
    const thirtyDaysAgo = new Date()
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30)
    
    const { error: normalCleanError, count: normalCount } = await supabase
      .from('idol_news')
      .delete({ count: 'exact' })
      .eq('priority', 'normal')
      .lt('created_at', thirtyDaysAgo.toISOString())
    
    if (!normalCleanError) cleanupResults.normal = normalCount || 0
    
    // Clean high priority news older than 60 days  
    const sixtyDaysAgo = new Date()
    sixtyDaysAgo.setDate(sixtyDaysAgo.getDate() - 60)
    
    const { error: highCleanError, count: highCount } = await supabase
      .from('idol_news')
      .delete({ count: 'exact' })
      .eq('priority', 'high')
      .lt('created_at', sixtyDaysAgo.toISOString())
    
    if (!highCleanError) cleanupResults.high = highCount || 0
    
    // Keep urgent news for 90 days
    const ninetyDaysAgo = new Date()
    ninetyDaysAgo.setDate(ninetyDaysAgo.getDate() - 90)
    
    const { error: urgentCleanError, count: urgentCount } = await supabase
      .from('idol_news')
      .delete({ count: 'exact' })
      .eq('priority', 'urgent')
      .lt('created_at', ninetyDaysAgo.toISOString())
    
    if (!urgentCleanError) cleanupResults.urgent = urgentCount || 0
    
    return cleanupResults
  } catch (error) {
    console.error('Error in intelligent cleanup:', error)
    return { error: error.message }
  }
}

async function sendUrgentNotifications(supabase: any) {
  try {
    // Get urgent and high priority news from last 2 hours that haven't been notified
    const twoHoursAgo = new Date()
    twoHoursAgo.setHours(twoHoursAgo.getHours() - 2)

    const { data: priorityNews, error } = await supabase
      .from('idol_news')
      .select('*')
      .in('priority', ['urgent', 'high'])
      .gte('created_at', twoHoursAgo.toISOString())
      .not('metadata', 'cs', '{"notified": true}')

    if (error) {
      console.error('Error fetching priority news:', error)
      return { notifications_sent: 0 }
    }

    let notificationCount = 0

    for (const news of priorityNews || []) {
      // Get users following this artist who want notifications
      const { data: users } = await supabase
        .from('user_artists')
        .select(`
          user_id,
          user_news_preferences!inner(
            notification_threshold
          )
        `)
        .eq('artist_id', news.artist_id)
        .eq('is_active', true)
        // Only notify users whose threshold allows this priority level
        .or(`user_news_preferences.notification_threshold.eq.${news.priority},user_news_preferences.notification_threshold.eq.high,user_news_preferences.notification_threshold.eq.normal`)

      for (const user of users || []) {
        // Check if user hasn't already been notified about this news
        const { data: existingNotification } = await supabase
          .from('news_notifications')
          .select('id')
          .eq('user_id', user.user_id)
          .eq('news_id', news.id)
          .single()

        if (!existingNotification) {
          // Create notification record
          await supabase
            .from('news_notifications')
            .insert({
              user_id: user.user_id,
              news_id: news.id,
              notification_type: news.priority === 'urgent' ? 'urgent' : news.news_type
            })

          notificationCount++

          // 🚀 NEW: Actually send push notification via APN service
          try {
            const supabaseUrl = Deno.env.get('SUPABASE_URL')
            const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')

            const response = await fetch(`${supabaseUrl}/functions/v1/send-push-notification`, {
              method: 'POST',
              headers: {
                'Authorization': `Bearer ${supabaseServiceKey}`,
                'Content-Type': 'application/json'
              },
              body: JSON.stringify({
                user_id: user.user_id,
                title: `${news.artist_name} News! 📰`,
                body: news.title,
                data: {
                  artist_name: news.artist_name,
                  news_id: news.id,
                  url: news.url
                },
                notification_type: 'news',
                artist_name: news.artist_name
              })
            })

            if (response.ok) {
              const result = await response.json()
              console.log(`✅ Push sent to user ${user.user_id}: ${result.sent_count} devices`)
            } else {
              console.error(`❌ Failed to send push to user ${user.user_id}`)
            }
          } catch (pushError) {
            console.error(`❌ Push notification error for user ${user.user_id}:`, pushError)
          }
        }
      }

      // Mark news as notified in metadata
      const updatedMetadata = { ...news.metadata, notified: true }
      await supabase
        .from('idol_news')
        .update({ metadata: updatedMetadata })
        .eq('id', news.id)
    }
    
    return { notifications_sent: notificationCount }
  } catch (error) {
    console.error('Error sending notifications:', error)
    return { error: error.message }
  }
}