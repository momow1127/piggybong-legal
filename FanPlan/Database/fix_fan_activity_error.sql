-- =====================================================
-- DIAGNOSE: Add Fan Activity Error
-- =====================================================

-- 1. Check if fan_activities table exists and structure
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'fan_activities'
ORDER BY ordinal_position;

-- 2. Check RLS policies on fan_activities
SELECT 
    policyname,
    cmd,
    permissive,
    roles,
    qual,
    with_check
FROM pg_policies
WHERE tablename = 'fan_activities'
ORDER BY policyname;

-- 3. Check if there are any constraints
SELECT
    con.conname as constraint_name,
    con.contype as constraint_type,
    pg_get_constraintdef(con.oid) as definition
FROM pg_constraint con
JOIN pg_class rel ON rel.oid = con.conrelid
WHERE rel.relname = 'fan_activities';

-- 4. Check indexes on fan_activities
SELECT 
    indexname,
    indexdef
FROM pg_indexes
WHERE tablename = 'fan_activities'
ORDER BY indexname;

-- 5. Test INSERT permission for authenticated user
-- This simulates what your app is trying to do
EXPLAIN (ANALYZE, VERBOSE)
INSERT INTO fan_activities (
    user_id,
    amount,
    category_id,
    artist_id,
    activity_date,
    note
) VALUES (
    auth.uid(), -- Current user's ID
    15.00,
    'concerts',
    (SELECT id FROM artists WHERE name = 'Jennie' LIMIT 1),
    CURRENT_DATE,
    'Test activity'
) RETURNING *;

-- 6. Check if artists table has Jennie
SELECT id, name 
FROM artists 
WHERE LOWER(name) LIKE '%jennie%';

-- 7. Check if category 'concerts' exists
SELECT DISTINCT category_id 
FROM fan_activities 
WHERE category_id LIKE '%concert%'
UNION
SELECT 'concerts' as category_id;

-- 8. Check recent errors in fan_activities
-- If there's a log table
SELECT * FROM fan_activities 
WHERE created_at > NOW() - INTERVAL '1 hour'
ORDER BY created_at DESC
LIMIT 5;