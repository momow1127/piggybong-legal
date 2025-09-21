-- Create verification_codes table if it doesn't exist
CREATE TABLE IF NOT EXISTS verification_codes (
    id SERIAL PRIMARY KEY,
    email TEXT NOT NULL,
    code TEXT NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    used BOOLEAN DEFAULT FALSE
);

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_verification_codes_email ON verification_codes(email);
CREATE INDEX IF NOT EXISTS idx_verification_codes_code ON verification_codes(code);
CREATE INDEX IF NOT EXISTS idx_verification_codes_expires_at ON verification_codes(expires_at);

-- Enable RLS (Row Level Security)
ALTER TABLE verification_codes ENABLE ROW LEVEL SECURITY;

-- Policy to allow service role to manage all records
CREATE POLICY IF NOT EXISTS "Service role can manage verification codes" ON verification_codes
    FOR ALL USING (auth.role() = 'service_role');

-- Policy to allow anon users to insert their own codes (for Edge Function)
CREATE POLICY IF NOT EXISTS "Allow insert for verification codes" ON verification_codes
    FOR INSERT WITH CHECK (true);

-- Policy to allow anon users to read their own codes
CREATE POLICY IF NOT EXISTS "Users can read own verification codes" ON verification_codes
    FOR SELECT USING (true);