-- Fix Final 3 RLS Policy Warnings on Users Table
-- Remove remaining duplicate policies

-- Drop all old individual policies on users table
DROP POLICY IF EXISTS "Users can delete their own profile" ON public.users;
DROP POLICY IF EXISTS "Users can view their own profile" ON public.users;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.users;

-- Verify the optimized policy exists (it should from previous migration)
-- If not, create it
DROP POLICY IF EXISTS "users_optimized_policy" ON public.users;

CREATE POLICY "users_optimized_policy" ON public.users
    FOR ALL
    TO authenticated
    USING (id = (SELECT auth.uid()))
    WITH CHECK (id = (SELECT auth.uid()));

-- Ensure proper permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON public.users TO authenticated;

-- Update statistics
ANALYZE public.users;

-- Verification: Check remaining policies on users table
-- (This is a comment - you can run this separately to verify)
-- SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
-- FROM pg_policies
-- WHERE tablename = 'users'
-- ORDER BY policyname;