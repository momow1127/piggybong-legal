import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, GET, OPTIONS, PUT, DELETE',
};

interface NotificationRequest {
  user_id?: string;
  notification_type?: 'all' | 'budget' | 'goal' | 'release' | 'reminder';
  immediate?: boolean;
}

interface SmartNotification {
  id: string;
  user_id: string;
  type: string;
  title: string;
  body: string;
  action_text?: string;
  action_url?: string;
  priority: 'low' | 'medium' | 'high' | 'urgent';
  scheduled_for: string;
  metadata?: Record<string, any>;
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL');
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

    if (!supabaseUrl || !supabaseKey) {
      throw new Error('Missing Supabase configuration');
    }

    const supabase = createClient(supabaseUrl, supabaseKey);

    let requestBody: NotificationRequest = {};
    if (req.method === 'POST') {
      requestBody = await req.json();
    }

    const {
      user_id,
      notification_type = 'all',
      immediate = false
    } = requestBody;

    console.log(`Smart Notifications triggered: type=${notification_type}, user=${user_id || 'all'}`);

    const notifications: SmartNotification[] = [];

    // Generate notifications
    if (user_id) {
      const userNotifications = await generatePersonalizedNotifications(supabase, user_id, notification_type);
      notifications.push(...userNotifications);
    } else {
      const allUserNotifications = await generateBulkNotifications(supabase, notification_type);
      notifications.push(...allUserNotifications);
    }

    // Process and send notifications
    const processedNotifications: SmartNotification[] = [];
    for (const notification of notifications) {
      try {
        if (immediate) {
          await sendImmediateNotification(notification);
        } else {
          await scheduleNotification(supabase, notification);
        }
        processedNotifications.push(notification);
      } catch (error) {
        console.error(`Failed to process notification ${notification.id}:`, error);
      }
    }

    console.log(`Processed ${processedNotifications.length} smart notifications`);

    return new Response(
      JSON.stringify({
        success: true,
        processed: processedNotifications.length,
        notifications: processedNotifications.map((n) => ({
          id: n.id,
          user_id: n.user_id,
          type: n.type,
          title: n.title,
          priority: n.priority,
          scheduled_for: n.scheduled_for
        }))
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    );

  } catch (error) {
    console.error('Smart Notifications Error:', error);
    return new Response(
      JSON.stringify({
        error: 'Internal server error',
        details: error.message
      }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    );
  }
});

async function generatePersonalizedNotifications(
  supabase: any,
  userId: string,
  type: string
): Promise<SmartNotification[]> {
  const notifications: SmartNotification[] = [];

  // Fetch user data
  const { data: user } = await supabase
    .from('users')
    .select('*')
    .eq('id', userId)
    .single();

  if (!user) return notifications;

  // Generate different types of notifications
  if (type === 'budget' || type === 'all') {
    const budgetNotifications = await generateBudgetNotifications(supabase, user);
    notifications.push(...budgetNotifications);
  }

  if (type === 'goal' || type === 'all') {
    const goalNotifications = await generateGoalNotifications(supabase, user);
    notifications.push(...goalNotifications);
  }

  if (type === 'release' || type === 'all') {
    const releaseNotifications = await generateReleaseNotifications(supabase, user);
    notifications.push(...releaseNotifications);
  }

  if (type === 'reminder' || type === 'all') {
    const reminderNotifications = await generateReminderNotifications(supabase, user);
    notifications.push(...reminderNotifications);
  }

  return notifications;
}

async function generateBudgetNotifications(supabase: any, user: any): Promise<SmartNotification[]> {
  const notifications: SmartNotification[] = [];
  const now = new Date();
  const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);

  // Get current month spending
  const { data: spending } = await supabase
    .from('fan_activities')
    .select('amount')
    .eq('user_id', user.id)
    .gte('created_at', startOfMonth.toISOString());

  const totalSpent = spending?.reduce((sum: number, tx: any) => sum + (tx.amount || 0), 0) || 0;
  const monthlyBudget = user.monthly_budget || 500; // Default budget
  const budgetUsed = (totalSpent / monthlyBudget) * 100;

  // Critical budget alert
  if (budgetUsed >= 90) {
    notifications.push({
      id: `budget-critical-${user.id}-${Date.now()}`,
      user_id: user.id,
      type: 'budget_alert',
      title: '🚨 Budget Alert!',
      body: `You've used ${budgetUsed.toFixed(1)}% of your monthly budget ($${totalSpent.toFixed(2)}/$${monthlyBudget})`,
      action_text: 'Review Spending',
      action_url: '/budget',
      priority: 'urgent',
      scheduled_for: now.toISOString(),
      metadata: {
        budget_used: budgetUsed,
        total_spent: totalSpent,
        monthly_budget: monthlyBudget
      }
    });
  }
  // Warning at 75%
  else if (budgetUsed >= 75) {
    notifications.push({
      id: `budget-warning-${user.id}-${Date.now()}`,
      user_id: user.id,
      type: 'budget_warning',
      title: '⚠️ Budget Check',
      body: `You're at ${budgetUsed.toFixed(1)}% of your monthly budget. $${(monthlyBudget - totalSpent).toFixed(2)} remaining.`,
      action_text: 'View Budget',
      action_url: '/budget',
      priority: 'medium',
      scheduled_for: now.toISOString(),
      metadata: {
        budget_used: budgetUsed,
        remaining: monthlyBudget - totalSpent
      }
    });
  }
  // Opportunity notification
  else if (budgetUsed < 50 && now.getDate() > 15) {
    notifications.push({
      id: `budget-opportunity-${user.id}-${Date.now()}`,
      user_id: user.id,
      type: 'budget_insight',
      title: '💡 Budget Opportunity',
      body: `You have $${(monthlyBudget - totalSpent).toFixed(2)} left this month! Perfect time to save for upcoming releases.`,
      action_text: 'Set Goal',
      action_url: '/goals',
      priority: 'low',
      scheduled_for: now.toISOString(),
      metadata: {
        available_budget: monthlyBudget - totalSpent
      }
    });
  }

  return notifications;
}

async function generateGoalNotifications(supabase: any, user: any): Promise<SmartNotification[]> {
  const notifications: SmartNotification[] = [];
  const now = new Date();

  // Get user's active goals
  const { data: goals } = await supabase
    .from('goals')
    .select('*, artists(name)')
    .eq('user_id', user.id)
    .eq('is_active', true);

  for (const goal of goals || []) {
    const deadline = new Date(goal.deadline);
    const daysUntilDeadline = Math.ceil((deadline.getTime() - now.getTime()) / (1000 * 60 * 60 * 24));
    const progressPercent = (goal.current_amount / goal.target_amount) * 100;

    // Deadline approaching
    if (daysUntilDeadline <= 7 && daysUntilDeadline > 0) {
      const urgency = daysUntilDeadline <= 3 ? 'urgent' : 'high';
      notifications.push({
        id: `goal-deadline-${goal.id}-${Date.now()}`,
        user_id: user.id,
        type: 'goal_deadline',
        title: `⏰ Goal Deadline Approaching`,
        body: `"${goal.title}" deadline is in ${daysUntilDeadline} days. You're ${progressPercent.toFixed(1)}% complete.`,
        action_text: 'View Goal',
        action_url: `/goals/${goal.id}`,
        priority: urgency,
        scheduled_for: now.toISOString(),
        metadata: {
          goal_id: goal.id,
          days_left: daysUntilDeadline,
          progress: progressPercent
        }
      });
    }

    // Milestone achievement
    if (progressPercent >= 75 && progressPercent < 100) {
      notifications.push({
        id: `goal-milestone-${goal.id}-${Date.now()}`,
        user_id: user.id,
        type: 'goal_milestone',
        title: '🎯 Almost There!',
        body: `You're ${progressPercent.toFixed(1)}% done with "${goal.title}". Only $${(goal.target_amount - goal.current_amount).toFixed(2)} to go!`,
        action_text: 'Add Progress',
        action_url: `/goals/${goal.id}`,
        priority: 'medium',
        scheduled_for: now.toISOString(),
        metadata: {
          goal_id: goal.id,
          progress: progressPercent,
          remaining: goal.target_amount - goal.current_amount
        }
      });
    }
  }

  return notifications;
}

async function generateReleaseNotifications(supabase: any, user: any): Promise<SmartNotification[]> {
  const notifications: SmartNotification[] = [];

  // Get user's followed artists
  const { data: userArtists } = await supabase
    .from('fan_idols')
    .select('artist_id, artists(name)')
    .eq('user_id', user.id);

  // Get upcoming events for followed artists
  const { data: upcomingEvents } = await supabase
    .from('events')
    .select('*')
    .gte('event_date', new Date().toISOString())
    .lte('event_date', new Date(Date.now() + 14 * 24 * 60 * 60 * 1000).toISOString());

  for (const event of upcomingEvents || []) {
    const isFollowing = userArtists?.some((ua: any) => ua.artist_id === event.artist_id);

    if (isFollowing) {
      const eventDate = new Date(event.event_date);
      const daysUntil = Math.ceil((eventDate.getTime() - Date.now()) / (1000 * 60 * 60 * 24));

      notifications.push({
        id: `release-${event.id}-${Date.now()}`,
        user_id: user.id,
        type: 'release_alert',
        title: `🎵 ${event.artist_name} Event Coming Soon!`,
        body: `${event.title} is in ${daysUntil} days. Start saving now!`,
        action_text: 'Set Goal',
        action_url: '/goals/new',
        priority: 'medium',
        scheduled_for: new Date().toISOString(),
        metadata: {
          event_id: event.id,
          artist_name: event.artist_name,
          event_date: event.event_date,
          days_until: daysUntil
        }
      });
    }
  }

  return notifications;
}

async function generateReminderNotifications(supabase: any, user: any): Promise<SmartNotification[]> {
  const notifications: SmartNotification[] = [];
  const now = new Date();

  // Weekly spending review (Mondays)
  if (now.getDay() === 1) {
    const weekAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);

    const { data: weeklySpending } = await supabase
      .from('fan_activities')
      .select('amount')
      .eq('user_id', user.id)
      .gte('created_at', weekAgo.toISOString());

    const weeklySpent = weeklySpending?.reduce((sum: number, tx: any) => sum + (tx.amount || 0), 0) || 0;

    if (weeklySpent > 0) {
      notifications.push({
        id: `weekly-reminder-${user.id}-${Date.now()}`,
        user_id: user.id,
        type: 'weekly_reminder',
        title: '📊 Weekly Spending Review',
        body: `Last week you spent $${weeklySpent.toFixed(2)} on K-pop. Review your spending patterns!`,
        action_text: 'View Analysis',
        action_url: '/dashboard',
        priority: 'low',
        scheduled_for: now.toISOString(),
        metadata: {
          weekly_spent: weeklySpent
        }
      });
    }
  }

  return notifications;
}

async function generateBulkNotifications(supabase: any, type: string): Promise<SmartNotification[]> {
  const { data: activeUsers } = await supabase
    .from('users')
    .select('id')
    .not('last_active_at', 'is', null);

  const allNotifications: SmartNotification[] = [];

  for (const user of activeUsers || []) {
    const userNotifications = await generatePersonalizedNotifications(supabase, user.id, type);
    allNotifications.push(...userNotifications);
  }

  return allNotifications;
}

async function scheduleNotification(supabase: any, notification: SmartNotification) {
  const { error } = await supabase
    .from('scheduled_notifications')
    .insert({
      id: notification.id,
      user_id: notification.user_id,
      type: notification.type,
      title: notification.title,
      body: notification.body,
      action_text: notification.action_text,
      action_url: notification.action_url,
      priority: notification.priority,
      scheduled_for: notification.scheduled_for,
      metadata: notification.metadata,
      status: 'scheduled'
    });

  if (error) {
    console.error('Failed to schedule notification:', error);
    throw error;
  }
}

async function sendImmediateNotification(notification: SmartNotification) {
  // In production, integrate with push notification services:
  // - Apple Push Notification Service (APNs)
  // - Firebase Cloud Messaging (FCM)
  // - OneSignal
  console.log(`Sending immediate notification: ${notification.title} to user ${notification.user_id}`);

  // For now, just log. In production, you'd call your push service here.
}