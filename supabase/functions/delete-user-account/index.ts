import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

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
    // Create Supabase client with service role key for admin operations
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      {
        auth: {
          autoRefreshToken: false,
          persistSession: false
        }
      }
    )

    // Get JWT from request
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(
        JSON.stringify({ success: false, error: 'No authorization header' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Get the user from the JWT token
    const token = authHeader.replace('Bearer ', '')
    const { data: { user }, error: userError } = await supabaseAdmin.auth.getUser(token)

    if (userError || !user) {
      console.error('Auth error:', userError)
      return new Response(
        JSON.stringify({ success: false, error: 'Invalid token' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    console.log(`🗑️ Starting account deletion for user: ${user.id}`)

    // Start transaction-like deletion process
    // Order matters for foreign key constraints!

    // 1. Delete from fan_activities (references users.id)
    const { error: activitiesError } = await supabaseAdmin
      .from('fan_activities')
      .delete()
      .eq('user_id', user.id)

    if (activitiesError) {
      console.error('Error deleting fan_activities:', activitiesError)
      // Continue anyway as table might not exist
    }

    // 2. Delete from user_artists (references users.id)
    const { error: artistsError } = await supabaseAdmin
      .from('user_artists')
      .delete()
      .eq('user_id', user.id)

    if (artistsError) {
      console.error('Error deleting user_artists:', artistsError)
      // Continue anyway as table might not exist
    }

    // 3. Delete from user_priorities (references users.id)
    const { error: prioritiesError } = await supabaseAdmin
      .from('user_priorities')
      .delete()
      .eq('user_id', user.id)

    if (prioritiesError) {
      console.error('Error deleting user_priorities:', prioritiesError)
      // Continue anyway as table might not exist
    }

    // 4. Delete from insight_feedback (references users.id)
    const { error: feedbackError } = await supabaseAdmin
      .from('insight_feedback')
      .delete()
      .eq('user_id', user.id)

    if (feedbackError) {
      console.error('Error deleting insight_feedback:', feedbackError)
      // Continue anyway as table might not exist
    }

    // 5. Delete from users table
    const { error: usersError } = await supabaseAdmin
      .from('users')
      .delete()
      .eq('id', user.id)

    if (usersError) {
      console.error('Error deleting from users table:', usersError)
      return new Response(
        JSON.stringify({
          success: false,
          error: 'Failed to delete user data',
          message: usersError.message
        }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // 6. Finally, delete from auth.users (this will sign them out)
    const { error: authError } = await supabaseAdmin.auth.admin.deleteUser(user.id)

    if (authError) {
      console.error('Error deleting auth user:', authError)
      return new Response(
        JSON.stringify({
          success: false,
          error: 'Failed to delete auth account',
          message: authError.message
        }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    console.log(`✅ Successfully deleted account for user: ${user.id}`)

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Account successfully deleted'
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Unexpected error:', error)
    return new Response(
      JSON.stringify({
        success: false,
        error: 'An unexpected error occurred',
        message: error.message
      }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})