-- =====================================================
-- SAFE DROP: Remove redundant idx_fan_idols_user_id
-- Verdict: REDUNDANT - covered by another index
-- =====================================================

-- 1. First, verify what index will take over
SELECT 
    indexname,
    indexdef,
    substring(indexdef from '\((.*?)\)') as columns
FROM pg_indexes
WHERE tablename = 'fan_idols'
    AND indexdef LIKE '%(user_id%'
ORDER BY indexname;

-- 2. Check current usage one more time
SELECT 
    indexrelname,
    idx_scan as times_used
FROM pg_stat_user_indexes
WHERE indexrelname = 'idx_fan_idols_user_id';

-- 3. DROP the redundant index
-- Using CONCURRENTLY to avoid locking the table
DROP INDEX CONCURRENTLY IF EXISTS public.idx_fan_idols_user_id;

-- 4. Verify it's gone
SELECT 
    'After drop:' as status,
    COUNT(*) as remaining_indexes
FROM pg_indexes
WHERE tablename = 'fan_idols';

-- 5. Test that queries still work efficiently
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM fan_idols WHERE user_id = gen_random_uuid();

-- 6. Confirm the composite index is being used
-- You should see "Index Scan" using the remaining index

-- =====================================================
-- ROLLBACK PLAN (if needed)
-- =====================================================
-- If you need to recreate it:
-- CREATE INDEX CONCURRENTLY idx_fan_idols_user_id 
-- ON public.fan_idols(user_id);

-- =====================================================
-- SPACE RECLAIMED: 8192 bytes (8 KB)
-- =====================================================