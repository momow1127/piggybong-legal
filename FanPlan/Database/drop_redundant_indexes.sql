-- =====================================================
-- DROP Redundant Indexes - SAFE Version
-- Total space to reclaim: ~72 KB
-- =====================================================

-- IMPORTANT: Before running these, verify:
-- 1. These indexes have 0 or very low usage (check pg_stat_user_indexes)
-- 2. Another index covers the same columns
-- 3. Run during low-traffic period
-- 4. Have a backup ready

-- First, let's verify these are truly redundant and unused
SELECT 
    indexrelname as index_name,
    schemaname,
    tablename,
    idx_scan as times_used,
    pg_size_pretty(pg_relation_size(indexrelid)) as size
FROM pg_stat_user_indexes
WHERE indexrelname IN (
    'refresh_tokens_instance_id_idx',
    'sessions_user_id_idx',
    'users_instance_id_idx',
    'mfa_factors_user_id_idx',
    'idx_fan_idols_user_id',
    'idx_objects_bucket_id_name'
)
ORDER BY idx_scan;

-- =====================================================
-- DROP STATEMENTS - Run one at a time
-- Using CONCURRENTLY to avoid locking tables
-- =====================================================

-- Auth schema indexes (Supabase managed tables)
-- Be VERY careful with these - they might be used by Supabase internally

-- 1. refresh_tokens table (16 KB)
-- Check if covered by another index first!
-- DROP INDEX CONCURRENTLY IF EXISTS auth.refresh_tokens_instance_id_idx;

-- 2. sessions table (16 KB)  
-- Check if covered by another index first!
-- DROP INDEX CONCURRENTLY IF EXISTS auth.sessions_user_id_idx;

-- 3. users table (16 KB)
-- Check if covered by another index first!
-- DROP INDEX CONCURRENTLY IF EXISTS auth.users_instance_id_idx;

-- 4. mfa_factors table (8 KB)
-- Check if covered by another index first!
-- DROP INDEX CONCURRENTLY IF EXISTS auth.mfa_factors_user_id_idx;

-- =====================================================
-- Your custom table indexes (SAFER to drop)
-- =====================================================

-- 5. fan_idols table (8 KB)
-- This is YOUR table, safer to modify
-- Verify it's covered by a composite index first
SELECT indexname, indexdef 
FROM pg_indexes 
WHERE tablename = 'fan_idols';

-- If you see another index starting with user_id, then drop:
-- DROP INDEX CONCURRENTLY IF EXISTS public.idx_fan_idols_user_id;

-- 6. objects table (8 KB) - This is Supabase storage
-- Be careful - might be used by Supabase storage internally
-- DROP INDEX CONCURRENTLY IF EXISTS storage.idx_objects_bucket_id_name;

-- =====================================================
-- SAFER APPROACH - Start with your custom tables only
-- =====================================================

-- Step 1: Drop redundant index on YOUR fan_idols table
DROP INDEX CONCURRENTLY IF EXISTS public.idx_fan_idols_user_id;

-- Step 2: Verify everything still works in your app

-- Step 3: If all good, consider auth schema indexes
-- But TEST THOROUGHLY first!

-- =====================================================
-- POST-DROP VERIFICATION
-- =====================================================

-- After dropping, run this to ensure queries still work:
EXPLAIN (ANALYZE, BUFFERS) 
SELECT * FROM fan_idols WHERE user_id = 'some-uuid-here';

-- Check that it uses the composite index instead

-- =====================================================
-- ROLLBACK PLAN - Recreate if needed
-- =====================================================

-- If you need to recreate any dropped index:

-- CREATE INDEX CONCURRENTLY idx_fan_idols_user_id 
-- ON public.fan_idols(user_id);

-- CREATE INDEX CONCURRENTLY sessions_user_id_idx 
-- ON auth.sessions(user_id);

-- etc...