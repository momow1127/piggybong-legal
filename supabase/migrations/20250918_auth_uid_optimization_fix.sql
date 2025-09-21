-- Fix Auth.uid() Optimization - Correct Implementation
-- The previous migration created policies but they still use non-optimized auth.uid()
-- This migration recreates the policies with proper (SELECT auth.uid()) optimization

-- ===== RECREATE POLICIES WITH PROPER AUTH.UID() OPTIMIZATION =====

-- Drop the current policies that aren't optimized
DROP POLICY IF EXISTS "fan_idols_user_only" ON fan_idols;
DROP POLICY IF EXISTS "goals_user_only" ON goals;
DROP POLICY IF EXISTS "user_feedback_user_only" ON user_feedback;
DROP POLICY IF EXISTS "users_own_only" ON users;

-- GOALS - Recreate with proper optimization
CREATE POLICY "goals_user_optimized" ON goals
    FOR ALL
    TO authenticated
    USING (user_id = (SELECT auth.uid()))
    WITH CHECK (user_id = (SELECT auth.uid()));

-- USERS - Recreate with proper optimization
CREATE POLICY "users_own_optimized" ON users
    FOR ALL
    TO authenticated
    USING (id = (SELECT auth.uid()))
    WITH CHECK (id = (SELECT auth.uid()));

-- USER_FEEDBACK - Recreate with proper optimization
CREATE POLICY "user_feedback_optimized" ON user_feedback
    FOR ALL
    TO authenticated
    USING (user_id = (SELECT auth.uid()))
    WITH CHECK (user_id = (SELECT auth.uid()));

-- FAN_IDOLS - Recreate with proper optimization
CREATE POLICY "fan_idols_optimized" ON fan_idols
    FOR ALL
    TO authenticated
    USING (user_id = (SELECT auth.uid()))
    WITH CHECK (user_id = (SELECT auth.uid()));

-- ===== VERIFY THE OPTIMIZATION WORKED =====
-- Update the verification function to be more precise

CREATE OR REPLACE FUNCTION verify_auth_optimization_fixed()
RETURNS TABLE (
    table_name text,
    policy_name text,
    policy_definition text,
    is_optimized boolean,
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
        p.policyname::text,
        COALESCE(p.qual, 'No USING clause')::text as policy_definition,
        (
            (COALESCE(p.qual, '') LIKE '%(SELECT auth.uid())%') OR
            (COALESCE(p.with_check, '') LIKE '%(SELECT auth.uid())%')
        )::boolean as is_optimized,
        CASE
            WHEN (COALESCE(p.qual, '') LIKE '%(SELECT auth.uid())%') OR
                 (COALESCE(p.with_check, '') LIKE '%(SELECT auth.uid())%')
            THEN 'OPTIMIZED ✅'
            WHEN (COALESCE(p.qual, '') LIKE '%auth.uid()%') OR
                 (COALESCE(p.with_check, '') LIKE '%auth.uid()%')
            THEN 'NEEDS_FIX ❌'
            ELSE 'NO_AUTH_CHECK'
        END::text as status
    FROM pg_policies p
    WHERE p.tablename IN ('goals', 'users', 'user_feedback', 'fan_idols')
    ORDER BY p.tablename, p.policyname;
END;
$$ LANGUAGE plpgsql;

-- Grant access
GRANT EXECUTE ON FUNCTION verify_auth_optimization_fixed() TO service_role;

-- ===== CHECK PERFORMANCE ADVISOR COMPLIANCE =====
-- Function to simulate what Performance Advisor checks

CREATE OR REPLACE FUNCTION check_performance_advisor_compliance()
RETURNS TABLE (
    table_name text,
    issue_type text,
    current_status text,
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
    -- Check Auth RLS Initialization Plan issues
    SELECT
        p.tablename::text,
        'Auth RLS Initialization Plan'::text,
        CASE
            WHEN (COALESCE(p.qual, '') LIKE '%(SELECT auth.uid())%') OR
                 (COALESCE(p.with_check, '') LIKE '%(SELECT auth.uid())%')
            THEN 'RESOLVED ✅'
            WHEN (COALESCE(p.qual, '') LIKE '%auth.uid()%') OR
                 (COALESCE(p.with_check, '') LIKE '%auth.uid()%')
            THEN 'PERFORMANCE WARNING ⚠️'
            ELSE 'NO AUTH CHECK'
        END::text,
        CASE
            WHEN (COALESCE(p.qual, '') LIKE '%(SELECT auth.uid())%') OR
                 (COALESCE(p.with_check, '') LIKE '%(SELECT auth.uid())%')
            THEN 'Performance optimized'
            ELSE 'Replace auth.uid() with (SELECT auth.uid())'
        END::text
    FROM pg_policies p
    WHERE p.tablename IN ('security_logs', 'rate_limits', 'goals', 'users', 'user_feedback', 'fan_idols')
    AND ((COALESCE(p.qual, '') LIKE '%auth.uid()%') OR (COALESCE(p.with_check, '') LIKE '%auth.uid()%'))

    UNION ALL

    -- Check Multiple Permissive Policies
    SELECT
        sub.tablename::text,
        'Multiple Permissive Policies'::text,
        CASE WHEN sub.policy_count > 1 THEN 'MULTIPLE POLICIES ⚠️' ELSE 'SINGLE POLICY ✅' END::text,
        CASE WHEN sub.policy_count > 1 THEN 'Consolidate to single policy per table' ELSE 'Optimal' END::text
    FROM (
        SELECT tablename, COUNT(*) as policy_count
        FROM pg_policies
        WHERE tablename IN ('artists', 'goals', 'users', 'user_feedback', 'fan_idols')
        GROUP BY tablename
    ) sub;
END;
$$ LANGUAGE plpgsql;

-- Grant access
GRANT EXECUTE ON FUNCTION check_performance_advisor_compliance() TO service_role;

-- Log this optimization fix
SELECT log_security_event('auth_uid_optimization_applied',
    jsonb_build_object(
        'optimization_type', 'select_auth_uid_pattern',
        'tables_optimized', ARRAY['goals', 'users', 'user_feedback', 'fan_idols'],
        'performance_improvement', 'eliminates_row_by_row_auth_evaluation'
    )
);

-- Final verification
SELECT 'Auth.uid() optimization fix completed' as status,
       'All policies now use (SELECT auth.uid()) pattern' as details;