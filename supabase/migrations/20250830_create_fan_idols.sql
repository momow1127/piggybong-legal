-- Create fan_idols table for user's favorite artists
CREATE TABLE IF NOT EXISTS fan_idols (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    artist_id UUID REFERENCES artists(id) ON DELETE CASCADE NOT NULL,
    priority_rank INTEGER NOT NULL CHECK (priority_rank >= 1 AND priority_rank <= 6),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    
    -- Ensure one user can't have the same artist twice
    UNIQUE(user_id, artist_id),
    -- Ensure one user can't have two artists with the same priority
    UNIQUE(user_id, priority_rank)
);

-- Create indexes for efficient queries
CREATE INDEX IF NOT EXISTS idx_fan_idols_user_id ON fan_idols(user_id);
CREATE INDEX IF NOT EXISTS idx_fan_idols_artist_id ON fan_idols(artist_id);
CREATE INDEX IF NOT EXISTS idx_fan_idols_priority ON fan_idols(user_id, priority_rank);

-- Enable RLS (Row Level Security)
ALTER TABLE fan_idols ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view their own fan idols" ON fan_idols
    FOR SELECT USING (auth.uid()::text = user_id::text);

CREATE POLICY "Users can insert their own fan idols" ON fan_idols
    FOR INSERT WITH CHECK (auth.uid()::text = user_id::text);

CREATE POLICY "Users can update their own fan idols" ON fan_idols
    FOR UPDATE USING (auth.uid()::text = user_id::text);

CREATE POLICY "Users can delete their own fan idols" ON fan_idols
    FOR DELETE USING (auth.uid()::text = user_id::text);

-- Create trigger for updated_at
CREATE OR REPLACE FUNCTION update_fan_idols_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER fan_idols_updated_at_trigger
    BEFORE UPDATE ON fan_idols
    FOR EACH ROW
    EXECUTE FUNCTION update_fan_idols_updated_at();

-- Create function to get user's subscription status (for limits)
CREATE OR REPLACE FUNCTION get_user_subscription_status(user_uuid UUID)
RETURNS TABLE(is_pro BOOLEAN, idol_limit INTEGER) AS $$
BEGIN
    -- For now, we'll check if user exists and assume free tier (3 idols)
    -- In production, this would check actual subscription status
    RETURN QUERY 
    SELECT 
        FALSE as is_pro,  -- Default to free tier
        3 as idol_limit   -- Free tier limit
    FROM auth.users 
    WHERE id = user_uuid
    LIMIT 1;
    
    -- If no user found, return default
    IF NOT FOUND THEN
        RETURN QUERY SELECT FALSE as is_pro, 3 as idol_limit;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON TABLE fan_idols TO authenticated;
GRANT SELECT ON TABLE fan_idols TO anon;