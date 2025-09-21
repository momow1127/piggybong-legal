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
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Only allow POST requests
    if (req.method !== 'POST') {
      return new Response(
        JSON.stringify({ error: 'Method not allowed' }),
        {
          status: 405,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    // Get auth header
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: 'Missing authorization header' }),
        {
          status: 401,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    // Create Supabase client with user context
    const supabase = createClient(supabaseUrl, supabaseServiceKey, {
      global: {
        headers: { Authorization: authHeader }
      }
    })

    // Get user from JWT token
    const { data: { user }, error: userError } = await supabase.auth.getUser()
    if (userError || !user) {
      return new Response(
        JSON.stringify({ error: 'Invalid or expired token' }),
        {
          status: 401,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    // Parse request body
    const { artist_id, feedback } = await req.json()

    // Validate input
    if (!feedback || !['positive', 'negative'].includes(feedback)) {
      return new Response(
        JSON.stringify({
          error: 'Invalid feedback. Must be "positive" or "negative"'
        }),
        {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    // Check if user already provided feedback for this artist (optional - remove if multiple feedback allowed)
    if (artist_id) {
      const { data: existingFeedback } = await supabase
        .from('insight_feedback')
        .select('id')
        .eq('user_id', user.id)
        .eq('artist_id', artist_id)
        .single()

      // If feedback exists, update it instead of creating new
      if (existingFeedback) {
        const { data, error } = await supabase
          .from('insight_feedback')
          .update({ feedback })
          .eq('id', existingFeedback.id)
          .select()
          .single()

        if (error) {
          throw error
        }

        return new Response(
          JSON.stringify({
            success: true,
            message: 'Feedback updated successfully',
            data
          }),
          {
            status: 200,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' }
          }
        )
      }
    }

    // Insert new feedback
    const { data, error } = await supabase
      .from('insight_feedback')
      .insert({
        user_id: user.id,
        artist_id: artist_id || null,
        feedback
      })
      .select()
      .single()

    if (error) {
      throw error
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Feedback stored successfully',
        data
      }),
      {
        status: 201,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )

  } catch (error) {
    console.error('Store feedback error:', error)

    return new Response(
      JSON.stringify({
        error: 'Failed to store feedback',
        details: error.message
      }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  }
})