-- ====================================
-- SUPABASE DIAGNOSTIC SQL QUERIES
-- Run these in your Supabase Dashboard SQL Editor
-- ====================================

-- =====================================
-- STEP 1: BASIC AUTHENTICATION CHECK
-- =====================================

-- 1.1 Check if you're authenticated (should return your user UUID)
SELECT auth.uid() as current_user_id;

-- 1.2 Find your Google user account
SELECT 
    id,
    email,
    email_confirmed_at IS NOT NULL as email_confirmed,
    created_at,
    last_sign_in_at,
    raw_app_meta_data->>'provider' as auth_provider
FROM auth.users 
WHERE email = 'YOUR-GOOGLE-EMAIL@gmail.com'  -- Replace with your actual email
ORDER BY created_at DESC;

-- =====================================
-- STEP 2: TABLE STRUCTURE VALIDATION
-- =====================================

-- 2.1 Check if fan_activities table exists and its structure
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'fan_activities'
  AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2.2 Check table permissions and RLS status
SELECT 
    schemaname, 
    tablename, 
    tableowner, 
    rowsecurity as rls_enabled,
    relrowsecurity as rls_enforced
FROM pg_tables t
JOIN pg_class c ON c.relname = t.tablename
WHERE tablename = 'fan_activities';

-- =====================================
-- STEP 3: RLS POLICIES VALIDATION
-- =====================================

-- 3.1 List all policies on fan_activities table
SELECT 
    schemaname,
    tablename,
    policyname,
    cmd as command,      -- INSERT, SELECT, UPDATE, DELETE
    permissive,          -- PERMISSIVE or RESTRICTIVE
    qual as using_expression,
    with_check as with_check_expression
FROM pg_policies 
WHERE tablename = 'fan_activities';

-- 3.2 Test policy logic (should return true if RLS allows access)
SELECT 
    auth.uid() = auth.uid() as auth_uid_works,
    auth.uid() IS NOT NULL as auth_uid_exists;

-- =====================================
-- STEP 4: MANUAL INSERT TEST
-- =====================================

-- 4.1 Get your exact user ID first
DO $$
DECLARE
    current_user_id UUID;
BEGIN
    SELECT id INTO current_user_id 
    FROM auth.users 
    WHERE email = 'YOUR-GOOGLE-EMAIL@gmail.com';  -- Replace with your email
    
    RAISE NOTICE 'Your User ID: %', current_user_id;
    
    -- Test if this user ID matches auth.uid()
    IF current_user_id = auth.uid() THEN
        RAISE NOTICE '✅ User ID matches auth.uid()';
    ELSE
        RAISE NOTICE '❌ User ID does NOT match auth.uid()';
        RAISE NOTICE 'Expected: %, Got: %', current_user_id, auth.uid();
    END IF;
END $$;

-- 4.2 Manual insert test with your actual user ID
-- REPLACE 'YOUR-USER-ID-HERE' with the UUID from above
INSERT INTO fan_activities (
    user_id, 
    amount, 
    category_id, 
    category_title, 
    idol_id, 
    note
) VALUES (
    'YOUR-USER-ID-HERE'::uuid,  -- Replace with your actual UUID
    25.00,
    'test',
    'Test Category',
    'Debug Artist',
    'SQL manual test - ' || NOW()::text
);

-- =====================================
-- STEP 5: TROUBLESHOOTING QUERIES
-- =====================================

-- 5.1 Check for foreign key constraints that might block insert
SELECT
    tc.table_name, 
    kcu.column_name, 
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name,
    tc.constraint_name
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
    AND tc.table_name = 'fan_activities';

-- 5.2 Check if user_id exists in auth.users (should return 1)
SELECT COUNT(*) as user_exists
FROM auth.users 
WHERE id = auth.uid();

-- 5.3 Test SELECT with RLS (should work if policies are correct)
SELECT COUNT(*) as my_activities
FROM fan_activities 
WHERE user_id = auth.uid();

-- =====================================
-- STEP 6: POLICY FIXES (if needed)
-- =====================================

-- 6.1 Drop existing policies if they're incorrect
DROP POLICY IF EXISTS "Users can insert their own activities" ON fan_activities;
DROP POLICY IF EXISTS "Enable INSERT for authenticated users" ON fan_activities;
DROP POLICY IF EXISTS "Users can view own activities" ON fan_activities;

-- 6.2 Create correct RLS policies
CREATE POLICY "Users can insert own activities" ON fan_activities
    FOR INSERT 
    TO authenticated 
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view own activities" ON fan_activities
    FOR SELECT 
    TO authenticated 
    USING (auth.uid() = user_id);

-- 6.3 Ensure RLS is enabled
ALTER TABLE fan_activities ENABLE ROW LEVEL SECURITY;

-- =====================================
-- STEP 7: FINAL VALIDATION
-- =====================================

-- 7.1 Test the complete flow
DO $$
DECLARE
    test_record_id UUID;
    current_user_id UUID;
BEGIN
    -- Get current user
    current_user_id := auth.uid();
    RAISE NOTICE '🔐 Current User: %', current_user_id;
    
    -- Test insert
    INSERT INTO fan_activities (
        user_id, amount, category_id, category_title, idol_id, note
    ) VALUES (
        current_user_id, 30.00, 'validation', 'Validation Test', 'Test Artist', 'Complete validation test'
    ) RETURNING id INTO test_record_id;
    
    RAISE NOTICE '✅ Insert successful! Record ID: %', test_record_id;
    
    -- Test select
    IF EXISTS(SELECT 1 FROM fan_activities WHERE id = test_record_id) THEN
        RAISE NOTICE '✅ Select successful! Record can be read back';
    ELSE
        RAISE NOTICE '❌ Select failed! Record was inserted but cannot be read';
    END IF;
    
    -- Clean up test record
    DELETE FROM fan_activities WHERE id = test_record_id;
    RAISE NOTICE '🧹 Test record cleaned up';
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '❌ Test failed with error: %', SQLERRM;
END $$;

-- =====================================
-- STEP 8: EMERGENCY RLS DISABLE (DEBUG ONLY)
-- =====================================

-- ⚠️ ONLY USE FOR DEBUGGING - RE-ENABLE IMMEDIATELY AFTER
-- ALTER TABLE fan_activities DISABLE ROW LEVEL SECURITY;

-- Test insert without RLS
-- INSERT INTO fan_activities (user_id, amount, category_id, idol_id, note) 
-- VALUES (auth.uid(), 99.99, 'no-rls-test', 'Test', 'Insert without RLS');

-- ⚠️ IMMEDIATELY RE-ENABLE RLS AFTER TESTING
-- ALTER TABLE fan_activities ENABLE ROW LEVEL SECURITY;

-- =====================================
-- EXPECTED RESULTS SUMMARY
-- =====================================

/*
STEP 1: Should show your UUID and user details
STEP 2: Should show fan_activities table structure 
STEP 3: Should show INSERT and SELECT policies
STEP 4: Manual insert should succeed
STEP 5: Should show no blocking foreign keys
STEP 6: Policy creation should succeed
STEP 7: Complete flow test should pass

If any step fails, that's where your issue is!
*/