-- Create insight_feedback table for storing user feedback on AI insights
CREATE TABLE IF NOT EXISTS insight_feedback (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL,
    artist_id TEXT,
    feedback TEXT NOT NULL CHECK (feedback IN ('positive', 'negative')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add foreign key constraint to auth.users
ALTER TABLE insight_feedback
ADD CONSTRAINT fk_insight_feedback_user_id
FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_insight_feedback_user_id ON insight_feedback(user_id);
CREATE INDEX IF NOT EXISTS idx_insight_feedback_artist_id ON insight_feedback(artist_id);
CREATE INDEX IF NOT EXISTS idx_insight_feedback_created_at ON insight_feedback(created_at);

-- Enable Row Level Security (RLS)
ALTER TABLE insight_feedback ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can insert their own feedback" ON insight_feedback;
DROP POLICY IF EXISTS "Users can view their own feedback" ON insight_feedback;
DROP POLICY IF EXISTS "Users can update their own feedback" ON insight_feedback;

-- Create RLS policies
CREATE POLICY "Users can insert their own feedback" ON insight_feedback
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view their own feedback" ON insight_feedback
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own feedback" ON insight_feedback
    FOR UPDATE USING (auth.uid() = user_id);

-- Create trigger for updating updated_at timestamp
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

CREATE TRIGGER trigger_update_insight_feedback_updated_at
    BEFORE UPDATE ON insight_feedback
    FOR EACH ROW
    EXECUTE FUNCTION update_insight_feedback_updated_at();

-- Add comments for documentation
COMMENT ON TABLE insight_feedback IS 'Stores user feedback (thumbs up/down) for AI-generated insights';
COMMENT ON COLUMN insight_feedback.user_id IS 'Reference to the user who provided feedback';
COMMENT ON COLUMN insight_feedback.artist_id IS 'Artist the insight was about (optional)';
COMMENT ON COLUMN insight_feedback.feedback IS 'Either positive or negative feedback';