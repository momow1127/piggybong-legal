# Row Level Security Implementation Guide

## 🔐 **Complete RLS Setup for fan_activities Table**

### **Step 1: Remove Conflicting Policies**
Before adding the new policies, remove any overly broad ALL policies:

```sql
-- Check existing policies first
SELECT policyname, cmd FROM pg_policies 
WHERE schemaname = 'public' AND tablename = 'fan_activities';

-- Drop conflicting policies (adjust names based on what you see)
DROP POLICY IF EXISTS "Enable all operations for authenticated users" ON public.fan_activities;
DROP POLICY IF EXISTS "fan_activities_all_policy" ON public.fan_activities;
```

### **Step 2: Apply the New Policies**
Run the complete SQL from `fan_activities_rls_policies.sql`:

```sql
-- Enable RLS
ALTER TABLE public.fan_activities ENABLE ROW LEVEL SECURITY;

-- Create the 4 granular policies
CREATE POLICY "fan_activities_select_own" ON public.fan_activities
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "fan_activities_insert_own" ON public.fan_activities
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "fan_activities_update_own" ON public.fan_activities
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "fan_activities_delete_own" ON public.fan_activities
    FOR DELETE USING (auth.uid() = user_id);
```

### **Step 3: Verify Implementation**

#### **1. Check Policy Status**
```sql
SELECT policyname, cmd, permissive, qual, with_check 
FROM pg_policies 
WHERE schemaname = 'public' AND tablename = 'fan_activities'
ORDER BY policyname;
```

**Expected Results:**
- `fan_activities_select_own` - SELECT 
- `fan_activities_insert_own` - INSERT
- `fan_activities_update_own` - UPDATE  
- `fan_activities_delete_own` - DELETE

#### **2. Test User Isolation**
```sql
-- This should only return YOUR activities
SELECT count(*) FROM public.fan_activities;

-- This should show your user ID
SELECT auth.uid() as my_user_id;

-- This should match the user_id in your activities  
SELECT DISTINCT user_id FROM public.fan_activities;
```

### **Step 4: Update Your App Code**

Ensure your Supabase client code sets `user_id` correctly:

```javascript
// ✅ CORRECT: Always set user_id to current user
const { data, error } = await supabase
  .from('fan_activities')
  .insert({
    user_id: supabase.auth.getUser().then(u => u.data.user?.id),
    amount: 25.00,
    category_id: 'merch'
  });

// ❌ WRONG: Never hardcode or allow user_id from client
const { data, error } = await supabase
  .from('fan_activities')
  .insert({
    user_id: 'some-other-user-id', // This will be rejected
    amount: 25.00,
    category_id: 'merch'
  });
```

## 🛡️ **Security Benefits**

### **What These Policies Protect Against:**
- ✅ **Data isolation**: Users can't see other users' activities
- ✅ **Impersonation**: Users can't create activities for other users  
- ✅ **Unauthorized updates**: Users can't modify others' data
- ✅ **Data theft**: Users can't delete others' activities
- ✅ **Unauthenticated access**: All operations require valid auth

### **Policy Behavior:**

| Operation | Authenticated User | Unauthenticated User |
|-----------|-------------------|---------------------|
| **SELECT** | Own activities only | Nothing |  
| **INSERT** | With own user_id only | Rejected |
| **UPDATE** | Own activities only | Nothing |
| **DELETE** | Own activities only | Nothing |

## 🔧 **Troubleshooting**

### **Common Issues:**

#### **1. "permission denied for table fan_activities"**
- **Cause**: User not authenticated or token expired
- **Solution**: Check authentication status and refresh token

#### **2. INSERT operations fail**
- **Cause**: user_id doesn't match auth.uid()
- **Solution**: Ensure client code sets user_id to current user's ID

#### **3. No data returned from SELECT**
- **Cause**: No activities exist for current user
- **Solution**: Verify user_id values in database match auth.uid()

#### **4. Policies not working**  
- **Cause**: Conflicting ALL policies or RLS disabled
- **Solution**: Drop broad policies and ensure RLS is enabled

### **Debug Queries:**
```sql
-- Check if RLS is enabled
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE tablename = 'fan_activities';

-- Check your current user ID
SELECT auth.uid() as current_user;

-- Check user_id distribution in your data
SELECT user_id, count(*) 
FROM public.fan_activities 
GROUP BY user_id;

-- Test policy (should only return your activities)
SELECT * FROM public.fan_activities LIMIT 5;
```

## 📝 **Best Practices**

1. **Always use auth.uid()**: Never trust client-provided user_id values
2. **Test thoroughly**: Verify policies work with different user accounts  
3. **Monitor logs**: Watch for RLS policy violations in your logs
4. **Use least privilege**: Only grant permissions needed for your app
5. **Regular audits**: Periodically review policies and user access patterns

Your RLS setup is now secure and follows Supabase best practices! 🎉