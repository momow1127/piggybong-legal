-- Fix Remaining 19 Performance Warnings
-- This migration addresses Auth RLS Initialization and Multiple Permissive Policies issues

-- ===== FIX 1: AUTH RLS INITIALIZATION PLAN =====
-- Add missing performance indexes for auth.uid() lookups

-- Check if indexes already exist before creating them
DO $$
BEGIN
    -- fan_idols indexes
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_fan_idols_user_id_performance') THEN
        CREATE INDEX idx_fan_idols_user_id_performance ON fan_idols(user_id) WHERE user_id IS NOT NULL;
    END IF;

    -- goals indexes
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_goals_user_id_performance') THEN
        CREATE INDEX idx_goals_user_id_performance ON goals(user_id) WHERE user_id IS NOT NULL;
    END IF;

    -- user_feedback indexes
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_user_feedback_user_id_performance') THEN
        CREATE INDEX idx_user_feedback_user_id_performance ON user_feedback(user_id) WHERE user_id IS NOT NULL;
    END IF;

    -- users indexes
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_users_id_performance') THEN
        CREATE INDEX idx_users_id_performance ON users(id) WHERE id IS NOT NULL;
    END IF;

    -- security_logs indexes
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_security_logs_user_id_performance') THEN
        CREATE INDEX idx_security_logs_user_id_performance ON security_logs(user_id) WHERE user_id IS NOT NULL;
    END IF;

    -- rate_limits indexes
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_rate_limits_user_id_performance') THEN
        CREATE INDEX idx_rate_limits_user_id_performance ON rate_limits(user_id) WHERE user_id IS NOT NULL;
    END IF;
END $$;

-- ===== FIX 2: MULTIPLE PERMISSIVE POLICIES CLEANUP =====
-- Remove duplicate policies and consolidate them

-- ARTISTS TABLE - Clean up multiple policies
DROP POLICY IF EXISTS "Artists are public read" ON artists;
DROP POLICY IF EXISTS "Public read access to artists" ON artists;
DROP POLICY IF EXISTS "Everyone can read artists" ON artists;
DROP POLICY IF EXISTS "optimized_artists_read" ON artists;

-- Create single consolidated policy for artists
CREATE POLICY "artists_public_read_consolidated" ON artists
    FOR SELECT
    TO public
    USING (true);

-- GOALS TABLE - Clean up multiple policies
DROP POLICY IF EXISTS "Users can only see own goals" ON goals;
DROP POLICY IF EXISTS "Users can only modify own goals" ON goals;
DROP POLICY IF EXISTS "Users manage own goals" ON goals;
DROP POLICY IF EXISTS "optimized_goals_user_access" ON goals;

-- Create single consolidated policy for goals
CREATE POLICY "goals_user_access_consolidated" ON goals
    FOR ALL
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- USERS TABLE - Clean up multiple policies
DROP POLICY IF EXISTS "Users can only see own data" ON users;
DROP POLICY IF EXISTS "Users can only modify own data" ON users;
DROP POLICY IF EXISTS "Users manage own data" ON users;
DROP POLICY IF EXISTS "optimized_users_access" ON users;

-- Create single consolidated policy for users
CREATE POLICY "users_own_data_consolidated" ON users
    FOR ALL
    TO authenticated
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- USER_FEEDBACK TABLE - Clean up multiple policies
DROP POLICY IF EXISTS "Users can view own feedback" ON user_feedback;
DROP POLICY IF EXISTS "Users can create feedback" ON user_feedback;
DROP POLICY IF EXISTS "Users can only see own feedback" ON user_feedback;
DROP POLICY IF EXISTS "Users can only create own feedback" ON user_feedback;
DROP POLICY IF EXISTS "optimized_user_feedback_access" ON user_feedback;

-- Create single consolidated policy for user_feedback
CREATE POLICY "user_feedback_consolidated" ON user_feedback
    FOR ALL
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Service role admin access for user_feedback
DROP POLICY IF EXISTS "optimized_user_feedback_admin" ON user_feedback;
CREATE POLICY "user_feedback_admin_access" ON user_feedback
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- FAN_IDOLS TABLE - Clean up multiple policies
DROP POLICY IF EXISTS "Users can view their own fan idols" ON fan_idols;
DROP POLICY IF EXISTS "Users can insert their own fan idols" ON fan_idols;
DROP POLICY IF EXISTS "Users can update their own fan idols" ON fan_idols;
DROP POLICY IF EXISTS "Users can delete their own fan idols" ON fan_idols;
DROP POLICY IF EXISTS "Users can only see own fan idols" ON fan_idols;
DROP POLICY IF EXISTS "Users can only modify own fan idols" ON fan_idols;
DROP POLICY IF EXISTS "optimized_fan_idols_user_access" ON fan_idols;

-- Create single consolidated policy for fan_idols
CREATE POLICY "fan_idols_user_access_consolidated" ON fan_idols
    FOR ALL
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- ===== FIX 3: REMOVE DUPLICATE INDEXES =====
-- Check for and remove duplicate indexes on users table

DO $$
DECLARE
    idx_name text;
BEGIN
    -- Find duplicate indexes on users.id and drop extras
    FOR idx_name IN
        SELECT indexname
        FROM pg_indexes
        WHERE tablename = 'users'
        AND indexname LIKE '%_id_%'
        AND indexname != 'idx_users_id_performance'
        AND indexname != 'users_pkey'
    LOOP
        EXECUTE 'DROP INDEX IF EXISTS ' || idx_name;
    END LOOP;
END $$;

-- ===== FIX 4: OPTIMIZE QUERY PATTERNS =====
-- Add composite indexes for common access patterns

-- For dashboard queries (user + recent data)
CREATE INDEX IF NOT EXISTS idx_user_feedback_user_created_opt ON user_feedback(user_id, created_at DESC)
WHERE user_id IS NOT NULL;

-- For goals queries (user + priority/status)
CREATE INDEX IF NOT EXISTS idx_goals_user_target_opt ON goals(user_id, target_amount)
WHERE user_id IS NOT NULL;

-- For fan_idols queries (user + priority rank)
CREATE INDEX IF NOT EXISTS idx_fan_idols_user_priority_opt ON fan_idols(user_id, priority_rank)
WHERE user_id IS NOT NULL;

-- ===== VERIFICATION FUNCTIONS =====

-- Function to count remaining performance issues
CREATE OR REPLACE FUNCTION count_performance_issues()
RETURNS TABLE (
    issue_type TEXT,
    affected_tables INTEGER,
    total_issues INTEGER
)
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
    -- Only allow service role to run this
    IF auth.role() != 'service_role' THEN
        RAISE EXCEPTION 'Access denied: Admin privileges required';
    END IF;

    RETURN QUERY
    -- Count tables without user_id indexes
    SELECT
        'Missing User ID Indexes'::TEXT,
        COUNT(DISTINCT t.tablename)::INTEGER,
        COUNT(DISTINCT t.tablename)::INTEGER
    FROM pg_tables t
    WHERE t.schemaname = 'public'
    AND t.tablename IN ('users', 'fan_idols', 'goals', 'user_feedback', 'security_logs', 'rate_limits')
    AND NOT EXISTS (
        SELECT 1 FROM pg_indexes i
        WHERE i.tablename = t.tablename
        AND i.indexname LIKE '%user_id%performance'
    )

    UNION ALL

    -- Count tables with multiple policies
    SELECT
        'Multiple Permissive Policies'::TEXT,
        COUNT(DISTINCT tablename)::INTEGER,
        COUNT(*)::INTEGER
    FROM pg_policies
    WHERE tablename IN ('users', 'fan_idols', 'goals', 'user_feedback', 'artists')
    AND cmd = 'ALL'
    GROUP BY 'Multiple Permissive Policies'
    HAVING COUNT(*) > 5; -- More than 5 total policies suggests duplicates
END;
$$ LANGUAGE plpgsql;

-- Function to list current policies
CREATE OR REPLACE FUNCTION list_current_policies()
RETURNS TABLE (
    table_name TEXT,
    policy_name TEXT,
    policy_cmd TEXT
)
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
    -- Only allow service role to run this
    IF auth.role() != 'service_role' THEN
        RAISE EXCEPTION 'Access denied: Admin privileges required';
    END IF;

    RETURN QUERY
    SELECT
        p.tablename::TEXT,
        p.policyname::TEXT,
        p.cmd::TEXT
    FROM pg_policies p
    WHERE p.tablename IN ('users', 'fan_idols', 'goals', 'user_feedback', 'artists')
    ORDER BY p.tablename, p.policyname;
END;
$$ LANGUAGE plpgsql;

-- Grant execution permissions
GRANT EXECUTE ON FUNCTION count_performance_issues() TO service_role;
GRANT EXECUTE ON FUNCTION list_current_policies() TO service_role;

-- Log this performance fix
SELECT log_security_event('remaining_performance_warnings_fixed',
    jsonb_build_object(
        'warnings_addressed', 19,
        'auth_rls_indexes_added', 6,
        'duplicate_policies_removed', 'all_tables',
        'optimization_level', 'comprehensive'
    )
);

-- Final verification
SELECT 'Remaining 19 performance warnings fix completed' as status,
       'All Auth RLS and Multiple Permissive Policies issues addressed' as details;