-- User Priorities Table for PiggyBong
-- This table stores user priority settings for different fan categories
-- Used by the AI insights system to provide personalized recommendations

CREATE TABLE IF NOT EXISTS user_priorities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    artist_id UUID REFERENCES artists(id) ON DELETE SET NULL,
    category TEXT NOT NULL, -- 'concerts', 'albums', 'merch', 'events', 'subs', 'other'
    priority INTEGER NOT NULL CHECK (priority >= 1 AND priority <= 3), -- 1=high, 2=medium, 3=low
    monthly_allocation DECIMAL(10,2) DEFAULT 0.00,
    spent DECIMAL(10,2) DEFAULT 0.00,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Ensure one priority per user per category per artist
    UNIQUE(user_id, category, artist_id)
);

-- Index for efficient queries
CREATE INDEX IF NOT EXISTS idx_user_priorities_user_id ON user_priorities(user_id);
CREATE INDEX IF NOT EXISTS idx_user_priorities_category ON user_priorities(category);
CREATE INDEX IF NOT EXISTS idx_user_priorities_priority ON user_priorities(priority);

-- Row Level Security (RLS) policies
ALTER TABLE user_priorities ENABLE ROW LEVEL SECURITY;

-- Users can only access their own priorities
CREATE POLICY "Users can view their own priorities" 
    ON user_priorities FOR SELECT 
    USING (auth.uid()::text = user_id::text);

CREATE POLICY "Users can insert their own priorities" 
    ON user_priorities FOR INSERT 
    WITH CHECK (auth.uid()::text = user_id::text);

CREATE POLICY "Users can update their own priorities" 
    ON user_priorities FOR UPDATE 
    USING (auth.uid()::text = user_id::text)
    WITH CHECK (auth.uid()::text = user_id::text);

CREATE POLICY "Users can delete their own priorities" 
    ON user_priorities FOR DELETE 
    USING (auth.uid()::text = user_id::text);

-- Function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_user_priorities_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to call the function
CREATE TRIGGER user_priorities_updated_at_trigger
    BEFORE UPDATE ON user_priorities
    FOR EACH ROW
    EXECUTE FUNCTION update_user_priorities_updated_at();

-- Comments for documentation
COMMENT ON TABLE user_priorities IS 'Stores user priority settings for different fan categories, used by AI insights';
COMMENT ON COLUMN user_priorities.category IS 'Fan category: concerts, albums, merch, events, subs, other';
COMMENT ON COLUMN user_priorities.priority IS 'Priority level: 1=high, 2=medium, 3=low';
COMMENT ON COLUMN user_priorities.monthly_allocation IS 'Monthly budget allocated to this category';
COMMENT ON COLUMN user_priorities.spent IS 'Amount spent in current month for this category';
COMMENT ON COLUMN user_priorities.artist_id IS 'Optional: specific artist for this priority, null for category-wide';

-- Sample query to verify the table works
-- SELECT * FROM user_priorities WHERE user_id = 'your-user-id';