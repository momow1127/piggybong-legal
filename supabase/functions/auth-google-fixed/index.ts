import { serve } from "https://deno.land/std@0.224.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface GoogleAuthRequest {
  idToken: string
  accessToken?: string
  nonce?: string
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

    const { idToken, accessToken, nonce } = await req.json() as GoogleAuthRequest

    console.log('🔍 Google Sign In with Supabase OAuth started')
    console.log('📝 Request data:', { hasToken: !!idToken, hasAccess: !!accessToken, hasNonce: !!nonce })

    // Use Supabase's built-in Google OAuth flow
    const { data: authData, error: authError } = await supabase.auth.signInWithIdToken({
      provider: 'google',
      token: idToken,
      nonce: nonce, // Include nonce for proper validation
      access_token: accessToken, // Optional access token
      options: {
        skipHttpRefreshToken: true
      }
    })

    if (authError) {
      console.error('❌ Supabase Google OAuth error:', authError)
      throw new Error(`Google OAuth failed: ${authError.message}`)
    }

    if (!authData.user) {
      throw new Error('No user data returned from Google OAuth')
    }

    console.log('✅ Google OAuth successful:', { 
      userId: authData.user.id, 
      email: authData.user.email,
      provider: authData.user.app_metadata?.provider
    })

    // Extract display name from user metadata
    const displayName = authData.user.user_metadata?.full_name || 
                        authData.user.user_metadata?.name || 
                        authData.user.user_metadata?.given_name || 
                        'Fan User'
    
    const profilePicture = authData.user.user_metadata?.avatar_url || 
                          authData.user.user_metadata?.picture

    console.log('👤 User info extracted:', { 
      userId: authData.user.id,
      email: authData.user.email, 
      displayName,
      hasProfilePicture: !!profilePicture
    })

    // Check if this is a new user by looking for existing profile
    const { data: existingProfile, error: profileError } = await supabase
      .from('users')
      .select('*')
      .eq('email', authData.user.email)
      .single()

    let isNewUser = !existingProfile

    if (isNewUser) {
      // Create user profile
      const { error: createError } = await supabase
        .from('users')
        .insert({
          id: authData.user.id, // Use the auth user ID
          name: displayName,
          email: authData.user.email!,
          monthly_budget: 0,
          google_user_id: authData.user.user_metadata?.sub,
          auth_provider: 'google',
          email_verified: authData.user.email_confirmed_at ? true : false,
          profile_picture_url: profilePicture,
          last_login_at: new Date().toISOString()
        })

      if (createError) {
        console.error('❌ Error creating user profile:', createError)
        throw new Error('Failed to create user profile')
      }

      console.log('✅ New user profile created')
    } else {
      // Update existing user login timestamp and profile picture
      const { error: updateError } = await supabase
        .from('users')
        .update({ 
          last_login_at: new Date().toISOString(),
          name: displayName, // Update name in case it changed
          profile_picture_url: profilePicture // Update profile picture
        })
        .eq('id', authData.user.id)

      if (updateError) {
        console.error('❌ Error updating user profile:', updateError)
      } else {
        console.log('✅ Existing user profile updated')
      }
    }

    // Return success response with session data
    return new Response(
      JSON.stringify({
        success: true,
        userId: authData.user.id,
        email: authData.user.email,
        displayName: displayName,
        profilePicture: profilePicture,
        isNewUser: isNewUser,
        session: {
          access_token: authData.session?.access_token,
          refresh_token: authData.session?.refresh_token,
          expires_at: authData.session?.expires_at,
          user: authData.user
        }
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
  "accessToken": "ya29.a0ARrdaM...", // Optional
  "nonce": "abc123def456..." // REQUIRED if nonce was used in OAuth flow
}

Response:
{
  "success": true,
  "userId": "uuid-here",
  "email": "john.doe@gmail.com", 
  "displayName": "John Doe",
  "profilePicture": "https://lh3.googleusercontent.com/...",
  "isNewUser": true,
  "session": {
    "access_token": "eyJhbGciOiJIUzI1NiIs...",
    "refresh_token": "abc123...",
    "expires_at": 1640995200,
    "user": { ... }
  }
}
*/