-- Clean setup: Drop existing tables and create consolidated users table
-- This will backup your data first, then create a clean users table

-- Step 1: Backup existing data (optional - comment out if not needed)
-- CREATE TABLE profiles_backup AS SELECT * FROM profiles;
-- CREATE TABLE user_profiles_backup AS SELECT * FROM user_profiles;

-- Step 2: Drop existing tables and their dependencies
DROP TRIGGER IF EXISTS update_profiles_updated_at ON profiles;
DROP TRIGGER IF EXISTS update_user_profiles_updated_at ON user_profiles;
DROP TABLE IF EXISTS profiles CASCADE;
DROP TABLE IF EXISTS user_profiles CASCADE;

-- Step 3: Create the new consolidated users table
CREATE TABLE users (
    -- Primary identity
    id UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
    email TEXT UNIQUE NOT NULL,
    name TEXT,
    avatar_url TEXT,
    
    -- OAuth fields (needed by auth functions)
    google_user_id TEXT,
    apple_user_id TEXT,
    auth_provider TEXT DEFAULT 'email',
    email_verified BOOLEAN DEFAULT FALSE,
    profile_picture_url TEXT,
    last_login_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- User preferences
    selected_mood TEXT,
    selected_bias TEXT,
    location TEXT,
    preferred_genres TEXT[] DEFAULT ARRAY['K-pop'::text],
    has_completed_onboarding BOOLEAN DEFAULT FALSE,
    
    -- Additional fields
    notifications_enabled BOOLEAN DEFAULT TRUE,
    fan_priority TEXT,
    life_stage TEXT,
    region TEXT,
    artist_type TEXT,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Step 4: Create indexes for performance
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_google_user_id ON users(google_user_id);
CREATE INDEX idx_users_apple_user_id ON users(apple_user_id);
CREATE INDEX idx_users_auth_provider ON users(auth_provider);
CREATE INDEX idx_users_created_at ON users(created_at);
CREATE INDEX idx_users_onboarding ON users(has_completed_onboarding);

-- Step 5: Create update trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_users_updated_at 
    BEFORE UPDATE ON users 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Step 6: Set up RLS policies for auth compatibility
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own profile" ON users
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON users
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON users
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Step 7: Insert some test data to verify it works
INSERT INTO users (email, name, selected_bias, preferred_genres) VALUES
    ('test@example.com', 'Test User', 'NewJeans', ARRAY['K-pop', 'Pop'])
ON CONFLICT (email) DO NOTHING;

-- Verify the new table
SELECT 
    'Users table created successfully!' as status,
    COUNT(*) as total_users
FROM users;

-- Show table structure
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'users' 
ORDER BY ordinal_position;