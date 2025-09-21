-- Fix Search Path Security Issues for All Functions
-- This migration fixes the "Function Search Path Mutable" security warnings
-- by setting explicit search_path on all security-sensitive functions

-- Fix: validate_user_input function
CREATE OR REPLACE FUNCTION validate_user_input(input_text text)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public  -- Fixed: Explicitly set search_path
AS $$
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
$$;

-- Fix: log_security_event function
CREATE OR REPLACE FUNCTION log_security_event(
    event_type text,
    event_data jsonb DEFAULT '{}'::jsonb
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public  -- Fixed: Explicitly set search_path
AS $$
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
$$;

-- Fix: check_rate_limit function
CREATE OR REPLACE FUNCTION check_rate_limit(
    action_type_param text,
    max_requests integer DEFAULT 100,
    window_minutes integer DEFAULT 60
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public  -- Fixed: Explicitly set search_path
AS $$
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
$$;

-- Fix: sanitize_input function
CREATE OR REPLACE FUNCTION sanitize_input(input_text text)
RETURNS text
LANGUAGE plpgsql
IMMUTABLE
SECURITY DEFINER
SET search_path = public  -- Fixed: Explicitly set search_path
AS $$
BEGIN
    -- Remove potentially dangerous characters
    input_text := regexp_replace(input_text, '[<>"'';&|`$(){}[\]\\]', '', 'g');

    -- Trim whitespace
    input_text := trim(input_text);

    -- Limit length
    IF length(input_text) > 500 THEN
        input_text := left(input_text, 500);
    END IF;

    RETURN input_text;
END;
$$;

-- Fix: update_updated_at_column function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public  -- Fixed: Explicitly set search_path
AS $$
BEGIN
    NEW.updated_at = TIMEZONE('utc', NOW());
    RETURN NEW;
END;
$$;

-- Also fix any other functions that might have this issue
-- Fix: update_fan_idols_updated_at function (if it exists)
CREATE OR REPLACE FUNCTION update_fan_idols_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public  -- Fixed: Explicitly set search_path
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

-- Create a function to check all functions have proper search_path
CREATE OR REPLACE FUNCTION audit_function_search_paths()
RETURNS TABLE (
    function_name TEXT,
    has_search_path BOOLEAN,
    is_security_definer BOOLEAN,
    recommendation TEXT
)
LANGUAGE plpgsql
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
            THEN 'SECURITY RISK: Add SET search_path = public'
            WHEN p.prosecdef AND EXISTS (SELECT 1 FROM unnest(p.proconfig) AS config
                                       WHERE config LIKE 'search_path=%')
            THEN 'SECURE: Search path is set'
            ELSE 'OK: Not security definer'
        END::TEXT as recommendation
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public'
    ORDER BY p.prosecdef DESC, p.proname;
END;
$$;

-- Log this security fix
SELECT log_security_event('search_path_security_fixed',
    jsonb_build_object(
        'functions_fixed', ARRAY[
            'validate_user_input',
            'log_security_event',
            'check_rate_limit',
            'sanitize_input',
            'update_updated_at_column'
        ],
        'security_warnings_resolved', 5
    )
);

-- Comments for documentation
COMMENT ON FUNCTION validate_user_input IS 'Validates user input with secure search_path';
COMMENT ON FUNCTION log_security_event IS 'Logs security events with secure search_path';
COMMENT ON FUNCTION check_rate_limit IS 'Rate limiting with secure search_path';
COMMENT ON FUNCTION sanitize_input IS 'Input sanitization with secure search_path';
COMMENT ON FUNCTION update_updated_at_column IS 'Trigger function with secure search_path';
COMMENT ON FUNCTION audit_function_search_paths IS 'Audits all functions for search_path security';