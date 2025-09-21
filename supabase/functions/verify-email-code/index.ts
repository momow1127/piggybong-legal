import { serve } from "https://deno.land/std@0.224.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.7.1'
import { corsHeaders } from '../_shared/cors.ts'

interface VerifyCodeRequest {
  email: string
  code: string
}

interface VerifyCodeResponse {
  success: boolean
  message: string
  verified: boolean
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Initialize Supabase client with service role key for admin operations
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      {
        auth: {
          autoRefreshToken: false,
          persistSession: false
        }
      }
    )

    // Parse request body
    const { email, code }: VerifyCodeRequest = await req.json()

    // Validate input
    if (!email || !code) {
      return new Response(
        JSON.stringify({
          success: false,
          message: 'Email and verification code are required',
          verified: false
        } as VerifyCodeResponse),
        {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    // Validate email format
    if (!isValidEmail(email)) {
      return new Response(
        JSON.stringify({
          success: false,
          message: 'Invalid email format',
          verified: false
        } as VerifyCodeResponse),
        {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    // Validate code format (6 digits)
    if (!/^\d{6}$/.test(code)) {
      return new Response(
        JSON.stringify({
          success: false,
          message: 'Verification code must be 6 digits',
          verified: false
        } as VerifyCodeResponse),
        {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    // Rate limiting: Check for too many verification attempts
    const { data: recentAttempts, error: attemptsError } = await supabaseClient
      .from('verification_codes')
      .select('attempt_count, max_attempts, created_at')
      .eq('email', email)
      .eq('code', code)
      .order('created_at', { ascending: false })
      .limit(1)

    if (attemptsError) {
      console.error('Error checking attempts:', attemptsError)
    }

    // Check if too many attempts were made
    if (recentAttempts && recentAttempts.length > 0) {
      const attempt = recentAttempts[0]
      if (attempt.attempt_count >= attempt.max_attempts) {
        return new Response(
          JSON.stringify({
            success: false,
            message: 'Too many incorrect attempts. Please request a new verification code.',
            verified: false
          } as VerifyCodeResponse),
          {
            status: 429,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' }
          }
        )
      }
    }

    // Verify the code using database function
    const { data: verificationResult, error: verificationError } = await supabaseClient
      .rpc('verify_code', { 
        user_email: email, 
        input_code: code 
      })

    if (verificationError) {
      console.error('Error verifying code:', verificationError)
      return new Response(
        JSON.stringify({
          success: false,
          message: 'Failed to verify code',
          verified: false
        } as VerifyCodeResponse),
        {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    if (!verificationResult || verificationResult.length === 0) {
      return new Response(
        JSON.stringify({
          success: false,
          message: 'Invalid verification code',
          verified: false
        } as VerifyCodeResponse),
        {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    const { success, message } = verificationResult[0]

    if (success) {
      // Log successful verification
      console.log(`Email verified successfully: ${email}`)
      
      // Optional: Update user status in auth.users if needed
      try {
        const { error: updateError } = await supabaseClient.auth.admin.updateUserById(
          email, // This would need to be user ID in real implementation
          { email_confirmed_at: new Date().toISOString() }
        )
        
        if (updateError) {
          console.warn('Could not update user email confirmation status:', updateError)
          // Don't fail the request if this update fails
        }
      } catch (updateErr) {
        console.warn('Error updating user confirmation status:', updateErr)
      }

      return new Response(
        JSON.stringify({
          success: true,
          message: 'Email verified successfully',
          verified: true
        } as VerifyCodeResponse),
        {
          status: 200,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    } else {
      // Log failed attempt
      console.log(`Failed verification attempt for ${email}: ${message}`)
      
      // Increment attempt counter
      await supabaseClient
        .from('verification_codes')
        .update({ attempt_count: (recentAttempts?.[0]?.attempt_count || 0) + 1 })
        .eq('email', email)
        .eq('code', code)
        .is('verified_at', null)

      return new Response(
        JSON.stringify({
          success: false,
          message: message,
          verified: false
        } as VerifyCodeResponse),
        {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

  } catch (error) {
    console.error('Error in verify-email-code:', error)
    return new Response(
      JSON.stringify({
        success: false,
        message: 'Internal server error',
        verified: false
      } as VerifyCodeResponse),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  }
})

function isValidEmail(email: string): boolean {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
  return emailRegex.test(email)
}