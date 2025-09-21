-- =====================================================
-- SIMPLE CHECK: Fan_idols index analysis
-- =====================================================

-- 1. List ALL indexes on fan_idols table
SELECT 
    indexname,
    indexdef
FROM pg_indexes
WHERE tablename = 'fan_idols'
ORDER BY indexname;

-- 2. Count rows in fan_idols table
SELECT COUNT(*) as total_rows FROM fan_idols;

-- 3. Check index usage stats
SELECT 
    indexrelname as index_name,
    idx_scan as times_used,
    idx_tup_read as rows_read
FROM pg_stat_user_indexes
WHERE relname = 'fan_idols'
ORDER BY idx_scan DESC;

-- 4. Test with forced index use
SET enable_seqscan = OFF;
EXPLAIN ANALYZE
SELECT * FROM fan_idols 
WHERE user_id = (SELECT id FROM auth.users LIMIT 1);
SET enable_seqscan = ON;

-- 5. Check if idx_fan_idols_user_id is redundant
WITH indexes AS (
    SELECT 
        indexname,
        indexdef,
        substring(indexdef from '\((.*?)\)') as columns
    FROM pg_indexes
    WHERE tablename = 'fan_idols'
)
SELECT 
    indexname,
    columns,
    CASE 
        WHEN indexname = 'idx_fan_idols_user_id' THEN 'CHECKING THIS ONE'
        WHEN columns LIKE 'user_id,%' THEN 'COVERS user_id queries'
        ELSE 'OTHER INDEX'
    END as analysis
FROM indexes
ORDER BY indexname;

-- 6. Final verdict
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM pg_indexes 
            WHERE tablename = 'fan_idols' 
            AND indexname = 'idx_fan_idols_user_id'
        ) AND EXISTS (
            SELECT 1 FROM pg_indexes 
            WHERE tablename = 'fan_idols' 
            AND indexname != 'idx_fan_idols_user_id'
            AND indexdef LIKE '%(user_id,%'
        ) THEN '✅ idx_fan_idols_user_id is REDUNDANT - another index covers user_id'
        
        WHEN EXISTS (
            SELECT 1 FROM pg_indexes 
            WHERE tablename = 'fan_idols' 
            AND indexname = 'idx_fan_idols_user_id'
        ) AND NOT EXISTS (
            SELECT 1 FROM pg_indexes 
            WHERE tablename = 'fan_idols' 
            AND indexname != 'idx_fan_idols_user_id'
            AND indexdef LIKE '%(user_id%'
        ) THEN '❌ idx_fan_idols_user_id is NEEDED - no other index on user_id'
        
        ELSE '❓ idx_fan_idols_user_id does not exist'
    END as verdict;