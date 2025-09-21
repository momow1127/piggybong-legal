-- =====================================================
-- DIAGNOSE: Why isn't the index being used?
-- =====================================================

-- 1. Check if indexes actually exist on fan_idols
SELECT 
    indexname,
    indexdef,
    tablespace,
    substring(indexdef from '\((.*?)\)') as indexed_columns
FROM pg_indexes
WHERE tablename = 'fan_idols'
    AND schemaname = 'public'
ORDER BY indexname;

-- 2. Check table size (small tables often skip indexes)
SELECT 
    schemaname,
    relname as table_name,
    n_live_tup as row_count,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||relname)) as total_size,
    pg_size_pretty(pg_relation_size(schemaname||'.'||relname)) as table_size,
    n_dead_tup as dead_rows,
    last_vacuum,
    last_analyze
FROM pg_stat_user_tables
WHERE relname = 'fan_idols';

-- 3. Check index usage statistics
SELECT 
    indexrelname,
    idx_scan as times_used,
    idx_tup_read as rows_read,
    idx_tup_fetch as rows_fetched
FROM pg_stat_user_indexes
WHERE relname = 'fan_idols'
ORDER BY idx_scan DESC;

-- 4. Force index usage to test if it works
SET enable_seqscan = OFF;
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM fan_idols 
WHERE user_id = (SELECT id FROM auth.users LIMIT 1);
SET enable_seqscan = ON;

-- 5. Check if there's a composite index that should be used
SELECT 
    c.relname as index_name,
    i.indkey,
    i.indisunique as is_unique,
    i.indisprimary as is_primary,
    pg_size_pretty(pg_relation_size(c.oid)) as index_size,
    array_agg(a.attname ORDER BY a.attnum) as column_names
FROM pg_index i
JOIN pg_class c ON c.oid = i.indexrelid
JOIN pg_class t ON t.oid = i.indrelid
JOIN pg_attribute a ON a.attrelid = t.oid AND a.attnum = ANY(i.indkey)
WHERE t.relname = 'fan_idols'
GROUP BY c.relname, i.indkey, i.indisunique, i.indisprimary, c.oid
ORDER BY c.relname;

-- 6. Check if statistics are up to date
ANALYZE fan_idols;

-- 7. Now test again after ANALYZE
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM fan_idols 
WHERE user_id = (SELECT id FROM auth.users LIMIT 1);

-- 8. Check for any partial indexes or expression indexes
SELECT 
    indexname,
    indexdef,
    CASE 
        WHEN indexdef LIKE '%WHERE%' THEN 'PARTIAL INDEX'
        WHEN indexdef ~ '\([^)]*\([^)]*\)' THEN 'EXPRESSION INDEX'
        ELSE 'REGULAR INDEX'
    END as index_type
FROM pg_indexes
WHERE tablename = 'fan_idols';

-- 9. Summary recommendation
SELECT 
    'RECOMMENDATION' as analysis,
    CASE 
        WHEN COUNT(*) FILTER (WHERE indexname = 'idx_fan_idols_user_id') > 0 
            AND COUNT(*) FILTER (WHERE indexdef LIKE '%user_id, %') > 0
        THEN 'idx_fan_idols_user_id is REDUNDANT - covered by composite index'
        WHEN COUNT(*) FILTER (WHERE indexname = 'idx_fan_idols_user_id') > 0 
            AND COUNT(*) FILTER (WHERE indexdef LIKE '%user_id, %') = 0
        THEN 'idx_fan_idols_user_id is NEEDED - no composite index covers it'
        ELSE 'idx_fan_idols_user_id does not exist'
    END as verdict
FROM pg_indexes
WHERE tablename = 'fan_idols';