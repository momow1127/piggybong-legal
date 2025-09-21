import { serve } from "https://deno.land/std@0.177.0/http/server.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, GET, OPTIONS, PUT, DELETE',
}

const TICKETMASTER_API_KEY = Deno.env.get('TICKETMASTER_API_KEY')

serve(async (req) => {
  console.log('🚀 Function invoked with method:', req.method)

  if (req.method === 'OPTIONS') {
    console.log('✅ CORS preflight request')
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    console.log('🔑 API Key check:', TICKETMASTER_API_KEY ? 'Present' : 'MISSING')

    if (!TICKETMASTER_API_KEY) {
      console.error('❌ TICKETMASTER_API_KEY environment variable not set')
      throw new Error('Ticketmaster API key not configured')
    }

    console.log('📥 Reading request body...')
    const requestBody = await req.json()
    console.log('📋 Request parameters:', JSON.stringify(requestBody, null, 2))

    const { genres, location, limit, artists } = requestBody

    // Build Ticketmaster API URL
    const params = new URLSearchParams({
      apikey: TICKETMASTER_API_KEY,
      classificationName: genres?.[0] || 'music',
      size: (limit || 50).toString(),
      sort: 'date,asc'
    })

    if (location) {
      params.append('city', location)
    }

    // Add artist keyword search if artists provided
    if (artists && artists.length > 0) {
      console.log('🎤 Searching for artists:', artists)
      params.append('keyword', artists[0])
    }

    const url = `https://app.ticketmaster.com/discovery/v2/events.json?${params}`
    console.log('🌐 Ticketmaster API URL:', url.replace(TICKETMASTER_API_KEY, '[REDACTED]'))

    console.log('📡 Making request to Ticketmaster...')
    const response = await fetch(url)

    console.log('📊 Ticketmaster response status:', response.status)

    if (!response.ok) {
      const errorText = await response.text()
      console.error('❌ Ticketmaster API error:', response.status, errorText)
      throw new Error(`Ticketmaster API error: ${response.status} - ${errorText}`)
    }

    const data = await response.json()
    console.log('📈 Ticketmaster response structure:', {
      hasEmbedded: !!data._embedded,
      hasEvents: !!data._embedded?.events,
      eventCount: data._embedded?.events?.length || 0,
      totalElements: data.page?.totalElements || 0
    })

    // Transform data to match app's expected format
    const allEvents = data._embedded?.events?.map((event: any) => ({
      id: event.id,
      name: event.name,
      artist: event._embedded?.attractions?.[0]?.name || 'Unknown Artist',
      venue: event._embedded?.venues?.[0]?.name || 'Unknown Venue',
      city: event._embedded?.venues?.[0]?.city?.name || 'Unknown City',
      date: event.dates?.start?.localDate,
      time: event.dates?.start?.localTime,
      min_price: event.priceRanges?.[0]?.min,
      max_price: event.priceRanges?.[0]?.max,
      currency: event.priceRanges?.[0]?.currency || 'USD',
      url: event.url,
      image_url: event.images?.[0]?.url
    })) || []

    console.log('🔄 Transformed events count:', allEvents.length)

    // Filter by user's artists if provided
    const events = artists && artists.length > 0
      ? allEvents.filter((event: any) => {
          const eventText = `${event.name} ${event.artist}`.toLowerCase()
          return artists.some((artist: string) =>
            eventText.includes(artist.toLowerCase())
          )
        })
      : allEvents

    console.log('✅ Final filtered events count:', events.length)

    // FIX: Match iOS app's expected response structure
    const responseData = {
      events,
      total_count: data.page?.totalElements || 0
    }

    console.log('📤 Sending response:', {
      eventCount: events.length,
      totalCount: responseData.total_count
    })

    return new Response(
      JSON.stringify(responseData),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )

  } catch (error) {
    console.error('💥 Function error:', error)
    console.error('📍 Error stack:', error.stack)

    return new Response(
      JSON.stringify({
        error: error.message || 'Internal server error',
        events: [],
        total_count: 0
      }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  }
})