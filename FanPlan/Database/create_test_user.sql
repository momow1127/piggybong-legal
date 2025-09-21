-- =====================================================
-- CREATE TEST USER: Authenticated Supabase user for development
-- =====================================================

-- 1. Create user in auth.users table (Supabase auth)
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
    '00000000-0000-0000-0000-000000000001',
    'authenticated',
    'authenticated',
    'test@piggyapp.com',
    crypt('testpassword123', gen_salt('bf')), -- Encrypted password
    NOW(),
    NOW(),
    NOW(),
    '',
    '',
    '',
    ''
) ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    updated_at = NOW();

-- 2. Create corresponding user profile (if you have a users/profiles table)
-- Check what user tables exist first
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
    AND table_name LIKE '%user%';

-- 3. Create some test artists for the user
INSERT INTO fan_artists (
    id,
    user_id,
    name,
    image_url,
    created_at,
    updated_at
) VALUES 
    (
        '10000000-0000-0000-0000-000000000001',
        '00000000-0000-0000-0000-000000000001',
        'Jennie',
        'https://example.com/jennie.jpg',
        NOW(),
        NOW()
    ),
    (
        '10000000-0000-0000-0000-000000000002',
        '00000000-0000-0000-0000-000000000001',
        'NewJeans',
        'https://example.com/newjeans.jpg',
        NOW(),
        NOW()
    ),
    (
        '10000000-0000-0000-0000-000000000003',
        '00000000-0000-0000-0000-000000000001',
        'TWICE',
        'https://example.com/twice.jpg',
        NOW(),
        NOW()
    )
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    updated_at = NOW();

-- 4. Test the authentication by inserting a fan activity
-- This should work now that we have a real authenticated user
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
    '00000000-0000-0000-0000-000000000001',
    25.00,
    'concerts',
    'Concerts & Shows',
    'music',
    '10000000-0000-0000-0000-000000000001',
    'Jennie',
    'Test activity - authentication working!'
) RETURNING id, amount, category_id, category_title, idol_name, created_at;

-- 5. Verify the test user and data
SELECT 
    'Test user verification:' as status,
    id,
    email,
    email_confirmed_at IS NOT NULL as email_confirmed,
    created_at
FROM auth.users 
WHERE email = 'test@piggyapp.com';

SELECT 
    'Test artists for user:' as status,
    COUNT(*) as artist_count
FROM fan_artists 
WHERE user_id = '00000000-0000-0000-0000-000000000001';

SELECT 
    'Test activities for user:' as status,
    COUNT(*) as activity_count
FROM fan_activities 
WHERE user_id = '00000000-0000-0000-0000-000000000001';

-- 6. Show the complete fan activity record
SELECT 
    id,
    amount,
    category_id,
    category_title,
    idol_name,
    note,
    created_at
FROM fan_activities 
WHERE user_id = '00000000-0000-0000-0000-000000000001'
ORDER BY created_at DESC
LIMIT 3;