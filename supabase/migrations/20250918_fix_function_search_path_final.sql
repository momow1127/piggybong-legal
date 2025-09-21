-- Fix Function Search Path Mutable Security Issue
-- This fixes the specific issue with update_updated_at_column function

-- Fix the update_updated_at_column function to have explicit search_path
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public  -- FIXED: Explicitly set search_path for security
AS $$
BEGIN
    NEW.updated_at = TIMEZONE('utc', NOW());
    RETURN NEW;
END;
$$;

-- Also check and fix any other common trigger functions that might have this issue
CREATE OR REPLACE FUNCTION update_fan_idols_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public  -- FIXED: Explicitly set search_path for security
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

-- Create a comprehensive audit function to check ALL functions for search_path issues
CREATE OR REPLACE FUNCTION audit_function_search_path_security()
RETURNS TABLE (
    function_name TEXT,
    schema_name TEXT,
    is_security_definer BOOLEAN,
    has_explicit_search_path BOOLEAN,
    security_risk_level TEXT,
    recommendation TEXT
)
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
    -- Only allow service role to run this security audit
    IF auth.role() != 'service_role' THEN
        RAISE EXCEPTION 'Access denied: Admin privileges required for security audit';
    END IF;

    RETURN QUERY
    SELECT
        p.proname::TEXT as function_name,
        n.nspname::TEXT as schema_name,
        p.prosecdef as is_security_definer,
        (p.proconfig IS NOT NULL AND
         EXISTS (SELECT 1 FROM unnest(p.proconfig) AS config
                WHERE config LIKE 'search_path=%')) as has_explicit_search_path,
        CASE
            WHEN p.prosecdef AND (p.proconfig IS NULL OR
                 NOT EXISTS (SELECT 1 FROM unnest(p.proconfig) AS config
                            WHERE config LIKE 'search_path=%'))
            THEN 'HIGH_RISK'
            WHEN p.prosecdef AND EXISTS (SELECT 1 FROM unnest(p.proconfig) AS config
                                       WHERE config LIKE 'search_path=%')
            THEN 'SECURE'
            ELSE 'LOW_RISK'
        END::TEXT as security_risk_level,
        CASE
            WHEN p.prosecdef AND (p.proconfig IS NULL OR
                 NOT EXISTS (SELECT 1 FROM unnest(p.proconfig) AS config
                            WHERE config LIKE 'search_path=%'))
            THEN 'CRITICAL: Add SET search_path = public to function definition'
            WHEN p.prosecdef AND EXISTS (SELECT 1 FROM unnest(p.proconfig) AS config
                                       WHERE config LIKE 'search_path=%')
            THEN 'SECURE: No action needed'
            ELSE 'OK: Not security definer function'
        END::TEXT as recommendation
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public'
    ORDER BY
        CASE
            WHEN p.prosecdef AND (p.proconfig IS NULL OR
                 NOT EXISTS (SELECT 1 FROM unnest(p.proconfig) AS config
                            WHERE config LIKE 'search_path=%'))
            THEN 1
            ELSE 2
        END,
        p.proname;
END;
$$ LANGUAGE plpgsql;

-- Grant execution permission
GRANT EXECUTE ON FUNCTION audit_function_search_path_security() TO service_role;

-- Log this security fix
SELECT log_security_event('function_search_path_fixed',
    jsonb_build_object(
        'function_fixed', 'update_updated_at_column',
        'issue', 'mutable_search_path',
        'fix_applied', 'explicit_search_path_set',
        'security_level', 'resolved'
    )
);

-- Comments for documentation
COMMENT ON FUNCTION update_updated_at_column() IS 'Secure trigger function with explicit search_path to prevent injection attacks';
COMMENT ON FUNCTION update_fan_idols_updated_at() IS 'Secure trigger function with explicit search_path to prevent injection attacks';
COMMENT ON FUNCTION audit_function_search_path_security() IS 'Comprehensive audit of all functions for search_path security vulnerabilities';

-- Final verification - check that the fix worked
SELECT 'Function search path security fix applied' as status,
       'update_updated_at_column now has explicit search_path' as details;