// Supabase Edge Function for handling parental consent approval
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
    const url = new URL(req.url)
    const token = url.searchParams.get('token')
    const action = url.searchParams.get('action') || 'approve' // approve or deny

    if (!token) {
      return new Response(`
        <!DOCTYPE html>
        <html>
        <head><title>Invalid Link</title></head>
        <body>
          <h1>Invalid Consent Link</h1>
          <p>This consent link is invalid or has expired.</p>
          <p>Please contact <a href="mailto:privacy@piggybong.app">privacy@piggybong.app</a> for help.</p>
        </body>
        </html>
      `, { 
        status: 400, 
        headers: { ...corsHeaders, 'Content-Type': 'text/html' } 
      })
    }

    // Create Supabase client
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseKey)

    // Find consent request by token
    const { data: consentRequest, error: findError } = await supabase
      .from('parental_consent_requests')
      .select('*')
      .eq('consent_token', token)
      .eq('status', 'pending')
      .single()

    if (findError || !consentRequest) {
      return new Response(`
        <!DOCTYPE html>
        <html>
        <head>
          <title>Consent Link Invalid</title>
          <style>
            body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; padding: 40px; text-align: center; }
            .container { max-width: 500px; margin: 0 auto; }
            .error { color: #dc3545; }
          </style>
        </head>
        <body>
          <div class="container">
            <h1>🚫 Consent Link Invalid</h1>
            <p class="error">This consent link has expired, is invalid, or has already been used.</p>
            <p>If you need a new consent link, please have your child try signing up for PiggyBong again.</p>
            <p>Questions? Contact us at <a href="mailto:privacy@piggybong.app">privacy@piggybong.app</a></p>
          </div>
        </body>
        </html>
      `, { 
        status: 404, 
        headers: { ...corsHeaders, 'Content-Type': 'text/html' } 
      })
    }

    // Check if consent has expired
    const expiresAt = new Date(consentRequest.expires_at)
    const now = new Date()
    if (now > expiresAt) {
      return new Response(`
        <!DOCTYPE html>
        <html>
        <head>
          <title>Consent Link Expired</title>
          <style>
            body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; padding: 40px; text-align: center; }
            .container { max-width: 500px; margin: 0 auto; }
            .warning { color: #856404; background: #fff3cd; padding: 15px; border-radius: 4px; }
          </style>
        </head>
        <body>
          <div class="container">
            <h1>⏰ Consent Link Expired</h1>
            <div class="warning">
              <p>This consent request for <strong>${consentRequest.child_name}</strong> has expired.</p>
            </div>
            <p>Please have your child sign up for PiggyBong again to receive a new consent request.</p>
            <p>Questions? Contact us at <a href="mailto:privacy@piggybong.app">privacy@piggybong.app</a></p>
          </div>
        </body>
        </html>
      `, { 
        status: 410, 
        headers: { ...corsHeaders, 'Content-Type': 'text/html' } 
      })
    }

    // Handle GET request - show consent form
    if (req.method === 'GET') {
      return new Response(`
        <!DOCTYPE html>
        <html>
        <head>
          <title>PiggyBong Parental Consent</title>
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <style>
            body { 
              font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; 
              line-height: 1.6; margin: 0; padding: 20px; background: #f5f5f5;
            }
            .container { max-width: 700px; margin: 0 auto; background: white; border-radius: 8px; overflow: hidden; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
            .header { background: linear-gradient(135deg, #5D2CEE 0%, #8B55ED 100%); color: white; padding: 30px; text-align: center; }
            .content { padding: 30px; }
            .info-box { background: #f8f9fa; padding: 20px; border-left: 4px solid #5D2CEE; margin: 20px 0; border-radius: 4px; }
            .data-list { background: #fff; border: 1px solid #ddd; padding: 15px; border-radius: 4px; }
            .consent-actions { text-align: center; margin: 30px 0; }
            .btn { 
              display: inline-block; padding: 12px 24px; margin: 10px; text-decoration: none; 
              border-radius: 6px; font-weight: 500; border: none; cursor: pointer; font-size: 16px;
            }
            .btn-approve { background: #28a745; color: white; }
            .btn-deny { background: #dc3545; color: white; }
            .btn:hover { opacity: 0.9; }
            .child-info { background: #e7f3ff; padding: 15px; border-radius: 4px; margin: 15px 0; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h1>🐷 PiggyBong</h1>
              <h2>Parental Consent Request</h2>
            </div>
            <div class="content">
              <div class="child-info">
                <h3>👤 Child Information</h3>
                <p><strong>Name:</strong> ${consentRequest.child_name}</p>
                <p><strong>Age:</strong> Under 13 years old</p>
                <p><strong>Request Date:</strong> ${new Date(consentRequest.created_at).toLocaleDateString()}</p>
              </div>

              <h3>📋 What is PiggyBong?</h3>
              <p>PiggyBong is a K-pop spending tracker that helps fans manage their money responsibly while enjoying their hobby. It teaches budgeting skills and prevents overspending on concerts, albums, and merchandise.</p>

              <div class="info-box">
                <h4>🔒 Privacy Protection for Your Child</h4>
                <p>We take children's privacy seriously and follow COPPA regulations:</p>
                <ul>
                  <li>✅ <strong>Limited data collection</strong> - Only spending amounts and artist preferences</li>
                  <li>✅ <strong>No personal information</strong> - No full names, addresses, or phone numbers</li>
                  <li>✅ <strong>No targeted advertising</strong> - Your child won't see ads</li>
                  <li>✅ <strong>Secure storage</strong> - All data is encrypted and protected</li>
                  <li>✅ <strong>Parental control</strong> - You can request data deletion anytime</li>
                </ul>
              </div>

              <div class="data-list">
                <h4>📊 Data We Will Collect:</h4>
                <ul>
                  <li>Spending amounts and categories (albums, concerts, merchandise)</li>
                  <li>Favorite K-pop artists</li>
                  <li>Budget goals and savings progress</li>
                  <li>Achievement badges and milestones</li>
                </ul>
                
                <h4>🚫 Data We Will NOT Collect:</h4>
                <ul>
                  <li>Full name, address, or phone number</li>
                  <li>Photos or videos</li>
                  <li>Location information</li>
                  <li>Social media profiles</li>
                  <li>Payment or credit card information</li>
                </ul>
              </div>

              <div class="info-box">
                <h4>👨‍👩‍👧‍👦 Your Parental Rights</h4>
                <ul>
                  <li>📧 <strong>Contact us anytime:</strong> privacy@piggybong.app</li>
                  <li>📋 <strong>Review data:</strong> Request to see what data we have</li>
                  <li>🗑️ <strong>Delete data:</strong> Request immediate deletion of your child's account</li>
                  <li>✋ <strong>Stop collection:</strong> Disable data collection features</li>
                  <li>📞 <strong>Support:</strong> Get help with privacy concerns</li>
                </ul>
              </div>

              <div class="consent-actions">
                <h3>📝 Your Decision</h3>
                <p>Do you give permission for <strong>${consentRequest.child_name}</strong> to use PiggyBong?</p>
                
                <form method="POST" style="display: inline;">
                  <input type="hidden" name="token" value="${token}">
                  <input type="hidden" name="action" value="approve">
                  <button type="submit" class="btn btn-approve">
                    ✅ Yes, I Give Permission
                  </button>
                </form>
                
                <form method="POST" style="display: inline;">
                  <input type="hidden" name="token" value="${token}">
                  <input type="hidden" name="action" value="deny">
                  <button type="submit" class="btn btn-deny">
                    ❌ No, I Don't Give Permission
                  </button>
                </form>
              </div>

              <div style="margin-top: 40px; padding-top: 20px; border-top: 1px solid #eee; font-size: 14px; color: #666;">
                <p><strong>Questions or concerns?</strong> Contact us at <a href="mailto:privacy@piggybong.app">privacy@piggybong.app</a></p>
                <p>This consent request expires on ${expiresAt.toLocaleDateString()}.</p>
                <p>PiggyBong complies with COPPA (Children's Online Privacy Protection Act) regulations.</p>
              </div>
            </div>
          </div>
        </body>
        </html>
      `, { 
        status: 200, 
        headers: { ...corsHeaders, 'Content-Type': 'text/html' } 
      })
    }

    // Handle POST request - process consent decision
    if (req.method === 'POST') {
      const formData = await req.formData()
      const formToken = formData.get('token')
      const formAction = formData.get('action')

      if (formToken !== token) {
        throw new Error('Token mismatch')
      }

      const isApproved = formAction === 'approve'
      const newStatus = isApproved ? 'approved' : 'denied'

      // Update consent request status
      const { error: updateError } = await supabase
        .from('parental_consent_requests')
        .update({ 
          status: newStatus,
          decided_at: new Date().toISOString(),
          parent_decision: formAction 
        })
        .eq('consent_token', token)

      if (updateError) {
        throw new Error('Failed to update consent status')
      }

      // Show success/denial page
      if (isApproved) {
        return new Response(`
          <!DOCTYPE html>
          <html>
          <head>
            <title>Consent Approved</title>
            <style>
              body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; padding: 40px; text-align: center; }
              .container { max-width: 500px; margin: 0 auto; }
              .success { color: #28a745; background: #d4edda; padding: 20px; border-radius: 8px; }
            </style>
          </head>
          <body>
            <div class="container">
              <div class="success">
                <h1>✅ Permission Granted</h1>
                <p>Thank you! <strong>${consentRequest.child_name}</strong> can now use PiggyBong.</p>
              </div>
              <p>Your child will be notified that they can start using the app.</p>
              <p>Remember, you can contact us anytime at <a href="mailto:privacy@piggybong.app">privacy@piggybong.app</a></p>
            </div>
          </body>
          </html>
        `, { 
          status: 200, 
          headers: { ...corsHeaders, 'Content-Type': 'text/html' } 
        })
      } else {
        return new Response(`
          <!DOCTYPE html>
          <html>
          <head>
            <title>Permission Denied</title>
            <style>
              body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; padding: 40px; text-align: center; }
              .container { max-width: 500px; margin: 0 auto; }
              .info { color: #856404; background: #fff3cd; padding: 20px; border-radius: 8px; }
            </style>
          </head>
          <body>
            <div class="container">
              <div class="info">
                <h1>❌ Permission Not Granted</h1>
                <p>We understand. <strong>${consentRequest.child_name}</strong> will not be able to use PiggyBong.</p>
              </div>
              <p>No data has been collected, and no account has been created.</p>
              <p>If you change your mind later, your child can sign up again.</p>
              <p>Questions? Contact us at <a href="mailto:privacy@piggybong.app">privacy@piggybong.app</a></p>
            </div>
          </body>
          </html>
        `, { 
          status: 200, 
          headers: { ...corsHeaders, 'Content-Type': 'text/html' } 
        })
      }
    }

  } catch (error) {
    console.error('Error:', error)
    return new Response(`
      <!DOCTYPE html>
      <html>
      <head><title>Error</title></head>
      <body>
        <h1>Error</h1>
        <p>An error occurred processing your consent request.</p>
        <p>Please contact <a href="mailto:privacy@piggybong.app">privacy@piggybong.app</a> for help.</p>
      </body>
      </html>
    `, { 
      status: 500, 
      headers: { ...corsHeaders, 'Content-Type': 'text/html' } 
    })
  }
})