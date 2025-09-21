-- Fix Remaining Security Issues
-- 1. Function Search Path Mutable: update_updated_at_column
-- 2. Materialized View in API: user_session_cache

-- ===== FIX 1: FUNCTION SEARCH PATH MUTABLE =====
-- Fix the update_updated_at_column function to have explicit search_path

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public  -- FIXED: Explicitly set search_path
AS $$
BEGIN
    NEW.updated_at = TIMEZONE('utc', NOW());
    RETURN NEW;
END;
$$;

-- Also fix any other trigger functions that might have this issue
CREATE OR REPLACE FUNCTION update_fan_idols_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public  -- FIXED: Explicitly set search_path
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

-- ===== FIX 2: MATERIALIZED VIEW API EXPOSURE =====
-- The previous fix may not have worked completely, let's be more aggressive

-- First, revoke ALL permissions from ALL roles
REVOKE ALL ON user_session_cache FROM PUBLIC;
REVOKE ALL ON user_session_cache FROM anon;
REVOKE ALL ON user_session_cache FROM authenticated;
REVOKE ALL ON user_session_cache FROM service_role;

-- Enable RLS on the materialized view (if not already enabled)
ALTER MATERIALIZED VIEW user_session_cache ENABLE ROW LEVEL SECURITY;

-- Drop any existing policies and create a strict one
DROP POLICY IF EXISTS "Users can only see own cached session data" ON user_session_cache;

-- Create a very restrictive policy - users can only see their own data
CREATE POLICY "strict_user_session_cache_access" ON user_session_cache
    FOR SELECT
    TO authenticated
    USING (auth.uid() = id);

-- Only grant minimal necessary permissions
GRANT SELECT ON user_session_cache TO authenticated; -- This will be restricted by RLS
GRANT ALL ON user_session_cache TO service_role; -- Only service role can manage the view

-- ===== ALTERNATIVE: REMOVE MATERIALIZED VIEW ENTIRELY =====
-- If the above doesn't work, we can drop the materialized view and use functions only

-- Uncomment these lines if you want to completely remove the materialized view:
-- DROP MATERIALIZED VIEW IF EXISTS user_session_cache CASCADE;

-- Create a more secure session cache function instead
CREATE OR REPLACE FUNCTION get_secure_user_session()
RETURNS TABLE (
    user_id UUID,
    user_email TEXT,
    session_created TIMESTAMPTZ
)
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
    -- Only return data for authenticated users about themselves
    IF auth.uid() IS NULL THEN
        RETURN; -- Return empty result for unauthenticated users
    END IF;

    RETURN QUERY
    SELECT
        u.id as user_id,
        u.email as user_email,
        u.created_at as session_created
    FROM users u
    WHERE u.id = auth.uid()
    AND u.created_at > NOW() - INTERVAL '30 days'
    LIMIT 1;
END;
$$ LANGUAGE plpgsql;

-- Grant access to the secure function
GRANT EXECUTE ON FUNCTION get_secure_user_session() TO authenticated;

-- ===== FIX 3: VERIFY ALL SECURITY DEFINER FUNCTIONS HAVE SEARCH_PATH =====
-- Create a comprehensive audit function

CREATE OR REPLACE FUNCTION audit_all_function_security()
RETURNS TABLE (
    function_name TEXT,
    has_search_path BOOLEAN,
    is_security_definer BOOLEAN,
    security_status TEXT,
    recommendation TEXT
)
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
    -- Only allow service role to run this audit
    IF auth.role() != 'service_role' THEN
        RAISE EXCEPTION 'Access denied: Admin privileges required';
    END IF;

    RETURN QUERY
    SELECT
        p.proname::TEXT as function_name,
        (p.proconfig IS NOT NULL AND
         EXISTS (SELECT 1 FROM unnest(p.proconfig) AS config
                WHERE config LIKE 'search_path=%')) as has_search_path,
        p.prosecdef as is_security_definer,
        CASE
            WHEN p.prosecdef AND (p.proconfig IS NULL OR
                 NOT EXISTS (SELECT 1 FROM unnest(p.proconfig) AS config
                            WHERE config LIKE 'search_path=%'))
            THEN 'VULNERABLE'
            WHEN p.prosecdef AND EXISTS (SELECT 1 FROM unnest(p.proconfig) AS config
                                       WHERE config LIKE 'search_path=%')
            THEN 'SECURE'
            ELSE 'OK'
        END::TEXT as security_status,
        CASE
            WHEN p.prosecdef AND (p.proconfig IS NULL OR
                 NOT EXISTS (SELECT 1 FROM unnest(p.proconfig) AS config
                            WHERE config LIKE 'search_path=%'))
            THEN 'CRITICAL: Add SET search_path = public'
            WHEN p.prosecdef AND EXISTS (SELECT 1 FROM unnest(p.proconfig) AS config
                                       WHERE config LIKE 'search_path=%')
            THEN 'SECURE: No action needed'
            ELSE 'OK: Not security definer'
        END::TEXT as recommendation
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public'
    ORDER BY p.prosecdef DESC, p.proname;
END;
$$ LANGUAGE plpgsql;

-- ===== VERIFY MATERIALIZED VIEW SECURITY =====
CREATE OR REPLACE FUNCTION verify_materialized_view_security()
RETURNS TABLE (
    view_name TEXT,
    has_rls BOOLEAN,
    anon_can_select BOOLEAN,
    auth_can_select BOOLEAN,
    security_status TEXT
)
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
    -- Only allow service role to run security verification
    IF auth.role() != 'service_role' THEN
        RAISE EXCEPTION 'Access denied: Admin privileges required';
    END IF;

    RETURN QUERY
    SELECT
        mv.matviewname::TEXT as view_name,
        mv.matviewrowsecurity as has_rls,
        has_table_privilege('anon', 'public.' || mv.matviewname, 'SELECT') as anon_can_select,
        has_table_privilege('authenticated', 'public.' || mv.matviewname, 'SELECT') as auth_can_select,
        CASE
            WHEN mv.matviewrowsecurity
                AND NOT has_table_privilege('anon', 'public.' || mv.matviewname, 'SELECT')
                AND has_table_privilege('authenticated', 'public.' || mv.matviewname, 'SELECT')
            THEN 'SECURE'
            WHEN NOT mv.matviewrowsecurity
            THEN 'CRITICAL: RLS NOT ENABLED'
            WHEN has_table_privilege('anon', 'public.' || mv.matviewname, 'SELECT')
            THEN 'CRITICAL: ANON ACCESS ALLOWED'
            ELSE 'REVIEW_NEEDED'
        END::TEXT as security_status
    FROM pg_matviews mv
    WHERE mv.schemaname = 'public';
END;
$$ LANGUAGE plpgsql;

-- Log these security fixes
SELECT log_security_event('remaining_security_issues_fixed',
    jsonb_build_object(
        'function_search_path_fixed', 'update_updated_at_column',
        'materialized_view_secured', 'user_session_cache',
        'additional_functions_secured', 'update_fan_idols_updated_at',
        'audit_functions_created', 'comprehensive_security_verification'
    )
);

-- Comments for documentation
COMMENT ON FUNCTION update_updated_at_column() IS 'Secure trigger function with explicit search_path';
COMMENT ON FUNCTION get_secure_user_session() IS 'Secure alternative to materialized view for session data';
COMMENT ON FUNCTION audit_all_function_security() IS 'Comprehensive audit of all function security configurations';
COMMENT ON FUNCTION verify_materialized_view_security() IS 'Verifies security status of all materialized views';

-- Final verification query
SELECT 'Security fixes applied' as status,
       'Check audit functions for verification' as next_step;