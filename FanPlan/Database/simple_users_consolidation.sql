-- Simple user table consolidation - Essential fields only
-- Merge profiles + user_profiles → users (no goal/budget)

-- Step 1: Create the consolidated users table with essential fields
CREATE TABLE IF NOT EXISTS users (
    -- Primary identity (from profiles)
    id UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
    email TEXT UNIQUE NOT NULL,
    name TEXT, -- was display_name in profiles
    avatar_url TEXT,
    
    -- OAuth fields (needed by auth functions)
    google_user_id TEXT,
    apple_user_id TEXT,
    auth_provider TEXT DEFAULT 'email',
    email_verified BOOLEAN DEFAULT FALSE,
    profile_picture_url TEXT,
    last_login_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- User preferences (from user_profiles - essential only)
    selected_mood TEXT,
    selected_bias TEXT,
    location TEXT,
    preferred_genres TEXT[] DEFAULT ARRAY['K-pop'::text],
    has_completed_onboarding BOOLEAN DEFAULT FALSE,
    
    -- Additional fields from profiles
    notifications_enabled BOOLEAN DEFAULT TRUE,
    fan_priority TEXT,
    life_stage TEXT,
    region TEXT,
    artist_type TEXT,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Step 2: Migrate data from profiles table
INSERT INTO users (
    id, email, name, avatar_url, notifications_enabled, 
    has_completed_onboarding, created_at, updated_at,
    fan_priority, life_stage, region, selected_bias, artist_type
)
SELECT 
    id, email, display_name, avatar_url, notifications_enabled,
    onboarding_completed, created_at, updated_at,
    fan_priority, life_stage, region, selected_bias, artist_type
FROM profiles
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    avatar_url = EXCLUDED.avatar_url,
    notifications_enabled = EXCLUDED.notifications_enabled,
    has_completed_onboarding = EXCLUDED.has_completed_onboarding,
    fan_priority = EXCLUDED.fan_priority,
    life_stage = EXCLUDED.life_stage,
    region = EXCLUDED.region,
    selected_bias = EXCLUDED.selected_bias,
    artist_type = EXCLUDED.artist_type;

-- Step 3: Merge essential data from user_profiles table (no goal/budget)
UPDATE users 
SET 
    selected_mood = up.selected_mood,
    selected_bias = COALESCE(users.selected_bias, up.selected_bias),
    location = up.location,
    preferred_genres = up.preferred_genres,
    has_completed_onboarding = GREATEST(users.has_completed_onboarding, up.has_completed_onboarding)
FROM user_profiles up 
WHERE users.id = up.id;

-- Step 4: Set profile_picture_url from avatar_url
UPDATE users SET profile_picture_url = avatar_url WHERE profile_picture_url IS NULL;

-- Step 5: Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_google_user_id ON users(google_user_id);
CREATE INDEX IF NOT EXISTS idx_users_apple_user_id ON users(apple_user_id);
CREATE INDEX IF NOT EXISTS idx_users_auth_provider ON users(auth_provider);
CREATE INDEX IF NOT EXISTS idx_users_created_at ON users(created_at);
CREATE INDEX IF NOT EXISTS idx_users_onboarding ON users(has_completed_onboarding);

-- Step 6: Create update trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS update_users_updated_at ON users;
CREATE TRIGGER update_users_updated_at 
    BEFORE UPDATE ON users 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Step 7: Set up RLS policies for auth compatibility
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own profile" ON users;
DROP POLICY IF EXISTS "Users can update own profile" ON users;  
DROP POLICY IF EXISTS "Users can insert own profile" ON users;

CREATE POLICY "Users can view own profile" ON users
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON users
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON users
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Verify the consolidation
SELECT 
    'Users table consolidated successfully!' as status,
    COUNT(*) as total_users,
    COUNT(CASE WHEN email IS NOT NULL THEN 1 END) as has_email,
    COUNT(CASE WHEN selected_bias IS NOT NULL THEN 1 END) as has_bias,
    COUNT(CASE WHEN auth_provider IS NOT NULL THEN 1 END) as oauth_ready
FROM users;

-- Show final table structure
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'users' 
ORDER BY ordinal_position;