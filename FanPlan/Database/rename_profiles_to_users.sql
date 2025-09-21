-- Rename profiles table to users and add missing OAuth fields
-- This will preserve your existing user data

-- First, add the missing OAuth fields to profiles table
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS google_user_id TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS apple_user_id TEXT;  
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS auth_provider TEXT DEFAULT 'email';
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS email_verified BOOLEAN DEFAULT FALSE;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS profile_picture_url TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS last_login_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Map display_name to name (auth functions expect 'name' field)
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS name TEXT;
UPDATE profiles SET name = display_name WHERE name IS NULL;

-- Map avatar_url to profile_picture_url 
UPDATE profiles SET profile_picture_url = avatar_url WHERE profile_picture_url IS NULL;

-- Add monthly_budget field that some functions might expect
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS monthly_budget DECIMAL(10,2) DEFAULT 0.00;

-- Create indexes for OAuth lookups
CREATE INDEX IF NOT EXISTS idx_profiles_google_user_id ON profiles(google_user_id);
CREATE INDEX IF NOT EXISTS idx_profiles_apple_user_id ON profiles(apple_user_id);
CREATE INDEX IF NOT EXISTS idx_profiles_auth_provider ON profiles(auth_provider);

-- Now rename the table from profiles to users
ALTER TABLE profiles RENAME TO users;

-- Update the indexes to reflect new table name
DROP INDEX IF EXISTS profiles_created_at_idx;
CREATE INDEX IF NOT EXISTS idx_users_created_at ON users(created_at);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- Update the trigger name
DROP TRIGGER IF EXISTS update_profiles_updated_at ON users;
CREATE TRIGGER update_users_updated_at 
    BEFORE UPDATE ON users 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Enable RLS and create policies for OAuth compatibility
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Drop existing policies and recreate with proper names
DROP POLICY IF EXISTS "Users can view own profile" ON users;
DROP POLICY IF EXISTS "Users can update own profile" ON users;  
DROP POLICY IF EXISTS "Users can insert own profile" ON users;

-- Create RLS policies compatible with auth functions
CREATE POLICY "Users can view own profile" ON users
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON users
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON users
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Verify the changes
SELECT 
    'Table renamed successfully!' as status,
    COUNT(*) as total_users,
    COUNT(CASE WHEN auth_provider IS NOT NULL THEN 1 END) as oauth_ready
FROM users;

-- Show table structure
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'users' 
ORDER BY ordinal_position;