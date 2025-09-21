import { serve } from 'https://deno.land/std@0.224.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// API Keys (store in environment variables)
const SPOTIFY_CLIENT_ID = Deno.env.get('SPOTIFY_CLIENT_ID') ?? ''
const SPOTIFY_CLIENT_SECRET = Deno.env.get('SPOTIFY_CLIENT_SECRET') ?? ''
const TICKETMASTER_API_KEY = Deno.env.get('TICKETMASTER_API_KEY') ?? ''

// Priority Keywords Configuration
const PRIORITY_KEYWORDS = {
  HIGH: ['comeback', 'album', 'debut', 'release', 'mv', 'music video', 'single', 'new song'],
  MEDIUM: ['tour', 'concert', 'fanmeet', 'interview', 'performance', 'award', 'collaboration', 'collab', 'feature'],
  LOW: ['mention', 'spotted', 'fashion', 'airport', 'instagram', 'twitter', 'social']
}

// Cache configuration
const CACHE_TTL = {
  SPOTIFY_TOKEN: 3600, // 1 hour
  RSS_FEEDS: 1800, // 30 minutes
  TICKETMASTER: 3600 // 1 hour
}

// Rate limiting configuration
const RATE_LIMITS = {
  SPOTIFY: { requests: 100, window: 60000 }, // 100 req/min
  TICKETMASTER: { requests: 5, window: 1000 }, // 5 req/sec
  RSS: { requests: 10, window: 60000 } // 10 req/min
}

const rateLimiters = new Map()

interface IdolNewsRequest {
  artistName: string
  artistId?: string
  sources?: ('spotify' | 'rss' | 'ticketmaster')[]
  userId?: string
  priorityFilter?: 'all' | 'high' | 'medium_high'
  useCache?: boolean
}

interface CachedResult {
  data: any[]
  timestamp: number
  ttl: number
}

interface RateLimiter {
  requests: number
  window: number
  timestamps: number[]
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

    const { 
      artistName, 
      artistId, 
      sources = ['spotify', 'rss', 'ticketmaster'],
      userId,
      priorityFilter = 'all',
      useCache = true
    } = await req.json() as IdolNewsRequest

    if (!artistName) {
      throw new Error('Artist name is required')
    }

    // Check cache first for efficiency
    const cacheKey = `news:${artistName}:${sources.join(',')}`
    let newsItems: any[] = []
    
    if (useCache) {
      const cachedResult = await getCachedResult(supabase, cacheKey)
      if (cachedResult) {
        newsItems = cachedResult
      }
    }
    
    if (newsItems.length === 0) {
      // Check rate limits before fetching
      for (const source of sources) {
        if (!checkRateLimit(source)) {
          console.warn(`Rate limit exceeded for ${source}, skipping...`)
          sources.splice(sources.indexOf(source), 1)
        }
      }
      
      // Get user's followed artists for priority context
      const userArtists = userId ? await getUserFollowedArtists(supabase, userId) : []
      const isFollowedArtist = userArtists.some(ua => ua.artist_name === artistName)
      
      // Fetch from multiple sources with priority-based scheduling
      const fetchPromises = []
      
      // HIGH PRIORITY: Always fetch (Spotify releases + RSS with high keywords)
      if (sources.includes('spotify')) {
        fetchPromises.push(fetchSpotifyNews(artistName, artistId, isFollowedArtist))
      }
      if (sources.includes('rss')) {
        fetchPromises.push(fetchRSSNews(artistName, priorityFilter, isFollowedArtist))
      }
      
      // MEDIUM PRIORITY: Fetch less frequently (Ticketmaster concerts)
      if (sources.includes('ticketmaster')) {
        const shouldFetchConcerts = await shouldFetchMediumPriority(supabase, artistName, 'ticketmaster')
        if (shouldFetchConcerts) {
          fetchPromises.push(fetchTicketmasterEvents(artistName, artistId, isFollowedArtist))
        }
      }
      
      const results = await Promise.allSettled(fetchPromises)
      
      // Combine and filter news items by priority
      results.forEach((result) => {
        if (result.status === 'fulfilled' && result.value) {
          newsItems.push(...result.value)
        }
      })
      
      // Apply priority filtering
      newsItems = filterByPriority(newsItems, priorityFilter)
      
      // Cache the results
      if (useCache && newsItems.length > 0) {
        await setCachedResult(supabase, cacheKey, newsItems, CACHE_TTL.RSS_FEEDS)
      }
    }

    // Store news items in database
    if (newsItems.length > 0) {
      const { error: insertError } = await supabase
        .from('idol_news')
        .upsert(newsItems, { 
          onConflict: 'source,source_url',
          ignoreDuplicates: true 
        })

      if (insertError) {
        console.error('Error inserting news:', insertError)
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        count: newsItems.length,
        items: newsItems
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

// Helper Functions
async function getCachedResult(supabase: any, key: string): Promise<any[] | null> {
  try {
    const { data, error } = await supabase
      .from('news_cache')
      .select('data, created_at, ttl')
      .eq('cache_key', key)
      .single()
    
    if (error || !data) return null
    
    const now = Date.now()
    const cacheTime = new Date(data.created_at).getTime()
    
    if (now - cacheTime > data.ttl * 1000) {
      // Cache expired, delete it
      await supabase.from('news_cache').delete().eq('cache_key', key)
      return null
    }
    
    return data.data
  } catch (error) {
    console.error('Cache read error:', error)
    return null
  }
}

async function setCachedResult(supabase: any, key: string, data: any[], ttl: number): Promise<void> {
  try {
    await supabase
      .from('news_cache')
      .upsert({
        cache_key: key,
        data: data,
        ttl: ttl,
        created_at: new Date().toISOString()
      })
  } catch (error) {
    console.error('Cache write error:', error)
  }
}

async function getUserFollowedArtists(supabase: any, userId: string) {
  try {
    const { data, error } = await supabase
      .from('user_artists')
      .select('artist_id, artists(name)')
      .eq('user_id', userId)
      .eq('is_active', true)
      .limit(3) // MVP constraint
    
    if (error) return []
    return data.map((ua: any) => ({ artist_name: ua.artists.name, artist_id: ua.artist_id }))
  } catch (error) {
    console.error('Error fetching user artists:', error)
    return []
  }
}

function checkRateLimit(source: string): boolean {
  const config = RATE_LIMITS[source.toUpperCase() as keyof typeof RATE_LIMITS]
  if (!config) return true
  
  const now = Date.now()
  const rateLimiter = rateLimiters.get(source) || {
    requests: config.requests,
    window: config.window,
    timestamps: []
  }
  
  // Remove old timestamps outside the window
  rateLimiter.timestamps = rateLimiter.timestamps.filter(ts => now - ts < config.window)
  
  if (rateLimiter.timestamps.length >= config.requests) {
    return false
  }
  
  rateLimiter.timestamps.push(now)
  rateLimiters.set(source, rateLimiter)
  return true
}

function calculatePriority(content: string, newsType: string, isFollowedArtist: boolean = false): string {
  const lowerContent = content.toLowerCase()
  
  // High priority for followed artists
  if (isFollowedArtist) {
    if (newsType === 'release' || newsType === 'concert') return 'urgent'
    if (PRIORITY_KEYWORDS.HIGH.some(keyword => lowerContent.includes(keyword))) {
      return 'high'
    }
  }
  
  // Check priority keywords
  if (PRIORITY_KEYWORDS.HIGH.some(keyword => lowerContent.includes(keyword))) {
    return newsType === 'release' || newsType === 'concert' ? 'high' : 'normal'
  }
  
  if (PRIORITY_KEYWORDS.MEDIUM.some(keyword => lowerContent.includes(keyword))) {
    return 'normal'
  }
  
  if (PRIORITY_KEYWORDS.LOW.some(keyword => lowerContent.includes(keyword))) {
    return 'low'
  }
  
  return 'normal'
}

function filterByPriority(items: any[], filter: string): any[] {
  if (filter === 'all') return items
  
  const priorityOrder = ['urgent', 'high', 'normal', 'low']
  
  if (filter === 'high') {
    return items.filter(item => ['urgent', 'high'].includes(item.priority))
  }
  
  if (filter === 'medium_high') {
    return items.filter(item => ['urgent', 'high', 'normal'].includes(item.priority))
  }
  
  return items
}

// Spotify API Integration
async function fetchSpotifyNews(artistName: string, artistId?: string, isFollowedArtist: boolean = false): Promise<any[]> {
  try {
    // Get Spotify access token
    const tokenResponse = await fetch('https://accounts.spotify.com/api/token', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Authorization': 'Basic ' + btoa(`${SPOTIFY_CLIENT_ID}:${SPOTIFY_CLIENT_SECRET}`)
      },
      body: 'grant_type=client_credentials'
    })

    const { access_token } = await tokenResponse.json()

    // Search for artist
    const searchResponse = await fetch(
      `https://api.spotify.com/v1/search?q=${encodeURIComponent(artistName)}&type=artist&limit=1`,
      {
        headers: {
          'Authorization': `Bearer ${access_token}`
        }
      }
    )

    const searchData = await searchResponse.json()
    const spotifyArtist = searchData.artists?.items?.[0]

    if (!spotifyArtist) {
      return []
    }

    // Get latest releases
    const albumsResponse = await fetch(
      `https://api.spotify.com/v1/artists/${spotifyArtist.id}/albums?include_groups=album,single&limit=5`,
      {
        headers: {
          'Authorization': `Bearer ${access_token}`
        }
      }
    )

    const albumsData = await albumsResponse.json()
    const newsItems = []

    for (const album of albumsData.items || []) {
      newsItems.push({
        artist_id: artistId,
        artist_name: artistName,
        title: `New ${album.album_type}: ${album.name}`,
        description: `${artistName} released ${album.name} on ${album.release_date}`,
        source: 'spotify',
        source_url: album.external_urls?.spotify,
        image_url: album.images?.[0]?.url,
        news_type: 'release',
        priority: calculateSpotifyPriority(album, isFollowedArtist),
        event_date: album.release_date,
        metadata: {
          spotify_id: album.id,
          album_type: album.album_type,
          total_tracks: album.total_tracks
        }
      })
    }

    return newsItems
  } catch (error) {
    console.error('Spotify API error:', error)
    return []
  }
}

function calculateSpotifyPriority(album: any, isFollowedArtist: boolean): string {
  const isRecent = isRecentRelease(album.release_date)
  
  if (isFollowedArtist && isRecent) return 'urgent'
  if (isRecent) return 'high'
  if (isFollowedArtist) return 'high'
  return 'normal'
}

// RSS Feed Integration with Priority Filtering
async function fetchRSSNews(artistName: string, priorityFilter: string = 'all', isFollowedArtist: boolean = false): Promise<any[]> {
  try {
    // K-pop news RSS feeds
    const feeds = [
      `https://www.allkpop.com/feed`,
      `https://www.soompi.com/feed`,
      `https://www.koreaboo.com/feed/`
    ]

    const newsItems = []
    
    for (const feedUrl of feeds) {
      try {
        const response = await fetch(feedUrl)
        const text = await response.text()
        
        // Simple RSS parsing (you might want to use a proper RSS parser library)
        const items = text.match(/<item>([\s\S]*?)<\/item>/g) || []
        
        for (const item of items.slice(0, 3)) { // Limit to 3 items per feed
          // Check if item mentions the artist
          if (item.toLowerCase().includes(artistName.toLowerCase())) {
            const title = item.match(/<title>(.*?)<\/title>/)?.[1] || ''
            const description = item.match(/<description>(.*?)<\/description>/)?.[1] || ''
            const link = item.match(/<link>(.*?)<\/link>/)?.[1] || ''
            const pubDate = item.match(/<pubDate>(.*?)<\/pubDate>/)?.[1] || ''
            
            newsItems.push({
              artist_name: artistName,
              title: cleanHtml(title),
              description: cleanHtml(description).substring(0, 500),
              source: 'rss',
              source_url: link,
              news_type: 'news',
              priority: calculatePriority(`${title} ${description}`, 'news', isFollowedArtist),
              event_date: pubDate ? new Date(pubDate).toISOString() : null,
              metadata: {
                feed_source: new URL(feedUrl).hostname
              }
            })
          }
        }
      } catch (feedError) {
        console.error(`Error fetching feed ${feedUrl}:`, feedError)
      }
    }

    return newsItems
  } catch (error) {
    console.error('RSS feed error:', error)
    return []
  }
}

// Ticketmaster API Integration
async function fetchTicketmasterEvents(artistName: string, artistId?: string, isFollowedArtist: boolean = false): Promise<any[]> {
  try {
    const response = await fetch(
      `https://app.ticketmaster.com/discovery/v2/events.json?keyword=${encodeURIComponent(artistName)}&apikey=${TICKETMASTER_API_KEY}&size=5&sort=date,asc`
    )

    const data = await response.json()
    const events = data._embedded?.events || []
    const newsItems = []

    for (const event of events) {
      const venue = event._embedded?.venues?.[0]
      
      newsItems.push({
        artist_id: artistId,
        artist_name: artistName,
        title: `Concert: ${event.name}`,
        description: `${artistName} concert at ${venue?.name || 'TBA'} in ${venue?.city?.name || 'TBA'}`,
        source: 'ticketmaster',
        source_url: event.url,
        image_url: event.images?.[0]?.url,
        news_type: 'concert',
        priority: calculateTicketmasterPriority(event, isFollowedArtist),
        event_date: event.dates?.start?.dateTime,
        metadata: {
          ticketmaster_id: event.id,
          venue_name: venue?.name,
          venue_city: venue?.city?.name,
          venue_country: venue?.country?.name,
          sale_start: event.sales?.public?.startDateTime,
          price_range: event.priceRanges?.[0]
        }
      })
    }

    return newsItems
  } catch (error) {
    console.error('Ticketmaster API error:', error)
    return []
  }
}

// Helper functions
function cleanHtml(text: string): string {
  return text
    .replace(/<[^>]*>/g, '')
    .replace(/&nbsp;/g, ' ')
    .replace(/&amp;/g, '&')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .trim()
}

function isRecentRelease(dateString: string): boolean {
  const releaseDate = new Date(dateString)
  const daysSinceRelease = (Date.now() - releaseDate.getTime()) / (1000 * 60 * 60 * 24)
  return daysSinceRelease <= 30 // Within last 30 days
}

function calculateTicketmasterPriority(event: any, isFollowedArtist: boolean): string {
  const isUpcoming = isUpcomingEvent(event.dates?.start?.localDate)
  const isPresale = event.sales?.presales?.length > 0
  
  if (isFollowedArtist && (isUpcoming || isPresale)) return 'urgent'
  if (isUpcoming || isPresale) return 'high'
  if (isFollowedArtist) return 'high'
  return 'normal'
}

function isUpcomingEvent(dateString: string): boolean {
  if (!dateString) return false
  const eventDate = new Date(dateString)
  const daysUntilEvent = (eventDate.getTime() - Date.now()) / (1000 * 60 * 60 * 24)
  return daysUntilEvent > 0 && daysUntilEvent <= 30 // Within next 30 days
}

// Smart scheduling for MEDIUM priority sources (Ticketmaster)
async function shouldFetchMediumPriority(supabase: any, artistName: string, source: string): Promise<boolean> {
  try {
    // Check when we last fetched MEDIUM priority content for this artist
    const { data: lastFetch } = await supabase
      .from('news_fetch_log')
      .select('last_fetched')
      .eq('artist_name', artistName)
      .eq('source', source)
      .eq('priority_level', 'medium')
      .single()

    if (!lastFetch) {
      // No previous fetch, so fetch now
      await logFetch(supabase, artistName, source, 'medium')
      return true
    }

    const hoursSinceLastFetch = (Date.now() - new Date(lastFetch.last_fetched).getTime()) / (1000 * 60 * 60)
    
    // Fetch MEDIUM priority content once every 6 hours (vs HIGH priority every 30 minutes)
    if (hoursSinceLastFetch >= 6) {
      await logFetch(supabase, artistName, source, 'medium')
      return true
    }

    return false
  } catch (error) {
    console.error('Error checking fetch schedule:', error)
    // Default to fetching on error
    return true
  }
}

async function logFetch(supabase: any, artistName: string, source: string, priorityLevel: string) {
  await supabase
    .from('news_fetch_log')
    .upsert({
      artist_name: artistName,
      source: source,
      priority_level: priorityLevel,
      last_fetched: new Date().toISOString()
    }, {
      onConflict: 'artist_name,source,priority_level'
    })
}