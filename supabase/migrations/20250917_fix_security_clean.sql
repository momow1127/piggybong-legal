-- Clean migration to fix security warning only
-- This only addresses the trigger function security issue

-- Fix the trigger function security warning
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

-- Recreate the trigger if it was dropped
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger
        WHERE tgname = 'trigger_update_insight_feedback_updated_at'
    ) THEN
        CREATE TRIGGER trigger_update_insight_feedback_updated_at
            BEFORE UPDATE ON insight_feedback
            FOR EACH ROW
            EXECUTE FUNCTION update_insight_feedback_updated_at();
    END IF;
END $$;