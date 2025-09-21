import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, GET, OPTIONS, PUT, DELETE'
};

// Log function startup
console.log('🚀 Edge Function starting up...');
const TICKETMASTER_API_KEY = Deno.env.get('TICKETMASTER_API_KEY');
console.log('🔑 API Key status:', TICKETMASTER_API_KEY ? 'CONFIGURED' : 'MISSING');

serve(async (req) => {
  // Log every invocation
  console.log(`📝 Function invoked: ${new Date().toISOString()} - Method: ${req.method}`);

  try {
    if (req.method === 'OPTIONS') {
      console.log('✅ Handling CORS preflight');
      return new Response('ok', { headers: corsHeaders });
    }

    console.log('🔍 Starting main logic...');

    // Check API key first
    if (!TICKETMASTER_API_KEY) {
      console.error('❌ TICKETMASTER_API_KEY not found in environment');
      throw new Error('Ticketmaster API key not configured');
    }

    console.log('📥 Reading request body...');
    const requestBody = await req.json();
    console.log('📋 Request received:', JSON.stringify(requestBody, null, 2));

    const { genres, location, limit, artists } = requestBody;

    // Build Ticketmaster API URL
    console.log('🔧 Building Ticketmaster API URL...');
    const params = new URLSearchParams({
      apikey: TICKETMASTER_API_KEY,
      classificationName: genres?.[0] || 'music',
      size: (limit || 50).toString(),
      sort: 'date,asc'
    });

    if (location) {
      console.log(`📍 Adding location filter: ${location}`);
      params.append('city', location);
    }

    if (artists && artists.length > 0) {
      console.log(`🎤 Adding artist keyword: ${artists[0]}`);
      params.append('keyword', artists[0]);
    }

    const url = `https://app.ticketmaster.com/discovery/v2/events.json?${params}`;
    console.log('🌐 Making request to Ticketmaster API...');
    // Don't log the full URL with API key for security
    console.log('🌐 URL endpoint: https://app.ticketmaster.com/discovery/v2/events.json');

    const response = await fetch(url);
    console.log(`📡 Ticketmaster API responded with status: ${response.status}`);

    if (!response.ok) {
      const errorText = await response.text();
      console.error(`❌ Ticketmaster API error: ${response.status} - ${errorText}`);
      throw new Error(`Ticketmaster API error: ${response.status}`);
    }

    console.log('📊 Parsing Ticketmaster response...');
    const data = await response.json();

    const eventCount = data._embedded?.events?.length || 0;
    const totalElements = data.page?.totalElements || 0;
    console.log(`📈 Ticketmaster returned ${eventCount} events (total available: ${totalElements})`);

    // Transform data to match app's expected format
    console.log('🔄 Transforming event data...');
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
    })) || [];

    console.log(`✨ Transformed ${allEvents.length} events`);

    // Filter by user's artists if provided
    const events = artists && artists.length > 0
      ? allEvents.filter((event: any) => {
          const eventText = `${event.name} ${event.artist}`.toLowerCase();
          return artists.some((artist: string) =>
            eventText.includes(artist.toLowerCase())
          );
        })
      : allEvents;

    console.log(`🎯 Final filtered events: ${events.length}`);

    const responseData = {
      events,
      total_count: data.page?.totalElements || 0
    };

    console.log('✅ Sending successful response');
    return new Response(JSON.stringify(responseData), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });

  } catch (error) {
    console.error('💥 Function error occurred:');
    console.error('📍 Error message:', error.message);
    console.error('📍 Error stack:', error.stack);

    const errorResponse = {
      error: error.message || 'Internal server error',
      events: [],
      total_count: 0
    };

    console.log('❌ Sending error response:', JSON.stringify(errorResponse));

    return new Response(JSON.stringify(errorResponse), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

console.log('🎯 Edge Function setup complete, ready to serve requests');