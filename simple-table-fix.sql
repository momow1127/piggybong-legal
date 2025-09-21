-- Simple fix for your existing tables
-- Just add the missing columns we need, don't assume any existing columns

-- Add only the columns we need for API integration
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
ADD COLUMN IF NOT EXISTS country TEXT,
ADD COLUMN IF NOT EXISTS artist_name TEXT;  -- Add this column

-- Same for idol_events
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
ADD COLUMN IF NOT EXISTS country TEXT,
ADD COLUMN IF NOT EXISTS artist_name TEXT;  -- Add this column

-- Simple function that just returns all events
CREATE OR REPLACE FUNCTION get_all_events(limit_count INTEGER DEFAULT 50)
RETURNS TABLE(
    id UUID,
    name TEXT,
    event_date TIMESTAMP,
    venue TEXT,
    event_type TEXT,
    status TEXT,
    days_left INTEGER,
    created_at TIMESTAMP
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        k.id,
        k.name,
        k.event_date,
        k.venue,
        k.event_type,
        k.status,
        k.days_left,
        k.created_at
    FROM kpop_events k
    ORDER BY k.event_date ASC NULLS LAST
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;