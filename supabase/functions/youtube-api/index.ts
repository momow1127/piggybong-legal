import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS, PUT, DELETE',
};

console.info('YouTube API Edge Function started');

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // Get YouTube API key from environment variables
    const YOUTUBE_API_KEY = Deno.env.get('YOUTUBE_API_KEY');

    if (!YOUTUBE_API_KEY) {
      console.error('Missing YouTube API key in environment variables');
      throw new Error('YouTube API key not configured');
    }

    const url = new URL(req.url);
    const endpoint = url.searchParams.get('endpoint') || 'search';
    const channelId = url.searchParams.get('channelId');
    const query = url.searchParams.get('q');
    const maxResults = url.searchParams.get('maxResults') || '10';
    const order = url.searchParams.get('order') || 'date';
    const regionCode = url.searchParams.get('regionCode') || 'KR';

    let youtubeUrl = '';

    switch (endpoint) {
      case 'search':
        youtubeUrl = `https://www.googleapis.com/youtube/v3/search?part=snippet&type=video&maxResults=${maxResults}&order=${order}&key=${YOUTUBE_API_KEY}`;
        if (channelId) youtubeUrl += `&channelId=${channelId}`;
        if (query) youtubeUrl += `&q=${encodeURIComponent(query)}`;
        break;

      case 'trending':
        youtubeUrl = `https://www.googleapis.com/youtube/v3/videos?part=snippet&chart=mostPopular&regionCode=${regionCode}&videoCategoryId=10&maxResults=${maxResults}&key=${YOUTUBE_API_KEY}`;
        break;

      case 'channel':
        if (!channelId) {
          throw new Error('channelId is required for channel endpoint');
        }
        youtubeUrl = `https://www.googleapis.com/youtube/v3/channels?part=snippet,statistics&id=${channelId}&key=${YOUTUBE_API_KEY}`;
        break;

      case 'videos':
        const videoIds = url.searchParams.get('videoIds');
        if (!videoIds) {
          throw new Error('videoIds is required for videos endpoint');
        }
        youtubeUrl = `https://www.googleapis.com/youtube/v3/videos?part=snippet,statistics&id=${videoIds}&key=${YOUTUBE_API_KEY}`;
        break;

      default:
        return new Response(
          JSON.stringify({
            error: 'Invalid endpoint',
            availableEndpoints: ['search', 'trending', 'channel', 'videos'],
            endpoint: endpoint
          }),
          {
            status: 400,
            headers: {
              ...corsHeaders,
              'Content-Type': 'application/json'
            }
          }
        );
    }

    console.info(`Requesting YouTube ${endpoint} endpoint: ${youtubeUrl.split('&key=')[0]}`);

    const response = await fetch(youtubeUrl);

    if (!response.ok) {
      const errorText = await response.text();
      console.error(`YouTube API error: ${response.status} - ${errorText}`);

      // Handle quota exceeded specifically
      if (response.status === 403) {
        return new Response(
          JSON.stringify({
            error: 'YouTube API quota exceeded',
            message: 'Daily API quota has been exceeded. Please try again tomorrow.',
            status: 403
          }),
          {
            status: 403,
            headers: {
              ...corsHeaders,
              'Content-Type': 'application/json'
            }
          }
        );
      }

      throw new Error(`YouTube API error: ${response.status}`);
    }

    const data = await response.json();

    // Add metadata to response
    const responseData = {
      ...data,
      metadata: {
        endpoint,
        timestamp: new Date().toISOString(),
        requestParams: {
          channelId,
          query,
          maxResults,
          order,
          regionCode
        }
      }
    };

    return new Response(
      JSON.stringify(responseData),
      {
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json',
          // Cache for 5 minutes for most requests, 15 minutes for trending
          'Cache-Control': `public, max-age=${endpoint === 'trending' ? 900 : 300}`
        }
      }
    );

  } catch (error) {
    console.error('Error in YouTube API function:', error);

    return new Response(
      JSON.stringify({
        error: 'YouTube API request failed',
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