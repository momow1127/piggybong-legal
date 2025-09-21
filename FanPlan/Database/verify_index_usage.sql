-- =====================================================
-- VERIFICATION: Check Index Usage Stats
-- Run this BEFORE dropping any indexes
-- =====================================================

-- Query 1: Check usage stats for potentially redundant indexes
SELECT 
    indexrelname as index_name,
    schemaname,
    relname as tablename,
    idx_scan as times_used,
    idx_tup_read as rows_read_via_index,
    idx_tup_fetch as rows_fetched_via_index,
    pg_size_pretty(pg_relation_size(indexrelid)) as size,
    CASE 
        WHEN idx_scan = 0 THEN '✅ NEVER USED - Safe to drop'
        WHEN idx_scan < 10 THEN '⚠️ RARELY USED - Probably safe'
        WHEN idx_scan < 100 THEN '⚠️ OCCASIONALLY USED - Review carefully'
        ELSE '❌ FREQUENTLY USED - Do not drop!'
    END as recommendation
FROM pg_stat_user_indexes
WHERE indexrelname IN (
    'refresh_tokens_instance_id_idx',
    'sessions_user_id_idx',
    'users_instance_id_idx',
    'mfa_factors_user_id_idx',
    'idx_fan_idols_user_id',
    'idx_objects_bucket_id_name'
)
ORDER BY idx_scan DESC;

-- Query 2: Check what other indexes exist on these tables
-- This shows what indexes would take over after dropping
SELECT 
    tablename,
    indexname,
    indexdef,
    CASE 
        WHEN indexname IN (
            'refresh_tokens_instance_id_idx',
            'sessions_user_id_idx', 
            'users_instance_id_idx',
            'mfa_factors_user_id_idx',
            'idx_fan_idols_user_id',
            'idx_objects_bucket_id_name'
        ) THEN '🗑️ CANDIDATE FOR REMOVAL'
        ELSE '✅ KEEP'
    END as status
FROM pg_indexes
WHERE tablename IN ('refresh_tokens', 'sessions', 'users', 'mfa_factors', 'fan_idols', 'objects')
    AND schemaname IN ('auth', 'public', 'storage')
ORDER BY tablename, indexname;

-- Query 3: Specific check for fan_idols table
-- Shows all indexes and their columns to verify redundancy
SELECT 
    '=== FAN_IDOLS TABLE ===' as analysis,
    indexname,
    substring(indexdef from '\((.*?)\)') as indexed_columns,
    pg_size_pretty(pg_relation_size(('public.'||indexname)::regclass)) as size,
    CASE 
        WHEN indexname = 'idx_fan_idols_user_id' THEN '🗑️ REDUNDANT (if covered by composite)'
        WHEN indexname LIKE '%user_id%idol_id%' THEN '✅ COMPOSITE (covers user_id queries)'
        ELSE '✅ OTHER'
    END as assessment
FROM pg_indexes
WHERE tablename = 'fan_idols'
ORDER BY indexname;

-- Query 4: Check recent index usage (last stats reset)
SELECT 
    '=== STATS LAST RESET ===' as info,
    stats_reset::date as last_reset,
    CURRENT_DATE - stats_reset::date as days_of_stats
FROM pg_stat_database
WHERE datname = current_database();

-- Query 5: Test query performance WITHOUT the index
-- This simulates what would happen after dropping idx_fan_idols_user_id
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM fan_idols 
WHERE user_id = (SELECT id FROM auth.users LIMIT 1);
-- Look for "Index Scan" in the output - if it uses another index, you're safe!