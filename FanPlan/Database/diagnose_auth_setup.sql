-- =====================================================
-- DIAGNOSE: Authentication Setup Issues
-- =====================================================

-- 1. Check if auth.users table exists and is accessible
SELECT 
    'Auth users table check:' as info,
    COUNT(*) as existing_users,
    'Can access auth.users table' as status
FROM auth.users
LIMIT 5;

-- 2. Check authentication providers configuration
-- This would show which providers are enabled in your Supabase project
SELECT 
    'Checking auth providers...' as info,
    'Run this in Supabase Dashboard > Authentication > Providers' as instruction;

-- 3. Test basic email signup (simulate what your app does)
-- We'll try to see what error occurs
SELECT 
    'Testing basic auth flow...' as info,
    'Check Supabase Dashboard > Authentication > Settings > Email Templates' as check_1,
    'Check Supabase Dashboard > Authentication > Settings > SMTP Settings' as check_2,
    'Check Supabase Dashboard > Authentication > Providers > Email' as check_3;

-- 4. Check current auth configuration
SELECT 
    'Current session info:' as info,
    auth.uid() as current_user_id,
    auth.email() as current_email,
    CASE 
        WHEN auth.uid() IS NULL THEN 'Not authenticated'
        ELSE 'Authenticated'
    END as auth_status;

-- 5. Check if we can create a user manually (for testing)
-- This will help us understand if the issue is with providers or the auth system itself
SELECT 
    'Manual user creation test:' as info,
    'Will try to create a test user directly...' as status;

-- Try to insert a user directly into auth.users (this might fail with permissions)
-- This is just to test if the auth system is working
INSERT INTO auth.users (
    instance_id,
    id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    created_at,
    updated_at,
    confirmation_token,
    recovery_token,
    email_change_token_new,
    email_change
) VALUES (
    '00000000-0000-0000-0000-000000000000',
    gen_random_uuid(),
    'authenticated',
    'authenticated',
    'test@example.com',
    crypt('password123', gen_salt('bf')),
    NOW(),
    NOW(),
    NOW(),
    '',
    '',
    '',
    ''
) RETURNING id, email, created_at;

-- 6. Check what happened
SELECT 
    'Test completed' as status,
    'Check the results above to identify the issue' as next_step;