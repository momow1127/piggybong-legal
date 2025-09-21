-- =====================================================
-- COMPLETE FIX: Add ALL missing columns to fan_activities
-- Current: id, user_id, amount, created_at (4 columns)
-- Need to add: 7 missing columns
-- =====================================================

-- 1. Add ALL missing columns that the app expects

-- Category columns (required by app)
ALTER TABLE fan_activities 
ADD COLUMN category_id TEXT NOT NULL DEFAULT 'uncategorized';

ALTER TABLE fan_activities 
ADD COLUMN category_title TEXT NOT NULL DEFAULT 'Uncategorized';

ALTER TABLE fan_activities 
ADD COLUMN category_icon TEXT NOT NULL DEFAULT 'star';

-- Artist/Idol columns (optional, can be NULL)
ALTER TABLE fan_activities 
ADD COLUMN idol_id UUID REFERENCES fan_artists(id) ON DELETE SET NULL;

ALTER TABLE fan_activities 
ADD COLUMN idol_name TEXT;

-- Note column (optional)
ALTER TABLE fan_activities 
ADD COLUMN note TEXT;

-- Updated at column (for triggers)
ALTER TABLE fan_activities 
ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- 2. Create the updated_at trigger (from schema.sql)
CREATE TRIGGER update_fan_activities_updated_at
    BEFORE UPDATE ON fan_activities
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- 3. Add missing indexes for performance
CREATE INDEX IF NOT EXISTS idx_fan_activities_category_id ON fan_activities(category_id);

-- 4. Verify all columns are now present
SELECT 
    'After adding ALL columns:' as status,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'fan_activities'
    AND table_schema = 'public'
ORDER BY ordinal_position;

-- 5. Test the exact INSERT that was failing in the app
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
    auth.uid(),
    15.00,
    'concerts',
    'Concerts & Shows',
    'music',
    (SELECT id FROM fan_artists WHERE name ILIKE '%jennie%' LIMIT 1),
    'Jennie',
    'Test - schema fix verification'
) RETURNING id, amount, category_id, category_title, idol_name, created_at, updated_at;

-- 6. Verify the test insert worked
SELECT 
    'Test insert verification:' as status,
    id, amount, category_id, category_title, idol_name, note, created_at
FROM fan_activities 
WHERE note = 'Test - schema fix verification'
ORDER BY created_at DESC
LIMIT 1;

-- 7. Clean up test data
DELETE FROM fan_activities 
WHERE note = 'Test - schema fix verification';