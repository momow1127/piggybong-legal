import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const requestBody = await req.json()
    const { artist_names = [], limit = 50, offset = 0 } = requestBody

    console.log(`🎵 Fetching updates for artists: ${artist_names.join(', ')}`)

    // For now, return mock data since we don't have RSS feeds set up
    // In production, this would fetch from actual RSS feeds or APIs
    const mockUpdates = artist_names.flatMap((artistName: string, index: number) => [
      {
        id: `${artistName.toLowerCase().replace(/\s+/g, '-')}-update-1-${Date.now()}`,
        artist_name: artistName,
        update_type: 'news',
        title: `${artistName} announces new album coming soon`,
        description: `${artistName} has confirmed their upcoming album release date.`,
        timestamp: new Date(Date.now() - index * 1000 * 60 * 60 * 24).toISOString(),
        source_url: null,
        image_url: null,
        is_breaking: false
      },
      {
        id: `${artistName.toLowerCase().replace(/\s+/g, '-')}-update-2-${Date.now()}`,
        artist_name: artistName,
        update_type: 'social',
        title: `${artistName} shares behind-the-scenes content`,
        description: `Check out the latest social media updates from ${artistName}.`,
        timestamp: new Date(Date.now() - (index + 1) * 1000 * 60 * 60 * 12).toISOString(),
        source_url: null,
        image_url: null,
        is_breaking: false
      }
    ]).slice(offset, offset + limit)

    return new Response(
      JSON.stringify({
        success: true,
        updates: mockUpdates,
        error: null
      }),
      {
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json'
        }
      }
    )

  } catch (error) {
    console.error('Error in get-artist-updates:', error)
    return new Response(
      JSON.stringify({
        success: false,
        updates: [],
        error: error.message
      }),
      {
        status: 500,
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json'
        }
      }
    )
  }
})