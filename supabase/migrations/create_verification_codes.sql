-- Create verification_codes table for email verification
CREATE TABLE IF NOT EXISTS verification_codes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    email TEXT NOT NULL,
    code TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    verified_at TIMESTAMPTZ,
    attempt_count INTEGER DEFAULT 0,
    max_attempts INTEGER DEFAULT 5,
    
    -- Indexes for performance
    CONSTRAINT unique_active_code UNIQUE (email, code),
    CONSTRAINT valid_code_length CHECK (length(code) = 6),
    CONSTRAINT valid_email_format CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

-- Create index for efficient lookups
CREATE INDEX IF NOT EXISTS idx_verification_codes_email ON verification_codes(email);
CREATE INDEX IF NOT EXISTS idx_verification_codes_expires_at ON verification_codes(expires_at);
CREATE INDEX IF NOT EXISTS idx_verification_codes_created_at ON verification_codes(created_at);

-- Enable Row Level Security
ALTER TABLE verification_codes ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users can only access their own verification codes
CREATE POLICY "Users can access own verification codes" ON verification_codes
    FOR ALL USING (
        auth.jwt() ->> 'email' = email OR 
        auth.role() = 'service_role'
    );

-- Function to cleanup expired codes (called by scheduled function)
CREATE OR REPLACE FUNCTION cleanup_expired_verification_codes()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM verification_codes 
    WHERE expires_at < NOW() - INTERVAL '1 hour';
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    -- Also cleanup old verified codes (older than 24 hours)
    DELETE FROM verification_codes 
    WHERE verified_at IS NOT NULL 
    AND verified_at < NOW() - INTERVAL '24 hours';
    
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to generate random 6-digit code
CREATE OR REPLACE FUNCTION generate_verification_code()
RETURNS TEXT AS $$
BEGIN
    -- Generate 6-digit numeric code
    RETURN LPAD((RANDOM() * 999999)::INTEGER::TEXT, 6, '0');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to create verification code
CREATE OR REPLACE FUNCTION create_verification_code(user_email TEXT)
RETURNS TABLE(code TEXT, expires_at TIMESTAMPTZ) AS $$
DECLARE
    new_code TEXT;
    expiry_time TIMESTAMPTZ;
BEGIN
    -- Generate new code
    new_code := generate_verification_code();
    expiry_time := NOW() + INTERVAL '15 minutes';
    
    -- Deactivate any existing codes for this email
    UPDATE verification_codes 
    SET verified_at = NOW()
    WHERE email = user_email 
    AND verified_at IS NULL 
    AND expires_at > NOW();
    
    -- Insert new code
    INSERT INTO verification_codes (email, code, expires_at)
    VALUES (user_email, new_code, expiry_time);
    
    -- Return the code and expiry
    RETURN QUERY SELECT new_code, expiry_time;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to verify code
CREATE OR REPLACE FUNCTION verify_code(user_email TEXT, input_code TEXT)
RETURNS TABLE(success BOOLEAN, message TEXT) AS $$
DECLARE
    code_record RECORD;
BEGIN
    -- Find the active code
    SELECT * INTO code_record
    FROM verification_codes
    WHERE email = user_email
    AND code = input_code
    AND expires_at > NOW()
    AND verified_at IS NULL
    ORDER BY created_at DESC
    LIMIT 1;
    
    -- Check if code exists
    IF code_record IS NULL THEN
        -- Check if code exists but expired/used
        IF EXISTS (
            SELECT 1 FROM verification_codes 
            WHERE email = user_email AND code = input_code
        ) THEN
            RETURN QUERY SELECT FALSE, 'Verification code has expired or already been used';
        ELSE
            RETURN QUERY SELECT FALSE, 'Invalid verification code';
        END IF;
        RETURN;
    END IF;
    
    -- Check attempt count
    IF code_record.attempt_count >= code_record.max_attempts THEN
        RETURN QUERY SELECT FALSE, 'Too many attempts. Please request a new code';
        RETURN;
    END IF;
    
    -- Mark as verified
    UPDATE verification_codes
    SET verified_at = NOW(),
        attempt_count = attempt_count + 1
    WHERE id = code_record.id;
    
    RETURN QUERY SELECT TRUE, 'Email verified successfully';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE ON verification_codes TO anon, authenticated;
GRANT EXECUTE ON FUNCTION cleanup_expired_verification_codes() TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION generate_verification_code() TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION create_verification_code(TEXT) TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION verify_code(TEXT, TEXT) TO anon, authenticated, service_role;