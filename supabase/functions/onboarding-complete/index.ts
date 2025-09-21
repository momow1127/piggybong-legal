import { serve } from "https://deno.land/std@0.224.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface OnboardingCompleteRequest {
  name: string
  monthly_budget: number
  selected_artists: Array<{
    id: string
    priority_rank: number
    monthly_allocation: number
  }>
  selected_goals: Array<{
    name: string
    target_amount: number
    category: string
    artist_id?: string
    goal_type: string
    deadline: string
    is_time_sensitive: boolean
    event_date?: string
    countdown_context?: string
  }>
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

    const requestBody: OnboardingCompleteRequest = await req.json()

    // Validate required fields
    if (!requestBody.name || !requestBody.monthly_budget || !requestBody.selected_artists) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields' }),
        {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    // Validate budget is positive
    if (requestBody.monthly_budget <= 0) {
      return new Response(
        JSON.stringify({ error: 'Monthly budget must be positive' }),
        {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    // Validate artists selection
    if (requestBody.selected_artists.length === 0) {
      return new Response(
        JSON.stringify({ error: 'At least one artist must be selected' }),
        {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    // Start transaction-like operations
    try {
      // 1. Update or create user profile
      const { data: existingUser } = await supabase
        .from('users')
        .select('id')
        .eq('id', user.id)
        .single()

      if (existingUser) {
        // Update existing user
        const { error: userUpdateError } = await supabase
          .from('users')
          .update({
            name: requestBody.name,
            monthly_budget: requestBody.monthly_budget,
            updated_at: new Date().toISOString()
          })
          .eq('id', user.id)

        if (userUpdateError) {
          throw new Error(`Failed to update user: ${userUpdateError.message}`)
        }
      } else {
        // Create new user record
        const { error: userCreateError } = await supabase
          .from('users')
          .insert({
            id: user.id,
            email: user.email!,
            name: requestBody.name,
            monthly_budget: requestBody.monthly_budget,
            currency: 'USD'
          })

        if (userCreateError) {
          throw new Error(`Failed to create user: ${userCreateError.message}`)
        }
      }

      // 2. Clear existing user artists and insert new ones
      await supabase
        .from('user_artists')
        .delete()
        .eq('user_id', user.id)

      const userArtistsData = requestBody.selected_artists.map(artist => ({
        user_id: user.id,
        artist_id: artist.id,
        priority_rank: artist.priority_rank,
        monthly_allocation: artist.monthly_allocation,
        is_active: true
      }))

      const { error: artistsError } = await supabase
        .from('user_artists')
        .insert(userArtistsData)

      if (artistsError) {
        throw new Error(`Failed to save user artists: ${artistsError.message}`)
      }

      // 3. Create goals if provided
      let createdGoals = []
      if (requestBody.selected_goals && requestBody.selected_goals.length > 0) {
        const goalsData = requestBody.selected_goals.map(goal => ({
          user_id: user.id,
          artist_id: goal.artist_id || null,
          name: goal.name,
          target_amount: goal.target_amount,
          current_amount: 0,
          deadline: goal.deadline,
          category: goal.category,
          priority: 'medium',
          goal_type: goal.goal_type,
          is_time_sensitive: goal.is_time_sensitive,
          event_date: goal.event_date || null,
          countdown_context: goal.countdown_context || null
        }))

        const { data: goals, error: goalsError } = await supabase
          .from('goals')
          .insert(goalsData)
          .select()

        if (goalsError) {
          throw new Error(`Failed to create goals: ${goalsError.message}`)
        }

        createdGoals = goals || []
      }

      // 4. Create user preferences
      const { error: preferencesError } = await supabase
        .from('user_fan_preferences')
        .upsert({
          user_id: user.id,
          comeback_notifications: true,
          concert_alerts: true,
          budget_warnings: true,
          ai_coaching_level: 'basic',
          preferred_currency: 'USD',
          timezone: 'UTC'
        })

      if (preferencesError) {
        console.warn('Failed to create user preferences:', preferencesError.message)
      }

      // 5. Create welcome AI tip
      const topArtist = requestBody.selected_artists.find(a => a.priority_rank === 1)
      const { data: artistData } = await supabase
        .from('artists')
        .select('name')
        .eq('id', topArtist?.id)
        .single()

      const welcomeMessage = artistData?.name 
        ? `Welcome to PiggyBong! ${artistData.name} fans are known for being smart with their money. Let's make your fan dreams come true! 💜`
        : `Welcome to PiggyBong! You're ready to plan your fan life without overspending. Let's get started! ✨`

      await supabase
        .from('ai_tips')
        .insert({
          user_id: user.id,
          artist_id: topArtist?.id || null,
          tip_type: 'cheer',
          message: welcomeMessage,
          is_premium: false
        })

      // 6. Add onboarding completion activity
      await supabase
        .from('fan_activity')
        .insert({
          user_id: user.id,
          activity_type: 'onboarding_complete',
          title: 'Welcome to PiggyBong!',
          description: `Added ${requestBody.selected_artists.length} artists and set $${requestBody.monthly_budget} monthly budget`
        })

      // Prepare response
      const response = {
        success: true,
        user_id: user.id,
        artists_added: requestBody.selected_artists.length,
        goals_created: createdGoals.length,
        total_budget: requestBody.monthly_budget,
        welcome_message: welcomeMessage,
        created_goals: createdGoals
      }

      return new Response(
        JSON.stringify(response),
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )

    } catch (error) {
      console.error('Transaction error:', error)
      return new Response(
        JSON.stringify({ error: `Onboarding failed: ${error.message}` }),
        {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

  } catch (error) {
    console.error('Onboarding complete error:', error)
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    )
  }
})