-- =====================================================
-- Redundant Index Analysis - Detailed Examination
-- =====================================================

-- Query 1: Deep dive into mfa_factors indexes
-- Shows all indexes on this table to understand redundancy
SELECT 
    '=== MFA_FACTORS TABLE ===' as analysis,
    indexname,
    indexdef,
    tablename,
    schemaname
FROM pg_indexes
WHERE tablename = 'mfa_factors'
ORDER BY indexname;

-- Query 2: Check all indexes for the tables shown in screenshot
WITH target_tables AS (
    SELECT unnest(ARRAY[
        'mfa_factors', 'refresh_tokens', 'sessions', 
        'users', 'fan_idols', 'kpop_events', 'objects'
    ]) as table_name
)
SELECT 
    '=== INDEX DEFINITIONS BY TABLE ===' as analysis,
    t.table_name,
    i.indexname,
    i.indexdef,
    CASE 
        WHEN i.indexdef LIKE '%UNIQUE%' THEN 'UNIQUE'
        WHEN i.indexname LIKE '%_pkey' THEN 'PRIMARY KEY'
        ELSE 'REGULAR'
    END as index_type,
    -- Extract columns from index definition
    substring(i.indexdef from '\((.*?)\)') as indexed_columns
FROM target_tables t
LEFT JOIN pg_indexes i ON i.tablename = t.table_name
WHERE i.schemaname NOT IN ('pg_catalog', 'information_schema')
ORDER BY t.table_name, i.indexname;

-- Query 3: Show exact redundancy relationships
-- This shows which indexes cover which other indexes
WITH index_columns AS (
    SELECT 
        i.schemaname,
        i.tablename,
        i.indexname,
        i.indexdef,
        -- Extract the column list from the index definition
        regexp_replace(
            regexp_replace(i.indexdef, '.*\((.*?)\).*', '\1'),
            '"', '', 'g'
        ) as column_list,
        -- Get index size
        pg_size_pretty(pg_relation_size((i.schemaname||'.'||i.indexname)::regclass)) as index_size,
        -- Get index usage stats
        COALESCE(s.idx_scan, 0) as scan_count
    FROM pg_indexes i
    LEFT JOIN pg_stat_user_indexes s 
        ON s.indexrelname = i.indexname 
        AND s.schemaname = i.schemaname
    WHERE i.schemaname NOT IN ('pg_catalog', 'information_schema')
),
redundancy_check AS (
    SELECT 
        i1.tablename,
        i1.indexname as redundant_index,
        i1.column_list as redundant_columns,
        i1.index_size as redundant_size,
        i1.scan_count as redundant_scans,
        i2.indexname as covering_index,
        i2.column_list as covering_columns,
        i2.index_size as covering_size,
        i2.scan_count as covering_scans
    FROM index_columns i1
    JOIN index_columns i2 
        ON i1.schemaname = i2.schemaname 
        AND i1.tablename = i2.tablename 
        AND i1.indexname != i2.indexname
    WHERE 
        -- i2 covers i1 if i2's columns start with i1's columns
        i2.column_list LIKE i1.column_list || ',%'
        OR i2.column_list = i1.column_list
)
SELECT 
    '=== REDUNDANCY RELATIONSHIPS ===' as analysis,
    tablename,
    redundant_index,
    redundant_columns,
    redundant_size,
    redundant_scans,
    covering_index,
    covering_columns,
    covering_size,
    covering_scans,
    CASE 
        WHEN redundant_scans = 0 THEN '✅ SAFE TO DROP (never used)'
        WHEN redundant_scans < covering_scans * 0.1 THEN '⚠️ PROBABLY SAFE (low usage)'
        ELSE '❌ IN USE (review carefully)'
    END as recommendation
FROM redundancy_check
WHERE tablename IN ('mfa_factors', 'refresh_tokens', 'sessions', 'users', 'fan_idols', 'kpop_events', 'objects')
ORDER BY tablename, redundant_index;

-- Query 4: Specific example - fan_idols table
SELECT 
    '=== FAN_IDOLS DETAILED ===' as analysis,
    indexname,
    indexdef,
    substring(indexdef from '\((.*?)\)') as columns,
    pg_size_pretty(pg_relation_size(('public.'||indexname)::regclass)) as size
FROM pg_indexes
WHERE tablename = 'fan_idols'
ORDER BY indexname;

-- Query 5: Show potential space savings
WITH redundant_indexes AS (
    SELECT 
        i.schemaname,
        i.tablename,
        i.indexname,
        pg_relation_size((i.schemaname||'.'||i.indexname)::regclass) as size_bytes,
        pg_size_pretty(pg_relation_size((i.schemaname||'.'||i.indexname)::regclass)) as size_pretty
    FROM pg_indexes i
    WHERE i.indexname IN (
        'mfa_factors_user_id_idx',
        'refresh_tokens_instance_id_idx', 
        'sessions_user_id_idx',
        'users_instance_id_idx',
        'idx_fan_idols_user_id',
        'ux_kpop_events_artist_day_idx',
        'idx_objects_bucket_id_name'
    )
)
SELECT 
    '=== POTENTIAL SPACE SAVINGS ===' as analysis,
    tablename,
    indexname,
    size_pretty,
    SUM(size_bytes) OVER() as total_bytes,
    pg_size_pretty(SUM(size_bytes) OVER()) as total_potential_savings
FROM redundant_indexes
ORDER BY size_bytes DESC;