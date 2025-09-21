import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, GET, OPTIONS, PUT, DELETE',
};

console.info('Spotify Auth Edge Function started');

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // Get Spotify credentials from environment variables
    const SPOTIFY_CLIENT_ID = Deno.env.get('SPOTIFY_CLIENT_ID');
    const SPOTIFY_CLIENT_SECRET = Deno.env.get('SPOTIFY_CLIENT_SECRET');

    if (!SPOTIFY_CLIENT_ID || !SPOTIFY_CLIENT_SECRET) {
      console.error('Missing Spotify credentials in environment variables');
      throw new Error('Spotify credentials not configured');
    }

    console.log('Fetching Spotify access token...');

    const tokenUrl = 'https://accounts.spotify.com/api/token';
    const credentials = btoa(`${SPOTIFY_CLIENT_ID}:${SPOTIFY_CLIENT_SECRET}`);

    const response = await fetch(tokenUrl, {
      method: 'POST',
      headers: {
        'Authorization': `Basic ${credentials}`,
        'Content-Type': 'application/x-www-form-urlencoded'
      },
      body: 'grant_type=client_credentials'
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error(`Spotify API error: ${response.status} - ${errorText}`);
      throw new Error(`Failed to get Spotify token: ${response.status}`);
    }

    const data = await response.json();
    const expiresAt = Date.now() + (data.expires_in * 1000);

    console.log('Successfully fetched Spotify access token');

    return new Response(
      JSON.stringify({
        access_token: data.access_token,
        token_type: data.token_type,
        expires_in: data.expires_in,
        expires_at: expiresAt,
        scope: data.scope || null
      }),
      {
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json',
          // Cache for slightly less than expiry time to avoid using expired tokens
          'Cache-Control': `public, max-age=${Math.max(data.expires_in - 60, 0)}`
        }
      }
    );

  } catch (error) {
    console.error('Error in Spotify auth function:', error);

    return new Response(
      JSON.stringify({
        error: 'Failed to authenticate with Spotify',
        details: error.message,
        timestamp: new Date().toISOString()
      }),
      {
        status: 500,
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json'
        }
      }
    );
  }
});