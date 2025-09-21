-- Fix Remaining RLS Performance Issues
-- Issue 1: auth.uid() re-evaluation per row (major performance killer)
-- Issue 2: Additional duplicate policies

-- ========================================
-- FIX 1: Optimize auth.uid() calls
-- Replace auth.uid() with (SELECT auth.uid()) to prevent re-evaluation
-- ========================================

-- Fix notification_preferences table
DROP POLICY IF EXISTS "notification_preferences_user_policy" ON public.notification_preferences;
DROP POLICY IF EXISTS "Users can view their own notification preferences" ON public.notification_preferences;
DROP POLICY IF EXISTS "Users can update their own notification preferences" ON public.notification_preferences;

CREATE POLICY "notification_preferences_optimized" ON public.notification_preferences
    FOR ALL
    TO authenticated
    USING (user_id = (SELECT auth.uid()))
    WITH CHECK (user_id = (SELECT auth.uid()));

-- Fix user_device_tokens table
DROP POLICY IF EXISTS "user_device_tokens_user_policy" ON public.user_device_tokens;

CREATE POLICY "user_device_tokens_optimized" ON public.user_device_tokens
    FOR ALL
    TO authenticated
    USING (user_id = (SELECT auth.uid()))
    WITH CHECK (user_id = (SELECT auth.uid()));

-- Fix artist_notification_preferences table
DROP POLICY IF EXISTS "artist_notification_preferences_user_policy" ON public.artist_notification_preferences;

CREATE POLICY "artist_notification_preferences_optimized" ON public.artist_notification_preferences
    FOR ALL
    TO authenticated
    USING (user_id = (SELECT auth.uid()))
    WITH CHECK (user_id = (SELECT auth.uid()));

-- Fix notification_logs table
DROP POLICY IF EXISTS "notification_logs_user_select" ON public.notification_logs;

CREATE POLICY "notification_logs_optimized_select" ON public.notification_logs
    FOR SELECT
    TO authenticated
    USING (user_id = (SELECT auth.uid()));

-- ========================================
-- FIX 2: Fix users table duplicate policies
-- ========================================

-- Drop duplicate policies on users table
DROP POLICY IF EXISTS "Users can create their own profile" ON public.users;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.users;

-- Create single optimized policy for users table
CREATE POLICY "users_optimized_policy" ON public.users
    FOR ALL
    TO authenticated
    USING (id = (SELECT auth.uid()))
    WITH CHECK (id = (SELECT auth.uid()));

-- ========================================
-- FIX 3: Additional Performance Optimizations
-- ========================================

-- Create indexes that support the RLS policies efficiently
CREATE INDEX IF NOT EXISTS idx_notification_preferences_user_id_fast
ON public.notification_preferences(user_id)
WHERE user_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_user_device_tokens_user_id_fast
ON public.user_device_tokens(user_id, active)
WHERE user_id IS NOT NULL AND active = true;

CREATE INDEX IF NOT EXISTS idx_artist_notification_preferences_user_id_fast
ON public.artist_notification_preferences(user_id)
WHERE user_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_notification_logs_user_id_fast
ON public.notification_logs(user_id, sent_at DESC)
WHERE user_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_users_id_fast
ON public.users(id)
WHERE id IS NOT NULL;

-- ========================================
-- FIX 4: Ensure service role can still write
-- ========================================

-- Keep service role insert policy for notification_logs
-- (This should exist from previous migration, but ensure it's there)
DROP POLICY IF EXISTS "notification_logs_service_insert" ON public.notification_logs;

CREATE POLICY "notification_logs_service_insert_optimized" ON public.notification_logs
    FOR INSERT
    TO service_role
    WITH CHECK (true);

-- ========================================
-- FIX 5: Clean up and verify permissions
-- ========================================

-- Ensure proper permissions are granted
GRANT SELECT, INSERT, UPDATE, DELETE ON public.notification_preferences TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.user_device_tokens TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.artist_notification_preferences TO authenticated;
GRANT SELECT ON public.notification_logs TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.users TO authenticated;

-- Service role permissions for logging
GRANT INSERT ON public.notification_logs TO service_role;

-- Update table statistics for query planner
ANALYZE public.notification_preferences;
ANALYZE public.user_device_tokens;
ANALYZE public.artist_notification_preferences;
ANALYZE public.notification_logs;
ANALYZE public.users;

-- ========================================
-- VERIFICATION QUERIES
-- (Run these after the above to verify performance)
-- ========================================

-- These should run fast and show the optimized policy in use:
-- EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM notification_preferences WHERE user_id = (SELECT auth.uid()) LIMIT 1;
-- EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM user_device_tokens WHERE user_id = (SELECT auth.uid()) AND active = true LIMIT 1;