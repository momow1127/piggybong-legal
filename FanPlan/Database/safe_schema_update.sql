-- Safe Database Schema Update - Handles Existing Objects
-- Run this in your Supabase SQL Editor

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create enum types (safe if exists)
DO $$ BEGIN
    CREATE TYPE purchase_category AS ENUM (
        'album', 'concert', 'merchandise', 'digital', 'photocard', 'other'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Create or update users table with OAuth support
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    monthly_budget DECIMAL(10,2) DEFAULT 0.00,
    currency TEXT DEFAULT 'USD',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add OAuth columns if they don't exist
DO $$ BEGIN
    ALTER TABLE users ADD COLUMN google_user_id TEXT;
EXCEPTION
    WHEN duplicate_column THEN null;
END $$;

DO $$ BEGIN
    ALTER TABLE users ADD COLUMN apple_user_id TEXT;
EXCEPTION
    WHEN duplicate_column THEN null;
END $$;

DO $$ BEGIN
    ALTER TABLE users ADD COLUMN auth_provider TEXT DEFAULT 'email';
EXCEPTION
    WHEN duplicate_column THEN null;
END $$;

DO $$ BEGIN
    ALTER TABLE users ADD COLUMN email_verified BOOLEAN DEFAULT FALSE;
EXCEPTION
    WHEN duplicate_column THEN null;
END $$;

DO $$ BEGIN
    ALTER TABLE users ADD COLUMN profile_picture_url TEXT;
EXCEPTION
    WHEN duplicate_column THEN null;
END $$;

DO $$ BEGIN
    ALTER TABLE users ADD COLUMN last_login_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
EXCEPTION
    WHEN duplicate_column THEN null;
END $$;

-- Create other tables if they don't exist
CREATE TABLE IF NOT EXISTS artists (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    group_name TEXT,
    image_url TEXT,
    spotify_id TEXT,
    is_following BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes safely
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_google_user_id ON users(google_user_id);
CREATE INDEX IF NOT EXISTS idx_users_apple_user_id ON users(apple_user_id);
CREATE INDEX IF NOT EXISTS idx_users_auth_provider ON users(auth_provider);

-- Create update function if it doesn't exist
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger safely (drop first if exists)
DROP TRIGGER IF EXISTS update_users_updated_at ON users;
CREATE TRIGGER update_users_updated_at 
    BEFORE UPDATE ON users 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Enable RLS on users table
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Drop existing policies first, then recreate
DROP POLICY IF EXISTS "Users can view own profile" ON users;
DROP POLICY IF EXISTS "Users can update own profile" ON users;  
DROP POLICY IF EXISTS "Users can insert own profile" ON users;

-- Create RLS policies for users (OAuth compatible)
CREATE POLICY "Users can view own profile" ON users
    FOR SELECT USING (auth.uid()::text = id::text);

CREATE POLICY "Users can update own profile" ON users
    FOR UPDATE USING (auth.uid()::text = id::text);

CREATE POLICY "Users can insert own profile" ON users
    FOR INSERT WITH CHECK (auth.uid()::text = id::text);

-- Artists table policies (public read)
ALTER TABLE artists ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Artists are viewable by everyone" ON artists;
CREATE POLICY "Artists are viewable by everyone" ON artists
    FOR SELECT USING (true);

-- Insert sample artists (ignore conflicts)
INSERT INTO artists (name, group_name) VALUES
    ('BTS', 'BTS'),
    ('BLACKPINK', 'BLACKPINK'),
    ('NewJeans', 'NewJeans'),
    ('IVE', 'IVE'),
    ('aespa', 'aespa'),
    ('TWICE', 'TWICE'),
    ('Red Velvet', 'Red Velvet'),
    ('ITZY', 'ITZY'),
    ('NMIXX', 'NMIXX'),
    ('LE SSERAFIM', 'LE SSERAFIM'),
    ('(G)I-DLE', '(G)I-DLE'),
    ('STRAY KIDS', 'STRAY KIDS'),
    ('SEVENTEEN', 'SEVENTEEN'),
    ('NCT', 'NCT'),
    ('ENHYPEN', 'ENHYPEN')
ON CONFLICT (name) DO NOTHING;

-- Verify users table has OAuth fields
SELECT 
    'Users table updated successfully!' as status,
    column_name, 
    data_type,
    is_nullable 
FROM information_schema.columns 
WHERE table_name = 'users' 
ORDER BY ordinal_position;