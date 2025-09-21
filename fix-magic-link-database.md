# 🔧 Fix Magic Link Database Error

## 🚨 **Issue:**
```
Authentication Error: Failed to send login link: Sign in failed:
Authentication failed: Database error saving new user
```

## 🎯 **Root Cause:**
Supabase database schema or auth configuration is not properly set up for email authentication.

## ✅ **Solutions (Try in order):**

### **1. Enable Email Authentication in Supabase Dashboard**

Go to: https://supabase.com/dashboard/project/YOUR-PROJECT-REF/auth/settings

**Enable these settings:**
- ✅ **Enable email confirmations**
- ✅ **Enable email change confirmations**
- ✅ **Double confirm email changes**: OFF (for simplicity)

### **2. Check User Table Schema**

Go to: https://supabase.com/dashboard/project/YOUR-PROJECT-REF/editor

**Ensure these tables exist:**

**`auth.users` (automatic)**
- Should exist automatically with Supabase Auth

**`public.profiles` or `public.users` (if you have custom user data)**
```sql
-- Example user profile table
CREATE TABLE profiles (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  email TEXT,
  name TEXT,
  monthly_budget DECIMAL,
  currency TEXT DEFAULT 'USD',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Allow users to see and edit their own profile
CREATE POLICY "Users can view own profile" ON profiles
FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON profiles
FOR UPDATE USING (auth.uid() = id);
```

### **3. Database Trigger (if using custom profiles table)**

```sql
-- Create function to handle user creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, name)
  VALUES (NEW.id, NEW.email, COALESCE(NEW.raw_user_meta_data->>'name', NEW.email));
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to create profile when user signs up
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
```

### **4. Test with Simpler Email Setup**

If the above doesn't work, try with minimal configuration:

**Disable custom user creation temporarily:**
- Just use Supabase's built-in `auth.users` table
- Don't try to create records in custom tables during magic link flow

### **5. Check Supabase Logs**

Go to: https://supabase.com/dashboard/project/YOUR-PROJECT-REF/logs/explorer

**Look for:**
- Database errors during user creation
- Auth function failures
- Trigger execution errors

## 🧪 **Quick Test:**

After making these changes:

1. **Run your app**
2. **Enter email**: Use a test email you can access
3. **Tap "Send Magic Link"**
4. **Check Supabase Dashboard > Authentication > Users**
5. **Should see the user appear** (even if email not verified yet)

## 🎯 **Expected Flow After Fix:**

1. User enters email → `signInWithOTP` called
2. Supabase creates user in `auth.users` (automatic)
3. Database trigger creates user in `profiles` (if configured)
4. Email sent with magic link
5. User clicks link → authenticates successfully

---

**Most likely fix: Enable "Confirm email" in Authentication Settings and ensure no custom database triggers are failing.**