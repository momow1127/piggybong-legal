-- Extend your existing idol_events table for app compatibility
-- This adds only the columns needed for API integration

-- Add missing columns to your existing idol_events table
ALTER TABLE idol_events 
ADD COLUMN IF NOT EXISTS cache_expires_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '24 hours'),
ADD COLUMN IF NOT EXISTS source TEXT DEFAULT 'manual',
ADD COLUMN IF NOT EXISTS is_breaking BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS external_id TEXT,
ADD COLUMN IF NOT EXISTS min_price DECIMAL(10,2),
ADD COLUMN IF NOT EXISTS max_price DECIMAL(10,2),
ADD COLUMN IF NOT EXISTS currency TEXT DEFAULT 'USD';

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_idol_events_artist ON idol_events(artist);
CREATE INDEX IF NOT EXISTS idx_idol_events_date ON idol_events(date DESC);
CREATE INDEX IF NOT EXISTS idx_idol_events_type ON idol_events(type);
CREATE INDEX IF NOT EXISTS idx_idol_events_cache_expires ON idol_events(cache_expires_at);

-- Enable Row Level Security
ALTER TABLE idol_events ENABLE ROW LEVEL SECURITY;

-- Public read access for authenticated users
CREATE POLICY "Idol events are readable" ON idol_events
    FOR SELECT USING (auth.role() = 'authenticated');

-- Service role can manage events (for API updates)
CREATE POLICY "Service role can manage idol events" ON idol_events
    FOR ALL USING (auth.jwt() ->> 'role' = 'service_role');

-- Function to get events using your existing column names
CREATE OR REPLACE FUNCTION get_idol_events(limit_count INTEGER DEFAULT 50)
RETURNS TABLE(
    id UUID,
    external_id TEXT,
    title TEXT,
    description TEXT,
    event_date TIMESTAMP WITH TIME ZONE,
    venue TEXT,
    artist_name TEXT,
    event_type TEXT,
    source TEXT,
    min_price DECIMAL(10,2),
    max_price DECIMAL(10,2),
    currency TEXT,
    image_url TEXT,
    ticket_url TEXT,
    is_breaking BOOLEAN,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        e.id,
        e.external_id,
        e.title,
        e.description,
        e.date as event_date,
        e.location as venue,
        e.artist as artist_name,
        e.type as event_type,
        e.source,
        e.min_price,
        e.max_price,
        e.currency,
        e.image_url,
        e.ticket_url,
        e.is_breaking,
        e.created_at,
        e.updated_at
    FROM idol_events e
    WHERE (e.cache_expires_at > NOW() OR e.cache_expires_at IS NULL)
    ORDER BY 
        e.is_breaking DESC,
        e.date ASC NULLS LAST,
        e.created_at DESC
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to search events by artist
CREATE OR REPLACE FUNCTION search_idol_events(artist_name TEXT, limit_count INTEGER DEFAULT 20)
RETURNS TABLE(
    id UUID,
    title TEXT,
    artist_name TEXT,
    event_date TIMESTAMP WITH TIME ZONE,
    venue TEXT,
    event_type TEXT,
    ticket_url TEXT,
    image_url TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        e.id,
        e.title,
        e.artist as artist_name,
        e.date as event_date,
        e.location as venue,
        e.type as event_type,
        e.ticket_url,
        e.image_url
    FROM idol_events e
    WHERE 
        (artist_name = '' OR e.artist ILIKE '%' || artist_name || '%')
        AND (e.cache_expires_at > NOW() OR e.cache_expires_at IS NULL)
    ORDER BY e.date ASC NULLS LAST
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Success message
SELECT 'idol_events table successfully extended for app compatibility!' as status;