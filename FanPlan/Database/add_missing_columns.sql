-- =====================================================
-- FIX: Add missing columns to fan_activities table
-- =====================================================

-- 1. First, check current structure
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'fan_activities'
    AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. Add missing columns based on schema.sql
-- These columns are expected by the app but don't exist in the actual table

ALTER TABLE fan_activities 
ADD COLUMN IF NOT EXISTS category_id TEXT NOT NULL DEFAULT 'uncategorized';

ALTER TABLE fan_activities 
ADD COLUMN IF NOT EXISTS category_title TEXT NOT NULL DEFAULT 'Uncategorized';

ALTER TABLE fan_activities 
ADD COLUMN IF NOT EXISTS category_icon TEXT NOT NULL DEFAULT 'star';

ALTER TABLE fan_activities 
ADD COLUMN IF NOT EXISTS idol_id UUID REFERENCES fan_artists(id) ON DELETE SET NULL;

ALTER TABLE fan_activities 
ADD COLUMN IF NOT EXISTS idol_name TEXT;

-- 3. Add indexes for performance (matching schema.sql)
CREATE INDEX IF NOT EXISTS idx_fan_activities_category_id ON fan_activities(category_id);

-- 4. Verify columns were added successfully
SELECT 
    'After adding columns:' as status,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'fan_activities'
    AND table_schema = 'public'
ORDER BY ordinal_position;

-- 5. Test that the app's INSERT will now work
-- This simulates what the app is trying to do
INSERT INTO fan_activities (
    user_id,
    amount,
    category_id,
    category_title,
    category_icon,
    idol_id,
    idol_name,
    note
) VALUES (
    auth.uid(), -- Current user's ID
    15.00,
    'concerts',
    'Concerts & Shows',
    'music',
    (SELECT id FROM fan_artists WHERE name = 'Jennie' LIMIT 1),
    'Jennie',
    'Test activity after schema fix'
) RETURNING id, amount, category_id, category_title, idol_name, created_at;

-- 6. Clean up test data (remove the test insert)
DELETE FROM fan_activities 
WHERE note = 'Test activity after schema fix' 
    AND amount = 15.00;