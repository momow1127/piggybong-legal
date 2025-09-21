-- =====================================================
-- CHECK: What columns actually exist in fan_activities
-- =====================================================

-- 1. Show ALL actual columns in fan_activities table
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'fan_activities'
    AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. Show expected vs actual columns
WITH expected_columns AS (
    SELECT unnest(ARRAY[
        'id', 'user_id', 'amount', 'category_id', 'category_title', 
        'category_icon', 'idol_id', 'idol_name', 'note', 
        'created_at', 'updated_at'
    ]) as col_name
),
actual_columns AS (
    SELECT column_name as col_name
    FROM information_schema.columns
    WHERE table_name = 'fan_activities'
        AND table_schema = 'public'
)
SELECT 
    e.col_name as expected_column,
    CASE 
        WHEN a.col_name IS NOT NULL THEN '✅ EXISTS'
        ELSE '❌ MISSING'
    END as status
FROM expected_columns e
LEFT JOIN actual_columns a ON e.col_name = a.col_name
ORDER BY status DESC, e.col_name;

-- 3. Show a sample row to understand current structure
SELECT * 
FROM fan_activities 
LIMIT 3;