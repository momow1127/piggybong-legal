-- =====================================================
-- CHECK: fan_activities table actual structure
-- =====================================================

-- 1. Show EXACT columns in fan_activities table
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'fan_activities'
    AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. Show the CREATE TABLE statement (if available)
SELECT 
    'fan_activities table columns:' as info,
    array_agg(column_name ORDER BY ordinal_position) as all_columns
FROM information_schema.columns
WHERE table_name = 'fan_activities'
    AND table_schema = 'public';

-- 3. Check if there's a 'category' column (without _id)
SELECT 
    column_name,
    data_type
FROM information_schema.columns
WHERE table_name = 'fan_activities'
    AND table_schema = 'public'
    AND column_name LIKE '%categ%';

-- 4. Check sample data to see structure
SELECT * 
FROM fan_activities 
LIMIT 5;

-- 5. Check what columns the app might be expecting vs what exists
WITH expected_columns AS (
    SELECT unnest(ARRAY[
        'id', 'user_id', 'amount', 'category_id', 'category',
        'artist_id', 'activity_date', 'note', 'created_at', 'updated_at'
    ]) as col_name
),
actual_columns AS (
    SELECT column_name as col_name
    FROM information_schema.columns
    WHERE table_name = 'fan_activities'
        AND table_schema = 'public'
)
SELECT 
    e.col_name,
    CASE 
        WHEN a.col_name IS NOT NULL THEN '✅ EXISTS'
        ELSE '❌ MISSING'
    END as status
FROM expected_columns e
LEFT JOIN actual_columns a ON e.col_name = a.col_name
ORDER BY status DESC, e.col_name;