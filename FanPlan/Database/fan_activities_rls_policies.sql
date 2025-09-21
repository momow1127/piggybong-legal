-- =====================================================
-- Row Level Security Policies for fan_activities Table
-- =====================================================
-- 
-- This file contains all RLS policies for the fan_activities table
-- to ensure users can only access their own data.
--
-- Prerequisites:
-- 1. RLS must be enabled on the table
-- 2. user_id column must contain auth.uid() values
-- 3. Remove any overly broad ALL policies first
--
-- =====================================================

-- STEP 1: Enable Row Level Security (if not already enabled)
ALTER TABLE public.fan_activities ENABLE ROW LEVEL SECURITY;

-- STEP 2: Drop any existing overly broad policies (adjust names as needed)
-- Uncomment these if you have conflicting policies:
-- DROP POLICY IF EXISTS "fan_activities_all_policy" ON public.fan_activities;
-- DROP POLICY IF EXISTS "Enable all operations for authenticated users" ON public.fan_activities;
-- DROP POLICY IF EXISTS "Allow all for authenticated users" ON public.fan_activities;

-- STEP 3: Create granular policies for each operation

-- =====================================================
-- SELECT Policy: Users can only view their own activities
-- =====================================================
CREATE POLICY "fan_activities_select_own" ON public.fan_activities
    FOR SELECT 
    USING (
        auth.uid() = user_id
    );

-- =====================================================  
-- INSERT Policy: Users can only insert activities with their own user_id
-- =====================================================
CREATE POLICY "fan_activities_insert_own" ON public.fan_activities
    FOR INSERT 
    WITH CHECK (
        auth.uid() = user_id
    );

-- =====================================================
-- UPDATE Policy: Users can only update their own activities  
-- =====================================================
CREATE POLICY "fan_activities_update_own" ON public.fan_activities
    FOR UPDATE
    USING (
        auth.uid() = user_id
    )
    WITH CHECK (
        auth.uid() = user_id
    );

-- =====================================================
-- DELETE Policy: Users can only delete their own activities
-- =====================================================
CREATE POLICY "fan_activities_delete_own" ON public.fan_activities
    FOR DELETE
    USING (
        auth.uid() = user_id
    );

-- =====================================================
-- VERIFICATION QUERIES
-- =====================================================
-- Run these to verify your policies are working correctly:

-- 1. Check that RLS is enabled
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE tablename = 'fan_activities';
-- Expected result: rowsecurity = true

-- 2. List all policies on the table
SELECT policyname, cmd, permissive, roles, qual, with_check 
FROM pg_policies 
WHERE schemaname = 'public' AND tablename = 'fan_activities'
ORDER BY policyname;

-- 3. Test SELECT policy (should only return current user's activities)
-- SELECT * FROM public.fan_activities;

-- 4. Test INSERT policy (should only allow inserting with current user's ID)
-- INSERT INTO public.fan_activities (user_id, amount, category_id) 
-- VALUES (auth.uid(), 25.00, 'merch');

-- =====================================================
-- POLICY EXPLANATIONS
-- =====================================================

/*
1. SELECT Policy (fan_activities_select_own):
   - USING clause: auth.uid() = user_id
   - Only allows viewing rows where the user_id matches the authenticated user's ID
   - Returns empty result set for unauthenticated users (auth.uid() is null)

2. INSERT Policy (fan_activities_insert_own):  
   - WITH CHECK clause: auth.uid() = user_id
   - Only allows inserting rows where user_id equals the authenticated user's ID
   - Prevents users from inserting activities for other users
   - Prevents unauthenticated inserts

3. UPDATE Policy (fan_activities_update_own):
   - USING clause: auth.uid() = user_id (can only update own records)
   - WITH CHECK clause: auth.uid() = user_id (prevents changing user_id to another user)
   - Both clauses ensure users can only modify their own activities
   - Prevents transferring activities between users

4. DELETE Policy (fan_activities_delete_own):
   - USING clause: auth.uid() = user_id  
   - Only allows deleting rows owned by the authenticated user
   - Prevents deleting other users' activities

Key Security Features:
- All policies use auth.uid() which is automatically set by Supabase Auth
- Unauthenticated users (auth.uid() = null) cannot access any data
- Users cannot access, modify, or delete other users' data
- INSERT policy prevents impersonation by enforcing correct user_id
- UPDATE policy prevents transferring ownership of activities
*/

-- =====================================================
-- COMMON ISSUES & TROUBLESHOOTING
-- =====================================================

/*
Issue 1: "permission denied for table fan_activities"
Solution: Make sure you're authenticated and your JWT token is valid

Issue 2: INSERT fails even for own user_id  
Solution: Verify your app is setting user_id to auth.uid() in INSERT statements

Issue 3: No data returned from SELECT
Solution: Check if user_id column actually contains your auth.uid() value:
   SELECT auth.uid() as my_id, user_id, * FROM fan_activities WHERE user_id = auth.uid();

Issue 4: Policy conflicts
Solution: Drop overly broad ALL policies that might conflict:
   DROP POLICY IF EXISTS "broad_policy_name" ON public.fan_activities;

Issue 5: RLS not working
Solution: Ensure RLS is enabled:
   ALTER TABLE public.fan_activities ENABLE ROW LEVEL SECURITY;
*/

-- =====================================================
-- OPTIONAL: Grant statements (if needed)
-- =====================================================
-- These might be needed depending on your setup:

-- Grant basic table permissions to authenticated users
-- GRANT SELECT, INSERT, UPDATE, DELETE ON public.fan_activities TO authenticated;
-- GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- Grant permissions to anon role for public access (usually not needed for user data)
-- GRANT SELECT ON public.fan_activities TO anon;