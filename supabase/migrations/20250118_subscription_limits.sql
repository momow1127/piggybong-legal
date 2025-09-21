-- Subscription Management Schema for PiggyBong MVP Limits
-- This implements the Free (3 artists, 1 goal) vs Paid (3 artists, 3 goals) tiers

-- Enhanced user subscription status table
CREATE TABLE IF NOT EXISTS user_subscriptions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    plan_type TEXT NOT NULL DEFAULT 'free' CHECK (plan_type IN ('free', 'paid')),
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'cancelled', 'past_due')),
    
    -- RevenueCat integration fields
    revenuecat_user_id TEXT,
    original_transaction_id TEXT,
    product_identifier TEXT,
    purchase_date TIMESTAMPTZ,
    expiration_date TIMESTAMPTZ,
    
    -- Plan limits (dynamically adjustable)
    max_artists INTEGER NOT NULL DEFAULT 3,
    max_active_goals INTEGER NOT NULL DEFAULT 1,
    
    -- Audit fields
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(user_id)
);

-- Create index for efficient subscription lookups
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_user_status ON user_subscriptions(user_id, status) WHERE status = 'active';
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_revenuecat ON user_subscriptions(revenuecat_user_id) WHERE revenuecat_user_id IS NOT NULL;

-- Enhanced user_artists table with soft limits
-- Note: We keep the existing table but add validation logic
ALTER TABLE user_artists ADD COLUMN IF NOT EXISTS is_premium_slot BOOLEAN DEFAULT FALSE;

-- Enhanced goals table with priority system for limit enforcement
ALTER TABLE goals ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE;
ALTER TABLE goals ADD COLUMN IF NOT EXISTS priority INTEGER DEFAULT 0; -- Higher number = higher priority for free users

-- Function to check user's current limits
CREATE OR REPLACE FUNCTION get_user_limits(p_user_id UUID)
RETURNS TABLE(
    plan_type TEXT,
    max_artists INTEGER,
    max_active_goals INTEGER,
    current_artists INTEGER,
    current_active_goals INTEGER,
    can_add_artist BOOLEAN,
    can_add_goal BOOLEAN
) AS $$
DECLARE
    user_sub user_subscriptions%ROWTYPE;
    current_artist_count INTEGER;
    current_goal_count INTEGER;
BEGIN
    -- Get user subscription info
    SELECT * INTO user_sub 
    FROM user_subscriptions 
    WHERE user_id = p_user_id AND status = 'active'
    ORDER BY updated_at DESC 
    LIMIT 1;
    
    -- If no subscription found, create free tier default
    IF user_sub IS NULL THEN
        INSERT INTO user_subscriptions (user_id, plan_type, max_artists, max_active_goals)
        VALUES (p_user_id, 'free', 3, 1)
        ON CONFLICT (user_id) DO NOTHING;
        
        SELECT * INTO user_sub 
        FROM user_subscriptions 
        WHERE user_id = p_user_id;
    END IF;
    
    -- Count current usage
    SELECT COUNT(*) INTO current_artist_count
    FROM user_artists
    WHERE user_id = p_user_id AND is_active = TRUE;
    
    SELECT COUNT(*) INTO current_goal_count
    FROM goals
    WHERE user_id = p_user_id AND is_active = TRUE;
    
    -- Return limits and current usage
    RETURN QUERY SELECT
        user_sub.plan_type,
        user_sub.max_artists,
        user_sub.max_active_goals,
        current_artist_count,
        current_goal_count,
        (current_artist_count < user_sub.max_artists) as can_add_artist,
        (current_goal_count < user_sub.max_active_goals) as can_add_goal;
END;
$$ LANGUAGE plpgsql;

-- Function to validate artist addition
CREATE OR REPLACE FUNCTION can_add_artist(p_user_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    user_limits RECORD;
BEGIN
    SELECT * INTO user_limits FROM get_user_limits(p_user_id);
    RETURN user_limits.can_add_artist;
END;
$$ LANGUAGE plpgsql;

-- Function to validate goal creation
CREATE OR REPLACE FUNCTION can_add_goal(p_user_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    user_limits RECORD;
BEGIN
    SELECT * INTO user_limits FROM get_user_limits(p_user_id);
    RETURN user_limits.can_add_goal;
END;
$$ LANGUAGE plpgsql;

-- Function to handle subscription upgrades/downgrades
CREATE OR REPLACE FUNCTION update_user_subscription(
    p_user_id UUID,
    p_plan_type TEXT,
    p_revenuecat_data JSONB DEFAULT '{}'::JSONB
)
RETURNS TABLE(
    success BOOLEAN,
    message TEXT,
    requires_goal_selection BOOLEAN
) AS $$
DECLARE
    old_plan TEXT;
    current_goals INTEGER;
    downgrade_needed BOOLEAN := FALSE;
BEGIN
    -- Get current plan
    SELECT plan_type INTO old_plan 
    FROM user_subscriptions 
    WHERE user_id = p_user_id AND status = 'active';
    
    -- Update subscription
    INSERT INTO user_subscriptions (
        user_id, 
        plan_type, 
        max_artists, 
        max_active_goals,
        revenuecat_user_id,
        original_transaction_id,
        product_identifier,
        purchase_date,
        expiration_date
    )
    VALUES (
        p_user_id,
        p_plan_type,
        3, -- Both plans have same artist limit for MVP
        CASE WHEN p_plan_type = 'paid' THEN 3 ELSE 1 END,
        p_revenuecat_data->>'user_id',
        p_revenuecat_data->>'original_transaction_id',
        p_revenuecat_data->>'product_identifier',
        CASE WHEN p_revenuecat_data->>'purchase_date' IS NOT NULL 
             THEN (p_revenuecat_data->>'purchase_date')::TIMESTAMPTZ 
             ELSE NULL END,
        CASE WHEN p_revenuecat_data->>'expiration_date' IS NOT NULL 
             THEN (p_revenuecat_data->>'expiration_date')::TIMESTAMPTZ 
             ELSE NULL END
    )
    ON CONFLICT (user_id) 
    DO UPDATE SET
        plan_type = EXCLUDED.plan_type,
        max_active_goals = EXCLUDED.max_active_goals,
        revenuecat_user_id = EXCLUDED.revenuecat_user_id,
        original_transaction_id = EXCLUDED.original_transaction_id,
        product_identifier = EXCLUDED.product_identifier,
        purchase_date = EXCLUDED.purchase_date,
        expiration_date = EXCLUDED.expiration_date,
        updated_at = NOW();
    
    -- Check if downgrade requires goal deactivation
    IF old_plan = 'paid' AND p_plan_type = 'free' THEN
        SELECT COUNT(*) INTO current_goals
        FROM goals
        WHERE user_id = p_user_id AND is_active = TRUE;
        
        IF current_goals > 1 THEN
            downgrade_needed := TRUE;
        END IF;
    END IF;
    
    RETURN QUERY SELECT
        TRUE as success,
        CASE 
            WHEN downgrade_needed THEN 'Subscription updated. Please select which goal to keep active.'
            ELSE 'Subscription updated successfully.'
        END as message,
        downgrade_needed as requires_goal_selection;
END;
$$ LANGUAGE plpgsql;

-- Function to handle goal deactivation for downgrades
CREATE OR REPLACE FUNCTION handle_goal_downgrade(
    p_user_id UUID,
    p_goal_to_keep UUID
)
RETURNS BOOLEAN AS $$
BEGIN
    -- Deactivate all goals except the chosen one
    UPDATE goals
    SET is_active = FALSE, updated_at = NOW()
    WHERE user_id = p_user_id 
    AND id != p_goal_to_keep 
    AND is_active = TRUE;
    
    -- Ensure the kept goal is active and has highest priority
    UPDATE goals
    SET is_active = TRUE, priority = 999, updated_at = NOW()
    WHERE id = p_goal_to_keep;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Trigger to validate artist limits on insertion
CREATE OR REPLACE FUNCTION validate_artist_limit()
RETURNS TRIGGER AS $$
BEGIN
    IF NOT can_add_artist(NEW.user_id) THEN
        RAISE EXCEPTION 'Artist limit exceeded. Upgrade to add more artists.';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to validate goal limits on insertion
CREATE OR REPLACE FUNCTION validate_goal_limit()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.is_active = TRUE AND NOT can_add_goal(NEW.user_id) THEN
        RAISE EXCEPTION 'Active goal limit exceeded. Upgrade or deactivate existing goals.';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers
DROP TRIGGER IF EXISTS trigger_validate_artist_limit ON user_artists;
CREATE TRIGGER trigger_validate_artist_limit
    BEFORE INSERT ON user_artists
    FOR EACH ROW
    EXECUTE FUNCTION validate_artist_limit();

DROP TRIGGER IF EXISTS trigger_validate_goal_limit ON goals;
CREATE TRIGGER trigger_validate_goal_limit
    BEFORE INSERT OR UPDATE ON goals
    FOR EACH ROW
    EXECUTE FUNCTION validate_goal_limit();

-- Enhanced news feed function with subscription-aware limits
CREATE OR REPLACE FUNCTION get_subscription_aware_news_feed(
    p_user_id UUID,
    p_limit INTEGER DEFAULT 20
)
RETURNS TABLE (
    news_id UUID,
    artist_name TEXT,
    title TEXT,
    description TEXT,
    priority TEXT,
    news_type TEXT,
    created_at TIMESTAMP WITH TIME ZONE,
    source TEXT,
    is_premium_content BOOLEAN
) AS $$
DECLARE
    user_plan TEXT;
BEGIN
    -- Get user's plan
    SELECT plan_type INTO user_plan
    FROM user_subscriptions
    WHERE user_id = p_user_id AND status = 'active';
    
    -- Default to free if no subscription found
    IF user_plan IS NULL THEN
        user_plan := 'free';
    END IF;
    
    RETURN QUERY
    WITH user_followed_artists AS (
        SELECT ua.artist_id
        FROM user_artists ua
        WHERE ua.user_id = p_user_id AND ua.is_active = TRUE
    ),
    filtered_news AS (
        SELECT 
            n.id,
            n.artist_name,
            n.title,
            n.description,
            n.priority,
            n.news_type,
            n.created_at,
            n.source,
            -- Premium content logic (could be expanded later)
            CASE 
                WHEN n.source IN ('premium_sources') THEN TRUE
                ELSE FALSE 
            END as is_premium
        FROM idol_news n
        WHERE n.is_active = TRUE
        AND n.created_at >= NOW() - INTERVAL '7 days'
        AND (
            -- Always show news from followed artists
            EXISTS(SELECT 1 FROM user_followed_artists ufa WHERE ufa.artist_id = n.artist_id)
            OR
            -- Show high-priority news from all artists (both plans)
            n.priority IN ('urgent', 'high')
            OR
            -- For free users, limit to essential news types
            (user_plan = 'free' AND n.news_type IN ('release', 'concert'))
        )
        -- For free users, apply source limitations
        AND (
            user_plan = 'paid'
            OR 
            (user_plan = 'free' AND n.source NOT IN ('premium_sources'))
        )
    )
    SELECT 
        fn.id,
        fn.artist_name,
        fn.title,
        fn.description,
        fn.priority,
        fn.news_type,
        fn.created_at,
        fn.source,
        fn.is_premium
    FROM filtered_news fn
    ORDER BY 
        CASE fn.priority 
            WHEN 'urgent' THEN 1000 
            WHEN 'high' THEN 100 
            WHEN 'normal' THEN 10 
            ELSE 1 
        END DESC,
        fn.created_at DESC
    LIMIT CASE 
        WHEN user_plan = 'free' THEN LEAST(p_limit, 10) -- Free users get max 10 items
        ELSE p_limit 
    END;
END;
$$ LANGUAGE plpgsql;

-- Function to get user dashboard data with subscription context
CREATE OR REPLACE FUNCTION get_user_dashboard_data(p_user_id UUID)
RETURNS TABLE(
    plan_type TEXT,
    artist_slots_used INTEGER,
    artist_slots_total INTEGER,
    active_goals INTEGER,
    goal_slots_total INTEGER,
    recent_purchases INTEGER,
    monthly_spent DECIMAL(10,2),
    can_upgrade BOOLEAN,
    upgrade_benefits TEXT[]
) AS $$
DECLARE
    user_limits RECORD;
    monthly_spending DECIMAL(10,2);
    recent_purchase_count INTEGER;
BEGIN
    -- Get user limits
    SELECT * INTO user_limits FROM get_user_limits(p_user_id);
    
    -- Calculate monthly spending
    SELECT COALESCE(SUM(amount), 0) INTO monthly_spending
    FROM purchases
    WHERE user_id = p_user_id
    AND purchase_date >= date_trunc('month', CURRENT_DATE);
    
    -- Count recent purchases
    SELECT COUNT(*) INTO recent_purchase_count
    FROM purchases
    WHERE user_id = p_user_id
    AND purchase_date >= CURRENT_DATE - INTERVAL '7 days';
    
    RETURN QUERY SELECT
        user_limits.plan_type,
        user_limits.current_artists,
        user_limits.max_artists,
        user_limits.current_active_goals,
        user_limits.max_active_goals,
        recent_purchase_count,
        monthly_spending,
        (user_limits.plan_type = 'free') as can_upgrade,
        CASE WHEN user_limits.plan_type = 'free' 
             THEN ARRAY['Track up to 3 active goals', 'Premium news sources', 'Advanced analytics']
             ELSE ARRAY[]::TEXT[]
        END as upgrade_benefits;
END;
$$ LANGUAGE plpgsql;

-- Insert default subscription for existing users
INSERT INTO user_subscriptions (user_id, plan_type, max_artists, max_active_goals)
SELECT id, 'free', 3, 1
FROM users
ON CONFLICT (user_id) DO NOTHING;

-- Create RLS policies
ALTER TABLE user_subscriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own subscription" ON user_subscriptions
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Service role can manage subscriptions" ON user_subscriptions
    FOR ALL USING (auth.jwt() ->> 'role' = 'service_role');