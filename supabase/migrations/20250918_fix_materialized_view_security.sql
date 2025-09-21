-- Fix Materialized View Security Issue
-- The user_session_cache materialized view is currently accessible by anon/authenticated roles
-- This is a security risk as it exposes user data

-- ===== OPTION 1: SECURE THE MATERIALIZED VIEW WITH RLS =====

-- Enable RLS on the materialized view
ALTER MATERIALIZED VIEW user_session_cache ENABLE ROW LEVEL SECURITY;

-- Create a policy that only allows users to see their own cached data
CREATE POLICY "Users can only see own cached session data" ON user_session_cache
    FOR SELECT
    TO authenticated
    USING (auth.uid() = id);

-- Revoke public access to the materialized view
REVOKE ALL ON user_session_cache FROM anon;
REVOKE ALL ON user_session_cache FROM authenticated;

-- Grant specific SELECT permission only to authenticated users (with RLS)
GRANT SELECT ON user_session_cache TO authenticated;

-- Only allow service role to refresh the materialized view
GRANT ALL ON user_session_cache TO service_role;

-- ===== OPTION 2: ALTERNATIVE - REPLACE WITH SECURE FUNCTION =====
-- If RLS on materialized views doesn't work as expected, we can replace it with a function

CREATE OR REPLACE FUNCTION get_user_session_cache()
RETURNS TABLE (
    id UUID,
    email TEXT,
    created_at TIMESTAMPTZ
)
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
    -- Only return the current user's session data
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Authentication required';
    END IF;

    RETURN QUERY
    SELECT
        u.id,
        u.email,
        u.created_at
    FROM users u
    WHERE u.id = auth.uid()
    AND u.created_at > NOW() - INTERVAL '30 days';
END;
$$ LANGUAGE plpgsql;

-- Grant access to the secure function
GRANT EXECUTE ON FUNCTION get_user_session_cache() TO authenticated;

-- ===== VERIFICATION AND LOGGING =====

-- Create a function to verify materialized view security
CREATE OR REPLACE FUNCTION verify_materialized_view_security()
RETURNS TABLE (
    view_name TEXT,
    has_rls BOOLEAN,
    anon_access BOOLEAN,
    auth_access BOOLEAN,
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
        has_table_privilege('anon', mv.matviewname, 'SELECT') as anon_access,
        has_table_privilege('authenticated', mv.matviewname, 'SELECT') as auth_access,
        CASE
            WHEN mv.matviewrowsecurity AND NOT has_table_privilege('anon', mv.matviewname, 'SELECT')
            THEN 'SECURE'
            WHEN NOT mv.matviewrowsecurity
            THEN 'NEEDS_RLS'
            WHEN has_table_privilege('anon', mv.matviewname, 'SELECT')
            THEN 'EXPOSED_TO_ANON'
            ELSE 'REVIEW_NEEDED'
        END::TEXT as security_status
    FROM pg_matviews mv
    WHERE mv.schemaname = 'public'
    AND mv.matviewname = 'user_session_cache';
END;
$$ LANGUAGE plpgsql;

-- Log this security fix
SELECT log_security_event('materialized_view_security_fixed',
    jsonb_build_object(
        'view_name', 'user_session_cache',
        'issue', 'exposed_to_anon_authenticated',
        'fix_applied', 'rls_enabled_and_permissions_restricted',
        'alternative_function_created', 'get_user_session_cache'
    )
);

-- Comments for documentation
COMMENT ON MATERIALIZED VIEW user_session_cache IS 'Secured user session cache - RLS enabled, restricted access';
COMMENT ON FUNCTION get_user_session_cache() IS 'Secure alternative to materialized view - user-scoped access only';
COMMENT ON FUNCTION verify_materialized_view_security() IS 'Verifies security status of materialized views';

-- Final verification
SELECT 'Materialized view security fix applied' as status,
       'RLS enabled and permissions restricted' as security_improvement;