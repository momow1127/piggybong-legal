import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface GoogleTokenInfo {
  iss: string
  sub: string
  aud: string
  exp: number
  iat: number
  email: string
  email_verified: boolean
  name: string
  picture?: string
  given_name?: string
  family_name?: string
}

interface GoogleAuthRequest {
  idToken: string
  accessToken?: string
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const { idToken, accessToken } = await req.json() as GoogleAuthRequest

    console.log('🔍 Google Sign In validation started')

    // Verify Google ID token with Google's tokeninfo endpoint
    const tokenInfoResponse = await fetch(
      `https://oauth2.googleapis.com/tokeninfo?id_token=${idToken}`
    )

    if (!tokenInfoResponse.ok) {
      throw new Error('Invalid Google ID token')
    }

    const tokenInfo = await tokenInfoResponse.json() as GoogleTokenInfo

    console.log('🔐 Token info:', { 
      sub: tokenInfo.sub,
      email: tokenInfo.email,
      name: tokenInfo.name,
      email_verified: tokenInfo.email_verified 
    })

    // Validate token
    if (tokenInfo.iss !== 'https://accounts.google.com' && tokenInfo.iss !== 'accounts.google.com') {
      throw new Error('Invalid token issuer')
    }

    if (tokenInfo.exp < Date.now() / 1000) {
      throw new Error('Token expired')
    }

    if (!tokenInfo.email_verified) {
      throw new Error('Email not verified by Google')
    }

    // Extract user information
    const googleUserId = tokenInfo.sub
    const email = tokenInfo.email
    const displayName = tokenInfo.name || tokenInfo.given_name || 'Fan User'
    const profilePicture = tokenInfo.picture

    console.log('👤 User info extracted:', { googleUserId, email, displayName })

    // Check if user already exists
    const { data: existingUser, error: userError } = await supabase
      .from('users')
      .select('*')
      .eq('email', email)
      .single()

    let userId: string

    if (existingUser) {
      // User exists, update login timestamp and Google info
      userId = existingUser.id
      
      const { error: updateError } = await supabase
        .from('users')
        .update({ 
          last_login_at: new Date().toISOString(),
          google_user_id: googleUserId,
          profile_picture_url: profilePicture
        })
        .eq('id', userId)

      if (updateError) {
        console.error('❌ Error updating user:', updateError)
        throw new Error('Failed to update user login')
      }

      console.log('✅ Existing user logged in:', userId)
    } else {
      // Create new user
      const { data: newUser, error: createError } = await supabase
        .from('users')
        .insert({
          name: displayName,
          email: email,
          monthly_budget: 0,
          google_user_id: googleUserId,
          auth_provider: 'google',
          email_verified: tokenInfo.email_verified,
          profile_picture_url: profilePicture,
          last_login_at: new Date().toISOString()
        })
        .select()
        .single()

      if (createError || !newUser) {
        console.error('❌ Error creating user:', createError)
        throw new Error('Failed to create user account')
      }

      userId = newUser.id
      console.log('✅ New user created:', userId)
    }

    // Generate session for the user
    const { data: authData, error: authError } = await supabase.auth.admin.generateLink({
      type: 'magiclink',
      email: email,
      options: {
        redirectTo: `${Deno.env.get('SUPABASE_URL')}/auth/v1/verify`,
      }
    })

    if (authError) {
      console.error('❌ Auth session error:', authError)
      throw new Error('Failed to create auth session')
    }

    // Return success response
    return new Response(
      JSON.stringify({
        success: true,
        userId: userId,
        email: email,
        displayName: displayName,
        profilePicture: profilePicture,
        isNewUser: !existingUser,
        sessionUrl: authData.properties?.action_link
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    )

  } catch (error) {
    console.error('❌ Google Sign In validation failed:', error)
    
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message || 'Google Sign In validation failed'
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      }
    )
  }
})

/* Example usage from iOS:
POST /functions/v1/auth-google
{
  "idToken": "eyJhbGciOiJSUzI1NiIs...",
  "accessToken": "ya29.a0ARrdaM..." // Optional
}

Response:
{
  "success": true,
  "userId": "uuid-here",
  "email": "john.doe@gmail.com", 
  "displayName": "John Doe",
  "profilePicture": "https://lh3.googleusercontent.com/...",
  "isNewUser": true,
  "sessionUrl": "https://your-project.supabase.co/auth/v1/verify?token=..."
}
*/