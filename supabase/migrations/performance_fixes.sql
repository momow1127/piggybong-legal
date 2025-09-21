-- Performance Optimization for Push Notification Tables
-- Run this AFTER getting the specific warnings, but here are the most common fixes:

-- Fix 1: Index on user_device_tokens for fast user lookups
CREATE INDEX IF NOT EXISTS idx_user_device_tokens_user_id
ON public.user_device_tokens(user_id)
WHERE active = true;

-- Fix 2: Index on user_device_tokens for platform filtering
CREATE INDEX IF NOT EXISTS idx_user_device_tokens_platform_active
ON public.user_device_tokens(platform, active);

-- Fix 3: Index on notification_logs for user queries
CREATE INDEX IF NOT EXISTS idx_notification_logs_user_sent_at
ON public.notification_logs(user_id, sent_at DESC);

-- Fix 4: Index on notification_logs for analytics queries
CREATE INDEX IF NOT EXISTS idx_notification_logs_type_sent_at
ON public.notification_logs(notification_type, sent_at DESC);

-- Fix 5: Index on notification_preferences for user lookups
CREATE INDEX IF NOT EXISTS idx_notification_preferences_user_id
ON public.notification_preferences(user_id);

-- Fix 6: Index on artist_notification_preferences for user-artist lookups
CREATE INDEX IF NOT EXISTS idx_artist_notification_preferences_user_artist
ON public.artist_notification_preferences(user_id, artist_name);

-- Fix 7: Partial index for active push notifications preferences
CREATE INDEX IF NOT EXISTS idx_notification_preferences_push_enabled
ON public.notification_preferences(user_id)
WHERE push_notifications_enabled = true;

-- Fix 8: Index for notification templates by type
CREATE INDEX IF NOT EXISTS idx_notification_templates_type
ON public.notification_templates(template_type);

-- Fix 9: Composite index for efficient notification queries
CREATE INDEX IF NOT EXISTS idx_device_tokens_composite
ON public.user_device_tokens(user_id, platform, active, last_used_at DESC);

-- Fix 10: Index for cleanup queries (old notifications)
CREATE INDEX IF NOT EXISTS idx_notification_logs_cleanup
ON public.notification_logs(sent_at)
WHERE sent_at < NOW() - INTERVAL '30 days';

-- Fix 11: Speed up RLS policy checks
CREATE INDEX IF NOT EXISTS idx_user_device_tokens_auth_user
ON public.user_device_tokens(user_id)
WHERE active = true;

-- ANALYZE tables after creating indexes
ANALYZE public.user_device_tokens;
ANALYZE public.notification_logs;
ANALYZE public.notification_preferences;
ANALYZE public.artist_notification_preferences;

-- Vacuum to reclaim space
VACUUM ANALYZE public.user_device_tokens;
VACUUM ANALYZE public.notification_logs;