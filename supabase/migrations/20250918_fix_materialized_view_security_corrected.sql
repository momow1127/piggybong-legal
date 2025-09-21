-- Fix Materialized View Security - Corrected Syntax
-- Move user_session_cache to private schema to prevent API exposure

-- Create private schema if it doesn't exist
CREATE SCHEMA IF NOT EXISTS private;

-- For materialized views, we use the table syntax (not "MATERIALIZED VIEW")
-- Revoke all permissions from public roles
REVOKE ALL ON public.user_session_cache FROM PUBLIC;
REVOKE ALL ON public.user_session_cache FROM anon;
REVOKE ALL ON public.user_session_cache FROM authenticated;

-- Move materialized view to private schema
ALTER MATERIALIZED VIEW public.user_session_cache SET SCHEMA private;

-- Ensure no permissions in private schema
REVOKE ALL ON private.user_session_cache FROM PUBLIC;
REVOKE ALL ON private.user_session_cache FROM anon;
REVOKE ALL ON private.user_session_cache FROM authenticated;

-- Only service_role can access
GRANT ALL ON private.user_session_cache TO service_role;

-- Create secure access function for user's own session data
CREATE OR REPLACE FUNCTION get_current_user_session()
RETURNS TABLE (
    user_id UUID,
    user_email TEXT,
    session_created TIMESTAMPTZ
)
SECURITY INVOKER
SET search_path = private, public
AS $$
BEGIN
    -- Only return current user's session data
    IF auth.uid() IS NULL THEN
        RETURN; -- Empty result for unauthenticated
    END IF;

    RETURN QUERY
    SELECT
        usc.id as user_id,
        usc.email as user_email,
        usc.created_at as session_created
    FROM private.user_session_cache usc
    WHERE usc.id = auth.uid()
    LIMIT 1;
END;
$$ LANGUAGE plpgsql;

-- Grant access to the secure function
GRANT EXECUTE ON FUNCTION get_current_user_session() TO authenticated;

-- Update the refresh function to work with the new schema
CREATE OR REPLACE FUNCTION refresh_user_session_cache()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = private, public
AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY private.user_session_cache;
END;
$$;

-- Grant refresh permission to service role
GRANT EXECUTE ON FUNCTION refresh_user_session_cache() TO service_role;

-- Verify the security fix
CREATE OR REPLACE FUNCTION verify_materialized_view_security()
RETURNS TABLE (
    view_name TEXT,
    schema_name TEXT,
    anon_access BOOLEAN,
    auth_access BOOLEAN,
    security_status TEXT
)
SECURITY INVOKER
SET search_path = private, public
AS $$
BEGIN
    -- Only allow service role to run verification
    IF auth.role() != 'service_role' THEN
        RAISE EXCEPTION 'Access denied: Admin privileges required';
    END IF;

    RETURN QUERY
    SELECT
        mv.matviewname::TEXT as view_name,
        mv.schemaname::TEXT as schema_name,
        has_table_privilege('anon', mv.schemaname || '.' || mv.matviewname, 'SELECT') as anon_access,
        has_table_privilege('authenticated', mv.schemaname || '.' || mv.matviewname, 'SELECT') as auth_access,
        CASE
            WHEN mv.schemaname = 'private'
                AND NOT has_table_privilege('anon', mv.schemaname || '.' || mv.matviewname, 'SELECT')
                AND NOT has_table_privilege('authenticated', mv.schemaname || '.' || mv.matviewname, 'SELECT')
            THEN 'SECURE'
            WHEN mv.schemaname = 'public'
            THEN 'EXPOSED_IN_PUBLIC_SCHEMA'
            WHEN has_table_privilege('anon', mv.schemaname || '.' || mv.matviewname, 'SELECT')
            THEN 'ANON_ACCESS_GRANTED'
            WHEN has_table_privilege('authenticated', mv.schemaname || '.' || mv.matviewname, 'SELECT')
            THEN 'AUTH_ACCESS_GRANTED'
            ELSE 'REVIEW_NEEDED'
        END::TEXT as security_status
    FROM pg_matviews mv
    WHERE mv.matviewname = 'user_session_cache';
END;
$$ LANGUAGE plpgsql;

-- Log the security fix
SELECT log_security_event('materialized_view_moved_to_private',
    jsonb_build_object(
        'view_name', 'user_session_cache',
        'action', 'moved_from_public_to_private_schema',
        'secure_access_function_created', 'get_current_user_session',
        'api_exposure_eliminated', true
    )
);

-- Final verification
SELECT 'Materialized view security fix completed' as status,
       'user_session_cache moved to private schema' as details;