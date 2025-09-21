-- COPPA Compliance Database Schema
-- Migration: 20250829_coppa_compliance.sql

-- Table for tracking parental consent requests
CREATE TABLE IF NOT EXISTS parental_consent_requests (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    child_id TEXT NOT NULL, -- Temporary ID before user account creation
    parent_email TEXT NOT NULL,
    child_name TEXT NOT NULL,
    consent_token TEXT NOT NULL UNIQUE,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'denied', 'expired')),
    parent_decision TEXT CHECK (parent_decision IN ('approve', 'deny')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ NOT NULL,
    decided_at TIMESTAMPTZ,
    CONSTRAINT valid_status CHECK (
        (status = 'pending' AND decided_at IS NULL) OR
        (status IN ('approved', 'denied') AND decided_at IS NOT NULL)
    )
);

-- Table for user age verification and COPPA status
CREATE TABLE IF NOT EXISTS user_coppa_status (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    birth_year INTEGER NOT NULL,
    is_minor BOOLEAN NOT NULL,
    has_parental_consent BOOLEAN DEFAULT FALSE,
    consent_request_id UUID REFERENCES parental_consent_requests(id),
    verified_at TIMESTAMPTZ DEFAULT NOW(),
    parent_email TEXT, -- Store for ongoing communication
    
    UNIQUE(user_id),
    CONSTRAINT valid_birth_year CHECK (birth_year >= 1900 AND birth_year <= EXTRACT(YEAR FROM NOW())),
    CONSTRAINT consent_logic CHECK (
        (is_minor = FALSE) OR 
        (is_minor = TRUE AND has_parental_consent = TRUE AND consent_request_id IS NOT NULL) OR
        (is_minor = TRUE AND has_parental_consent = FALSE)
    )
);

-- Table for tracking data collection limits for minors
CREATE TABLE IF NOT EXISTS minor_data_restrictions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    restriction_type TEXT NOT NULL, -- 'no_location', 'no_photos', 'limited_social', etc.
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(user_id, restriction_type)
);

-- Table for parental data access requests
CREATE TABLE IF NOT EXISTS parental_data_requests (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    parent_email TEXT NOT NULL,
    request_type TEXT NOT NULL CHECK (request_type IN ('view_data', 'delete_data', 'export_data', 'modify_permissions')),
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'completed', 'denied')),
    verification_token TEXT NOT NULL UNIQUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    notes TEXT
);

-- Indexes for performance
CREATE INDEX idx_parental_consent_token ON parental_consent_requests(consent_token);
CREATE INDEX idx_parental_consent_status ON parental_consent_requests(status);
CREATE INDEX idx_parental_consent_expires ON parental_consent_requests(expires_at);
CREATE INDEX idx_user_coppa_status_user_id ON user_coppa_status(user_id);
CREATE INDEX idx_user_coppa_status_minor ON user_coppa_status(is_minor);
CREATE INDEX idx_minor_restrictions_user_id ON minor_data_restrictions(user_id);
CREATE INDEX idx_parental_requests_user_id ON parental_data_requests(user_id);
CREATE INDEX idx_parental_requests_token ON parental_data_requests(verification_token);

-- Row Level Security (RLS) Policies

-- Enable RLS on all COPPA tables
ALTER TABLE parental_consent_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_coppa_status ENABLE ROW LEVEL SECURITY;
ALTER TABLE minor_data_restrictions ENABLE ROW LEVEL SECURITY;
ALTER TABLE parental_data_requests ENABLE ROW LEVEL SECURITY;

-- Parental consent requests: Only accessible by service role for edge functions
CREATE POLICY "Service role can manage consent requests" ON parental_consent_requests
    FOR ALL USING (auth.role() = 'service_role');

-- User COPPA status: Users can view their own, service role can manage
CREATE POLICY "Users can view own COPPA status" ON user_coppa_status
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Service role can manage COPPA status" ON user_coppa_status
    FOR ALL USING (auth.role() = 'service_role');

-- Minor data restrictions: Users can view their own, service role can manage
CREATE POLICY "Users can view own data restrictions" ON minor_data_restrictions
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Service role can manage data restrictions" ON minor_data_restrictions
    FOR ALL USING (auth.role() = 'service_role');

-- Parental data requests: Only service role can manage
CREATE POLICY "Service role can manage parental requests" ON parental_data_requests
    FOR ALL USING (auth.role() = 'service_role');

-- Function to check if user is COPPA compliant
CREATE OR REPLACE FUNCTION is_coppa_compliant(user_uuid UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    coppa_record user_coppa_status%ROWTYPE;
BEGIN
    SELECT * INTO coppa_record 
    FROM user_coppa_status 
    WHERE user_id = user_uuid;
    
    -- If no record exists, user hasn't verified age
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;
    
    -- If user is not a minor, they're compliant
    IF coppa_record.is_minor = FALSE THEN
        RETURN TRUE;
    END IF;
    
    -- If user is a minor, they need parental consent
    RETURN coppa_record.has_parental_consent;
END;
$$;

-- Function to get user's COPPA restrictions
CREATE OR REPLACE FUNCTION get_user_restrictions(user_uuid UUID)
RETURNS TABLE(restriction_type TEXT)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT mdr.restriction_type
    FROM minor_data_restrictions mdr
    JOIN user_coppa_status ucs ON ucs.user_id = mdr.user_id
    WHERE mdr.user_id = user_uuid 
    AND ucs.is_minor = TRUE
    AND mdr.is_active = TRUE;
END;
$$;

-- Function to create default restrictions for minor users
CREATE OR REPLACE FUNCTION create_minor_restrictions(user_uuid UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Insert default restrictions for minors
    INSERT INTO minor_data_restrictions (user_id, restriction_type)
    VALUES 
        (user_uuid, 'no_location_tracking'),
        (user_uuid, 'no_photo_uploads'),
        (user_uuid, 'no_social_media_links'),
        (user_uuid, 'no_direct_messaging'),
        (user_uuid, 'limited_data_export'),
        (user_uuid, 'no_targeted_ads')
    ON CONFLICT (user_id, restriction_type) DO NOTHING;
END;
$$;

-- Function to expire old consent requests
CREATE OR REPLACE FUNCTION expire_consent_requests()
RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    expired_count INT;
BEGIN
    UPDATE parental_consent_requests
    SET status = 'expired'
    WHERE status = 'pending'
    AND expires_at < NOW();
    
    GET DIAGNOSTICS expired_count = ROW_COUNT;
    RETURN expired_count;
END;
$$;

-- Trigger to automatically create restrictions for new minor users
CREATE OR REPLACE FUNCTION trigger_create_minor_restrictions()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    IF NEW.is_minor = TRUE THEN
        PERFORM create_minor_restrictions(NEW.user_id);
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER create_minor_restrictions_trigger
    AFTER INSERT ON user_coppa_status
    FOR EACH ROW
    EXECUTE FUNCTION trigger_create_minor_restrictions();

-- Grant permissions
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO service_role;
GRANT SELECT ON user_coppa_status TO authenticated;
GRANT SELECT ON minor_data_restrictions TO authenticated;

-- Create a scheduled job to clean up expired consent requests (if pg_cron is available)
-- SELECT cron.schedule('expire-consent-requests', '0 2 * * *', 'SELECT expire_consent_requests();');