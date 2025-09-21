-- Fix security warning for insight_feedback trigger function
-- This addresses the "Function Search Path Mutable" security warning

-- Drop and recreate the function with proper security settings
DROP FUNCTION IF EXISTS update_insight_feedback_updated_at() CASCADE;

CREATE OR REPLACE FUNCTION update_insight_feedback_updated_at()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Recreate the trigger
DROP TRIGGER IF EXISTS trigger_update_insight_feedback_updated_at ON insight_feedback;

CREATE TRIGGER trigger_update_insight_feedback_updated_at
    BEFORE UPDATE ON insight_feedback
    FOR EACH ROW
    EXECUTE FUNCTION update_insight_feedback_updated_at();

-- Add comment for documentation
COMMENT ON FUNCTION update_insight_feedback_updated_at() IS 'Automatically updates the updated_at timestamp when insight_feedback rows are modified. Uses SECURITY DEFINER and fixed search_path for security.';