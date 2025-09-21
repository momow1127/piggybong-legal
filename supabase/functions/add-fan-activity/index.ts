import { serve } from "https://deno.land/std@0.224.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, GET, OPTIONS, PUT, DELETE',
}

interface FanActivityRequest {
  artist_name: string
  amount: number
  activity_type: string
  title: string
  description?: string
  fan_category?: string
  category_id?: string
  category_title?: string
  category_icon?: string
  idol_id?: string
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  if (req.method !== 'POST') {
    return new Response(
      JSON.stringify({ error: 'Method not allowed' }),
      {
        status: 405,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    )
  }

  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        global: {
          headers: { Authorization: req.headers.get('Authorization')! },
        },
      }
    )

    // Get user from JWT token
    const {
      data: { user },
    } = await supabase.auth.getUser()

    if (!user) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }),
        {
          status: 401,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    const requestBody: FanActivityRequest = await req.json()

    // Validate required fields
    if (!requestBody.artist_name || !requestBody.amount || !requestBody.activity_type || !requestBody.title) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields: artist_name, amount, activity_type, title' }),
        {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    // Validate amount is positive
    if (requestBody.amount <= 0) {
      return new Response(
        JSON.stringify({ error: 'Amount must be positive' }),
        {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    // Prepare activity data for fan_activities table
    const activityData = {
      user_id: user.id,
      artist_name: requestBody.artist_name,
      amount: requestBody.amount,
      activity_type: requestBody.activity_type,
      title: requestBody.title,
      description: requestBody.description || null,
      fan_category: requestBody.fan_category || null,
      category_id: requestBody.category_id || null,
      category_title: requestBody.category_title || null,
      category_icon: requestBody.category_icon || null,
      idol_id: requestBody.idol_id || null,
      created_at: new Date().toISOString()
    }

    console.log('Inserting fan activity:', activityData)

    // Insert activity into fan_activities table
    const { data: activity, error: activityError } = await supabase
      .from('fan_activities')
      .insert(activityData)
      .select()
      .single()

    if (activityError) {
      console.error('Error creating fan activity:', activityError)
      return new Response(
        JSON.stringify({
          error: 'Failed to create fan activity',
          details: activityError.message
        }),
        {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    console.log('Fan activity created successfully:', activity)

    // Prepare success response
    const response = {
      success: true,
      activity: activity,
      message: `Added ${requestBody.title} for ${requestBody.artist_name}`
    }

    return new Response(
      JSON.stringify(response),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    )

  } catch (error) {
    console.error('Add fan activity error:', error)
    return new Response(
      JSON.stringify({
        error: 'Internal server error',
        message: error.message
      }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    )
  }
})