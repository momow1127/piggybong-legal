-- Fixed Security Rules Migration for Supabase
-- This version works with Supabase's built-in auth system

-- Enable RLS on main tables (skip auth.users - it's managed by Supabase)
ALTER TABLE IF EXISTS users ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS artists ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS events ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS user_artists ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS user_feedback ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (ignore errors if they don't exist)
DROP POLICY IF EXISTS "Users can only see own data" ON users;
DROP POLICY IF EXISTS "Users can only modify own data" ON users;
DROP POLICY IF EXISTS "Users can only see own artists" ON user_artists;
DROP POLICY IF EXISTS "Users can only modify own artists" ON user_artists;
DROP POLICY IF EXISTS "Users can only see own goals" ON goals;
DROP POLICY IF EXISTS "Users can only modify own goals" ON goals;
DROP POLICY IF EXISTS "Users can only see own feedback" ON user_feedback;
DROP POLICY IF EXISTS "Users can only create own feedback" ON user_feedback;
DROP POLICY IF EXISTS "Events are public read" ON events;
DROP POLICY IF EXISTS "Artists are public read" ON artists;

-- USERS TABLE POLICIES (for your custom users table, not auth.users)
CREATE POLICY "Users can only see own data" ON users
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can only modify own data" ON users
    FOR ALL USING (auth.uid() = id);

-- USER_ARTISTS TABLE POLICIES
CREATE POLICY "Users can only see own artists" ON user_artists
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can only modify own artists" ON user_artists
    FOR ALL USING (auth.uid() = user_id);

-- GOALS TABLE POLICIES
CREATE POLICY "Users can only see own goals" ON goals
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can only modify own goals" ON goals
    FOR ALL USING (auth.uid() = user_id);

-- USER_FEEDBACK TABLE POLICIES
CREATE POLICY "Users can only see own feedback" ON user_feedback
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can only create own feedback" ON user_feedback
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- PUBLIC READ-ONLY DATA
CREATE POLICY "Events are public read" ON events
    FOR SELECT USING (true);

CREATE POLICY "Artists are public read" ON artists
    FOR SELECT USING (true);

-- SECURITY FUNCTIONS
-- Function to validate user input and prevent SQL injection
CREATE OR REPLACE FUNCTION validate_user_input(input_text text)
RETURNS boolean AS $$
BEGIN
    -- Check for suspicious patterns
    IF input_text ~ '(drop|delete|update|insert|select|union|--|;|<script|javascript|eval)' THEN
        RETURN false;
    END IF;

    -- Check length limits
    IF length(input_text) > 1000 THEN
        RETURN false;
    END IF;

    RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create security logs table
CREATE TABLE IF NOT EXISTS security_logs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    event_type TEXT NOT NULL,
    event_data JSONB DEFAULT '{}'::jsonb,
    ip_address TEXT,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Enable RLS on security logs (admin only)
ALTER TABLE security_logs ENABLE ROW LEVEL SECURITY;

-- Only service role can read security logs
CREATE POLICY "Only service role can access security logs" ON security_logs
    FOR ALL USING (auth.role() = 'service_role');

-- Function to log security events
CREATE OR REPLACE FUNCTION log_security_event(
    event_type text,
    event_data jsonb DEFAULT '{}'::jsonb
)
RETURNS void AS $$
BEGIN
    INSERT INTO security_logs (
        user_id,
        event_type,
        event_data,
        created_at
    ) VALUES (
        auth.uid(),
        event_type,
        event_data,
        now()
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Rate limiting table
CREATE TABLE IF NOT EXISTS rate_limits (
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    action_type TEXT NOT NULL,
    count INTEGER DEFAULT 1,
    window_start TIMESTAMP WITH TIME ZONE DEFAULT now(),
    PRIMARY KEY (user_id, action_type)
);

-- Enable RLS on rate limits
ALTER TABLE rate_limits ENABLE ROW LEVEL SECURITY;

-- Users can only see their own rate limits
CREATE POLICY "Users can only see own rate limits" ON rate_limits
    FOR ALL USING (auth.uid() = user_id);

-- Function to check rate limits
CREATE OR REPLACE FUNCTION check_rate_limit(
    action_type_param text,
    max_requests integer DEFAULT 100,
    window_minutes integer DEFAULT 60
)
RETURNS boolean AS $$
DECLARE
    current_count integer;
    window_start_time timestamp with time zone;
BEGIN
    -- Get current window start
    window_start_time := now() - (window_minutes || ' minutes')::interval;

    -- Clean old entries
    DELETE FROM rate_limits
    WHERE window_start < window_start_time;

    -- Get current count for user and action
    SELECT count INTO current_count
    FROM rate_limits
    WHERE user_id = auth.uid()
    AND action_type = action_type_param;

    -- If no record exists, create one
    IF current_count IS NULL THEN
        INSERT INTO rate_limits (user_id, action_type, count, window_start)
        VALUES (auth.uid(), action_type_param, 1, now())
        ON CONFLICT (user_id, action_type)
        DO UPDATE SET count = 1, window_start = now();
        RETURN true;
    END IF;

    -- Check if limit exceeded
    IF current_count >= max_requests THEN
        -- Log security event
        PERFORM log_security_event('rate_limit_exceeded',
            jsonb_build_object(
                'action_type', action_type_param,
                'current_count', current_count,
                'max_requests', max_requests
            )
        );
        RETURN false;
    END IF;

    -- Increment counter
    UPDATE rate_limits
    SET count = count + 1
    WHERE user_id = auth.uid()
    AND action_type = action_type_param;

    RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to sanitize input
CREATE OR REPLACE FUNCTION sanitize_input(input_text text)
RETURNS text AS $$
BEGIN
    -- Remove potentially dangerous characters
    input_text := regexp_replace(input_text, '[<>"\'';&|`$(){}[\]\\]', '', 'g');

    -- Trim whitespace
    input_text := trim(input_text);

    -- Limit length
    IF length(input_text) > 500 THEN
        input_text := left(input_text, 500);
    END IF;

    RETURN input_text;
END;
$$ LANGUAGE plpgsql IMMUTABLE SECURITY DEFINER;

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_security_logs_user_id ON security_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_security_logs_event_type ON security_logs(event_type);
CREATE INDEX IF NOT EXISTS idx_security_logs_created_at ON security_logs(created_at);
CREATE INDEX IF NOT EXISTS idx_rate_limits_user_action ON rate_limits(user_id, action_type);

-- Grant permissions to authenticated users
DO $$
BEGIN
    -- Grant usage on schema
    GRANT USAGE ON SCHEMA public TO authenticated;
    GRANT USAGE ON SCHEMA public TO anon;

    -- Grant specific table permissions
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'users') THEN
        GRANT SELECT, INSERT, UPDATE, DELETE ON users TO authenticated;
    END IF;

    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'user_artists') THEN
        GRANT SELECT, INSERT, UPDATE, DELETE ON user_artists TO authenticated;
    END IF;

    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'goals') THEN
        GRANT SELECT, INSERT, UPDATE, DELETE ON goals TO authenticated;
    END IF;

    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'user_feedback') THEN
        GRANT SELECT, INSERT ON user_feedback TO authenticated;
    END IF;

    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'artists') THEN
        GRANT SELECT ON artists TO authenticated;
    END IF;

    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'events') THEN
        GRANT SELECT ON events TO authenticated;
    END IF;

    -- Grant permissions on new security tables
    GRANT INSERT ON security_logs TO authenticated;
    GRANT SELECT, INSERT, UPDATE, DELETE ON rate_limits TO authenticated;
END $$;

-- Comment on security setup
COMMENT ON TABLE security_logs IS 'Logs all security-related events for monitoring and alerting';
COMMENT ON FUNCTION check_rate_limit IS 'Prevents abuse by limiting requests per user per time window';
COMMENT ON FUNCTION validate_user_input IS 'Validates and sanitizes user input to prevent injection attacks';

-- Log the security setup completion
SELECT log_security_event('security_migration_completed', '{"version": "20250918_fixed"}'::jsonb);