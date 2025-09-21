-- Simple fix: Only update the existing function's security settings
-- This avoids recreating triggers or policies that already exist

ALTER FUNCTION update_insight_feedback_updated_at()
SECURITY DEFINER
SET search_path = public;