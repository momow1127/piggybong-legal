-- Create missing user_artists table for PiggyBong app
-- Run this in your Supabase SQL Editor

-- Create user_artists table to match app expectations
CREATE TABLE IF NOT EXISTS user_artists (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    artist_id UUID REFERENCES artists(id) ON DELETE CASCADE,
    priority_rank INTEGER NOT NULL DEFAULT 1,
    monthly_allocation DECIMAL(10,2) DEFAULT 0.00,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Ensure unique artist per user
    UNIQUE(user_id, artist_id)
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_user_artists_user_id ON user_artists(user_id);
CREATE INDEX IF NOT EXISTS idx_user_artists_active ON user_artists(user_id, is_active);
CREATE INDEX IF NOT EXISTS idx_user_artists_priority ON user_artists(user_id, priority_rank);

-- Enable Row Level Security (RLS)
ALTER TABLE user_artists ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can view their own artists" ON user_artists
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own artists" ON user_artists
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own artists" ON user_artists
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own artists" ON user_artists
    FOR DELETE USING (auth.uid() = user_id);

-- Create updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS update_user_artists_updated_at ON user_artists;
CREATE TRIGGER update_user_artists_updated_at
    BEFORE UPDATE ON user_artists
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Insert some sample data for testing (optional)
-- INSERT INTO user_artists (user_id, artist_id, priority_rank, monthly_allocation)
-- VALUES
--   ('7B1F39DF-98D4-4E08-9071-41E90E7A3E11'::uuid,
--    (SELECT id FROM artists LIMIT 1),
--    1,
--    50.00)
-- ON CONFLICT (user_id, artist_id) DO NOTHING;

COMMENT ON TABLE user_artists IS 'Tracks which artists each user follows with priority and budget allocation';
COMMENT ON COLUMN user_artists.priority_rank IS 'User-defined priority ranking (1 = highest priority)';
COMMENT ON COLUMN user_artists.monthly_allocation IS 'Amount of monthly budget allocated to this artist';
COMMENT ON COLUMN user_artists.is_active IS 'Whether user is actively following this artist';