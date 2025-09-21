-- =====================================================
-- Redundant Index Analysis - Simple Version
-- Run each query separately
-- =====================================================

-- Query 1: Show ALL indexes for the tables in your screenshot
SELECT 
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE tablename IN ('mfa_factors', 'refresh_tokens', 'sessions', 'users', 'fan_idols', 'kpop_events', 'objects')
    AND schemaname = 'auth'
ORDER BY tablename, indexname;

-- Query 2: Show indexes for YOUR custom tables (public schema)
SELECT 
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE tablename IN ('fan_idols', 'kpop_events', 'fan_activities')
    AND schemaname = 'public'
ORDER BY tablename, indexname;

-- Query 3: Check mfa_factors specifically
SELECT 
    indexname,
    indexdef,
    substring(indexdef from '\((.*?)\)') as indexed_columns
FROM pg_indexes
WHERE tablename = 'mfa_factors'
ORDER BY indexname;

-- Query 4: Check fan_idols specifically  
SELECT 
    indexname,
    indexdef,
    substring(indexdef from '\((.*?)\)') as indexed_columns
FROM pg_indexes
WHERE tablename = 'fan_idols'
ORDER BY indexname;

-- Query 5: Show index usage stats for potentially redundant ones
SELECT 
    schemaname,
    tablename,
    indexrelname as index_name,
    idx_scan as times_used,
    idx_tup_read as rows_read,
    idx_tup_fetch as rows_fetched
FROM pg_stat_user_indexes
WHERE indexrelname IN (
    'mfa_factors_user_id_idx',
    'refresh_tokens_instance_id_idx',
    'sessions_user_id_idx',
    'users_instance_id_idx',
    'idx_fan_idols_user_id',
    'ux_kpop_events_artist_day_idx',
    'idx_objects_bucket_id_name'
)
ORDER BY idx_scan DESC;

-- Query 6: Find indexes that might be covering each other
-- This looks for indexes on the same table where one has all the columns of another
WITH index_info AS (
    SELECT 
        schemaname,
        tablename,
        indexname,
        -- Extract just the column names without modifiers
        regexp_replace(
            substring(indexdef from '\((.*?)\)'),
            '\s+(ASC|DESC|NULLS FIRST|NULLS LAST)', '', 'g'
        ) as columns
    FROM pg_indexes
    WHERE schemaname IN ('public', 'auth')
        AND tablename IN ('mfa_factors', 'fan_idols', 'sessions', 'users')
)
SELECT 
    a.tablename,
    a.indexname as index_a,
    a.columns as columns_a,
    b.indexname as index_b,
    b.columns as columns_b,
    CASE 
        WHEN position(a.columns in b.columns) = 1 THEN 'A is covered by B'
        WHEN position(b.columns in a.columns) = 1 THEN 'B is covered by A'
        ELSE 'No coverage'
    END as relationship
FROM index_info a
JOIN index_info b 
    ON a.tablename = b.tablename 
    AND a.indexname < b.indexname
WHERE position(a.columns in b.columns) = 1 
    OR position(b.columns in a.columns) = 1
ORDER BY a.tablename, a.indexname;