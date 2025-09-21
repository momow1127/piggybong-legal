-- First, check if table exists and drop if needed
DROP TABLE IF EXISTS user_priorities CASCADE;

-- Create the user_priorities table
CREATE TABLE user_priorities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    artist_id UUID,
    category TEXT NOT NULL,
    priority INTEGER NOT NULL CHECK (priority >= 1 AND priority <= 3),
    monthly_allocation DECIMAL(10,2) DEFAULT 0.00,
    spent DECIMAL(10,2) DEFAULT 0.00,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(user_id, category, artist_id)
);

-- Add foreign key constraints (only if tables exist)
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users') THEN
        ALTER TABLE user_priorities 
        ADD CONSTRAINT fk_user_priorities_user 
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'artists') THEN
        ALTER TABLE user_priorities 
        ADD CONSTRAINT fk_user_priorities_artist 
        FOREIGN KEY (artist_id) REFERENCES artists(id) ON DELETE SET NULL;
    END IF;
END $$;

-- Create indexes
CREATE INDEX idx_user_priorities_user_id ON user_priorities(user_id);
CREATE INDEX idx_user_priorities_category ON user_priorities(category);
CREATE INDEX idx_user_priorities_priority ON user_priorities(priority);

-- Enable Row Level Security
ALTER TABLE user_priorities ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view their own priorities" ON user_priorities;
DROP POLICY IF EXISTS "Users can insert their own priorities" ON user_priorities;
DROP POLICY IF EXISTS "Users can update their own priorities" ON user_priorities;
DROP POLICY IF EXISTS "Users can delete their own priorities" ON user_priorities;

-- Create RLS policies
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

-- Create or replace the update trigger function
CREATE OR REPLACE FUNCTION update_user_priorities_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop trigger if exists and recreate
DROP TRIGGER IF EXISTS user_priorities_updated_at_trigger ON user_priorities;
CREATE TRIGGER user_priorities_updated_at_trigger
    BEFORE UPDATE ON user_priorities
    FOR EACH ROW
    EXECUTE FUNCTION update_user_priorities_updated_at();

-- Add comments
COMMENT ON TABLE user_priorities IS 'Stores user priority settings for different fan categories, used by AI insights';
COMMENT ON COLUMN user_priorities.category IS 'Fan category: concerts, albums, merch, events, subs, other';
COMMENT ON COLUMN user_priorities.priority IS 'Priority level: 1=high, 2=medium, 3=low';
COMMENT ON COLUMN user_priorities.monthly_allocation IS 'Monthly budget allocated to this category';
COMMENT ON COLUMN user_priorities.spent IS 'Amount spent in current month for this category';
COMMENT ON COLUMN user_priorities.artist_id IS 'Optional: specific artist for this priority, null for category-wide';

-- Verify the table was created
SELECT 
    'Table created successfully' as status,
    count(*) as column_count
FROM information_schema.columns 
WHERE table_name = 'user_priorities';