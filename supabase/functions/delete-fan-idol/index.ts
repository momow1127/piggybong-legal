import { serve } from "https://deno.land/std@0.224.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, GET, OPTIONS, PUT, DELETE',
}

interface DeleteIdolRequest {
  idolId?: string;
  artistId?: string;  // Alternative - can delete by artist ID
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Initialize Supabase client
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    // Get user from JWT token
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(
        JSON.stringify({ success: false, message: 'Authentication required' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const token = authHeader.replace('Bearer ', '')
    const { data: { user }, error: authError } = await supabase.auth.getUser(token)

    if (authError || !user) {
      return new Response(
        JSON.stringify({ success: false, message: 'Invalid authentication token' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Parse request body
    const body: DeleteIdolRequest = await req.json()
    const { idolId, artistId } = body

    if (!idolId && !artistId) {
      return new Response(
        JSON.stringify({ success: false, message: 'Either idolId or artistId is required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Find the idol to delete (with artist info for logging)
    let query = supabase
      .from('fan_idols')
      .select(`
        id,
        artist_id,
        priority_rank,
        artists!inner(name)
      `)
      .eq('user_id', user.id)

    if (idolId) {
      query = query.eq('id', idolId)
    } else if (artistId) {
      query = query.eq('artist_id', artistId)
    }

    const { data: idolToDelete, error: findError } = await query.single()

    if (findError || !idolToDelete) {
      return new Response(
        JSON.stringify({ success: false, message: 'Idol not found in your list' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const artistName = (idolToDelete.artists as any).name
    const deletedPriorityRank = idolToDelete.priority_rank

    // Delete the idol - NOTE: fan_activities data is preserved by design
    // Only the fan_idols relationship is removed, not the activity history
    const { error: deleteError } = await supabase
      .from('fan_idols')
      .delete()
      .eq('id', idolToDelete.id)
      .eq('user_id', user.id) // Double-check ownership

    if (deleteError) {
      console.error('Error deleting fan idol:', deleteError)
      return new Response(
        JSON.stringify({ success: false, message: 'Failed to remove idol from your list' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Reorder remaining idols to fill the gap
    try {
      const { data: remainingIdols, error: reorderFetchError } = await supabase
        .from('fan_idols')
        .select('id, priority_rank')
        .eq('user_id', user.id)
        .gt('priority_rank', deletedPriorityRank)
        .order('priority_rank')

      if (reorderFetchError) {
        console.warn('Failed to fetch idols for reordering (non-critical):', reorderFetchError)
      } else if (remainingIdols && remainingIdols.length > 0) {
        // Move each idol down by 1 to fill the gap
        for (const idol of remainingIdols) {
          await supabase
            .from('fan_idols')
            .update({ priority_rank: idol.priority_rank - 1 })
            .eq('id', idol.id)
            .eq('user_id', user.id)
        }
      }
    } catch (reorderError) {
      console.warn('Failed to reorder idols after deletion (non-critical):', reorderError)
      // Don't fail the main operation if reordering fails
    }

    // Log activity for fan activity timeline
    try {
      await supabase
        .from('fan_activities')
        .insert({
          user_id: user.id,
          artist_id: idolToDelete.artist_id,
          activity_type: 'artist_removed',
          title: 'Removed Idol',
          description: `Removed ${artistName} from your idols list`,
          amount: null
        })
    } catch (activityError) {
      console.warn('Failed to log fan activity (non-critical):', activityError)
      // Don't fail the main operation if activity logging fails
    }

    // Get updated count
    const { count: newCount, error: countError } = await supabase
      .from('fan_idols')
      .select('*', { count: 'exact', head: true })
      .eq('user_id', user.id)

    return new Response(
      JSON.stringify({
        success: true,
        message: `${artistName} removed from your idols`,
        removedIdol: {
          id: idolToDelete.id,
          artistId: idolToDelete.artist_id,
          artistName: artistName,
          priorityRank: deletedPriorityRank
        },
        currentCount: newCount || 0
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Unexpected error in delete-fan-idol:', error)
    return new Response(
      JSON.stringify({ 
        success: false, 
        message: 'An unexpected error occurred. Please try again.' 
      }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})