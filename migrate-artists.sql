-- Option 1: Create new clean artists table and migrate data
-- This preserves your existing data while making it compatible

-- Create new standardized artists table
CREATE TABLE IF NOT EXISTS app_artists (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT UNIQUE NOT NULL,
    display_name TEXT,
    genre TEXT DEFAULT 'K-Pop',
    debut_date DATE,
    company TEXT,
    member_count INTEGER,
    country TEXT DEFAULT 'South Korea',
    image_url TEXT,
    spotify_id TEXT,
    instagram_handle TEXT,
    twitter_handle TEXT,
    official_website TEXT,
    fan_cafe_url TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    popularity_score INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_app_artists_name ON app_artists(name);
CREATE INDEX idx_app_artists_genre ON app_artists(genre);
CREATE INDEX idx_app_artists_popularity ON app_artists(popularity_score DESC);

-- Row Level Security
ALTER TABLE app_artists ENABLE ROW LEVEL SECURITY;

-- Public read access
CREATE POLICY "Artists are publicly readable" ON app_artists
    FOR SELECT USING (true);

-- Service role can manage
CREATE POLICY "Service role can manage artists" ON app_artists
    FOR ALL USING (auth.jwt() ->> 'role' = 'service_role');

-- Insert popular K-pop artists
INSERT INTO app_artists (name, display_name, company, member_count, debut_date, popularity_score) VALUES
('BLACKPINK', 'BLACKPINK', 'YG Entertainment', 4, '2016-08-08', 100),
('BTS', 'BTS (방탄소년단)', 'Big Hit Entertainment', 7, '2013-06-13', 100),
('TWICE', 'TWICE', 'JYP Entertainment', 9, '2015-10-20', 95),
('ITZY', 'ITZY', 'JYP Entertainment', 5, '2019-02-12', 90),
('aespa', 'aespa', 'SM Entertainment', 4, '2020-11-17', 90),
('(G)I-DLE', '(G)I-DLE', 'Cube Entertainment', 6, '2018-05-02', 85),
('NewJeans', 'NewJeans', 'ADOR', 5, '2022-08-01', 95),
('IVE', 'IVE', 'Starship Entertainment', 6, '2021-12-01', 90),
('LE SSERAFIM', 'LE SSERAFIM', 'Source Music', 5, '2022-05-02', 90),
('STRAY KIDS', 'Stray Kids', 'JYP Entertainment', 8, '2018-03-25', 95),
('SEVENTEEN', 'SEVENTEEN', 'Pledis Entertainment', 13, '2015-05-26', 95),
('ENHYPEN', 'ENHYPEN', 'Belift Lab', 7, '2020-11-30', 85),
('Red Velvet', 'Red Velvet', 'SM Entertainment', 5, '2014-08-01', 85),
('MAMAMOO', 'MAMAMOO', 'RBW', 4, '2014-06-18', 80),
('Girls Generation', 'Girls Generation (SNSD)', 'SM Entertainment', 8, '2007-08-05', 90);

-- Function to search artists
CREATE OR REPLACE FUNCTION search_artists(search_term TEXT DEFAULT '', limit_count INTEGER DEFAULT 20)
RETURNS TABLE(
    id UUID,
    name TEXT,
    display_name TEXT,
    genre TEXT,
    company TEXT,
    member_count INTEGER,
    debut_date DATE,
    image_url TEXT,
    popularity_score INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        a.id, a.name, a.display_name, a.genre, a.company, 
        a.member_count, a.debut_date, a.image_url, a.popularity_score
    FROM app_artists a
    WHERE 
        (search_term = '' OR 
         a.name ILIKE '%' || search_term || '%' OR 
         a.display_name ILIKE '%' || search_term || '%' OR
         a.company ILIKE '%' || search_term || '%')
        AND a.is_active = TRUE
    ORDER BY a.popularity_score DESC, a.name ASC
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Success message
SELECT 'New app_artists table created with popular K-pop artists!' as status;