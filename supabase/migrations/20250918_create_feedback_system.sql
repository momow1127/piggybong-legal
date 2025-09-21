-- Create feedback table for user reports
CREATE TABLE IF NOT EXISTS user_feedback (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,

    -- Feedback content
    type TEXT CHECK (type IN ('bug', 'feature', 'complaint', 'praise', 'other')),
    subject TEXT NOT NULL,
    message TEXT NOT NULL,

    -- Context info
    app_version TEXT,
    device_model TEXT,
    os_version TEXT,
    screen_name TEXT,

    -- Status tracking
    status TEXT DEFAULT 'new' CHECK (status IN ('new', 'reviewing', 'in_progress', 'resolved', 'wont_fix')),
    priority INTEGER DEFAULT 3 CHECK (priority BETWEEN 1 AND 5),

    -- Admin notes
    admin_notes TEXT,
    resolved_at TIMESTAMP WITH TIME ZONE,
    resolved_by UUID REFERENCES auth.users(id),

    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Create index for faster queries
CREATE INDEX idx_user_feedback_user_id ON user_feedback(user_id);
CREATE INDEX idx_user_feedback_status ON user_feedback(status);
CREATE INDEX idx_user_feedback_created_at ON user_feedback(created_at DESC);

-- Create RLS policies
ALTER TABLE user_feedback ENABLE ROW LEVEL SECURITY;

-- Users can create their own feedback
CREATE POLICY "Users can create feedback" ON user_feedback
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can view their own feedback
CREATE POLICY "Users can view own feedback" ON user_feedback
    FOR SELECT USING (auth.uid() = user_id);

-- Create a simple view for admin dashboard
CREATE OR REPLACE VIEW feedback_stats AS
SELECT
    COUNT(*) as total_feedback,
    COUNT(CASE WHEN status = 'new' THEN 1 END) as new_feedback,
    COUNT(CASE WHEN status = 'resolved' THEN 1 END) as resolved_feedback,
    COUNT(CASE WHEN type = 'bug' THEN 1 END) as bug_reports,
    COUNT(CASE WHEN type = 'feature' THEN 1 END) as feature_requests,
    COUNT(CASE WHEN created_at > NOW() - INTERVAL '7 days' THEN 1 END) as last_week_feedback
FROM user_feedback;

-- Function to auto-update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = TIMEZONE('utc', NOW());
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_user_feedback_updated_at BEFORE UPDATE
    ON user_feedback FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();