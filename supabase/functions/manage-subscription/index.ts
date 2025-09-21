import { serve } from "https://deno.land/std@0.224.0/http/server.ts"
import { corsHeaders } from '../_shared/cors.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const supabaseUrl = Deno.env.get('SUPABASE_URL')!
const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
const supabase = createClient(supabaseUrl, supabaseServiceKey)

interface SubscriptionRequest {
  action: 'get_limits' | 'check_can_add_artist' | 'check_can_add_goal' | 'handle_downgrade' | 'get_dashboard_data' | 'sync_revenuecat'
  goal_to_keep?: string
  revenuecat_user_id?: string
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Get user from Authorization header
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      throw new Error('Authorization header required')
    }

    const token = authHeader.replace('Bearer ', '')
    const { data: { user }, error: authError } = await supabase.auth.getUser(token)
    
    if (authError || !user) {
      throw new Error('Invalid authentication')
    }

    const body = await req.json() as SubscriptionRequest
    let result = {}

    switch (body.action) {
      case 'get_limits':
        // Get user's current limits and usage
        const { data: limits, error: limitsError } = await supabase
          .rpc('get_user_limits', { p_user_id: user.id })

        if (limitsError) throw limitsError

        result = {
          success: true,
          limits: limits[0] || {
            plan_type: 'free',
            max_artists: 3,
            max_active_goals: 1,
            current_artists: 0,
            current_active_goals: 0,
            can_add_artist: true,
            can_add_goal: true
          }
        }
        break

      case 'check_can_add_artist':
        const { data: canAddArtist, error: artistError } = await supabase
          .rpc('can_add_artist', { p_user_id: user.id })

        if (artistError) throw artistError

        result = {
          success: true,
          can_add: canAddArtist,
          message: canAddArtist ? 'Can add artist' : 'Artist limit reached. Upgrade to add more artists.'
        }
        break

      case 'check_can_add_goal':
        const { data: canAddGoal, error: goalError } = await supabase
          .rpc('can_add_goal', { p_user_id: user.id })

        if (goalError) throw goalError

        result = {
          success: true,
          can_add: canAddGoal,
          message: canAddGoal ? 'Can add goal' : 'Goal limit reached. Upgrade to track more goals simultaneously.'
        }
        break

      case 'handle_downgrade':
        if (!body.goal_to_keep) {
          throw new Error('goal_to_keep is required for downgrade')
        }

        const { data: downgradeResult, error: downgradeError } = await supabase
          .rpc('handle_goal_downgrade', {
            p_user_id: user.id,
            p_goal_to_keep: body.goal_to_keep
          })

        if (downgradeError) throw downgradeError

        result = {
          success: true,
          message: 'Successfully handled subscription downgrade'
        }
        break

      case 'get_dashboard_data':
        const { data: dashboardData, error: dashboardError } = await supabase
          .rpc('get_user_dashboard_data', { p_user_id: user.id })

        if (dashboardError) throw dashboardError

        result = {
          success: true,
          dashboard: dashboardData[0] || {
            plan_type: 'free',
            artist_slots_used: 0,
            artist_slots_total: 3,
            active_goals: 0,
            goal_slots_total: 1,
            recent_purchases: 0,
            monthly_spent: 0,
            can_upgrade: true,
            upgrade_benefits: ['Track up to 3 active goals', 'Premium news sources', 'Advanced analytics']
          }
        }
        break

      case 'sync_revenuecat':
        // Manual sync with RevenueCat for edge cases
        if (!body.revenuecat_user_id) {
          throw new Error('revenuecat_user_id required for sync')
        }

        // In a real implementation, you'd call RevenueCat API to get current subscription status
        // For MVP, we'll just verify the user has a valid subscription in our DB
        const { data: subscription, error: syncError } = await supabase
          .from('user_subscriptions')
          .select('*')
          .eq('user_id', user.id)
          .eq('status', 'active')
          .single()

        if (syncError && syncError.code !== 'PGRST116') { // Not found is ok
          throw syncError
        }

        result = {
          success: true,
          subscription: subscription || {
            plan_type: 'free',
            status: 'active',
            max_artists: 3,
            max_active_goals: 1
          },
          message: 'Subscription synced successfully'
        }
        break

      default:
        throw new Error(`Invalid action: ${body.action}`)
    }

    return new Response(
      JSON.stringify(result),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )

  } catch (error) {
    console.error('Subscription management error:', error)
    
    return new Response(
      JSON.stringify({ 
        success: false,
        error: error.message || 'Internal server error'
      }),
      { 
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  }
})

// Helper function to validate subscription status
async function validateSubscriptionStatus(userId: string): Promise<{ isValid: boolean, planType: string }> {
  const { data: subscription, error } = await supabase
    .from('user_subscriptions')
    .select('plan_type, status, expiration_date')
    .eq('user_id', userId)
    .eq('status', 'active')
    .single()

  if (error || !subscription) {
    return { isValid: false, planType: 'free' }
  }

  // Check if subscription has expired
  if (subscription.expiration_date && new Date(subscription.expiration_date) < new Date()) {
    // Update status to inactive
    await supabase
      .from('user_subscriptions')
      .update({ status: 'inactive', plan_type: 'free' })
      .eq('user_id', userId)
    
    return { isValid: false, planType: 'free' }
  }

  return { isValid: true, planType: subscription.plan_type }
}