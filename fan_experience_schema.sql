-- Fan Experience Database Schema Extensions for PiggyBong
-- This builds on the existing artist_database_schema.sql with fan-centric features

-- Enhanced user_artists table for bias budget allocation
CREATE TABLE IF NOT EXISTS user_artists (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  artist_id UUID NOT NULL REFERENCES artists(id) ON DELETE CASCADE,
  priority_rank INTEGER NOT NULL, -- 1 = #1 bias, 2 = #2 bias, etc.
  monthly_allocation DECIMAL(10,2) DEFAULT 0.00, -- Per-artist budget allocation
  total_spent DECIMAL(10,2) DEFAULT 0.00, -- Running total spent on this artist
  month_spent DECIMAL(10,2) DEFAULT 0.00, -- Current month spending
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(user_id, artist_id), -- One record per user-artist pair
  UNIQUE(user_id, priority_rank) WHERE is_active = TRUE -- One artist per priority rank
);

-- Enhanced purchases table with fan-specific context
ALTER TABLE purchases ADD COLUMN IF NOT EXISTS context_note TEXT; -- "SEVENTEEN comeback celebration!"
ALTER TABLE purchases ADD COLUMN IF NOT EXISTS fan_category TEXT DEFAULT 'other'; -- concert_prep, album_hunting, merch_haul, photocard_collecting
ALTER TABLE purchases ADD COLUMN IF NOT EXISTS is_comeback_related BOOLEAN DEFAULT FALSE;
ALTER TABLE purchases ADD COLUMN IF NOT EXISTS venue_location TEXT; -- For concert tickets
ALTER TABLE purchases ADD COLUMN IF NOT EXISTS album_version TEXT; -- For album purchases

-- Enhanced goals table with fan context and countdown features
ALTER TABLE goals ADD COLUMN IF NOT EXISTS goal_type TEXT DEFAULT 'general'; -- concert_tickets, album_collection, merch_haul, fanmeet_tickets
ALTER TABLE goals ADD COLUMN IF NOT EXISTS countdown_context TEXT; -- "15 days until presale"
ALTER TABLE goals ADD COLUMN IF NOT EXISTS is_time_sensitive BOOLEAN DEFAULT FALSE;
ALTER TABLE goals ADD COLUMN IF NOT EXISTS event_date DATE; -- For time-sensitive goals
ALTER TABLE goals ADD COLUMN IF NOT EXISTS presale_date DATE; -- For concert tickets
ALTER TABLE goals ADD COLUMN IF NOT EXISTS celebration_milestone DECIMAL(10,2); -- Amount to celebrate at

-- Per-artist budget tracking table
CREATE TABLE IF NOT EXISTS artist_budgets (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  artist_id UUID NOT NULL REFERENCES artists(id) ON DELETE CASCADE,
  month INTEGER NOT NULL,
  year INTEGER NOT NULL,
  allocated_budget DECIMAL(10,2) NOT NULL,
  spent_amount DECIMAL(10,2) DEFAULT 0.00,
  remaining_budget DECIMAL(10,2) GENERATED ALWAYS AS (allocated_budget - spent_amount) STORED,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(user_id, artist_id, month, year) -- One budget per artist per month
);

-- AI cheer tips and coaching table
CREATE TABLE IF NOT EXISTS ai_tips (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  artist_id UUID REFERENCES artists(id) ON DELETE SET NULL, -- Can be artist-specific or general
  tip_type TEXT NOT NULL, -- 'cheer', 'strategy', 'comeback_alert', 'budget_warning'
  message TEXT NOT NULL,
  is_premium BOOLEAN DEFAULT FALSE, -- Premium coaching vs free cheer
  is_read BOOLEAN DEFAULT FALSE,
  is_active BOOLEAN DEFAULT TRUE,
  expires_at TIMESTAMPTZ, -- For time-sensitive tips
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Fan goals progress tracking
CREATE TABLE IF NOT EXISTS goal_progress (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  goal_id UUID NOT NULL REFERENCES goals(id) ON DELETE CASCADE,
  amount_added DECIMAL(10,2) NOT NULL,
  note TEXT, -- "Got my paycheck!"
  celebration_triggered BOOLEAN DEFAULT FALSE, -- Did this trigger a milestone?
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- User preferences for fan experience
CREATE TABLE IF NOT EXISTS user_fan_preferences (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  comeback_notifications BOOLEAN DEFAULT TRUE,
  concert_alerts BOOLEAN DEFAULT TRUE,
  budget_warnings BOOLEAN DEFAULT TRUE,
  ai_coaching_level TEXT DEFAULT 'basic', -- 'basic', 'premium'
  preferred_currency TEXT DEFAULT 'USD',
  timezone TEXT DEFAULT 'UTC',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(user_id)
);

-- Fan activity timeline for recent activity
CREATE TABLE IF NOT EXISTS fan_activity (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  artist_id UUID REFERENCES artists(id) ON DELETE SET NULL,
  activity_type TEXT NOT NULL, -- 'purchase', 'goal_progress', 'artist_added', 'milestone_reached'
  title TEXT NOT NULL,
  description TEXT,
  amount DECIMAL(10,2), -- For money-related activities
  metadata JSONB, -- Flexible data storage
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_user_artists_user_priority ON user_artists(user_id, priority_rank) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_user_artists_user_allocation ON user_artists(user_id, monthly_allocation DESC) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_purchases_fan_category ON purchases(fan_category);
CREATE INDEX IF NOT EXISTS idx_purchases_comeback ON purchases(is_comeback_related) WHERE is_comeback_related = TRUE;
CREATE INDEX IF NOT EXISTS idx_goals_time_sensitive ON goals(is_time_sensitive, event_date) WHERE is_time_sensitive = TRUE;
CREATE INDEX IF NOT EXISTS idx_artist_budgets_current_month ON artist_budgets(user_id, month, year);
CREATE INDEX IF NOT EXISTS idx_ai_tips_active ON ai_tips(user_id, is_active, created_at DESC) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_goal_progress_goal ON goal_progress(goal_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_fan_activity_user_recent ON fan_activity(user_id, created_at DESC);

-- Functions for fan experience

-- Get user's bias budget status
CREATE OR REPLACE FUNCTION get_bias_budget_status(p_user_id UUID)
RETURNS TABLE(
  artist_name TEXT,
  priority_rank INTEGER,
  monthly_allocation DECIMAL(10,2),
  month_spent DECIMAL(10,2),
  remaining_budget DECIMAL(10,2),
  spent_percentage DECIMAL(5,2)
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    a.name,
    ua.priority_rank,
    ua.monthly_allocation,
    ua.month_spent,
    (ua.monthly_allocation - ua.month_spent) as remaining,
    CASE 
      WHEN ua.monthly_allocation > 0 THEN 
        ROUND((ua.month_spent / ua.monthly_allocation * 100)::DECIMAL, 2)
      ELSE 0
    END as percentage
  FROM user_artists ua
  JOIN artists a ON ua.artist_id = a.id
  WHERE ua.user_id = p_user_id 
    AND ua.is_active = TRUE
  ORDER BY ua.priority_rank ASC;
END;
$$ LANGUAGE plpgsql;

-- Get fan goals with countdown context
CREATE OR REPLACE FUNCTION get_fan_goals_with_countdown(p_user_id UUID)
RETURNS TABLE(
  goal_id UUID,
  goal_name TEXT,
  artist_name TEXT,
  target_amount DECIMAL(10,2),
  current_amount DECIMAL(10,2),
  progress_percentage DECIMAL(5,2),
  days_until_event INTEGER,
  countdown_context TEXT,
  is_urgent BOOLEAN
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    g.id,
    g.name,
    a.name,
    g.target_amount,
    g.current_amount,
    ROUND((g.current_amount / g.target_amount * 100)::DECIMAL, 2) as progress_pct,
    CASE 
      WHEN g.event_date IS NOT NULL THEN 
        EXTRACT(DAYS FROM g.event_date - CURRENT_DATE)::INTEGER
      ELSE NULL
    END as days_remaining,
    g.countdown_context,
    CASE 
      WHEN g.is_time_sensitive AND g.event_date IS NOT NULL 
        AND g.event_date - CURRENT_DATE <= INTERVAL '30 days' THEN TRUE
      ELSE FALSE
    END as urgent
  FROM goals g
  LEFT JOIN artists a ON g.artist_id = a.id
  WHERE g.user_id = p_user_id
  ORDER BY 
    CASE WHEN g.is_time_sensitive THEN 0 ELSE 1 END,
    g.event_date ASC NULLS LAST,
    g.priority DESC;
END;
$$ LANGUAGE plpgsql;

-- Generate daily AI cheer tip
CREATE OR REPLACE FUNCTION generate_daily_cheer_tip(p_user_id UUID)
RETURNS TEXT AS $$
DECLARE
  user_top_artist TEXT;
  user_budget_status DECIMAL(5,2);
  tip_message TEXT;
  recent_comeback BOOLEAN;
BEGIN
  -- Get user's #1 bias
  SELECT a.name INTO user_top_artist
  FROM user_artists ua
  JOIN artists a ON ua.artist_id = a.id
  WHERE ua.user_id = p_user_id 
    AND ua.priority_rank = 1 
    AND ua.is_active = TRUE;
  
  -- Calculate overall budget health
  SELECT COALESCE(AVG(
    CASE 
      WHEN ua.monthly_allocation > 0 THEN 
        ua.month_spent / ua.monthly_allocation * 100
      ELSE 0
    END
  ), 0) INTO user_budget_status
  FROM user_artists ua
  WHERE ua.user_id = p_user_id AND ua.is_active = TRUE;
  
  -- Check for recent comeback activity
  SELECT EXISTS(
    SELECT 1 FROM purchases 
    WHERE user_id = p_user_id 
      AND is_comeback_related = TRUE 
      AND created_at >= CURRENT_DATE - INTERVAL '30 days'
  ) INTO recent_comeback;
  
  -- Generate contextual tip
  IF user_budget_status < 50 THEN
    tip_message := COALESCE(user_top_artist || ' would be proud of your smart spending! ', 'Great budget control! ') || 'You''re staying strong! 💪';
  ELSIF user_budget_status < 80 THEN
    tip_message := 'You''re doing great balancing your fan life and budget! ' || COALESCE(user_top_artist || ' sees your dedication! 🌟', '🌟');
  ELSIF recent_comeback THEN
    tip_message := 'Comeback season is expensive but you''re managing well! ' || COALESCE(user_top_artist || ' appreciates your support! 💜', '💜');
  ELSE
    tip_message := 'Remember, being a smart fan means enjoying sustainably! ' || COALESCE('Your bias groups want you to be financially healthy too! ', '') || '✨';
  END IF;
  
  RETURN tip_message;
END;
$$ LANGUAGE plpgsql;

-- Update artist spending when purchase is made
CREATE OR REPLACE FUNCTION update_artist_spending()
RETURNS TRIGGER AS $$
BEGIN
  -- Update user_artists month_spent
  UPDATE user_artists 
  SET 
    month_spent = month_spent + NEW.amount,
    total_spent = total_spent + NEW.amount,
    updated_at = NOW()
  WHERE user_id = NEW.user_id AND artist_id = NEW.artist_id;
  
  -- Update or create artist_budgets record
  INSERT INTO artist_budgets (user_id, artist_id, month, year, allocated_budget, spent_amount)
  VALUES (
    NEW.user_id,
    NEW.artist_id,
    EXTRACT(MONTH FROM NEW.purchase_date),
    EXTRACT(YEAR FROM NEW.purchase_date),
    (SELECT monthly_allocation FROM user_artists WHERE user_id = NEW.user_id AND artist_id = NEW.artist_id),
    NEW.amount
  )
  ON CONFLICT (user_id, artist_id, month, year)
  DO UPDATE SET 
    spent_amount = artist_budgets.spent_amount + NEW.amount,
    updated_at = NOW();
  
  -- Add to activity timeline
  INSERT INTO fan_activity (user_id, artist_id, activity_type, title, description, amount)
  VALUES (
    NEW.user_id,
    NEW.artist_id,
    'purchase',
    NEW.description,
    COALESCE(NEW.context_note, 'Purchase in ' || NEW.category),
    NEW.amount
  );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for purchase tracking
DROP TRIGGER IF EXISTS trigger_update_artist_spending ON purchases;
CREATE TRIGGER trigger_update_artist_spending
  AFTER INSERT ON purchases
  FOR EACH ROW
  EXECUTE FUNCTION update_artist_spending();

-- Update goal progress when money is added
CREATE OR REPLACE FUNCTION update_goal_progress()
RETURNS TRIGGER AS $$
DECLARE
  goal_record goals%ROWTYPE;
  milestone_reached BOOLEAN := FALSE;
BEGIN
  -- Get the goal record
  SELECT * INTO goal_record FROM goals WHERE id = NEW.goal_id;
  
  -- Update goal current_amount
  UPDATE goals 
  SET 
    current_amount = current_amount + NEW.amount_added,
    updated_at = NOW()
  WHERE id = NEW.goal_id;
  
  -- Check if celebration milestone was reached
  IF goal_record.celebration_milestone IS NOT NULL 
     AND (goal_record.current_amount + NEW.amount_added) >= goal_record.celebration_milestone 
     AND goal_record.current_amount < goal_record.celebration_milestone THEN
    milestone_reached := TRUE;
    
    UPDATE goal_progress 
    SET celebration_triggered = TRUE 
    WHERE id = NEW.id;
  END IF;
  
  -- Add to activity timeline
  INSERT INTO fan_activity (user_id, artist_id, activity_type, title, description, amount)
  VALUES (
    (SELECT user_id FROM goals WHERE id = NEW.goal_id),
    goal_record.artist_id,
    CASE WHEN milestone_reached THEN 'milestone_reached' ELSE 'goal_progress' END,
    'Added to ' || goal_record.name,
    COALESCE(NEW.note, 'Progress update'),
    NEW.amount_added
  );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for goal progress tracking
DROP TRIGGER IF EXISTS trigger_update_goal_progress ON goal_progress;
CREATE TRIGGER trigger_update_goal_progress
  AFTER INSERT ON goal_progress
  FOR EACH ROW
  EXECUTE FUNCTION update_goal_progress();