import { serve } from "https://deno.land/std@0.224.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, GET, OPTIONS, PUT, DELETE',
}

const supabaseUrl = Deno.env.get('SUPABASE_URL')!
const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
const supabase = createClient(supabaseUrl, supabaseServiceKey)

// Artist social media handles for monitoring
const ARTIST_HANDLES = {
  'G-Dragon': {
    twitter: 'IBGDRGN',
    instagram: 'xxxibgdrgn',
    youtube: 'UCGrKEwgm6CjVRLmO7FYwTVQ'
  },
  'BABYMONSTER': {
    twitter: 'YGBABYMONSTER_',
    instagram: 'babymonster_ygofficial',
    youtube: 'UCceStaRAVoXy4dKZBv2RjYg'
  },
  'BLACKPINK': {
    twitter: 'BLACKPINK',
    instagram: 'blackpinkofficial',
    youtube: 'UCOmHUn--16B90oW2L6FRR3A'
  },
  'BTS': {
    twitter: 'BTS_official',
    instagram: 'bts.bighitofficial',
    youtube: 'UCLkAepWjdylmXSltofFvsYQ'
  },
  'NewJeans': {
    twitter: 'NewJeans_ADOR',
    instagram: 'newjeans_official',
    youtube: 'UCJj5lXNH7eT4NQhNyb3cGwg'
  }
}

// Keywords that indicate important announcements
const ANNOUNCEMENT_KEYWORDS = [
  'tour', 'concert', 'comeback', 'album', 'single', 'release', 'debut',
  'encore', 'world tour', 'asia tour', 'new song', 'mv',
  'music video', 'schedule', 'announcement', 'presale', 'tickets'
]

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    console.log('Starting global artist monitoring...')

    const monitoringResults = []

    // Monitor RSS feeds for K-pop news
    const rssFeeds = [
      'https://www.soompi.com/feed/',
      'https://www.allkpop.com/feed',
      'https://variety.com/c/music/feed/'
    ]

    for (const feedUrl of rssFeeds) {
      try {
        const feedResult = await monitorRSSFeed(feedUrl)
        if (feedResult.newAnnouncements.length > 0) {
          monitoringResults.push({
            source: 'rss',
            feed: feedUrl,
            announcements: feedResult.newAnnouncements
          })
        }
      } catch (error) {
        console.error(`RSS feed error for ${feedUrl}:`, error)
      }
    }

    // Monitor social media (placeholder for now - would need API keys)
    for (const [artistName, handles] of Object.entries(ARTIST_HANDLES)) {
      try {
        const socialResult = await monitorArtistSocial(artistName, handles)
        if (socialResult.newPosts.length > 0) {
          monitoringResults.push({
            source: 'social',
            artist: artistName,
            posts: socialResult.newPosts
          })
        }
      } catch (error) {
        console.error(`Social monitoring error for ${artistName}:`, error)
      }
    }

    // Process and store all new announcements
    let totalProcessed = 0
    for (const result of monitoringResults) {
      if (result.source === 'rss') {
        for (const announcement of result.announcements) {
          await storeAnnouncement(announcement)
          totalProcessed++
        }
      } else if (result.source === 'social') {
        for (const post of result.posts) {
          await storeAnnouncement(post)
          totalProcessed++
        }
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        monitored_sources: rssFeeds.length + Object.keys(ARTIST_HANDLES).length,
        new_announcements: totalProcessed,
        results: monitoringResults,
        timestamp: new Date().toISOString()
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Global monitoring error:', error)
    
    return new Response(
      JSON.stringify({ 
        success: false,
        error: error.message || 'Internal server error'
      }),
      { 
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  }
})

async function monitorRSSFeed(feedUrl: string) {
  const newAnnouncements = []
  
  try {
    const response = await fetch(feedUrl, {
      headers: {
        'User-Agent': 'PiggyBong-Monitor/1.0'
      }
    })
    
    if (!response.ok) {
      throw new Error(`RSS fetch failed: ${response.status}`)
    }
    
    const feedText = await response.text()
    
    // Simple RSS parsing (in production, use a proper XML parser)
    const items = feedText.match(/<item[^>]*>(.*?)<\/item>/gs) || []
    
    for (const item of items.slice(0, 5)) { // Check latest 5 items
      const title = item.match(/<title[^>]*><!\[CDATA\[(.*?)\]\]><\/title>/)?.[1] || 
                   item.match(/<title[^>]*>(.*?)<\/title>/)?.[1] || ''
      const link = item.match(/<link[^>]*>(.*?)<\/link>/)?.[1] || ''
      const pubDate = item.match(/<pubDate[^>]*>(.*?)<\/pubDate>/)?.[1] || ''
      
      // Check if this is a recent announcement (within last 24 hours)
      const articleDate = new Date(pubDate)
      const now = new Date()
      const hoursDiff = (now.getTime() - articleDate.getTime()) / (1000 * 60 * 60)
      
      if (hoursDiff <= 24) {
        // Check if title contains announcement keywords
        const titleLower = title.toLowerCase()
        const hasKeyword = ANNOUNCEMENT_KEYWORDS.some(keyword => 
          titleLower.includes(keyword.toLowerCase())
        )
        
        if (hasKeyword) {
          // Extract artist name from title
          const artistName = extractArtistFromTitle(title)
          
          if (artistName) {
            newAnnouncements.push({
              artist_name: artistName,
              title: title.trim(),
              content: `New announcement: ${title}`,
              source_url: link.trim(),
              update_type: determineUpdateType(title),
              priority: 'high',
              timestamp: articleDate.toISOString()
            })
          }
        }
      }
    }
  } catch (error) {
    console.error(`RSS monitoring error for ${feedUrl}:`, error)
  }
  
  return { newAnnouncements }
}

async function monitorArtistSocial(artistName: string, handles: any) {
  // Placeholder for social media monitoring
  // In production, this would use Twitter API, Instagram API, etc.
  // For now, return empty results
  return { newPosts: [] }
}

function extractArtistFromTitle(title: string): string | null {
  const artistNames = Object.keys(ARTIST_HANDLES)
  
  for (const artist of artistNames) {
    if (title.toLowerCase().includes(artist.toLowerCase())) {
      return artist
    }
  }
  
  // Check for other common artist names
  const commonArtists = [
    'IVE', 'aespa', 'ITZY', 'TWICE', 'Red Velvet', 'Girls Generation',
    'STRAY KIDS', 'SEVENTEEN', 'NCT', 'SHINee', 'EXO', 'BIGBANG',
    'IU', 'Taeyeon', 'LISA', 'JENNIE', 'ROSÉ', 'JISOO'
  ]
  
  for (const artist of commonArtists) {
    if (title.toLowerCase().includes(artist.toLowerCase())) {
      return artist
    }
  }
  
  return null
}

function determineUpdateType(title: string): string {
  const titleLower = title.toLowerCase()
  
  if (titleLower.includes('tour') || titleLower.includes('concert') || titleLower.includes('encore')) {
    return 'tour'
  }
  if (titleLower.includes('album') || titleLower.includes('comeback')) {
    return 'album'
  }
  if (titleLower.includes('single') || titleLower.includes('song') || titleLower.includes('mv')) {
    return 'single'
  }
  if (titleLower.includes('debut')) {
    return 'debut'
  }
  
  return 'general'
}

async function storeAnnouncement(announcement: any) {
  try {
    // Check if we already have this announcement to avoid duplicates
    const { data: existing } = await supabase
      .from('app_events')
      .select('id')
      .eq('title', announcement.title)
      .eq('artist_name', announcement.artist_name)
      .single()
    
    if (existing) {
      console.log('Duplicate announcement skipped:', announcement.title)
      return
    }
    
    // Store new announcement
    const { error } = await supabase
      .from('app_events')
      .insert({
        title: announcement.title,
        artist_name: announcement.artist_name,
        description: announcement.content,
        event_date: announcement.timestamp,
        category: announcement.update_type,
        source: 'global_monitor',
        source_url: announcement.source_url,
        is_breaking: announcement.priority === 'high',
        created_at: new Date().toISOString()
      })
    
    if (error) {
      console.error('Error storing announcement:', error)
    } else {
      console.log('Stored new announcement:', announcement.title)
      
      // Trigger notifications for users who follow this artist
      await triggerArtistNotifications(announcement)
    }
  } catch (error) {
    console.error('Store announcement error:', error)
  }
}

async function triggerArtistNotifications(announcement: any) {
  try {
    // Get users who have this artist as their bias
    const { data: users } = await supabase
      .from('user_profiles')
      .select('id, fcm_token')
      .eq('selected_bias', announcement.artist_name)
      .not('fcm_token', 'is', null)
    
    if (users && users.length > 0) {
      const notifications = users.map(user => ({
        user_id: user.id,
        title: `${announcement.artist_name} News!`,
        body: announcement.title,
        data: {
          artist_name: announcement.artist_name,
          update_type: announcement.update_type,
          source_url: announcement.source_url
        }
      }))
      
      // Store notifications for logging
      const { error } = await supabase
        .from('push_notifications')
        .insert(notifications)

      if (!error) {
        console.log(`Queued ${notifications.length} notifications for ${announcement.artist_name}`)

        // 🚀 NEW: Actually send push notifications via APN service
        for (const notification of notifications) {
          try {
            const response = await fetch(`${supabaseUrl}/functions/v1/send-push-notification`, {
              method: 'POST',
              headers: {
                'Authorization': `Bearer ${supabaseServiceKey}`,
                'Content-Type': 'application/json'
              },
              body: JSON.stringify({
                user_id: notification.user_id,
                title: notification.title,
                body: notification.body,
                data: notification.data,
                notification_type: 'news',
                artist_name: announcement.artist_name
              })
            })

            if (response.ok) {
              const result = await response.json()
              console.log(`✅ Push sent to user ${notification.user_id}: ${result.sent_count} devices`)
            } else {
              console.error(`❌ Failed to send push to user ${notification.user_id}`)
            }
          } catch (pushError) {
            console.error(`❌ Push notification error for user ${notification.user_id}:`, pushError)
          }
        }
      }
    }
  } catch (error) {
    console.error('Notification trigger error:', error)
  }
}