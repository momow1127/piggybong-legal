-- Fix Multiple Permissive RLS Policies Performance Issues
-- This consolidates duplicate policies into single, optimized ones

-- Fix 1: notification_preferences table
-- Drop existing conflicting policies
DROP POLICY IF EXISTS "Users can create their own notification preferences" ON public.notification_preferences;
DROP POLICY IF EXISTS "Users can manage their own notification preferences" ON public.notification_preferences;

-- Create single comprehensive policy
CREATE POLICY "notification_preferences_user_policy" ON public.notification_preferences
    FOR ALL
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Fix 2: user_device_tokens table
-- Drop existing conflicting policies
DROP POLICY IF EXISTS "Users can manage their own device tokens" ON public.user_device_tokens;
DROP POLICY IF EXISTS "Users can create device tokens" ON public.user_device_tokens;
DROP POLICY IF EXISTS "Users can update device tokens" ON public.user_device_tokens;

-- Create single comprehensive policy
CREATE POLICY "user_device_tokens_user_policy" ON public.user_device_tokens
    FOR ALL
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Fix 3: artist_notification_preferences table
-- Drop existing conflicting policies
DROP POLICY IF EXISTS "Users can manage their own artist notification preferences" ON public.artist_notification_preferences;
DROP POLICY IF EXISTS "Users can create artist preferences" ON public.artist_notification_preferences;

-- Create single comprehensive policy
CREATE POLICY "artist_notification_preferences_user_policy" ON public.artist_notification_preferences
    FOR ALL
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Fix 4: notification_logs table
-- Drop existing conflicting policies
DROP POLICY IF EXISTS "Users can view their own notification logs" ON public.notification_logs;
DROP POLICY IF EXISTS "Service role can insert notification logs" ON public.notification_logs;

-- Create optimized policies - separate read and write for performance
CREATE POLICY "notification_logs_user_select" ON public.notification_logs
    FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);

CREATE POLICY "notification_logs_service_insert" ON public.notification_logs
    FOR INSERT
    TO service_role
    WITH CHECK (true);

-- Additional optimizations for common queries

-- Fix 5: Add policy for anon users to read notification templates (public data)
CREATE POLICY "notification_templates_public_read" ON public.notification_templates
    FOR SELECT
    TO public
    USING (true);

-- Performance improvements: Enable RLS but with optimized policies
ALTER TABLE public.user_device_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.artist_notification_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_templates ENABLE ROW LEVEL SECURITY;

-- Grant necessary permissions with proper scope
GRANT SELECT, INSERT, UPDATE, DELETE ON public.user_device_tokens TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.notification_preferences TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.artist_notification_preferences TO authenticated;
GRANT SELECT ON public.notification_logs TO authenticated;
GRANT SELECT ON public.notification_templates TO authenticated, anon;

-- Service role permissions for logging
GRANT INSERT ON public.notification_logs TO service_role;

-- Analyze tables for query planner optimization
ANALYZE public.user_device_tokens;
ANALYZE public.notification_logs;
ANALYZE public.notification_preferences;
ANALYZE public.artist_notification_preferences;
ANALYZE public.notification_templates;