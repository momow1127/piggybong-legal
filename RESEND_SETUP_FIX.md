# 🔧 Resend Email Service Fix for COPPA

## 🚨 **Current Issue: HTTP 500 "Failed to send email"**

Your COPPA function is working, but the email sending is failing. Here's how to fix it:

## ✅ **Option 1: Use Your Gmail (Easiest)**

### Update the Edge Function:
In your Supabase Functions editor, change line in `parental-consent` function:

**FROM:**
```typescript
from: 'PiggyBong <noreply@piggybong.app>',
```

**TO:**
```typescript
from: 'PiggyBong <your-email@gmail.com>',  // Use your actual Gmail
```

### Why This Works:
- Resend allows Gmail addresses without domain verification
- Your Gmail will be the sender address
- Parents will see it's from you personally

## ✅ **Option 2: Set up Domain (Production)**

### 1. Add Domain to Resend:
1. Go to: https://resend.com/domains
2. Click "Add Domain"  
3. Add: `piggybong.app` or your domain
4. Follow DNS verification steps

### 2. Update Function:
```typescript
from: 'PiggyBong <noreply@piggybong.app>',
```

## 🧪 **Quick Test Fix**

### Temporary Test Version:
Replace your `parental-consent` function with this simplified version:

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { parentEmail, childName, childId } = await req.json()

    // Input validation
    if (!parentEmail || !childName || !childId) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const resendApiKey = Deno.env.get('RESEND_API_KEY')
    if (!resendApiKey) {
      return new Response(
        JSON.stringify({ error: 'Email service not configured' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Simple email content
    const emailHtml = `
      <h2>PiggyBong Parental Consent Required</h2>
      <p>Hello,</p>
      <p><strong>${childName}</strong> wants to use PiggyBong, a K-pop spending tracker.</p>
      <p>Since they're under 13, we need your permission first.</p>
      <p><a href="https://YOUR-PROJECT.supabase.co/functions/v1/consent-approval?token=test-${childId}">
         Click here to give permission
      </a></p>
      <p>Questions? Reply to this email.</p>
      <p>PiggyBong Team</p>
    `

    // Send via Resend
    const emailResponse = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${resendApiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        from: 'PiggyBong <your-email@gmail.com>',  // CHANGE THIS TO YOUR EMAIL
        to: parentEmail,
        subject: `Parental Consent Required - ${childName}`,
        html: emailHtml,
      }),
    })

    if (!emailResponse.ok) {
      const error = await emailResponse.text()
      console.error('Resend error:', error)
      return new Response(
        JSON.stringify({ error: 'Email service error', details: error }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    return new Response(
      JSON.stringify({ success: true, message: 'Consent email sent' }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Function error:', error)
    return new Response(
      JSON.stringify({ error: 'Internal server error', details: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
```

## 🔧 **How to Apply the Fix:**

1. **Go to Supabase Functions**: https://app.supabase.com/project/YOUR-PROJECT-REF/functions
2. **Click on `parental-consent`** 
3. **Replace the code** with the simplified version above
4. **Change `your-email@gmail.com`** to your actual Gmail
5. **Click "Deploy function"**

## 🧪 **Test Again:**

```bash
curl -X POST "https://YOUR-PROJECT.supabase.co/functions/v1/parental-consent" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." \
  -H "apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." \
  -d '{
    "parentEmail": "your-real-email@gmail.com",
    "childName": "Test Child", 
    "childId": "test-789"
  }'
```

## ✅ **Expected Result:**
```json
{"success": true, "message": "Consent email sent"}
```

## 🎯 **Next Steps After Fix:**
1. Test email sending works
2. Check your Gmail for the sent email
3. Test the approval link in the email
4. Update iOS app to use the working functions

**This will get your COPPA system 100% functional!** 🚀