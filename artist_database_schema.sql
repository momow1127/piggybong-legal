-- Artists Database Table for Dynamic Management
CREATE TABLE IF NOT EXISTS artists (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  display_name TEXT NOT NULL,
  type TEXT NOT NULL, -- 'boy_group', 'girl_group', 'male_solo', 'female_solo', 'co_ed'
  agency TEXT,
  debut_date DATE,
  is_active BOOLEAN DEFAULT TRUE,
  keywords TEXT[], -- Array of search keywords/aliases
  priority_level INTEGER DEFAULT 1, -- 1=high, 2=medium, 3=low
  has_us_tours BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert all your current artists
INSERT INTO artists (name, display_name, type, agency, keywords, priority_level, has_us_tours) VALUES
-- Boy Groups
('BTS', 'BTS', 'boy_group', 'HYBE', ARRAY['BTS', 'Bangtan', 'Bangtan Boys'], 1, TRUE),
('Stray Kids', 'Stray Kids', 'boy_group', 'JYP', ARRAY['Stray Kids', 'SKZ'], 1, TRUE),
('SEVENTEEN', 'SEVENTEEN', 'boy_group', 'PLEDIS', ARRAY['SEVENTEEN', 'SVT'], 1, TRUE),
('ENHYPEN', 'ENHYPEN', 'boy_group', 'HYBE', ARRAY['ENHYPEN'], 1, TRUE),
('ATEEZ', 'ATEEZ', 'boy_group', 'KQ', ARRAY['ATEEZ'], 1, TRUE),
('TXT', 'TOMORROW X TOGETHER', 'boy_group', 'HYBE', ARRAY['TXT', 'Tomorrow X Together'], 1, TRUE),
('RIIZE', 'RIIZE', 'boy_group', 'SM', ARRAY['RIIZE'], 2, FALSE),
('ZEROBASEONE', 'ZEROBASEONE', 'boy_group', 'WAKEONE', ARRAY['ZEROBASEONE', 'ZB1'], 2, FALSE),
('BOYNEXTDOOR', 'BOYNEXTDOOR', 'boy_group', 'HYBE', ARRAY['BOYNEXTDOOR'], 2, FALSE),
('XIKERS', 'XIKERS', 'boy_group', 'KQ', ARRAY['XIKERS'], 2, FALSE),
('MONSTA X', 'MONSTA X', 'boy_group', 'STARSHIP', ARRAY['MONSTA X'], 2, TRUE),
('BIGBANG', 'BIGBANG', 'boy_group', 'YG', ARRAY['BIGBANG'], 2, FALSE),
('Super Junior', 'Super Junior', 'boy_group', 'SM', ARRAY['Super Junior', 'SuJu'], 2, TRUE),
('SHINee', 'SHINee', 'boy_group', 'SM', ARRAY['SHINee'], 2, TRUE),

-- Girl Groups  
('NewJeans', 'NewJeans', 'girl_group', 'ADOR', ARRAY['NewJeans'], 1, TRUE),
('aespa', 'aespa', 'girl_group', 'SM', ARRAY['aespa'], 1, TRUE),
('IVE', 'IVE', 'girl_group', 'STARSHIP', ARRAY['IVE'], 1, TRUE),
('LE SSERAFIM', 'LE SSERAFIM', 'girl_group', 'HYBE', ARRAY['LE SSERAFIM', 'LESSERAFIM'], 1, TRUE),
('(G)I-DLE', '(G)I-DLE', 'girl_group', 'CUBE', ARRAY['(G)I-DLE', 'GIDLE'], 1, TRUE),
('ITZY', 'ITZY', 'girl_group', 'JYP', ARRAY['ITZY'], 1, TRUE),
('TWICE', 'TWICE', 'girl_group', 'JYP', ARRAY['TWICE'], 1, TRUE),
('BLACKPINK', 'BLACKPINK', 'girl_group', 'YG', ARRAY['BLACKPINK'], 1, TRUE),
('NMIXX', 'NMIXX', 'girl_group', 'JYP', ARRAY['NMIXX'], 2, FALSE),
('BABYMONSTER', 'BABYMONSTER', 'girl_group', 'YG', ARRAY['BABYMONSTER'], 2, FALSE),
('KISS OF LIFE', 'KISS OF LIFE', 'girl_group', 'S2', ARRAY['KISS OF LIFE', 'KIOF'], 2, FALSE),
('ILLIT', 'ILLIT', 'girl_group', 'HYBE', ARRAY['ILLIT'], 2, FALSE),
('YOUNG POSSE', 'YOUNG POSSE', 'girl_group', 'DSP', ARRAY['YOUNG POSSE'], 2, FALSE),
('KiiiKiii', 'KiiiKiii', 'girl_group', 'STARSHIP', ARRAY['KiiiKiii'], 2, FALSE),
('Hearts2Hearts', 'Hearts2Hearts', 'girl_group', 'SM', ARRAY['Hearts2Hearts'], 2, FALSE),
('Red Velvet', 'Red Velvet', 'girl_group', 'SM', ARRAY['Red Velvet'], 2, TRUE),
('Girls Generation', 'Girls Generation', 'girl_group', 'SM', ARRAY['Girls Generation', 'SNSD'], 2, FALSE),
('2NE1', '2NE1', 'girl_group', 'YG', ARRAY['2NE1'], 2, TRUE),

-- Co-ed Groups
('ALLDAY PROJECT', 'ALLDAY PROJECT', 'co_ed', 'THEBLACKLABEL', ARRAY['ALLDAY PROJECT', 'ALL DAY PROJECT'], 2, FALSE),

-- Female Solo Artists
('Lisa', 'Lisa', 'female_solo', 'LLOUD', ARRAY['Lisa', 'Lalisa'], 1, TRUE),
('Jennie', 'Jennie', 'female_solo', 'ODD ATELIER', ARRAY['Jennie'], 1, TRUE),
('Rosé', 'Rosé', 'female_solo', 'THEBLACKLABEL', ARRAY['Rosé', 'Rose'], 1, TRUE),
('Jisoo', 'Jisoo', 'female_solo', 'YG', ARRAY['Jisoo'], 1, FALSE),
('IU', 'IU', 'female_solo', 'EDAM', ARRAY['IU'], 1, TRUE),
('Taeyeon', 'Taeyeon', 'female_solo', 'SM', ARRAY['Taeyeon'], 2, TRUE),
('Chungha', 'Chungha', 'female_solo', 'MNH', ARRAY['Chungha'], 2, FALSE),
('Sunmi', 'Sunmi', 'female_solo', 'ABYSS', ARRAY['Sunmi'], 2, FALSE),
('HyunA', 'HyunA', 'female_solo', 'P NATION', ARRAY['HyunA'], 2, FALSE),

-- Male Solo Artists
('G-Dragon', 'G-Dragon', 'male_solo', 'YG', ARRAY['G-Dragon', 'GD'], 1, FALSE),
('Taeyang', 'Taeyang', 'male_solo', 'YG', ARRAY['Taeyang'], 2, TRUE),
('Daesung', 'Daesung', 'male_solo', 'YG', ARRAY['Daesung'], 2, FALSE),
('Jay Park', 'Jay Park', 'male_solo', 'MORE VISION', ARRAY['Jay Park'], 2, TRUE),
('Dean', 'Dean', 'male_solo', 'Universal', ARRAY['Dean'], 2, FALSE),
('Crush', 'Crush', 'male_solo', 'P NATION', ARRAY['Crush'], 2, FALSE),
('Zico', 'Zico', 'male_solo', 'KOZ', ARRAY['Zico'], 2, FALSE);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_artists_active ON artists(is_active) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_artists_type ON artists(type);
CREATE INDEX IF NOT EXISTS idx_artists_priority ON artists(priority_level);
CREATE INDEX IF NOT EXISTS idx_artists_keywords ON artists USING GIN(keywords);

-- Function to get all active artist keywords for n8n
CREATE OR REPLACE FUNCTION get_artist_keywords()
RETURNS TEXT[] AS $$
DECLARE
    result TEXT[];
BEGIN
    SELECT array_agg(keyword)
    INTO result
    FROM (
        SELECT unnest(keywords) as keyword
        FROM artists 
        WHERE is_active = TRUE
    ) t;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Function to find artist by content
CREATE OR REPLACE FUNCTION find_artist_in_content(content_text TEXT)
RETURNS TABLE(artist_name TEXT, artist_type TEXT, priority INTEGER) AS $$
BEGIN
    RETURN QUERY
    SELECT a.name, a.type, a.priority_level
    FROM artists a
    WHERE a.is_active = TRUE
    AND EXISTS (
        SELECT 1 
        FROM unnest(a.keywords) as keyword
        WHERE lower(content_text) LIKE '%' || lower(keyword) || '%'
    )
    ORDER BY a.priority_level ASC
    LIMIT 1;
END;
$$ LANGUAGE plpgsql;