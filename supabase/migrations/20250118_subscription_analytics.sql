-- Subscription Analytics and Events Tracking
-- This helps track subscription behavior and optimize the freemium model

-- Subscription events for analytics
CREATE TABLE IF NOT EXISTS user_subscription_events (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    event_type TEXT NOT NULL, -- 'INITIAL_PURCHASE', 'RENEWAL', 'CANCELLATION', 'EXPIRATION', 'BILLING_ISSUE', 'PRODUCT_CHANGE'
    plan_type TEXT NOT NULL,
    revenue_usd DECIMAL(10,2) DEFAULT 0,
    product_id TEXT,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- User engagement tracking for conversion optimization
CREATE TABLE IF NOT EXISTS user_engagement_events (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    event_type TEXT NOT NULL, -- 'limit_hit_artist', 'limit_hit_goal', 'upgrade_prompt_shown', 'upgrade_prompt_clicked', 'feature_gated'
    feature_context TEXT, -- 'add_artist', 'add_goal', 'premium_news', etc.
    plan_type TEXT NOT NULL DEFAULT 'free',
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Feature usage analytics
CREATE TABLE IF NOT EXISTS feature_usage_stats (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    feature_name TEXT NOT NULL, -- 'artist_management', 'goal_tracking', 'news_feed', 'spending_tracking'
    usage_count INTEGER DEFAULT 1,
    last_used TIMESTAMPTZ DEFAULT NOW(),
    plan_type TEXT NOT NULL DEFAULT 'free',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(user_id, feature_name, DATE(created_at))
);

-- Indexes for analytics queries
CREATE INDEX IF NOT EXISTS idx_subscription_events_user_type ON user_subscription_events(user_id, event_type);
CREATE INDEX IF NOT EXISTS idx_subscription_events_created ON user_subscription_events(created_at);
CREATE INDEX IF NOT EXISTS idx_engagement_events_type ON user_engagement_events(event_type, plan_type);
CREATE INDEX IF NOT EXISTS idx_feature_usage_feature_plan ON feature_usage_stats(feature_name, plan_type);
CREATE INDEX IF NOT EXISTS idx_feature_usage_user_recent ON feature_usage_stats(user_id, last_used DESC);

-- Function to track engagement events
CREATE OR REPLACE FUNCTION track_engagement_event(
    p_user_id UUID,
    p_event_type TEXT,
    p_feature_context TEXT DEFAULT NULL,
    p_metadata JSONB DEFAULT '{}'::JSONB
)
RETURNS VOID AS $$
DECLARE
    user_plan TEXT;
BEGIN
    -- Get user's current plan
    SELECT plan_type INTO user_plan
    FROM user_subscriptions
    WHERE user_id = p_user_id AND status = 'active';
    
    IF user_plan IS NULL THEN
        user_plan := 'free';
    END IF;
    
    -- Insert engagement event
    INSERT INTO user_engagement_events (user_id, event_type, feature_context, plan_type, metadata)
    VALUES (p_user_id, p_event_type, p_feature_context, user_plan, p_metadata);
END;
$$ LANGUAGE plpgsql;

-- Function to track feature usage
CREATE OR REPLACE FUNCTION track_feature_usage(
    p_user_id UUID,
    p_feature_name TEXT
)
RETURNS VOID AS $$
DECLARE
    user_plan TEXT;
BEGIN
    -- Get user's current plan
    SELECT plan_type INTO user_plan
    FROM user_subscriptions
    WHERE user_id = p_user_id AND status = 'active';
    
    IF user_plan IS NULL THEN
        user_plan := 'free';
    END IF;
    
    -- Update or insert feature usage
    INSERT INTO feature_usage_stats (user_id, feature_name, plan_type)
    VALUES (p_user_id, p_feature_name, user_plan)
    ON CONFLICT (user_id, feature_name, DATE(created_at))
    DO UPDATE SET
        usage_count = feature_usage_stats.usage_count + 1,
        last_used = NOW();
END;
$$ LANGUAGE plpgsql;

-- Enhanced limit checking with engagement tracking
CREATE OR REPLACE FUNCTION can_add_artist_with_tracking(p_user_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    can_add BOOLEAN;
    user_plan TEXT;
BEGIN
    -- Check if can add artist
    SELECT can_add_artist(p_user_id) INTO can_add;
    
    -- If cannot add, track the limit hit event
    IF NOT can_add THEN
        SELECT plan_type INTO user_plan
        FROM user_subscriptions
        WHERE user_id = p_user_id AND status = 'active';
        
        IF user_plan IS NULL THEN
            user_plan := 'free';
        END IF;
        
        PERFORM track_engagement_event(
            p_user_id,
            'limit_hit_artist',
            'add_artist',
            jsonb_build_object('current_plan', user_plan)
        );
    END IF;
    
    RETURN can_add;
END;
$$ LANGUAGE plpgsql;

-- Enhanced goal limit checking with tracking
CREATE OR REPLACE FUNCTION can_add_goal_with_tracking(p_user_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    can_add BOOLEAN;
    user_plan TEXT;
BEGIN
    -- Check if can add goal
    SELECT can_add_goal(p_user_id) INTO can_add;
    
    -- If cannot add, track the limit hit event
    IF NOT can_add THEN
        SELECT plan_type INTO user_plan
        FROM user_subscriptions
        WHERE user_id = p_user_id AND status = 'active';
        
        IF user_plan IS NULL THEN
            user_plan := 'free';
        END IF;
        
        PERFORM track_engagement_event(
            p_user_id,
            'limit_hit_goal',
            'add_goal',
            jsonb_build_object('current_plan', user_plan)
        );
    END IF;
    
    RETURN can_add;
END;
$$ LANGUAGE plpgsql;

-- Analytics view for conversion funnel
CREATE OR REPLACE VIEW subscription_conversion_funnel AS
WITH user_journey AS (
    SELECT 
        u.id as user_id,
        u.created_at as signup_date,
        COALESCE(us.plan_type, 'free') as current_plan,
        us.created_at as subscription_date,
        
        -- Engagement metrics
        (SELECT COUNT(*) FROM user_engagement_events uee 
         WHERE uee.user_id = u.id AND uee.event_type = 'limit_hit_artist') as artist_limit_hits,
        (SELECT COUNT(*) FROM user_engagement_events uee 
         WHERE uee.user_id = u.id AND uee.event_type = 'limit_hit_goal') as goal_limit_hits,
        (SELECT COUNT(*) FROM user_engagement_events uee 
         WHERE uee.user_id = u.id AND uee.event_type = 'upgrade_prompt_shown') as upgrade_prompts_shown,
        (SELECT COUNT(*) FROM user_engagement_events uee 
         WHERE uee.user_id = u.id AND uee.event_type = 'upgrade_prompt_clicked') as upgrade_prompts_clicked,
        
        -- Usage metrics
        (SELECT COUNT(*) FROM user_artists ua WHERE ua.user_id = u.id AND ua.is_active = TRUE) as artists_followed,
        (SELECT COUNT(*) FROM goals g WHERE g.user_id = u.id AND g.is_active = TRUE) as active_goals,
        (SELECT COUNT(*) FROM purchases p WHERE p.user_id = u.id) as total_purchases,
        
        -- Time to conversion (if applicable)
        CASE WHEN us.created_at IS NOT NULL 
             THEN EXTRACT(DAYS FROM us.created_at - u.created_at)
             ELSE NULL 
        END as days_to_conversion
        
    FROM users u
    LEFT JOIN user_subscriptions us ON u.id = us.user_id AND us.status = 'active'
    WHERE u.created_at >= NOW() - INTERVAL '90 days' -- Last 90 days for relevant funnel analysis
)
SELECT 
    current_plan,
    COUNT(*) as users_count,
    AVG(artist_limit_hits) as avg_artist_limit_hits,
    AVG(goal_limit_hits) as avg_goal_limit_hits,
    AVG(upgrade_prompts_shown) as avg_upgrade_prompts_shown,
    AVG(upgrade_prompts_clicked) as avg_upgrade_prompts_clicked,
    AVG(artists_followed) as avg_artists_followed,
    AVG(active_goals) as avg_active_goals,
    AVG(total_purchases) as avg_total_purchases,
    AVG(days_to_conversion) FILTER (WHERE days_to_conversion IS NOT NULL) as avg_days_to_conversion,
    COUNT(*) FILTER (WHERE upgrade_prompts_clicked > 0) as users_who_clicked_upgrade,
    ROUND(
        (COUNT(*) FILTER (WHERE upgrade_prompts_clicked > 0) * 100.0 / 
         NULLIF(COUNT(*) FILTER (WHERE upgrade_prompts_shown > 0), 0)), 
        2
    ) as upgrade_click_rate_percent
FROM user_journey
GROUP BY current_plan;

-- Function to get subscription insights for admin dashboard
CREATE OR REPLACE FUNCTION get_subscription_insights(days_back INTEGER DEFAULT 30)
RETURNS TABLE(
    metric_name TEXT,
    metric_value NUMERIC,
    plan_type TEXT,
    period_label TEXT
) AS $$
BEGIN
    RETURN QUERY
    
    -- User acquisition by plan
    SELECT 
        'new_users' as metric_name,
        COUNT(*)::NUMERIC as metric_value,
        COALESCE(us.plan_type, 'free') as plan_type,
        'last_' || days_back || '_days' as period_label
    FROM users u
    LEFT JOIN user_subscriptions us ON u.id = us.user_id AND us.status = 'active'
    WHERE u.created_at >= NOW() - (days_back || ' days')::INTERVAL
    GROUP BY us.plan_type
    
    UNION ALL
    
    -- Conversion events
    SELECT 
        'conversions' as metric_name,
        COUNT(*)::NUMERIC as metric_value,
        'paid' as plan_type,
        'last_' || days_back || '_days' as period_label
    FROM user_subscription_events use
    WHERE use.created_at >= NOW() - (days_back || ' days')::INTERVAL
    AND use.event_type = 'INITIAL_PURCHASE'
    
    UNION ALL
    
    -- Revenue
    SELECT 
        'revenue_usd' as metric_name,
        COALESCE(SUM(use.revenue_usd), 0) as metric_value,
        'paid' as plan_type,
        'last_' || days_back || '_days' as period_label
    FROM user_subscription_events use
    WHERE use.created_at >= NOW() - (days_back || ' days')::INTERVAL
    AND use.event_type IN ('INITIAL_PURCHASE', 'RENEWAL')
    
    UNION ALL
    
    -- Churn events
    SELECT 
        'churned_users' as metric_name,
        COUNT(*)::NUMERIC as metric_value,
        'free' as plan_type,
        'last_' || days_back || '_days' as period_label
    FROM user_subscription_events use
    WHERE use.created_at >= NOW() - (days_back || ' days')::INTERVAL
    AND use.event_type IN ('CANCELLATION', 'EXPIRATION')
    
    ORDER BY metric_name, plan_type;
END;
$$ LANGUAGE plpgsql;

-- RLS Policies for analytics tables
ALTER TABLE user_subscription_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_engagement_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE feature_usage_stats ENABLE ROW LEVEL SECURITY;

-- Users can only see their own events
CREATE POLICY "Users see own subscription events" ON user_subscription_events
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users see own engagement events" ON user_engagement_events
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users see own feature usage" ON feature_usage_stats
    FOR SELECT USING (auth.uid() = user_id);

-- Service role can manage all analytics data
CREATE POLICY "Service role manages subscription events" ON user_subscription_events
    FOR ALL USING (auth.jwt() ->> 'role' = 'service_role');

CREATE POLICY "Service role manages engagement events" ON user_engagement_events
    FOR ALL USING (auth.jwt() ->> 'role' = 'service_role');

CREATE POLICY "Service role manages feature usage" ON feature_usage_stats
    FOR ALL USING (auth.jwt() ->> 'role' = 'service_role');