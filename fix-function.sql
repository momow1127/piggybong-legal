-- Fix the function with duplicate parameter names

-- Drop the problematic function first
DROP FUNCTION IF EXISTS search_idol_events(TEXT, INTEGER);

-- Create the fixed function
CREATE OR REPLACE FUNCTION search_idol_events(search_artist TEXT, limit_count INTEGER DEFAULT 20)
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
        e.artist,  -- Don't alias this, just return the actual column
        e.date as event_date,
        e.location as venue,
        e.type as event_type,
        e.ticket_url,
        e.image_url
    FROM idol_events e
    WHERE 
        (search_artist = '' OR e.artist ILIKE '%' || search_artist || '%')
        AND (e.cache_expires_at > NOW() OR e.cache_expires_at IS NULL)
    ORDER BY e.date ASC NULLS LAST
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Test the function
SELECT 'Fixed function created successfully!' as status;