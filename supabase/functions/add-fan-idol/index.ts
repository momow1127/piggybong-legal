import { serve } from "https://deno.land/std@0.224.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, GET, OPTIONS, PUT, DELETE',
}

interface AddIdolRequest {
  artistId: string;
  priorityRank?: number;
}

interface IdolLimitResponse {
  success: boolean;
  message?: string;
  currentCount?: number;
  maxAllowed?: number;
  isPro?: boolean;
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Initialize Supabase client with validation
    const supabaseUrl = Deno.env.get('SUPABASE_URL')
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')

    if (!supabaseUrl || !supabaseServiceKey) {
      console.error('Missing required environment variables')
      return new Response(
        JSON.stringify({ success: false, message: 'Service configuration error' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

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

    // Parse request body with error handling
    let body: AddIdolRequest
    try {
      body = await req.json()
    } catch (parseError) {
      return new Response(
        JSON.stringify({ success: false, message: 'Invalid JSON in request body' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const { artistId, priorityRank } = body

    if (!artistId) {
      return new Response(
        JSON.stringify({ success: false, message: 'Artist ID is required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Check current idol count and subscription limits
    const { data: currentIdols, error: countError } = await supabase
      .from('fan_idols')
      .select('id, priority_rank')
      .eq('user_id', user.id)
      .order('priority_rank')

    if (countError) {
      console.error('Error fetching current idols:', countError)
      return new Response(
        JSON.stringify({ success: false, message: 'Failed to check current idols' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const currentCount = currentIdols?.length || 0

    // Get subscription status from user profile or subscription table
    let isPro = false
    let maxAllowed = 3 // Default free tier limit

    try {
      // Check if user has an active subscription
      const { data: subscription, error: subError } = await supabase
        .from('user_subscriptions')
        .select('status, plan_type')
        .eq('user_id', user.id)
        .eq('status', 'active')
        .single()

      if (!subError && subscription) {
        isPro = subscription.plan_type === 'pro' || subscription.plan_type === 'premium'
        maxAllowed = isPro ? 6 : 3
        console.log(`User ${user.id} subscription: ${subscription.plan_type}, limit: ${maxAllowed}`)
      } else {
        console.log(`User ${user.id} has no active subscription, using free tier limit: ${maxAllowed}`)
      }
    } catch (subscriptionError) {
      console.warn('Failed to check subscription status, using free tier limit:', subscriptionError)
      // Continue with free tier limits as fallback
    }

    // Check if limit is reached
    if (currentCount >= maxAllowed) {
      return new Response(
        JSON.stringify({
          success: false,
          message: `You've reached the ${isPro ? 'Pro' : 'free'} limit of ${maxAllowed} idols. ${isPro ? '' : 'Upgrade to Pro for up to 6 idols.'}`,
          currentCount,
          maxAllowed,
          isPro
        } as IdolLimitResponse),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Check if artist already exists for this user
    const { data: existingIdol, error: duplicateError } = await supabase
      .from('fan_idols')
      .select('id')
      .eq('user_id', user.id)
      .eq('artist_id', artistId)
      .single()

    if (duplicateError && duplicateError.code !== 'PGRST116') { // PGRST116 = not found
      console.error('Error checking for duplicate idol:', duplicateError)
      return new Response(
        JSON.stringify({ success: false, message: 'Failed to verify idol uniqueness' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    if (existingIdol) {
      return new Response(
        JSON.stringify({ success: false, message: 'This artist is already in your idols list' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Determine priority rank
    let finalPriorityRank = priorityRank
    if (!finalPriorityRank) {
      // Auto-assign next available priority rank
      finalPriorityRank = currentCount + 1
    } else {
      // Check if priority rank is already taken
      const rankTaken = currentIdols?.some(idol => idol.priority_rank === finalPriorityRank)
      if (rankTaken) {
        return new Response(
          JSON.stringify({ success: false, message: `Priority rank ${finalPriorityRank} is already taken` }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }
    }

    // Verify artist exists
    const { data: artist, error: artistError } = await supabase
      .from('artists')
      .select('id, name')
      .eq('id', artistId)
      .single()

    if (artistError || !artist) {
      return new Response(
        JSON.stringify({ success: false, message: 'Artist not found' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Insert new fan idol
    const { data: newIdol, error: insertError } = await supabase
      .from('fan_idols')
      .insert({
        user_id: user.id,
        artist_id: artistId,
        priority_rank: finalPriorityRank
      })
      .select('id, priority_rank, created_at')
      .single()

    if (insertError) {
      console.error('Error inserting fan idol:', insertError)
      return new Response(
        JSON.stringify({ success: false, message: 'Failed to add idol to your list' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Log activity for fan activity timeline
    try {
      await supabase
        .from('fan_activities')
        .insert({
          user_id: user.id,
          artist_id: artistId,
          activity_type: 'artist_added',
          title: 'Added New Idol',
          description: `Added ${artist.name} to your idols list`,
          amount: null
        })
    } catch (activityError) {
      console.warn('Failed to log fan activity (non-critical):', activityError)
      // Don't fail the main operation if activity logging fails
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: `${artist.name} added to your idols!`,
        idol: {
          id: newIdol.id,
          artistId: artistId,
          artistName: artist.name,
          priorityRank: finalPriorityRank,
          createdAt: newIdol.created_at
        },
        currentCount: currentCount + 1,
        maxAllowed,
        isPro
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Unexpected error in add-fan-idol:', error)
    return new Response(
      JSON.stringify({ 
        success: false, 
        message: 'An unexpected error occurred. Please try again.' 
      }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})