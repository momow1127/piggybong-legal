-- Fix Security Definer Issue for feedback_stats view
-- This migration removes the problematic view and replaces it with a secure function

-- Drop the existing feedback_stats view that has SECURITY DEFINER issues
DROP VIEW IF EXISTS feedback_stats;

-- Create a secure function instead of a view for admin feedback statistics
-- This function explicitly checks permissions and only allows admins to access stats
CREATE OR REPLACE FUNCTION get_feedback_stats()
RETURNS TABLE (
    total_feedback bigint,
    new_feedback bigint,
    resolved_feedback bigint,
    bug_reports bigint,
    feature_requests bigint,
    last_week_feedback bigint
)
SECURITY INVOKER -- This ensures the function runs with the caller's permissions
AS $$
BEGIN
    -- Check if the user has admin privileges
    -- For now, we'll check if they have service_role or are in an admin table
    -- You can modify this check based on your admin system
    IF NOT (
        auth.role() = 'service_role' OR
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid()
            AND subscription_tier = 'admin'
        )
    ) THEN
        RAISE EXCEPTION 'Access denied: Admin privileges required';
    END IF;

    -- Return the statistics only if authorized
    RETURN QUERY
    SELECT
        COUNT(*) as total_feedback,
        COUNT(CASE WHEN uf.status = 'new' THEN 1 END) as new_feedback,
        COUNT(CASE WHEN uf.status = 'resolved' THEN 1 END) as resolved_feedback,
        COUNT(CASE WHEN uf.type = 'bug' THEN 1 END) as bug_reports,
        COUNT(CASE WHEN uf.type = 'feature' THEN 1 END) as feature_requests,
        COUNT(CASE WHEN uf.created_at > NOW() - INTERVAL '7 days' THEN 1 END) as last_week_feedback
    FROM user_feedback uf;
END;
$$ LANGUAGE plpgsql;

-- Alternative: Create a safe view that respects RLS policies
-- This view will only show aggregated data that the current user can see
CREATE OR REPLACE VIEW safe_feedback_stats
WITH (security_barrier = true) -- Ensures RLS is respected
AS
SELECT
    COUNT(*) as total_feedback,
    COUNT(CASE WHEN status = 'new' THEN 1 END) as new_feedback,
    COUNT(CASE WHEN status = 'resolved' THEN 1 END) as resolved_feedback,
    COUNT(CASE WHEN type = 'bug' THEN 1 END) as bug_reports,
    COUNT(CASE WHEN type = 'feature' THEN 1 END) as feature_requests,
    COUNT(CASE WHEN created_at > NOW() - INTERVAL '7 days' THEN 1 END) as last_week_feedback
FROM user_feedback
WHERE auth.uid() = user_id; -- Only count feedback from the current user

-- Grant permissions for the safe view to authenticated users
GRANT SELECT ON safe_feedback_stats TO authenticated;

-- Create admin-only policies for the feedback table if needed
-- Admin users (service role) can see all feedback for moderation
CREATE POLICY "Service role can manage all feedback" ON user_feedback
    FOR ALL USING (auth.role() = 'service_role');

-- Create a function to get user-specific feedback stats
CREATE OR REPLACE FUNCTION get_my_feedback_stats()
RETURNS TABLE (
    total_feedback bigint,
    new_feedback bigint,
    resolved_feedback bigint,
    bug_reports bigint,
    feature_requests bigint
)
SECURITY INVOKER
AS $$
BEGIN
    RETURN QUERY
    SELECT
        COUNT(*) as total_feedback,
        COUNT(CASE WHEN status = 'new' THEN 1 END) as new_feedback,
        COUNT(CASE WHEN status = 'resolved' THEN 1 END) as resolved_feedback,
        COUNT(CASE WHEN type = 'bug' THEN 1 END) as bug_reports,
        COUNT(CASE WHEN type = 'feature' THEN 1 END) as feature_requests
    FROM user_feedback
    WHERE user_id = auth.uid();
END;
$$ LANGUAGE plpgsql;

-- Log this security fix
SELECT log_security_event('feedback_stats_security_fixed',
    '{"action": "removed_security_definer_view", "replaced_with": "secure_function"}'::jsonb);

-- Comment on the security improvements
COMMENT ON FUNCTION get_feedback_stats() IS 'Secure admin function to get feedback statistics with proper authorization checks';
COMMENT ON VIEW safe_feedback_stats IS 'User-scoped feedback statistics that respects RLS policies';
COMMENT ON FUNCTION get_my_feedback_stats() IS 'User function to get their own feedback statistics';