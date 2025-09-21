// Supabase Edge Function for COPPA parental consent emails
import { serve } from "https://deno.land/std@0.224.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { parentEmail, childName, childId } = await req.json()

    // Input validation
    if (!parentEmail || !childName || !childId) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields: parentEmail, childName, childId' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Validate email format
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
    if (!emailRegex.test(parentEmail)) {
      return new Response(
        JSON.stringify({ error: 'Invalid email format' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Create Supabase client
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseKey)

    // Generate unique consent token
    const consentToken = crypto.randomUUID()
    const approvalUrl = `${supabaseUrl}/functions/v1/consent-approval?token=${consentToken}`

    // Store consent request in database
    const { data: consentRecord, error: dbError } = await supabase
      .from('parental_consent_requests')
      .insert({
        child_id: childId,
        parent_email: parentEmail,
        child_name: childName,
        consent_token: consentToken,
        status: 'pending',
        created_at: new Date().toISOString(),
        expires_at: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString() // 7 days
      })
      .select()
      .single()

    if (dbError) {
      console.error('Database error:', dbError)
      return new Response(
        JSON.stringify({ error: 'Failed to save consent request' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Create email content
    const emailHtml = `
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>PiggyBong Parental Consent Required</title>
        <style>
            body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: linear-gradient(135deg, #5D2CEE 0%, #8B55ED 100%); color: white; padding: 30px; text-align: center; border-radius: 8px 8px 0 0; }
            .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 8px 8px; }
            .button { background: #5D2CEE; color: white; padding: 12px 24px; text-decoration: none; border-radius: 6px; display: inline-block; margin: 20px 0; }
            .info-box { background: white; padding: 20px; border-left: 4px solid #5D2CEE; margin: 20px 0; border-radius: 4px; }
            .warning { background: #fff3cd; border-color: #ffc107; color: #856404; padding: 15px; border-radius: 4px; margin: 20px 0; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>🐷 PiggyBong</h1>
                <h2>Parental Consent Required</h2>
            </div>
            <div class="content">
                <p>Hello,</p>
                <p><strong>${childName}</strong> wants to use PiggyBong, a K-pop spending tracker app. Since they're under 13, we need your permission first.</p>
                
                <div class="info-box">
                    <h3>What is PiggyBong?</h3>
                    <p>PiggyBong helps K-pop fans track their spending on concerts, albums, and merchandise. It teaches smart budgeting habits while letting fans enjoy their hobby responsibly.</p>
                </div>

                <div class="info-box">
                    <h3>What information do we collect from children?</h3>
                    <ul>
                        <li>Birth year (for age verification only)</li>
                        <li>Spending amounts and categories</li>
                        <li>Favorite K-pop artists</li>
                        <li>Budget goals and achievements</li>
                    </ul>
                    <p><strong>We do NOT collect:</strong> Full names, addresses, phone numbers, or photos from children under 13.</p>
                </div>

                <div class="info-box">
                    <h3>How we protect your child's privacy:</h3>
                    <ul>
                        <li>✅ No targeted advertising to children</li>
                        <li>✅ No sharing data with third parties</li>
                        <li>✅ Limited data collection (only what's needed)</li>
                        <li>✅ You can request data deletion anytime</li>
                        <li>✅ Secure, encrypted data storage</li>
                    </ul>
                </div>

                <div class="warning">
                    <strong>⏰ This consent request expires in 7 days.</strong> If you don't respond, your child won't be able to use the app.
                </div>

                <p><strong>To give permission:</strong></p>
                <a href="${approvalUrl}" class="button">✅ I Give Permission</a>
                
                <p>Or visit: <a href="${approvalUrl}">${approvalUrl}</a></p>

                <p><strong>Need help or have questions?</strong><br>
                Email us: <a href="mailto:privacy@piggybong.app">privacy@piggybong.app</a></p>

                <hr style="margin: 30px 0; border: none; border-top: 1px solid #ddd;">
                <p style="font-size: 12px; color: #666;">
                    This email was sent because your child tried to sign up for PiggyBong. 
                    This request is required by COPPA (Children's Online Privacy Protection Act).
                    <br><br>
                    PiggyBong • K-pop Spending Tracker • privacy@piggybong.app
                </p>
            </div>
        </div>
    </body>
    </html>`

    // Send email using Resend (you'll need to set up Resend API key)
    const resendApiKey = Deno.env.get('RESEND_API_KEY')
    if (!resendApiKey) {
      console.error('RESEND_API_KEY not configured')
      return new Response(
        JSON.stringify({ error: 'Email service not configured' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const emailResponse = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${resendApiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        from: 'PiggyBong <noreply@piggybong.app>',
        to: parentEmail,
        subject: `Parental Consent Required - ${childName} wants to use PiggyBong`,
        html: emailHtml,
      }),
    })

    if (!emailResponse.ok) {
      const emailError = await emailResponse.text()
      console.error('Email sending failed:', emailError)
      return new Response(
        JSON.stringify({ error: 'Failed to send email' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const emailData = await emailResponse.json()
    console.log('Email sent successfully:', emailData)

    return new Response(
      JSON.stringify({ 
        success: true, 
        message: 'Consent request sent successfully',
        consentId: consentRecord.id 
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Error:', error)
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})