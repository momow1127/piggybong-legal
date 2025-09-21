-- =====================================================
-- SIMPLE APPROACH: Create test data for existing user
-- =====================================================

-- Option A: If you have an existing authenticated user, get their ID
SELECT 
    'Your current user ID (if logged in):' as info,
    auth.uid() as user_id,
    auth.email() as email;

-- Option B: Create test artists for any authenticated user
-- Run this after you sign up/log in to the app normally

-- First, let's see what users exist in auth.users (if we can access it)
SELECT 
    'Existing auth users:' as info,
    COUNT(*) as user_count
FROM auth.users
LIMIT 1;

-- Create test artists for the current authenticated user
INSERT INTO fan_artists (
    user_id,
    name,
    image_url,
    created_at,
    updated_at
) VALUES 
    (
        COALESCE(auth.uid(), '00000000-0000-0000-0000-000000000001'),
        'Jennie',
        'https://example.com/jennie.jpg',
        NOW(),
        NOW()
    ),
    (
        COALESCE(auth.uid(), '00000000-0000-0000-0000-000000000001'),
        'NewJeans',
        'https://example.com/newjeans.jpg',
        NOW(),
        NOW()
    ),
    (
        COALESCE(auth.uid(), '00000000-0000-0000-0000-000000000001'),
        'TWICE',
        'https://example.com/twice.jpg',
        NOW(),
        NOW()
    )
ON CONFLICT (id) DO NOTHING;

-- Test creating a fan activity (this will work if you're authenticated)
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
    COALESCE(auth.uid(), '00000000-0000-0000-0000-000000000001'),
    25.00,
    'concerts',
    'Concerts & Shows',
    'music',
    (SELECT id FROM fan_artists WHERE name = 'Jennie' AND user_id = COALESCE(auth.uid(), '00000000-0000-0000-0000-000000000001') LIMIT 1),
    'Jennie',
    'Test activity - SQL Editor test'
) RETURNING id, amount, category_id, category_title, idol_name, created_at;

-- Show results
SELECT 
    'Test completed successfully!' as status,
    'You can now use Add Fan Activity in the app' as message;