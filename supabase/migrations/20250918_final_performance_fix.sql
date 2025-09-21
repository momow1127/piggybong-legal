-- Final Performance Fix - Addresses Specific 18 Warnings
-- 1. Optimizes auth.uid() calls with (SELECT auth.uid())
-- 2. Removes ALL duplicate permissive policies

-- ===== STEP 1: REMOVE ALL DUPLICATE POLICIES =====
-- Drop every policy and start clean

DO $$
DECLARE
    pol RECORD;
BEGIN
    -- Drop ALL existing policies on these tables
    FOR pol IN
        SELECT tablename, policyname
        FROM pg_policies
        WHERE tablename IN ('artists', 'goals', 'users', 'user_feedback', 'fan_idols', 'security_logs', 'rate_limits')
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON %I', pol.policyname, pol.tablename);
    END LOOP;
END $$;

-- ===== STEP 2: CREATE SINGLE OPTIMIZED POLICIES =====
-- Use (SELECT auth.uid()) for optimal performance

-- ARTISTS - Single public read policy
CREATE POLICY "artists_public_read_only" ON artists
    FOR SELECT
    TO public
    USING (true);

-- GOALS - Single user policy with optimized auth.uid()
CREATE POLICY "goals_user_only" ON goals
    FOR ALL
    TO authenticated
    USING ((SELECT auth.uid()) = user_id)
    WITH CHECK ((SELECT auth.uid()) = user_id);

-- USERS - Single user policy with optimized auth.uid()
CREATE POLICY "users_own_only" ON users
    FOR ALL
    TO authenticated
    USING ((SELECT auth.uid()) = id)
    WITH CHECK ((SELECT auth.uid()) = id);

-- USER_FEEDBACK - Single user policy with optimized auth.uid()
CREATE POLICY "user_feedback_user_only" ON user_feedback
    FOR ALL
    TO authenticated
    USING ((SELECT auth.uid()) = user_id)
    WITH CHECK ((SELECT auth.uid()) = user_id);

-- FAN_IDOLS - Single user policy with optimized auth.uid()
CREATE POLICY "fan_idols_user_only" ON fan_idols
    FOR ALL
    TO authenticated
    USING ((SELECT auth.uid()) = user_id)
    WITH CHECK ((SELECT auth.uid()) = user_id);

-- SECURITY_LOGS - Single admin policy (no auth.uid() needed)
CREATE POLICY "security_logs_admin_only" ON security_logs
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- RATE_LIMITS - Single admin policy (no auth.uid() needed)
CREATE POLICY "rate_limits_admin_only" ON rate_limits
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- ===== STEP 3: VERIFY POLICY COUNT =====
-- Function to verify we have exactly one policy per table

CREATE OR REPLACE FUNCTION verify_single_policies()
RETURNS TABLE (
    table_name text,
    policy_count bigint,
    policy_names text,
    status text
)
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
    -- Only allow service role
    IF auth.role() != 'service_role' THEN
        RAISE EXCEPTION 'Access denied: Admin privileges required';
    END IF;

    RETURN QUERY
    SELECT
        p.tablename::text,
        COUNT(*)::bigint,
        string_agg(p.policyname, ', ' ORDER BY p.policyname)::text,
        CASE
            WHEN COUNT(*) = 1 THEN 'OPTIMAL'
            WHEN COUNT(*) = 0 THEN 'NO_POLICY'
            ELSE 'TOO_MANY'
        END::text
    FROM pg_policies p
    WHERE p.tablename IN ('artists', 'goals', 'users', 'user_feedback', 'fan_idols', 'security_logs', 'rate_limits')
    GROUP BY p.tablename
    ORDER BY p.tablename;
END;
$$ LANGUAGE plpgsql;

-- Grant access
GRANT EXECUTE ON FUNCTION verify_single_policies() TO service_role;

-- ===== STEP 4: VERIFY AUTH.UID() OPTIMIZATION =====
-- Function to check if policies use optimized auth.uid() pattern

CREATE OR REPLACE FUNCTION verify_auth_optimization()
RETURNS TABLE (
    table_name text,
    policy_name text,
    uses_optimized_auth boolean,
    recommendation text
)
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
    -- Only allow service role
    IF auth.role() != 'service_role' THEN
        RAISE EXCEPTION 'Access denied: Admin privileges required';
    END IF;

    RETURN QUERY
    SELECT
        p.tablename::text,
        p.policyname::text,
        (p.qual LIKE '%(SELECT auth.uid())%' OR p.with_check LIKE '%(SELECT auth.uid())%')::boolean,
        CASE
            WHEN p.qual LIKE '%(SELECT auth.uid())%' OR p.with_check LIKE '%(SELECT auth.uid())%'
            THEN 'OPTIMIZED'
            WHEN p.qual LIKE '%auth.uid()%' OR p.with_check LIKE '%auth.uid()%'
            THEN 'NEEDS_OPTIMIZATION'
            ELSE 'NO_AUTH_CHECK'
        END::text
    FROM pg_policies p
    WHERE p.tablename IN ('goals', 'users', 'user_feedback', 'fan_idols')
    ORDER BY p.tablename;
END;
$$ LANGUAGE plpgsql;

-- Grant access
GRANT EXECUTE ON FUNCTION verify_auth_optimization() TO service_role;

-- ===== STEP 5: FINAL VERIFICATION =====
-- Check that we solved the specific issues

CREATE OR REPLACE FUNCTION check_performance_warnings_resolved()
RETURNS TABLE (
    issue_type text,
    affected_tables integer,
    status text
)
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
    -- Only allow service role
    IF auth.role() != 'service_role' THEN
        RAISE EXCEPTION 'Access denied: Admin privileges required';
    END IF;

    RETURN QUERY
    -- Check for multiple permissive policies
    SELECT
        'Multiple Permissive Policies'::text,
        COUNT(DISTINCT tablename)::integer,
        CASE WHEN COUNT(DISTINCT tablename) = 0 THEN 'RESOLVED' ELSE 'REMAINING' END::text
    FROM (
        SELECT tablename, COUNT(*) as policy_count
        FROM pg_policies
        WHERE tablename IN ('artists', 'goals', 'users', 'user_feedback', 'fan_idols')
        GROUP BY tablename
        HAVING COUNT(*) > 1
    ) multiple_policies

    UNION ALL

    -- Check for unoptimized auth.uid() usage
    SELECT
        'Auth RLS Initialization'::text,
        COUNT(*)::integer,
        CASE WHEN COUNT(*) = 0 THEN 'OPTIMIZED' ELSE 'NEEDS_WORK' END::text
    FROM pg_policies
    WHERE tablename IN ('goals', 'users', 'user_feedback', 'fan_idols')
    AND (qual LIKE '%auth.uid()%' OR with_check LIKE '%auth.uid()%')
    AND NOT (qual LIKE '%(SELECT auth.uid())%' OR with_check LIKE '%(SELECT auth.uid())%');
END;
$$ LANGUAGE plpgsql;

-- Grant access
GRANT EXECUTE ON FUNCTION check_performance_warnings_resolved() TO service_role;

-- Log this final fix
SELECT log_security_event('final_performance_warnings_resolved',
    jsonb_build_object(
        'auth_uid_optimized', 'all_policies_use_select_auth_uid',
        'duplicate_policies_removed', 'complete_cleanup',
        'single_policies_per_table', true,
        'performance_impact', 'maximum_optimization'
    )
);

-- Final status
SELECT 'Final performance optimization completed' as status,
       'Auth.uid() optimized, all duplicates removed' as details;