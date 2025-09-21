-- Add OAuth fields to existing users table
-- This adds only the missing fields needed for Apple/Google Sign-In

-- Add OAuth-specific columns
ALTER TABLE users ADD COLUMN IF NOT EXISTS google_user_id TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS apple_user_id TEXT;  
ALTER TABLE users ADD COLUMN IF NOT EXISTS auth_provider TEXT DEFAULT 'email';
ALTER TABLE users ADD COLUMN IF NOT EXISTS email_verified BOOLEAN DEFAULT FALSE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS profile_picture_url TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS last_login_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Add 'name' field that auth functions expect (mapped from display_name)
ALTER TABLE users ADD COLUMN IF NOT EXISTS name TEXT;
UPDATE users SET name = display_name WHERE name IS NULL AND display_name IS NOT NULL;

-- Map avatar_url to profile_picture_url for auth functions
UPDATE users SET profile_picture_url = avatar_url WHERE profile_picture_url IS NULL AND avatar_url IS NOT NULL;

-- Add monthly_budget field (some functions may expect this)
ALTER TABLE users ADD COLUMN IF NOT EXISTS monthly_budget DECIMAL(10,2) DEFAULT 0.00;

-- Create indexes for OAuth lookups
CREATE INDEX IF NOT EXISTS idx_users_google_user_id ON users(google_user_id);
CREATE INDEX IF NOT EXISTS idx_users_apple_user_id ON users(apple_user_id);
CREATE INDEX IF NOT EXISTS idx_users_auth_provider ON users(auth_provider);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- Add RLS policy for OAuth user creation
DROP POLICY IF EXISTS "Users can insert own profile" ON users;
CREATE POLICY "Users can insert own profile" ON users
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Verify the changes
SELECT 
    'OAuth fields added successfully!' as status,
    COUNT(*) as total_users,
    COUNT(CASE WHEN auth_provider IS NOT NULL THEN 1 END) as oauth_ready_users
FROM users;

-- Show new table structure
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'users' 
AND column_name IN ('google_user_id', 'apple_user_id', 'auth_provider', 'email_verified', 'profile_picture_url', 'last_login_at', 'name', 'monthly_budget')
ORDER BY ordinal_position;