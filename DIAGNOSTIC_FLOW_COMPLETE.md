# 🔍 Complete Supabase Diagnostic Flow

## Overview
This guide walks you through the complete diagnostic process to identify the exact cause of your Supabase insert failures.

---

## 🚀 **Step 1: Run Authentication Debug**

### Add Debug Button to Your App:
```swift
// Add this to any SwiftUI view
Button("🔧 Debug Authentication") {
    Task {
        await fanDashboardService.debugAuthentication()
    }
}
.foregroundColor(.blue)
.padding()
```

### Expected Console Output Analysis:

#### ✅ **SUCCESS PATTERN:**
```
🔍 === STEP 1: AUTHENTICATION DEBUG ===
🔐 Auth client available: ✅
✅ Authentication successful:
   - User ID: 12345678-1234-1234-1234-123456789abc
   - User Email: user@gmail.com
   - Auth method: google
   - User confirmed: ✅
   - Access token available: ✅ (eyJhbGciOiJIUzI1NiIs...)
   - Token expires at timestamp: 1724889561.0
   - Token valid: ✅
```

#### ❌ **FAILURE PATTERNS:**

**Pattern A: Not Authenticated**
```
🔐 Auth client available: ✅
👤 Current User: ❌ NOT AUTHENTICATED
```
→ **Solution:** User needs to log in with Google

**Pattern B: Token Expired**
```
✅ Authentication successful:
   - User ID: 12345678-1234-1234-1234-123456789abc
   - Token valid: ❌ EXPIRED
```
→ **Solution:** Refresh token or re-authenticate

**Pattern C: Token Access Failed**
```
   - Access token: ❌ NOT AVAILABLE - Session expired
```
→ **Solution:** Handle session refresh

---

## 🚀 **Step 2: Validate User ID Format**

### Console Check:
Look for this line in your debug output:
```
- currentUserId: '12345678-1234-1234-1234-123456789abc' (UUID format: ✅)
```

### If UUID Format is ❌:
```swift
// Test UUID validation manually
let testUserId = "your-user-id-from-debug"
print("UUID Test: \(UUID(uuidString: testUserId) != nil ? "✅ Valid" : "❌ Invalid")")
```

---

## 🚀 **Step 3: Check RLS Policy Configuration**

### 3.1 Verify Current Policy in Supabase Dashboard:
1. Go to **Table Editor** → **fan_activities** → **Settings**
2. Check if **RLS is enabled**: Should show "RLS enabled"
3. Click **View Policies**

### 3.2 Required INSERT Policy:
```sql
-- Check existing policies
SELECT 
    schemaname, tablename, policyname, cmd, 
    qual, with_check
FROM pg_policies 
WHERE tablename = 'fan_activities';
```

### 3.3 Create Correct INSERT Policy (if missing):
```sql
-- Delete existing incorrect policies
DROP POLICY IF EXISTS "Users can insert their own activities" ON fan_activities;

-- Create correct policy for Google Auth
CREATE POLICY "Enable INSERT for authenticated users" 
ON fan_activities 
FOR INSERT 
TO authenticated 
WITH CHECK (auth.uid() = user_id);
```

### 3.4 Test Policy Logic:
```sql
-- Test 1: Check if auth.uid() works
SELECT auth.uid() as current_user_id;

-- Test 2: Verify you can see your user
SELECT id, email, created_at 
FROM auth.users 
WHERE email = 'your-google-email@gmail.com';

-- Test 3: Test policy with specific user ID
SELECT user_id 
FROM fan_activities 
WHERE user_id = auth.uid()
LIMIT 1;
```

---

## 🚀 **Step 4: Database Schema Validation**

### 4.1 Verify Table Structure:
```sql
-- Check exact column names and types
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'fan_activities'
ORDER BY ordinal_position;
```

### 4.2 Expected Schema (verify this matches):
| Column | Type | Nullable | Default |
|--------|------|----------|---------|
| id | uuid | NO | gen_random_uuid() |
| user_id | uuid | NO | NULL |
| amount | numeric | NO | NULL |
| category_id | text | YES | NULL |
| category_title | text | YES | NULL |
| idol_id | text | YES | NULL |
| note | text | YES | NULL |
| created_at | timestamptz | NO | now() |

### 4.3 Check for Foreign Key Constraints:
```sql
-- Check if user_id has foreign key constraint
SELECT
    tc.table_name, 
    kcu.column_name, 
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name 
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
  AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
  AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
  AND tc.table_name = 'fan_activities';
```

---

## 🚀 **Step 5: Manual Insert Test**

### 5.1 Get Your Actual User ID:
```sql
-- Find your user ID from Google login
SELECT id, email, created_at, email_confirmed_at 
FROM auth.users 
WHERE email = 'your-google-email@gmail.com';
```

### 5.2 Test Manual Insert (copy the exact payload from your app):
```sql
-- Test with your exact user ID
INSERT INTO fan_activities (
    user_id, 
    amount, 
    category_id, 
    category_title, 
    idol_id, 
    note
) VALUES (
    'PASTE-YOUR-USER-ID-HERE'::uuid,
    25.00,
    'album',
    'Album',
    'BTS',
    'Manual test from SQL editor'
);
```

### 5.3 If Manual Insert Fails, Check:
- **Permission denied**: RLS policy issue
- **Invalid UUID**: User ID format problem
- **Column doesn't exist**: Schema mismatch
- **Foreign key violation**: Referenced table issue

---

## 🚀 **Step 6: Test with RLS Temporarily Disabled**

### ⚠️ **CRITICAL: Only for debugging - re-enable immediately after**

```sql
-- DISABLE RLS temporarily
ALTER TABLE fan_activities DISABLE ROW LEVEL SECURITY;

-- Try the same INSERT query
INSERT INTO fan_activities (
    user_id, 
    amount, 
    category_id, 
    category_title, 
    idol_id, 
    note
) VALUES (
    'YOUR-USER-ID'::uuid,
    25.00,
    'album',
    'Album',
    'BTS',
    'Test without RLS'
);

-- IMMEDIATELY RE-ENABLE RLS
ALTER TABLE fan_activities ENABLE ROW LEVEL SECURITY;
```

### Results Analysis:
- **Insert works without RLS**: RLS policy is the issue
- **Insert still fails without RLS**: Schema or data format issue

---

## 🚀 **Step 7: Hidden Issues to Check**

### 7.1 Google Auth Role Restrictions:
```sql
-- Check user role and metadata
SELECT 
    id, 
    role,
    email,
    raw_app_meta_data,
    raw_user_meta_data
FROM auth.users 
WHERE email = 'your-email@gmail.com';
```

### 7.2 UUID Version Compatibility:
```swift
// In Xcode, test UUID generation compatibility
let testUUID = UUID()
print("Generated UUID: \(testUUID.uuidString)")
print("Supabase format: \(testUUID.uuidString.lowercased())")
```

### 7.3 Timestamp/Timezone Issues:
```sql
-- Check created_at column default
SELECT column_default 
FROM information_schema.columns 
WHERE table_name = 'fan_activities' 
  AND column_name = 'created_at';

-- Should return: now() or CURRENT_TIMESTAMP
```

### 7.4 Network/SSL Issues:
```swift
// Test basic connectivity
let testButton = Button("Test Connection") {
    Task {
        let connected = await SupabaseService.shared.databaseService.testConnection()
        print("Connection test: \(connected ? "✅" : "❌")")
    }
}
```

---

## 🎯 **Diagnostic Decision Tree**

### If Authentication Debug Shows:
1. **❌ NOT AUTHENTICATED** → Fix Google login flow
2. **❌ TOKEN EXPIRED** → Implement token refresh
3. **✅ All auth checks pass** → Continue to RLS check

### If Manual SQL Insert Shows:
1. **Works in SQL editor** → App code issue (likely auth token)
2. **Fails with permission denied** → RLS policy issue
3. **Fails with schema error** → Table structure mismatch

### If RLS Disabled Test Shows:
1. **Works without RLS** → Fix RLS policy
2. **Still fails without RLS** → Schema or data format issue

---

## 🔧 **Quick Fix Commands**

### Reset RLS Policy:
```sql
-- Clean slate approach
DROP POLICY IF EXISTS "Enable INSERT for authenticated users" ON fan_activities;
CREATE POLICY "Users can insert own activities" ON fan_activities
    FOR INSERT WITH CHECK (auth.uid() = user_id);
```

### Verify User Authentication:
```sql
-- Check if your Google user exists and is confirmed
SELECT 
    id,
    email,
    email_confirmed_at IS NOT NULL as email_confirmed,
    created_at
FROM auth.users 
WHERE email = 'your-google-email@gmail.com';
```

### Test App Connectivity:
```swift
// Add this debug button to test basic functionality
Button("🔗 Test Supabase Connection") {
    Task {
        do {
            let count = try await SupabaseService.shared.client
                .from("fan_activities")
                .select("*", head: true, count: .exact)
                .execute()
                .count
            print("✅ Connection successful, \(count ?? 0) records found")
        } catch {
            print("❌ Connection failed: \(error)")
        }
    }
}
```

---

## 🎉 **Success Indicators**

### When Everything is Working:
```
🔍 === STEP 1: AUTHENTICATION DEBUG ===
✅ Authentication successful
✅ Token valid
🔍 === STEP 5: DATABASE INSERT ATTEMPT ===
✅ Supabase SDK insert successful!
✅ This indicates RLS policies are working correctly
```

Follow this diagnostic flow systematically, and you'll identify the exact issue causing your authentication failures!