import { serve } from "https://deno.land/std@0.224.0/http/server.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, GET, OPTIONS, PUT, DELETE',
}

// Environment validation
const TICKETMASTER_API_KEY = Deno.env.get('TICKETMASTER_API_KEY')
const API_KEY_MASKED = TICKETMASTER_API_KEY ? `${TICKETMASTER_API_KEY.slice(0, 4)}****${TICKETMASTER_API_KEY.slice(-4)}` : 'NOT_SET'

// Validation helper
function validateApiKey(): { valid: boolean; message: string } {
  if (!TICKETMASTER_API_KEY) {
    return { valid: false, message: 'TICKETMASTER_API_KEY environment variable not set' }
  }
  if (TICKETMASTER_API_KEY.length < 10) {
    return { valid: false, message: `API key too short (${TICKETMASTER_API_KEY.length} chars, expected 20+)` }
  }
  if (TICKETMASTER_API_KEY === 'YOUR_TICKETMASTER_API_KEY_HERE') {
    return { valid: false, message: 'API key is still placeholder value' }
  }
  return { valid: true, message: 'API key valid' }
}

// Request validation helper
function validateRequest(body: any): { valid: boolean; message: string } {
  if (!body) {
    return { valid: false, message: 'Request body is required' }
  }

  const { genres, location, limit, artists } = body

  if (limit && (isNaN(limit) || limit < 1 || limit > 200)) {
    return { valid: false, message: 'Limit must be between 1 and 200' }
  }

  if (artists && !Array.isArray(artists)) {
    return { valid: false, message: 'Artists must be an array' }
  }

  return { valid: true, message: 'Request valid' }
}

// Response formatting helper
function formatSuccessResponse(events: any[], totalCount: number) {
  return {
    success: true,
    events,
    total_count: totalCount,
    processed_at: new Date().toISOString(),
    source: 'ticketmaster_api'
  }
}

function formatErrorResponse(error: string, code?: string) {
  return {
    success: false,
    error,
    error_code: code || 'UNKNOWN_ERROR',
    events: [],
    total_count: 0,
    processed_at: new Date().toISOString(),
    source: 'ticketmaster_api'
  }
}

serve(async (req) => {
  const startTime = Date.now()
  const requestId = crypto.randomUUID().slice(0, 8)

  console.log(`🎫 [${requestId}] Ticketmaster API request started`)
  console.log(`🔧 [${requestId}] API Key Status: ${API_KEY_MASKED}`)

  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // 1. Validate API Key
    const keyValidation = validateApiKey()
    if (!keyValidation.valid) {
      console.error(`❌ [${requestId}] API Key Error: ${keyValidation.message}`)
      return new Response(
        JSON.stringify(formatErrorResponse(keyValidation.message, 'INVALID_API_KEY')),
        {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }
    console.log(`✅ [${requestId}] API Key validated successfully`)

    // 2. Parse and validate request
    let requestBody
    try {
      requestBody = await req.json()
    } catch (parseError) {
      console.error(`❌ [${requestId}] JSON Parse Error:`, parseError)
      return new Response(
        JSON.stringify(formatErrorResponse('Invalid JSON in request body', 'INVALID_JSON')),
        {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    const requestValidation = validateRequest(requestBody)
    if (!requestValidation.valid) {
      console.error(`❌ [${requestId}] Request Validation Error: ${requestValidation.message}`)
      return new Response(
        JSON.stringify(formatErrorResponse(requestValidation.message, 'INVALID_REQUEST')),
        {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    const { genres, location, limit, artists } = requestBody
    console.log(`📋 [${requestId}] Request params:`, {
      genres: genres?.slice(0, 3),
      location,
      limit,
      artists: artists?.slice(0, 3)
    })

    // 3. Build Ticketmaster API URL
    const params = new URLSearchParams({
      apikey: TICKETMASTER_API_KEY,
      classificationName: genres?.[0] || 'music',
      size: Math.min(limit || 50, 200).toString(), // Cap at 200
      sort: 'date,asc'
    })

    if (location) {
      params.append('city', location)
    }

    // Add artist keyword search if artists provided
    if (artists && artists.length > 0) {
      // Use the first artist as primary keyword
      params.append('keyword', artists[0])
      console.log(`🎯 [${requestId}] Searching for artist: "${artists[0]}"`)
    }

    const url = `https://app.ticketmaster.com/discovery/v2/events.json?${params}`
    const maskedUrl = url.replace(TICKETMASTER_API_KEY, '****')
    console.log(`🌐 [${requestId}] Ticketmaster URL (masked): ${maskedUrl}`)

    // 4. Fetch from Ticketmaster API
    console.log(`📡 [${requestId}] Sending request to Ticketmaster...`)
    const fetchStartTime = Date.now()

    const response = await fetch(url, {
      method: 'GET',
      headers: {
        'Accept': 'application/json',
        'User-Agent': 'PiggyBong-App/1.0'
      }
    })

    const fetchDuration = Date.now() - fetchStartTime
    console.log(`⏱️ [${requestId}] Ticketmaster API responded in ${fetchDuration}ms with status ${response.status}`)
    
    if (!response.ok) {
      let errorDetails = `Status ${response.status}`
      try {
        const errorText = await response.text()
        errorDetails += `: ${errorText}`
        console.error(`❌ [${requestId}] Ticketmaster API Error:`, {
          status: response.status,
          statusText: response.statusText,
          body: errorText.slice(0, 500) // Limit error body length
        })
      } catch (textError) {
        console.error(`❌ [${requestId}] Failed to read error response:`, textError)
      }

      // Determine error code based on status
      let errorCode = 'TICKETMASTER_ERROR'
      if (response.status === 401) errorCode = 'UNAUTHORIZED'
      else if (response.status === 403) errorCode = 'FORBIDDEN'
      else if (response.status === 429) errorCode = 'RATE_LIMITED'
      else if (response.status >= 500) errorCode = 'SERVER_ERROR'

      return new Response(
        JSON.stringify(formatErrorResponse(`Ticketmaster API error: ${errorDetails}`, errorCode)),
        {
          status: response.status >= 500 ? 500 : 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    // 5. Parse response data
    let data
    try {
      data = await response.json()
      console.log(`📊 [${requestId}] Ticketmaster response parsed:`, {
        hasEvents: !!data._embedded?.events,
        eventCount: data._embedded?.events?.length || 0,
        totalElements: data.page?.totalElements || 0
      })
    } catch (jsonError) {
      console.error(`❌ [${requestId}] Failed to parse Ticketmaster JSON:`, jsonError)
      return new Response(
        JSON.stringify(formatErrorResponse('Invalid JSON response from Ticketmaster', 'INVALID_RESPONSE')),
        {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    // 6. Transform data safely
    const allEvents = (data._embedded?.events || []).map((event: any) => {
      try {
        return {
          id: event.id || crypto.randomUUID(),
          name: event.name || 'Unnamed Event',
          artist: event._embedded?.attractions?.[0]?.name || 'Unknown Artist',
          venue: event._embedded?.venues?.[0]?.name || 'Unknown Venue',
          city: event._embedded?.venues?.[0]?.city?.name || 'Unknown City',
          state: event._embedded?.venues?.[0]?.state?.stateCode || null,
          country: event._embedded?.venues?.[0]?.country?.countryCode || 'US',
          date: event.dates?.start?.localDate || null,
          time: event.dates?.start?.localTime || null,
          timezone: event.dates?.timezone || null,
          min_price: event.priceRanges?.[0]?.min || null,
          max_price: event.priceRanges?.[0]?.max || null,
          currency: event.priceRanges?.[0]?.currency || 'USD',
          url: event.url || '',
          image_url: event.images?.[0]?.url || event.images?.find((img: any) => img.width >= 300)?.url || null,
          status: event.dates?.status?.code || 'unknown',
          genre: event.classifications?.[0]?.genre?.name || 'Music',
          subgenre: event.classifications?.[0]?.subGenre?.name || null
        }
      } catch (transformError) {
        console.error(`⚠️ [${requestId}] Error transforming event:`, transformError, event)
        return null
      }
    }).filter(Boolean) // Remove null events

    console.log(`🔄 [${requestId}] Transformed ${allEvents.length} events from Ticketmaster`)

    // 7. Filter by user's artists if provided
    let filteredEvents = allEvents
    if (artists && artists.length > 0) {
      filteredEvents = allEvents.filter((event: any) => {
        const searchText = `${event.name} ${event.artist} ${event.venue}`.toLowerCase()
        const matched = artists.some((artist: string) => {
          const artistLower = artist.toLowerCase()
          return searchText.includes(artistLower) ||
                 artistLower.includes(searchText.split(' ')[0]) // Partial matching
        })
        return matched
      })
      console.log(`🎭 [${requestId}] Filtered to ${filteredEvents.length} events matching artists: ${artists.join(', ')}`)
    }

    const totalDuration = Date.now() - startTime
    console.log(`✅ [${requestId}] Request completed in ${totalDuration}ms, returning ${filteredEvents.length} events`)

    return new Response(
      JSON.stringify(formatSuccessResponse(filteredEvents, data.page?.totalElements || 0)),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )

  } catch (error) {
    const totalDuration = Date.now() - startTime
    console.error(`💥 [${requestId}] Unhandled error after ${totalDuration}ms:`, {
      name: error?.name,
      message: error?.message,
      stack: error?.stack?.slice(0, 500)
    })

    // Determine appropriate error response
    let errorMessage = 'Internal server error'
    let errorCode = 'INTERNAL_ERROR'
    let statusCode = 500

    if (error?.name === 'TypeError' && error?.message?.includes('fetch')) {
      errorMessage = 'Network error connecting to Ticketmaster API'
      errorCode = 'NETWORK_ERROR'
      statusCode = 503
    } else if (error?.message) {
      errorMessage = error.message
    }

    return new Response(
      JSON.stringify(formatErrorResponse(errorMessage, errorCode)),
      {
        status: statusCode,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  }
})