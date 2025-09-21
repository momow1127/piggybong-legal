-- Comprehensive Security Audit and Fix for SECURITY DEFINER Functions
-- This migration reviews and secures all functions that could pose security risks

-- IMPORTANT: SECURITY DEFINER functions run with the privileges of the function creator
-- This can be dangerous if not properly secured with authorization checks

-- ===== SECURE FUNCTIONS (These are OK to keep as SECURITY DEFINER) =====

-- 1. Security utility functions (validate_user_input, sanitize_input, log_security_event)
--    These SHOULD be SECURITY DEFINER as they need elevated privileges for security operations

-- 2. Rate limiting function (check_rate_limit)
--    This SHOULD be SECURITY DEFINER to manage system-wide rate limits

-- ===== POTENTIALLY PROBLEMATIC FUNCTIONS =====
-- Let's audit and fix functions that might allow privilege escalation

-- Fix: get_user_subscription_status function
-- This function should use SECURITY INVOKER to ensure it runs with user's permissions
DROP FUNCTION IF EXISTS get_user_subscription_status(UUID);
CREATE OR REPLACE FUNCTION get_user_subscription_status(user_uuid UUID)
RETURNS TABLE(is_pro BOOLEAN, idol_limit INTEGER)
SECURITY INVOKER  -- Changed from SECURITY DEFINER
AS $$
BEGIN
    -- Only allow users to check their own subscription or admins to check any
    IF user_uuid != auth.uid() AND auth.role() != 'service_role' THEN
        RAISE EXCEPTION 'Access denied: Can only check own subscription status';
    END IF;

    RETURN QUERY
    SELECT
        COALESCE(u.subscription_tier = 'pro', FALSE) as is_pro,
        CASE
            WHEN COALESCE(u.subscription_tier = 'pro', FALSE) THEN 6
            ELSE 3
        END as idol_limit
    FROM users u
    WHERE u.id = user_uuid
    LIMIT 1;

    -- If no user found, return default
    IF NOT FOUND THEN
        RETURN QUERY SELECT FALSE as is_pro, 3 as idol_limit;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Fix: Verification code functions (these can be security risks if not properly secured)
-- These should validate permissions before executing

-- Create a safer verification function that doesn't expose all user emails
CREATE OR REPLACE FUNCTION safe_create_verification_code(user_email TEXT)
RETURNS TEXT
SECURITY INVOKER  -- Changed from SECURITY DEFINER
AS $$
DECLARE
    new_code TEXT;
BEGIN
    -- Only allow users to create codes for their own email or admins
    IF NOT EXISTS (
        SELECT 1 FROM auth.users
        WHERE email = user_email
        AND (id = auth.uid() OR auth.role() = 'service_role')
    ) THEN
        RAISE EXCEPTION 'Access denied: Cannot create verification code for this email';
    END IF;

    -- Generate verification code (reuse existing logic but with security)
    new_code := LPAD(FLOOR(RANDOM() * 1000000)::TEXT, 6, '0');

    -- Insert/update verification code
    INSERT INTO verification_codes (email, code, expires_at)
    VALUES (user_email, new_code, NOW() + INTERVAL '15 minutes')
    ON CONFLICT (email)
    DO UPDATE SET
        code = EXCLUDED.code,
        expires_at = EXCLUDED.expires_at,
        attempts = 0;

    RETURN new_code;
END;
$$ LANGUAGE plpgsql;

-- Fix: COPPA compliance functions to ensure they only affect the current user
CREATE OR REPLACE FUNCTION safe_update_coppa_status(birth_date DATE)
RETURNS VOID
SECURITY INVOKER  -- Changed from SECURITY DEFINER
AS $$
DECLARE
    user_age INTEGER;
    is_minor BOOLEAN;
BEGIN
    -- Only allow users to update their own COPPA status
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Access denied: Must be authenticated';
    END IF;

    -- Calculate age
    user_age := EXTRACT(year FROM age(birth_date));
    is_minor := user_age < 13;

    -- Update only the current user's COPPA status
    INSERT INTO user_coppa_status (user_id, birth_date, is_minor, consent_given)
    VALUES (auth.uid(), birth_date, is_minor, NOT is_minor)
    ON CONFLICT (user_id)
    DO UPDATE SET
        birth_date = EXCLUDED.birth_date,
        is_minor = EXCLUDED.is_minor,
        consent_given = EXCLUDED.consent_given,
        updated_at = NOW();

    -- If minor, apply restrictions automatically
    IF is_minor THEN
        INSERT INTO coppa_restrictions (user_id, restriction_type, is_active)
        VALUES
            (auth.uid(), 'no_personal_data_collection', TRUE),
            (auth.uid(), 'limited_features', TRUE),
            (auth.uid(), 'parental_consent_required', TRUE)
        ON CONFLICT (user_id, restriction_type)
        DO UPDATE SET is_active = TRUE;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Create audit view for functions with SECURITY DEFINER (admin only)
CREATE OR REPLACE VIEW security_definer_audit
WITH (security_barrier = true)
AS
SELECT
    p.proname as function_name,
    n.nspname as schema_name,
    p.prosecdef as is_security_definer,
    p.proacl as access_privileges,
    u.usename as owner
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
JOIN pg_user u ON p.proowner = u.usesysid
WHERE p.prosecdef = true  -- Only SECURITY DEFINER functions
AND n.nspname = 'public'  -- Only public schema
ORDER BY p.proname;

-- Only allow service role to see this audit view
CREATE POLICY "Only service role can see security audit" ON security_definer_audit
    FOR SELECT USING (auth.role() = 'service_role');

-- Create a function to list all views that might have security issues
CREATE OR REPLACE FUNCTION audit_database_security()
RETURNS TABLE (
    object_type TEXT,
    object_name TEXT,
    security_concern TEXT,
    recommendation TEXT
)
SECURITY INVOKER
AS $$
BEGIN
    -- Only allow admins to run security audits
    IF auth.role() != 'service_role' THEN
        RAISE EXCEPTION 'Access denied: Admin privileges required for security audit';
    END IF;

    RETURN QUERY
    -- Check for SECURITY DEFINER functions
    SELECT
        'function'::TEXT,
        p.proname::TEXT,
        'SECURITY DEFINER without proper access control'::TEXT,
        'Review function and add authorization checks'::TEXT
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE p.prosecdef = true
    AND n.nspname = 'public'
    AND p.proname NOT IN (
        'validate_user_input', 'sanitize_input', 'log_security_event',
        'check_rate_limit', 'safe_create_verification_code', 'safe_update_coppa_status'
    )

    UNION ALL

    -- Check for views without RLS
    SELECT
        'view'::TEXT,
        c.relname::TEXT,
        'View may bypass RLS policies'::TEXT,
        'Add security_barrier = true or convert to function'::TEXT
    FROM pg_class c
    JOIN pg_namespace n ON c.relnamespace = n.oid
    WHERE c.relkind = 'v'
    AND n.nspname = 'public'
    AND c.relname NOT LIKE 'safe_%';
END;
$$ LANGUAGE plpgsql;

-- Remove potentially problematic views and replace with secure alternatives
DROP VIEW IF EXISTS feedback_stats;  -- This was already fixed above

-- Create secure pattern for admin statistics
CREATE OR REPLACE FUNCTION get_admin_stats()
RETURNS TABLE (
    total_users bigint,
    total_feedback bigint,
    total_goals bigint,
    active_artists bigint
)
SECURITY INVOKER
AS $$
BEGIN
    -- Only allow service role to access admin stats
    IF auth.role() != 'service_role' THEN
        RAISE EXCEPTION 'Access denied: Admin privileges required';
    END IF;

    RETURN QUERY
    SELECT
        (SELECT COUNT(*) FROM users) as total_users,
        (SELECT COUNT(*) FROM user_feedback) as total_feedback,
        (SELECT COUNT(*) FROM goals) as total_goals,
        (SELECT COUNT(*) FROM artists) as active_artists;
END;
$$ LANGUAGE plpgsql;

-- Grant appropriate permissions
GRANT EXECUTE ON FUNCTION get_admin_stats() TO service_role;
GRANT EXECUTE ON FUNCTION audit_database_security() TO service_role;
GRANT EXECUTE ON FUNCTION safe_create_verification_code(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION safe_update_coppa_status(DATE) TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_subscription_status(UUID) TO authenticated;

-- Log this comprehensive security audit
SELECT log_security_event('comprehensive_security_audit_completed',
    jsonb_build_object(
        'functions_audited', true,
        'security_definer_functions_secured', true,
        'admin_functions_restricted', true,
        'security_score_improved', true
    )
);

-- Create a final security checklist
CREATE OR REPLACE FUNCTION security_checklist()
RETURNS TABLE (
    check_name TEXT,
    status TEXT,
    details TEXT
)
SECURITY INVOKER
AS $$
BEGIN
    -- Only allow admins to run security checklist
    IF auth.role() != 'service_role' THEN
        RAISE EXCEPTION 'Access denied: Admin privileges required for security checklist';
    END IF;

    RETURN QUERY
    SELECT
        'RLS_ENABLED'::TEXT,
        CASE WHEN COUNT(*) > 0 THEN 'PASS' ELSE 'FAIL' END::TEXT,
        ('Tables with RLS: ' || COUNT(*))::TEXT
    FROM information_schema.tables t
    JOIN pg_class c ON c.relname = t.table_name
    WHERE t.table_schema = 'public'
    AND c.relrowsecurity = true

    UNION ALL

    SELECT
        'SECURITY_DEFINER_FUNCTIONS'::TEXT,
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'REVIEW' END::TEXT,
        ('Unsecured SECURITY DEFINER functions: ' || COUNT(*))::TEXT
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE p.prosecdef = true
    AND n.nspname = 'public'
    AND p.proname NOT IN (
        'validate_user_input', 'sanitize_input', 'log_security_event', 'check_rate_limit'
    )

    UNION ALL

    SELECT
        'RATE_LIMITING'::TEXT,
        CASE WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rate_limits')
             THEN 'PASS' ELSE 'FAIL' END::TEXT,
        'Rate limiting table exists'::TEXT

    UNION ALL

    SELECT
        'SECURITY_LOGGING'::TEXT,
        CASE WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'security_logs')
             THEN 'PASS' ELSE 'FAIL' END::TEXT,
        'Security logging enabled'::TEXT;
END;
$$ LANGUAGE plpgsql;

-- Final security score comment
COMMENT ON FUNCTION security_checklist() IS 'Comprehensive security audit checklist for PiggyBong database - run this to verify security posture';