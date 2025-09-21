-- Add BABYMONSTER and other popular missing K-pop artists

INSERT INTO app_artists (name, display_name, company, member_count, debut_date, popularity_score, genre, country, is_active) VALUES
-- YG Entertainment Artists
('BABYMONSTER', 'BABYMONSTER', 'YG Entertainment', 7, '2023-11-27', 90, 'K-Pop', 'South Korea', TRUE),

-- Other Popular Artists
('(G)I-DLE', '(G)I-DLE', 'Cube Entertainment', 5, '2018-05-02', 85, 'K-Pop', 'South Korea', TRUE),
('LESSERAFIM', 'LE SSERAFIM', 'Source Music', 5, '2022-05-02', 92, 'K-Pop', 'South Korea', TRUE),
('IVE', 'IVE', 'Starship Entertainment', 6, '2021-12-01', 88, 'K-Pop', 'South Korea', TRUE),
('NMIXX', 'NMIXX', 'JYP Entertainment', 7, '2022-02-22', 82, 'K-Pop', 'South Korea', TRUE),
('KARINA', 'aespa', 'SM Entertainment', 4, '2020-11-17', 89, 'K-Pop', 'South Korea', TRUE),
('TREASURE', 'TREASURE', 'YG Entertainment', 10, '2020-08-07', 80, 'K-Pop', 'South Korea', TRUE),
('ITZY', 'ITZY', 'JYP Entertainment', 5, '2019-02-12', 87, 'K-Pop', 'South Korea', TRUE),
('Red Velvet', 'Red Velvet', 'SM Entertainment', 5, '2014-08-01', 85, 'K-Pop', 'South Korea', TRUE),
('MAMAMOO', 'MAMAMOO', 'RBW', 4, '2014-06-18', 78, 'K-Pop', 'South Korea', TRUE),

-- Popular Boy Groups
('ATEEZ', 'ATEEZ', 'KQ Entertainment', 8, '2018-10-24', 83, 'K-Pop', 'South Korea', TRUE),
('TXT', 'Tomorrow X Together', 'Big Hit Entertainment', 5, '2019-03-04', 84, 'K-Pop', 'South Korea', TRUE),
('NCT', 'NCT', 'SM Entertainment', 23, '2016-04-09', 86, 'K-Pop', 'South Korea', TRUE),
('EXO', 'EXO', 'SM Entertainment', 9, '2012-04-08', 88, 'K-Pop', 'South Korea', TRUE),
('BIGBANG', 'BIGBANG', 'YG Entertainment', 5, '2006-08-19', 90, 'K-Pop', 'South Korea', TRUE),

-- Rising Artists
('IVE', 'IVE', 'Starship Entertainment', 6, '2021-12-01', 85, 'K-Pop', 'South Korea', TRUE),
('KISS OF LIFE', 'KISS OF LIFE', 'S2 Entertainment', 4, '2023-07-05', 75, 'K-Pop', 'South Korea', TRUE),
('RIIZE', 'RIIZE', 'SM Entertainment', 7, '2023-09-04', 78, 'K-Pop', 'South Korea', TRUE)

ON CONFLICT (name) DO UPDATE SET
    display_name = EXCLUDED.display_name,
    company = EXCLUDED.company,
    member_count = EXCLUDED.member_count,
    debut_date = EXCLUDED.debut_date,
    popularity_score = EXCLUDED.popularity_score,
    updated_at = NOW();

-- Add BABYMONSTER's "DRIP" comeback event for testing
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
) VALUES (
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
);

-- Add additional comeback events for testing
INSERT INTO app_events (
    title,
    artist_name,
    event_date,
    venue,
    city,
    category,
    source,
    description,
    is_breaking
) VALUES 
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
);

-- Success message
SELECT 'BABYMONSTER and missing artists added successfully!' as status;