-- Events table schema for caching real event data
-- Run this in your Supabase SQL Editor

-- Events Table for caching API data
CREATE TABLE IF NOT EXISTS events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    external_id TEXT UNIQUE, -- Ticketmaster ID, Spotify ID, etc.
    title TEXT NOT NULL,
    description TEXT,
    event_date TIMESTAMP WITH TIME ZONE,
    venue TEXT,
    city TEXT,
    country TEXT,
    artist_name TEXT NOT NULL,
    source TEXT NOT NULL CHECK (source IN ('ticketmaster', 'spotify', 'soompi')), 
    category TEXT NOT NULL DEFAULT 'concerts',
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

-- User Event Subscriptions (which artists they want to track)
CREATE TABLE IF NOT EXISTS user_event_subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    artist_name TEXT NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, artist_name)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_events_artist_name ON events(artist_name);
CREATE INDEX IF NOT EXISTS idx_events_event_date ON events(event_date DESC);
CREATE INDEX IF NOT EXISTS idx_events_source ON events(source);
CREATE INDEX IF NOT EXISTS idx_events_cache_expires ON events(cache_expires_at);
CREATE INDEX IF NOT EXISTS idx_user_event_subscriptions_user_id ON user_event_subscriptions(user_id);

-- Updated at trigger for events
CREATE TRIGGER update_events_updated_at
    BEFORE UPDATE ON events
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_event_subscriptions_updated_at
    BEFORE UPDATE ON user_event_subscriptions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Row Level Security
ALTER TABLE events ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_event_subscriptions ENABLE ROW LEVEL SECURITY;

-- Events are public (read-only for all authenticated users)
CREATE POLICY "Events are readable by authenticated users" ON events
    FOR SELECT USING (auth.role() = 'authenticated');

-- Only service role can insert/update events (via edge functions)
CREATE POLICY "Service role can manage events" ON events
    FOR ALL USING (auth.jwt() ->> 'role' = 'service_role');

-- User event subscriptions policies
CREATE POLICY "Users can view own event subscriptions" ON user_event_subscriptions
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own event subscriptions" ON user_event_subscriptions
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own event subscriptions" ON user_event_subscriptions
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own event subscriptions" ON user_event_subscriptions
    FOR DELETE USING (auth.uid() = user_id);

-- Function to get events for a specific user based on their artist subscriptions
CREATE OR REPLACE FUNCTION get_user_events(user_uuid UUID, limit_count INTEGER DEFAULT 50)
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
        e.id,
        e.external_id,
        e.title,
        e.description,
        e.event_date,
        e.venue,
        e.city,
        e.country,
        e.artist_name,
        e.source,
        e.category,
        e.min_price,
        e.max_price,
        e.currency,
        e.image_url,
        e.event_url,
        e.is_breaking,
        e.created_at,
        e.updated_at
    FROM events e
    WHERE e.artist_name IN (
        SELECT ues.artist_name 
        FROM user_event_subscriptions ues 
        WHERE ues.user_id = user_uuid AND ues.is_active = TRUE
    )
    AND e.cache_expires_at > NOW()  -- Only return non-expired cached events
    ORDER BY 
        e.is_breaking DESC,        -- Breaking events first
        e.event_date ASC NULLS LAST, -- Upcoming events first
        e.created_at DESC          -- Newest news first
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to clean up expired cache entries
CREATE OR REPLACE FUNCTION cleanup_expired_events()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM events WHERE cache_expires_at < NOW();
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;