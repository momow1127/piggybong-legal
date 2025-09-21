-- =====================================================
-- DROP REDUNDANT INDEX - Run these separately
-- =====================================================

-- IMPORTANT: In Supabase SQL Editor, run each command SEPARATELY
-- DO NOT run them all at once!

-- Step 1: Check what will take over (RUN THIS FIRST)
SELECT 
    indexname,
    indexdef,
    substring(indexdef from '\((.*?)\)') as columns
FROM pg_indexes
WHERE tablename = 'fan_idols'
    AND indexdef LIKE '%(user_id%'
ORDER BY indexname;

-- Step 2: DROP the redundant index (RUN THIS SEPARATELY)
-- Note: Cannot use CONCURRENTLY in Supabase SQL Editor
DROP INDEX IF EXISTS public.idx_fan_idols_user_id;

-- Step 3: Verify it's gone (RUN THIS AFTER DROP)
SELECT 
    indexname,
    indexdef
FROM pg_indexes
WHERE tablename = 'fan_idols'
ORDER BY indexname;

-- Step 4: Test queries still work (RUN THIS TO VERIFY)
EXPLAIN ANALYZE
SELECT * FROM fan_idols 
WHERE user_id = (SELECT id FROM auth.users LIMIT 1);

-- =====================================================
-- Alternative: Use Supabase CLI or direct connection
-- =====================================================
-- If you have Supabase CLI or can connect directly to the database:
-- psql $DATABASE_URL -c "DROP INDEX CONCURRENTLY IF EXISTS public.idx_fan_idols_user_id;"

-- =====================================================
-- ROLLBACK if needed
-- =====================================================
-- To recreate the index if something goes wrong:
-- CREATE INDEX idx_fan_idols_user_id ON public.fan_idols(user_id);