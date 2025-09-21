-- Create a new clean events table for the app
-- This won't touch your existing kpop_events and idol_events tables

CREATE TABLE IF NOT EXISTS app_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    external_id TEXT,
    title TEXT NOT NULL,
    description TEXT,
    event_date TIMESTAMP WITH TIME ZONE,
    venue TEXT,
    city TEXT,
    country TEXT,
    artist_name TEXT NOT NULL,
    source TEXT NOT NULL DEFAULT 'manual',
    category TEXT NOT NULL DEFAULT 'events',
    min_price DECIMAL(10,2),
    max_price DECIMAL(10,2),
    currency TEXT DEFAULT 'USD',
    image_url TEXT,
    event_url TEXT,
    is_breaking BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    cache_expires_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '24 hours')
);

-- Indexes for performance
CREATE INDEX idx_app_events_artist_name ON app_events(artist_name);
CREATE INDEX idx_app_events_event_date ON app_events(event_date DESC);
CREATE INDEX idx_app_events_cache_expires ON app_events(cache_expires_at);

-- Row Level Security
ALTER TABLE app_events ENABLE ROW LEVEL SECURITY;

-- Public read access for authenticated users
CREATE POLICY "App events are readable" ON app_events
    FOR SELECT USING (auth.role() = 'authenticated');

-- Service role can manage events (for API updates)
CREATE POLICY "Service role can manage app events" ON app_events
    FOR ALL USING (auth.jwt() ->> 'role' = 'service_role');

-- Function to get events
CREATE OR REPLACE FUNCTION get_app_events(limit_count INTEGER DEFAULT 50)
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
    SELECT 
        e.id, e.external_id, e.title, e.description, e.event_date,
        e.venue, e.city, e.country, e.artist_name, e.source, e.category,
        e.min_price, e.max_price, e.currency, e.image_url, e.event_url,
        e.is_breaking, e.created_at, e.updated_at
    FROM app_events e
    WHERE e.cache_expires_at > NOW()
    ORDER BY 
        e.is_breaking DESC,
        e.event_date ASC NULLS LAST,
        e.created_at DESC
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Add some sample data
INSERT INTO app_events (title, artist_name, event_date, venue, city, category) VALUES
('Sample Concert', 'BLACKPINK', '2025-12-25 20:00:00+00', 'MSG', 'New York', 'concerts'),
('Album Release', 'BTS', '2025-11-15 00:00:00+00', 'Spotify', 'Online', 'releases'),
('Fan Meeting', 'TWICE', '2025-10-30 18:00:00+00', 'Tokyo Dome', 'Tokyo', 'events');

-- Success message
SELECT 'New app_events table created successfully!' as status;