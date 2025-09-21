import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, GET, OPTIONS, PUT, DELETE'
};

const TICKETMASTER_API_KEY = Deno.env.get('TICKETMASTER_API_KEY');
console.log('🚀 Function initialized. API Key status:', TICKETMASTER_API_KEY ? 'CONFIGURED' : 'MISSING');

serve(async (req) => {
  console.log(`📝 ${new Date().toISOString()} - ${req.method} request received`);

  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    if (!TICKETMASTER_API_KEY) {
      console.error('❌ TICKETMASTER_API_KEY environment variable not configured');
      return new Response(JSON.stringify({
        error: 'Ticketmaster API key not configured. Please contact support.',
        events: [],
        total_count: 0
      }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    const requestBody = await req.json();
    console.log('📋 Request:', JSON.stringify(requestBody));

    const { genres, location, limit, artists } = requestBody;

    // Build Ticketmaster API URL
    const params = new URLSearchParams({
      apikey: TICKETMASTER_API_KEY,
      classificationName: genres?.[0] || 'music',
      size: (limit || 50).toString(),
      sort: 'date,asc'
    });

    if (location) {
      params.append('city', location);
    }

    if (artists && artists.length > 0) {
      params.append('keyword', artists[0]);
    }

    const url = `https://app.ticketmaster.com/discovery/v2/events.json?${params}`;
    console.log('🌐 Calling Ticketmaster API...');

    const response = await fetch(url);
    console.log(`📡 Ticketmaster responded: ${response.status}`);

    if (!response.ok) {
      const errorText = await response.text();
      console.error(`❌ Ticketmaster API error: ${response.status} - ${errorText}`);

      // Return empty results instead of throwing for API errors
      return new Response(JSON.stringify({
        error: `Ticketmaster API temporarily unavailable (${response.status})`,
        events: [],
        total_count: 0
      }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    const data = await response.json();
    const eventCount = data._embedded?.events?.length || 0;
    console.log(`📈 Found ${eventCount} events`);

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
    })) || [];

    // Filter by user's artists if provided
    const events = artists && artists.length > 0
      ? allEvents.filter((event: any) => {
          const eventText = `${event.name} ${event.artist}`.toLowerCase();
          return artists.some((artist: string) =>
            eventText.includes(artist.toLowerCase())
          );
        })
      : allEvents;

    console.log(`✅ Returning ${events.length} filtered events`);

    return new Response(JSON.stringify({
      events,
      total_count: data.page?.totalElements || 0
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });

  } catch (error) {
    console.error('💥 Function error:', error);

    return new Response(JSON.stringify({
      error: 'Internal server error',
      events: [],
      total_count: 0
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});