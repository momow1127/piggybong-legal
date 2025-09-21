-- Update existing idol_events and kpop_events tables for compatibility
-- Run this in Supabase SQL Editor to add missing columns if needed

-- Add any missing columns to idol_events
ALTER TABLE idol_events 
ADD COLUMN IF NOT EXISTS cache_expires_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '24 hours'),
ADD COLUMN IF NOT EXISTS source TEXT DEFAULT 'manual',
ADD COLUMN IF NOT EXISTS is_breaking BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS external_id TEXT,
ADD COLUMN IF NOT EXISTS event_url TEXT,
ADD COLUMN IF NOT EXISTS image_url TEXT,
ADD COLUMN IF NOT EXISTS min_price DECIMAL(10,2),
ADD COLUMN IF NOT EXISTS max_price DECIMAL(10,2),
ADD COLUMN IF NOT EXISTS currency TEXT DEFAULT 'USD';

-- Add any missing columns to kpop_events
ALTER TABLE kpop_events 
ADD COLUMN IF NOT EXISTS cache_expires_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '24 hours'),
ADD COLUMN IF NOT EXISTS source TEXT DEFAULT 'manual',
ADD COLUMN IF NOT EXISTS is_breaking BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS external_id TEXT,
ADD COLUMN IF NOT EXISTS event_url TEXT,
ADD COLUMN IF NOT EXISTS image_url TEXT,
ADD COLUMN IF NOT EXISTS min_price DECIMAL(10,2),
ADD COLUMN IF NOT EXISTS max_price DECIMAL(10,2),
ADD COLUMN IF NOT EXISTS currency TEXT DEFAULT 'USD';

-- Add indexes for performance if they don't exist
CREATE INDEX IF NOT EXISTS idx_idol_events_cache_expires ON idol_events(cache_expires_at);
CREATE INDEX IF NOT EXISTS idx_kpop_events_cache_expires ON kpop_events(cache_expires_at);

-- Create unified view for easy querying
CREATE OR REPLACE VIEW all_events AS
SELECT 
    id,
    external_id,
    title,
    description,
    event_date,
    venue,
    city,
    country,
    artist_name,
    source,
    'idol' as category,
    min_price,
    max_price,
    currency,
    image_url,
    event_url,
    is_breaking,
    created_at,
    updated_at,
    cache_expires_at
FROM idol_events
UNION ALL
SELECT 
    id,
    external_id,
    title,
    description,
    event_date,
    venue,
    city,
    country,
    artist_name,
    source,
    'kpop' as category,
    min_price,
    max_price,
    currency,
    image_url,
    event_url,
    is_breaking,
    created_at,
    updated_at,
    cache_expires_at
FROM kpop_events;

-- Function to get all events for a user
CREATE OR REPLACE FUNCTION get_user_events_from_existing_tables(user_uuid UUID, limit_count INTEGER DEFAULT 50)
RETURNS TABLE(
    id UUID,
    external_id TEXT,
    title TEXT,
    description TEXT,
    event_date TIMESTAMP WITH TIME ZONE,
    venue TEXT,
    city TEXT,
    country TEXT,
    artist_name TEXT,
    source TEXT,
    category TEXT,
    min_price DECIMAL(10,2),
    max_price DECIMAL(10,2),
    currency TEXT,
    image_url TEXT,
    event_url TEXT,
    is_breaking BOOLEAN,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT * FROM all_events
    WHERE cache_expires_at > NOW() OR cache_expires_at IS NULL
    ORDER BY 
        is_breaking DESC,
        event_date ASC NULLS LAST,
        created_at DESC
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;