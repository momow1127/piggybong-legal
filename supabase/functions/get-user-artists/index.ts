import { serve } from "https://deno.land/std@0.224.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, GET, OPTIONS, PUT, DELETE',
}

const supabaseUrl = Deno.env.get('SUPABASE_URL')!
const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabase = createClient(supabaseUrl, supabaseServiceKey)
    
    // Get user from JWT token
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      throw new Error('Authorization header required')
    }

    const { data: { user }, error: authError } = await supabase.auth.getUser(
      authHeader.replace('Bearer ', '')
    )

    if (authError || !user) {
      throw new Error('Invalid authentication')
    }

    // Get user's selected artists (max 3)
    const { data: userArtists, error: artistError } = await supabase
      .from('fan_artists')
      .select('*')
      .eq('user_id', user.id)
      .limit(3)

    if (artistError) {
      throw new Error(`Database error: ${artistError.message}`)
    }

    // Get artist details
    const artistIds = userArtists?.map(ua => ua.artist_id).filter(Boolean) || []

    let selectedArtists = []
    if (artistIds.length > 0) {
      const { data: artists, error: artistsError } = await supabase
        .from('artists')
        .select('id, name, type, image_url, genres')
        .in('id', artistIds)

      if (artistsError) {
        console.error('Error fetching artists:', artistsError)
      }

      selectedArtists = artists?.map(artist => ({
        id: artist.id,
        name: artist.name,
        type: artist.type,
        image_url: artist.image_url,
        genres: artist.genres || ['K-pop']
      })) || []
    }

    // Generate search terms for all services
    const searchTerms: string[] = []
    const artistNames: string[] = []

    selectedArtists.forEach(artist => {
      artistNames.push(artist.name)
      searchTerms.push(artist.name.toLowerCase())
    })

    return new Response(
      JSON.stringify({
        success: true,
        user_id: user.id,
        selected_artists: selectedArtists,
        artist_names: artistNames,
        search_terms: [...new Set(searchTerms)], // Remove duplicates
        count: selectedArtists.length
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )

  } catch (error) {
    console.error('Get user artists error:', error)
    
    return new Response(
      JSON.stringify({ 
        success: false,
        error: error.message || 'Internal server error',
        selected_artists: [],
        search_terms: []
      }),
      { 
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  }
})