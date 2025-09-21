-- Fix for your existing kpop_events table structure
-- This matches your actual column names

-- Add missing columns to kpop_events (using your existing column names)
ALTER TABLE kpop_events 
ADD COLUMN IF NOT EXISTS cache_expires_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '24 hours'),
ADD COLUMN IF NOT EXISTS source TEXT DEFAULT 'manual',
ADD COLUMN IF NOT EXISTS is_breaking BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS external_id TEXT,
ADD COLUMN IF NOT EXISTS event_url TEXT,
ADD COLUMN IF NOT EXISTS image_url TEXT,
ADD COLUMN IF NOT EXISTS min_price DECIMAL(10,2),
ADD COLUMN IF NOT EXISTS max_price DECIMAL(10,2),
ADD COLUMN IF NOT EXISTS currency TEXT DEFAULT 'USD',
ADD COLUMN IF NOT EXISTS description TEXT,
ADD COLUMN IF NOT EXISTS city TEXT,
ADD COLUMN IF NOT EXISTS country TEXT;

-- Add missing columns to idol_events (assuming similar structure)
ALTER TABLE idol_events 
ADD COLUMN IF NOT EXISTS cache_expires_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '24 hours'),
ADD COLUMN IF NOT EXISTS source TEXT DEFAULT 'manual',
ADD COLUMN IF NOT EXISTS is_breaking BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS external_id TEXT,
ADD COLUMN IF NOT EXISTS event_url TEXT,
ADD COLUMN IF NOT EXISTS image_url TEXT,
ADD COLUMN IF NOT EXISTS min_price DECIMAL(10,2),
ADD COLUMN IF NOT EXISTS max_price DECIMAL(10,2),
ADD COLUMN IF NOT EXISTS currency TEXT DEFAULT 'USD',
ADD COLUMN IF NOT EXISTS description TEXT,
ADD COLUMN IF NOT EXISTS city TEXT,
ADD COLUMN IF NOT EXISTS country TEXT;

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_kpop_events_cache_expires ON kpop_events(cache_expires_at);
CREATE INDEX IF NOT EXISTS idx_idol_events_cache_expires ON idol_events(cache_expires_at);
CREATE INDEX IF NOT EXISTS idx_kpop_events_artist ON kpop_events(artist_name);
CREATE INDEX IF NOT EXISTS idx_idol_events_artist ON idol_events(artist_name);

-- Create unified view using your actual column names
CREATE OR REPLACE VIEW all_events AS
SELECT 
    id,
    external_id,
    name as title,
    description,
    event_date,  -- Your table uses event_date
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
    cache_expires_at,
    event_status,
    status,
    event_type,
    days_left,
    priority,
    priority_type,
    instructions
FROM kpop_events
UNION ALL
SELECT 
    id,
    external_id,
    name as title,
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
    cache_expires_at,
    event_status,
    status,
    event_type,
    days_left,
    priority,
    priority_type,
    instructions
FROM idol_events;

-- Function to get events with your table structure
CREATE OR REPLACE FUNCTION get_user_events_existing(user_uuid UUID DEFAULT NULL, limit_count INTEGER DEFAULT 50)
RETURNS TABLE(
    id UUID,
    external_id TEXT,
    title TEXT,
    description TEXT,
    event_date TIMESTAMP,
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
    created_at TIMESTAMP,
    event_status TEXT,
    status TEXT,
    event_type TEXT,
    days_left INTEGER,
    priority INTEGER,
    priority_type TEXT,
    instructions TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ae.id,
        ae.external_id,
        ae.title,
        ae.description,
        ae.event_date,
        ae.venue,
        ae.city,
        ae.country,
        ae.artist_name,
        ae.source,
        ae.category,
        ae.min_price,
        ae.max_price,
        ae.currency,
        ae.image_url,
        ae.event_url,
        ae.is_breaking,
        ae.created_at,
        ae.event_status,
        ae.status,
        ae.event_type,
        ae.days_left,
        ae.priority,
        ae.priority_type,
        ae.instructions
    FROM all_events ae
    WHERE (ae.cache_expires_at > NOW() OR ae.cache_expires_at IS NULL)
    ORDER BY 
        ae.is_breaking DESC,
        ae.event_date ASC NULLS LAST,
        ae.created_at DESC
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;