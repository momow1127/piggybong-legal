-- Add OAuth fields to users table
-- Run this in your Supabase SQL Editor to enable Apple/Google Sign-In

-- Add OAuth-specific columns to existing users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS google_user_id TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS apple_user_id TEXT;  
ALTER TABLE users ADD COLUMN IF NOT EXISTS auth_provider TEXT DEFAULT 'email';
ALTER TABLE users ADD COLUMN IF NOT EXISTS email_verified BOOLEAN DEFAULT FALSE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS profile_picture_url TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS last_login_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Add indexes for OAuth lookups
CREATE INDEX IF NOT EXISTS idx_users_google_user_id ON users(google_user_id);
CREATE INDEX IF NOT EXISTS idx_users_apple_user_id ON users(apple_user_id);
CREATE INDEX IF NOT EXISTS idx_users_auth_provider ON users(auth_provider);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- Add RLS policy for users to insert their own profiles (needed for OAuth)
CREATE POLICY "Users can insert own profile" ON users
    FOR INSERT WITH CHECK (auth.uid()::text = id::text);

-- Update existing constraint to allow auth.users(id) as foreign key
-- The auth functions use the actual auth.users.id as the users.id
COMMENT ON COLUMN users.id IS 'References auth.users(id) - Supabase auth user ID';

-- Verify the schema changes
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'users' 
ORDER BY ordinal_position;