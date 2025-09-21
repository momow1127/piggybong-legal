# Quick COPPA Setup Guide for Supabase

## 🚀 Method 1: Supabase Dashboard (Easiest)

### Step 1: Database Tables
1. Go to: https://app.supabase.com/project/YOUR-PROJECT-REF/sql
2. Click "New Query"  
3. Copy entire contents of `supabase/migrations/20250829_coppa_compliance.sql`
4. Paste and click "Run"
5. ✅ Should see "Success. No rows returned"

### Step 2: Edge Functions
#### Function 1: parental-consent
1. Go to: https://app.supabase.com/project/YOUR-PROJECT-REF/functions
2. Click "Create a new function"
3. Name: `parental-consent`
4. Copy contents of `supabase/functions/parental-consent/index.ts`
5. Click "Deploy function"

#### Function 2: consent-approval  
1. Click "Create a new function"
2. Name: `consent-approval`
3. Copy contents of `supabase/functions/consent-approval/index.ts`
4. Click "Deploy function"

### Step 3: Email Service
1. Sign up: https://resend.com
2. Create API key (starts with `re_`)
3. Copy the key

### Step 4: Environment Variables
1. Go to: https://app.supabase.com/project/YOUR-PROJECT-REF/settings/functions
2. Add environment variable:
   - Name: `RESEND_API_KEY`
   - Value: `your-resend-api-key`

---

## 🛠️ Method 2: Command Line (Advanced)

### Prerequisites
```bash
# Install Supabase CLI
npm install -g supabase

# Login to Supabase
supabase login
```

### Quick Deploy
```bash
# Set your project reference
export SUPABASE_PROJECT_REF=YOUR-PROJECT-REF

# Run database migrations
supabase db push --project-ref $SUPABASE_PROJECT_REF

# Deploy Edge Functions
supabase functions deploy parental-consent --project-ref $SUPABASE_PROJECT_REF
supabase functions deploy consent-approval --project-ref $SUPABASE_PROJECT_REF

# Set environment variables
supabase secrets set RESEND_API_KEY="your-resend-key" --project-ref $SUPABASE_PROJECT_REF
```

---

## ✅ Verification Checklist

### Database Tables Created:
- [ ] `parental_consent_requests`
- [ ] `user_coppa_status` 
- [ ] `minor_data_restrictions`
- [ ] `parental_data_requests`

### Edge Functions Deployed:
- [ ] `parental-consent` function
- [ ] `consent-approval` function

### Environment Variables Set:
- [ ] `RESEND_API_KEY` configured

### Test URLs:
- **Consent Function**: `https://YOUR-PROJECT.supabase.co/functions/v1/parental-consent`
- **Approval Function**: `https://YOUR-PROJECT.supabase.co/functions/v1/consent-approval`

---

## 🧪 Quick Test

### Test Database Connection:
```sql
-- Run in SQL Editor
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name LIKE '%consent%';
```

### Test Edge Function:
```bash
curl -X OPTIONS "https://YOUR-PROJECT.supabase.co/functions/v1/parental-consent"
# Should return HTTP 200
```

---

## 📱 iOS App Integration

### Update SupabaseService.swift:
```swift
// Add these functions to your SupabaseService
func sendParentalConsentRequest(parentEmail: String, childName: String) async throws {
    let response = try await supabase.functions.invoke(
        "parental-consent",
        options: FunctionInvokeOptions(
            headers: ["Content-Type": "application/json"],
            body: [
                "parentEmail": parentEmail,
                "childName": childName,
                "childId": UUID().uuidString
            ]
        )
    )
}

func checkConsentStatus(childId: String) async throws -> Bool {
    // Check consent status in database
    let response = try await supabase
        .from("parental_consent_requests")
        .select("status")
        .eq("child_id", childId)
        .eq("status", "approved")
        .single()
    
    return response.data != nil
}
```

---

## 🚨 Troubleshooting

### Common Issues:

**Database Migration Fails:**
- Check you have the correct permissions
- Try running SQL queries one table at a time

**Edge Function Deploy Fails:**
- Verify TypeScript syntax is correct
- Check function name doesn't conflict

**Email Not Sending:**
- Verify RESEND_API_KEY is set correctly
- Check Resend dashboard for sending limits

**CORS Errors:**
- Edge Functions include CORS headers
- Test with Postman first

---

## 📞 Support

**Issues with setup?**
- Check Supabase logs in dashboard
- Verify all environment variables
- Test each component individually

**Ready to launch?**
- Update privacy policy in App Store
- Test full user flow
- Submit for legal review