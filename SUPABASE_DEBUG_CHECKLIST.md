# 🔍 Supabase Insert Debug Checklist

## Overview
Your Supabase insert is failing with authentication errors. Follow this step-by-step checklist to identify and fix the issue.

## ✅ Step 1: User Authentication Status

### In Xcode Console:
1. Add this code in your view and tap the button:
```swift
Button("🔧 Debug Auth") {
    Task {
        await fanDashboardService.debugAuthentication()
    }
}
```

### What to Look For:
- `✅ Current User: [user-id]` - User is logged in
- `❌ NOT AUTHENTICATED` - User is not logged in (main issue)
- `✅ Access Token: [token...]` - Token exists
- `❌ EXPIRED` - Token is expired

### In Supabase Dashboard:
1. Go to **Authentication → Users**
2. Check if your user exists
3. Note the User ID (UUID format)
4. Verify "Email Confirmed" is true

## ✅ Step 2: Row-Level Security (RLS) Policies

### Check RLS Status:
Go to **Table Editor → fan_activities → Settings**

### Required RLS Policy for INSERT:
```sql
-- Check existing policies
SELECT * FROM pg_policies WHERE tablename = 'fan_activities';

-- Create INSERT policy if missing
CREATE POLICY "Users can insert their own activities" ON fan_activities
FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Enable RLS if disabled
ALTER TABLE fan_activities ENABLE ROW LEVEL SECURITY;
```

### Test RLS Policy:
```sql
-- This should work when logged in
SELECT auth.uid(); -- Should return your user UUID

-- Test policy logic
SELECT user_id FROM fan_activities WHERE user_id = auth.uid();
```

## ✅ Step 3: Database Schema Validation

### Check Table Structure:
```sql
-- Verify table exists and columns
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'fan_activities';
```

### Expected Schema:
```sql
-- Your table should look like this:
CREATE TABLE fan_activities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    category_id TEXT,
    category_title TEXT,
    idol_id TEXT,
    note TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### Verify Data Types Match:
- `user_id`: UUID ✅
- `amount`: DECIMAL/NUMERIC ✅  
- `category_id`: TEXT ✅
- `idol_id`: TEXT ✅
- `note`: TEXT (nullable) ✅

## ✅ Step 4: Test Manual Insert

### In Supabase SQL Editor:
```sql
-- Test manual insert with your actual user ID
INSERT INTO fan_activities (user_id, amount, category_id, category_title, idol_id, note)
VALUES (
    '[YOUR-USER-UUID-HERE]'::uuid,
    25.00,
    'album',
    'Album',
    'BTS',
    'Test insert from dashboard'
);
```

### If This Fails:
- Check exact error message
- Verify user_id exists in auth.users
- Check all column names match exactly

## ✅ Step 5: Debug Your Code

### Enhanced Logging Added:
Your code now includes detailed logging. Look for:

1. **Authentication Check:**
```
🔍 === STEP 1: AUTHENTICATION DEBUG ===
✅ Authentication successful:
   - User ID: [uuid]
   - Access token available: ✅
```

2. **Data Validation:**
```
🔍 === STEP 2: DATA STRUCTURE VALIDATION ===
✅ All validations passed
```

3. **Insert Attempt:**
```
🔍 === STEP 5: DATABASE INSERT ATTEMPT ===
❌ Supabase SDK insert failed:
```

## 🔧 Common Issues & Solutions

### Issue 1: "Authentication Required"
**Cause:** User not logged in or token expired
**Solution:** 
- Ensure user is logged in before calling insert
- Refresh token if expired
- Check Google login flow is complete

### Issue 2: "Permission Denied" / "RLS Policy"
**Cause:** RLS policy blocking insert
**Solution:**
- Verify RLS policy allows INSERT for auth.uid()
- Test with RLS temporarily disabled
- Check user_id matches auth.uid()

### Issue 3: "Column Does Not Exist"
**Cause:** Column name mismatch
**Solution:**
- Check exact column names in table
- Verify case sensitivity
- Update payload to match schema

### Issue 4: "Foreign Key Violation"
**Cause:** Referenced IDs don't exist
**Solution:**
- Verify user_id exists in auth.users
- Check if idol_id references valid artist
- Use TEXT type for idol_id, not foreign key

## 🎯 Quick Debugging Commands

### Supabase Dashboard SQL:
```sql
-- 1. Check if table exists
SELECT * FROM fan_activities LIMIT 1;

-- 2. Check RLS policies
SELECT * FROM pg_policies WHERE tablename = 'fan_activities';

-- 3. Check your user ID
SELECT id, email FROM auth.users WHERE email = 'your-email@example.com';

-- 4. Test auth.uid() function
SELECT auth.uid();

-- 5. Temporarily disable RLS for testing
ALTER TABLE fan_activities DISABLE ROW LEVEL SECURITY;
-- Don't forget to re-enable after testing!
-- ALTER TABLE fan_activities ENABLE ROW LEVEL SECURITY;
```

## 📱 Test in Your App

1. **Build and run** with the enhanced debug logging
2. **Tap debug button** to see authentication status  
3. **Try the insert** and watch console for detailed error analysis
4. **Copy the error message** and match it to solutions above

## 🎉 Success Indicators

When working correctly, you should see:
```
✅ Authentication successful
✅ Data validation passed
✅ Supabase SDK insert successful!
✅ This indicates RLS policies are working correctly
```

Follow this checklist step by step, and you'll identify exactly where the authentication/insert is failing!