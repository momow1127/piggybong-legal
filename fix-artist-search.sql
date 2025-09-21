-- Fix artist search to use the complete 'artists' table instead of limited 'app_artists'
-- This will make all 41 artists (including BABYMONSTER) searchable

-- Drop the old search function that uses app_artists
DROP FUNCTION IF EXISTS search_artists(TEXT, INTEGER);

-- Create new search function that uses the complete 'artists' table
CREATE OR REPLACE FUNCTION search_artists(search_term TEXT DEFAULT '', limit_count INTEGER DEFAULT 20)
RETURNS TABLE(
    id UUID,
    name TEXT,
    display_name TEXT,
    type TEXT,
    agency TEXT,
    debut_year INTEGER,
    genres TEXT[],
    image_url TEXT,
    popularity_score INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        a.id,
        a.name,
        a.name as display_name, -- Use name as display_name for consistency
        a.type,
        a.agency,
        a.debut_year,
        a.genres,
        a.image_url,
        -- Calculate popularity score based on debut year and type
        CASE 
            WHEN a.name IN ('BTS', 'BLACKPINK') THEN 100
            WHEN a.name IN ('NewJeans', 'TWICE', 'SEVENTEEN', 'Stray Kids') THEN 95
            WHEN a.name IN ('aespa', 'LE SSERAFIM', 'BABYMONSTER', 'ITZY', 'IVE', 'ENHYPEN') THEN 90
            WHEN a.type = 'solo_male' AND a.agency = 'HYBE Labels' THEN 85 -- BTS solo members
            WHEN a.type = 'solo_female' AND a.agency = 'YG Entertainment' THEN 85 -- BLACKPINK solo members
            WHEN a.debut_year >= 2020 THEN 80 -- Recent debuts
            ELSE 75
        END as popularity_score
    FROM artists a
    WHERE 
        (search_term = '' OR 
         a.name ILIKE '%' || search_term || '%' OR 
         a.agency ILIKE '%' || search_term || '%' OR
         a.type ILIKE '%' || search_term || '%')
        AND a.name IS NOT NULL
    ORDER BY 
        -- Prioritize exact matches
        CASE WHEN a.name ILIKE search_term THEN 1 ELSE 2 END,
        -- Then by popularity score
        CASE 
            WHEN a.name IN ('BTS', 'BLACKPINK') THEN 100
            WHEN a.name IN ('NewJeans', 'TWICE', 'SEVENTEEN', 'Stray Kids') THEN 95
            WHEN a.name IN ('aespa', 'LE SSERAFIM', 'BABYMONSTER', 'ITZY', 'IVE', 'ENHYPEN') THEN 90
            WHEN a.type = 'solo_male' AND a.agency = 'HYBE Labels' THEN 85
            WHEN a.type = 'solo_female' AND a.agency = 'YG Entertainment' THEN 85
            WHEN a.debut_year >= 2020 THEN 80
            ELSE 75
        END DESC,
        -- Then alphabetically
        a.name ASC
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create a function to get all artists (for onboarding)
CREATE OR REPLACE FUNCTION get_all_artists(limit_count INTEGER DEFAULT 100)
RETURNS TABLE(
    id UUID,
    name TEXT,
    display_name TEXT,
    type TEXT,
    agency TEXT,
    debut_year INTEGER,
    genres TEXT[],
    image_url TEXT,
    popularity_score INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        a.id,
        a.name,
        a.name as display_name,
        a.type,
        a.agency,
        a.debut_year,
        a.genres,
        a.image_url,
        -- Calculate popularity score
        CASE 
            WHEN a.name IN ('BTS', 'BLACKPINK') THEN 100
            WHEN a.name IN ('NewJeans', 'TWICE', 'SEVENTEEN', 'Stray Kids') THEN 95
            WHEN a.name IN ('aespa', 'LE SSERAFIM', 'BABYMONSTER', 'ITZY', 'IVE', 'ENHYPEN') THEN 90
            WHEN a.type = 'solo_male' AND a.agency = 'HYBE Labels' THEN 85
            WHEN a.type = 'solo_female' AND a.agency = 'YG Entertainment' THEN 85
            WHEN a.debut_year >= 2020 THEN 80
            ELSE 75
        END as popularity_score
    FROM artists a
    WHERE a.name IS NOT NULL
    ORDER BY 
        -- Groups first, then solos
        CASE 
            WHEN a.type IN ('boy_group', 'girl_group', 'co_ed_group') THEN 1 
            ELSE 2 
        END,
        -- Then by popularity
        CASE 
            WHEN a.name IN ('BTS', 'BLACKPINK') THEN 100
            WHEN a.name IN ('NewJeans', 'TWICE', 'SEVENTEEN', 'Stray Kids') THEN 95
            WHEN a.name IN ('aespa', 'LE SSERAFIM', 'BABYMONSTER', 'ITZY', 'IVE', 'ENHYPEN') THEN 90
            WHEN a.type = 'solo_male' AND a.agency = 'HYBE Labels' THEN 85
            WHEN a.type = 'solo_female' AND a.agency = 'YG Entertainment' THEN 85
            WHEN a.debut_year >= 2020 THEN 80
            ELSE 75
        END DESC,
        a.name ASC
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Add BABYMONSTER comeback events since we now have them in the artists table
INSERT INTO app_events (
    title, 
    artist_name, 
    event_date, 
    venue, 
    city, 
    category, 
    source,
    description,
    is_breaking,
    external_id
) VALUES 
(
    'BABYMONSTER 2nd Mini Album "DRIP"',
    'BABYMONSTER',
    '2024-11-01 13:00:00+00', -- 1PM KST converted to UTC
    'Digital Release',
    'Global',
    'albums',
    'manual',
    'BABYMONSTER comeback with 2nd mini album "DRIP" featuring title track and new music',
    TRUE,
    'babymonster-drip-comeback-2024'
),
(
    'BABYMONSTER "DRIP" Music Video Release',
    'BABYMONSTER', 
    '2024-11-01 13:00:00+00',
    'YouTube',
    'Online',
    'albums',
    'manual',
    'Official music video for BABYMONSTER title track "DRIP"',
    TRUE
),
(
    'BABYMONSTER Comeback Show',
    'BABYMONSTER',
    '2024-11-02 10:00:00+00', 
    'Music Bank',
    'Seoul',
    'events',
    'manual',
    'BABYMONSTER first comeback stage performance on KBS Music Bank',
    FALSE
)
ON CONFLICT (external_id) DO NOTHING; -- Don't add duplicates

-- Success message
SELECT 'Artist search fixed! All 41 artists including BABYMONSTER now searchable!' as status;