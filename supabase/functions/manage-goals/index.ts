import { serve } from "https://deno.land/std@0.224.0/http/server.ts"
import { corsHeaders } from '../_shared/cors.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const supabaseUrl = Deno.env.get('SUPABASE_URL')!
const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
const supabase = createClient(supabaseUrl, supabaseServiceKey)

interface GoalRequest {
  action: 'create' | 'update' | 'delete' | 'toggle_active' | 'get_goals' | 'add_progress'
  goal_id?: string
  name?: string
  description?: string
  target_amount?: number
  artist_id?: string
  goal_type?: string
  event_date?: string
  is_time_sensitive?: boolean
  is_active?: boolean
  priority?: number
  progress_amount?: number
  progress_note?: string
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      throw new Error('Authorization header required')
    }

    const token = authHeader.replace('Bearer ', '')
    const { data: { user }, error: authError } = await supabase.auth.getUser(token)
    
    if (authError || !user) {
      throw new Error('Invalid authentication')
    }

    const body = await req.json() as GoalRequest
    let result = {}

    switch (body.action) {
      case 'create':
        // Check if user can add more goals
        const { data: canAddGoal, error: limitError } = await supabase
          .rpc('can_add_goal', { p_user_id: user.id })
        
        if (limitError) {
          throw new Error(`Limit check failed: ${limitError.message}`)
        }
        
        if (!canAddGoal) {
          return new Response(
            JSON.stringify({
              success: false,
              error: 'Goal limit reached',
              message: 'You have reached your active goal limit. Upgrade to Premium to track more goals simultaneously, or deactivate an existing goal.',
              requires_upgrade: true,
              current_plan: 'free'
            }),
            { 
              status: 403,
              headers: { ...corsHeaders, 'Content-Type': 'application/json' }
            }
          )
        }

        // Create new goal
        const { data: newGoal, error: createError } = await supabase
          .from('goals')
          .insert({
            user_id: user.id,
            name: body.name,
            description: body.description,
            target_amount: body.target_amount,
            artist_id: body.artist_id,
            goal_type: body.goal_type || 'general',
            event_date: body.event_date,
            is_time_sensitive: body.is_time_sensitive || false,
            is_active: true, // New goals are active by default
            priority: body.priority || await getNextGoalPriority(user.id),
            current_amount: 0.00
          })
          .select(`
            *,
            artists (
              id,
              name,
              display_name
            )
          `)
          .single()

        if (createError) {
          throw new Error(`Failed to create goal: ${createError.message}`)
        }

        result = {
          success: true,
          message: 'Goal created successfully',
          goal: newGoal
        }
        break

      case 'update':
        if (!body.goal_id) {
          throw new Error('goal_id is required for update')
        }

        const updateData: any = {}
        if (body.name !== undefined) updateData.name = body.name
        if (body.description !== undefined) updateData.description = body.description
        if (body.target_amount !== undefined) updateData.target_amount = body.target_amount
        if (body.goal_type !== undefined) updateData.goal_type = body.goal_type
        if (body.event_date !== undefined) updateData.event_date = body.event_date
        if (body.is_time_sensitive !== undefined) updateData.is_time_sensitive = body.is_time_sensitive
        if (body.priority !== undefined) updateData.priority = body.priority

        const { data: updatedGoal, error: updateError } = await supabase
          .from('goals')
          .update({ ...updateData, updated_at: new Date().toISOString() })
          .eq('id', body.goal_id)
          .eq('user_id', user.id) // Security check
          .select(`
            *,
            artists (
              id,
              name,
              display_name
            )
          `)
          .single()

        if (updateError) {
          throw new Error(`Failed to update goal: ${updateError.message}`)
        }

        result = {
          success: true,
          message: 'Goal updated successfully',
          goal: updatedGoal
        }
        break

      case 'toggle_active':
        if (!body.goal_id) {
          throw new Error('goal_id is required for toggle_active')
        }

        // Get current goal status
        const { data: currentGoal, error: getCurrentError } = await supabase
          .from('goals')
          .select('is_active, user_id')
          .eq('id', body.goal_id)
          .single()

        if (getCurrentError || !currentGoal || currentGoal.user_id !== user.id) {
          throw new Error('Goal not found or access denied')
        }

        const newActiveStatus = !currentGoal.is_active

        // If activating, check limits
        if (newActiveStatus) {
          const { data: canActivate, error: activateError } = await supabase
            .rpc('can_add_goal', { p_user_id: user.id })
          
          if (activateError) {
            throw new Error(`Limit check failed: ${activateError.message}`)
          }
          
          if (!canActivate) {
            return new Response(
              JSON.stringify({
                success: false,
                error: 'Cannot activate goal - limit reached',
                message: 'You have reached your active goal limit. Upgrade to Premium or deactivate another goal first.',
                requires_upgrade: true
              }),
              { 
                status: 403,
                headers: { ...corsHeaders, 'Content-Type': 'application/json' }
              }
            )
          }
        }

        const { data: toggledGoal, error: toggleError } = await supabase
          .from('goals')
          .update({ 
            is_active: newActiveStatus,
            updated_at: new Date().toISOString()
          })
          .eq('id', body.goal_id)
          .eq('user_id', user.id)
          .select(`
            *,
            artists (
              id,
              name,
              display_name
            )
          `)
          .single()

        if (toggleError) {
          throw new Error(`Failed to toggle goal: ${toggleError.message}`)
        }

        result = {
          success: true,
          message: `Goal ${newActiveStatus ? 'activated' : 'deactivated'} successfully`,
          goal: toggledGoal
        }
        break

      case 'add_progress':
        if (!body.goal_id || body.progress_amount === undefined) {
          throw new Error('goal_id and progress_amount are required')
        }

        // Add progress record
        const { data: progressRecord, error: progressError } = await supabase
          .from('goal_progress')
          .insert({
            goal_id: body.goal_id,
            amount_added: body.progress_amount,
            note: body.progress_note
          })
          .select()
          .single()

        if (progressError) {
          throw new Error(`Failed to add progress: ${progressError.message}`)
        }

        // Get updated goal with new amount (updated by trigger)
        const { data: updatedGoalProgress, error: getUpdatedError } = await supabase
          .from('goals')
          .select(`
            *,
            artists (
              id,
              name,
              display_name
            )
          `)
          .eq('id', body.goal_id)
          .single()

        if (getUpdatedError) {
          throw new Error(`Failed to get updated goal: ${getUpdatedError.message}`)
        }

        result = {
          success: true,
          message: 'Progress added successfully',
          goal: updatedGoalProgress,
          progress_record: progressRecord
        }
        break

      case 'get_goals':
        // Get user's goals with subscription context
        const { data: userGoals, error: getGoalsError } = await supabase
          .from('goals')
          .select(`
            *,
            artists (
              id,
              name,
              display_name,
              type
            )
          `)
          .eq('user_id', user.id)
          .order('is_active', { ascending: false })
          .order('priority', { ascending: false })
          .order('created_at', { ascending: false })

        if (getGoalsError) {
          throw new Error(`Failed to get goals: ${getGoalsError.message}`)
        }

        // Get user limits for context
        const { data: limits, error: limitsError } = await supabase
          .rpc('get_user_limits', { p_user_id: user.id })

        const userLimits = limits?.[0] || {
          plan_type: 'free',
          max_active_goals: 1,
          current_active_goals: userGoals.filter(g => g.is_active).length
        }

        // Enhanced goals with countdown info
        const { data: goalsWithCountdown, error: countdownError } = await supabase
          .rpc('get_fan_goals_with_countdown', { p_user_id: user.id })

        result = {
          success: true,
          goals: userGoals,
          goals_with_countdown: goalsWithCountdown || [],
          limits: userLimits,
          summary: {
            total_goals: userGoals.length,
            active_goals: userGoals.filter(g => g.is_active).length,
            inactive_goals: userGoals.filter(g => !g.is_active).length,
            time_sensitive_goals: userGoals.filter(g => g.is_time_sensitive && g.is_active).length,
            total_target_amount: userGoals
              .filter(g => g.is_active)
              .reduce((sum, goal) => sum + (goal.target_amount || 0), 0),
            total_current_amount: userGoals
              .filter(g => g.is_active)
              .reduce((sum, goal) => sum + (goal.current_amount || 0), 0)
          }
        }
        break

      case 'delete':
        if (!body.goal_id) {
          throw new Error('goal_id is required for delete')
        }

        const { error: deleteError } = await supabase
          .from('goals')
          .delete()
          .eq('id', body.goal_id)
          .eq('user_id', user.id) // Security check

        if (deleteError) {
          throw new Error(`Failed to delete goal: ${deleteError.message}`)
        }

        result = {
          success: true,
          message: 'Goal deleted successfully'
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
    console.error('Goal management error:', error)
    
    return new Response(
      JSON.stringify({ 
        success: false,
        error: error.message || 'Internal server error'
      }),
      { 
        status: error.message.includes('limit reached') || error.message.includes('requires_upgrade') ? 403 : 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  }
})

// Helper function to get next goal priority
async function getNextGoalPriority(userId: string): Promise<number> {
  const { data, error } = await supabase
    .from('goals')
    .select('priority')
    .eq('user_id', userId)
    .order('priority', { ascending: false })
    .limit(1)
  
  if (error || !data || data.length === 0) {
    return 1
  }
  
  return data[0].priority + 1
}