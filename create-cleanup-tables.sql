-- Create database tables for the cleanup-expired-codes function
-- Run this in your Supabase SQL Editor

-- Table for email verification codes
CREATE TABLE IF NOT EXISTS email_verification_codes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  email TEXT NOT NULL,
  code TEXT NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ DEFAULT NOW() + INTERVAL '1 hour',
  used_at TIMESTAMPTZ,
  UNIQUE(email, code)
);

-- Table for user sessions (optional - for tracking active sessions)
CREATE TABLE IF NOT EXISTS user_sessions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  session_token TEXT NOT NULL,
  device_info JSONB,
  ip_address INET,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  last_active TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ DEFAULT NOW() + INTERVAL '30 days'
);

-- Table for cleanup logs (to track cleanup operations)
CREATE TABLE IF NOT EXISTS cleanup_logs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  cleanup_type TEXT NOT NULL,
  items_cleaned INTEGER DEFAULT 0,
  details JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_email_verification_codes_created_at ON email_verification_codes(created_at);
CREATE INDEX IF NOT EXISTS idx_email_verification_codes_email ON email_verification_codes(email);
CREATE INDEX IF NOT EXISTS idx_user_sessions_created_at ON user_sessions(created_at);
CREATE INDEX IF NOT EXISTS idx_user_sessions_user_id ON user_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_cleanup_logs_created_at ON cleanup_logs(created_at);

-- Row Level Security (RLS) policies
ALTER TABLE email_verification_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE cleanup_logs ENABLE ROW LEVEL SECURITY;

-- Allow service role to manage all tables
CREATE POLICY "Service role can manage email_verification_codes" ON email_verification_codes
  FOR ALL USING (auth.jwt() ->> 'role' = 'service_role');

CREATE POLICY "Service role can manage user_sessions" ON user_sessions
  FOR ALL USING (auth.jwt() ->> 'role' = 'service_role');

CREATE POLICY "Service role can manage cleanup_logs" ON cleanup_logs
  FOR ALL USING (auth.jwt() ->> 'role' = 'service_role');

-- Allow users to read their own verification codes
CREATE POLICY "Users can read own verification codes" ON email_verification_codes
  FOR SELECT USING (auth.uid() = user_id);

-- Allow users to read their own sessions
CREATE POLICY "Users can read own sessions" ON user_sessions
  FOR SELECT USING (auth.uid() = user_id);

-- Function to automatically clean up expired codes (can be called by cron)
CREATE OR REPLACE FUNCTION cleanup_expired_verification_codes()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  deleted_count INTEGER;
BEGIN
  DELETE FROM email_verification_codes
  WHERE created_at < NOW() - INTERVAL '1 hour';

  GET DIAGNOSTICS deleted_count = ROW_COUNT;

  INSERT INTO cleanup_logs (cleanup_type, items_cleaned, details)
  VALUES ('verification_codes_auto', deleted_count, jsonb_build_object('deleted_at', NOW()));

  RETURN deleted_count;
END;
$$;

-- Grant execute permission to service role
GRANT EXECUTE ON FUNCTION cleanup_expired_verification_codes() TO service_role;