import { serve } from "https://deno.land/std@0.224.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface AppleAuthRequest {
  idToken: string
  authorizationCode?: string
  nonce?: string
  user?: {
    name?: {
      firstName?: string
      lastName?: string
    }
    email?: string
  }
  fullName?: {
    givenName?: string
    familyName?: string
  }
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

    const { idToken, nonce, user, fullName } = await req.json() as AppleAuthRequest

    console.log('🍎 Apple Sign In with Supabase OAuth started')
    console.log('📝 Request data:', { hasToken: !!idToken, hasNonce: !!nonce, hasUser: !!user })

    // Use Supabase's built-in Apple OAuth flow
    const { data: authData, error: authError } = await supabase.auth.signInWithIdToken({
      provider: 'apple',
      token: idToken,
      nonce: nonce, // Include nonce for proper validation
      options: {
        skipHttpRefreshToken: true
      }
    })

    if (authError) {
      console.error('❌ Supabase Apple OAuth error:', authError)
      throw new Error(`Apple OAuth failed: ${authError.message}`)
    }

    if (!authData.user) {
      throw new Error('No user data returned from Apple OAuth')
    }

    console.log('✅ Apple OAuth successful:', { 
      userId: authData.user.id, 
      email: authData.user.email,
      provider: authData.user.app_metadata?.provider
    })

    // Extract display name from user data or fallback
    let displayName = authData.user.user_metadata?.full_name || authData.user.user_metadata?.name || 'Fan User'
    
    // Try to get name from the request data if not in metadata
    if (displayName === 'Fan User') {
      if (fullName?.givenName) {
        displayName = fullName.givenName
        if (fullName.familyName) {
          displayName += ` ${fullName.familyName}`
        }
      } else if (user?.name?.firstName) {
        displayName = user.name.firstName
        if (user.name.lastName) {
          displayName += ` ${user.name.lastName}`
        }
      }
    }

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
          apple_user_id: authData.user.user_metadata?.sub,
          auth_provider: 'apple',
          email_verified: authData.user.email_confirmed_at ? true : false,
          last_login_at: new Date().toISOString()
        })

      if (createError) {
        console.error('❌ Error creating user profile:', createError)
        throw new Error('Failed to create user profile')
      }

      console.log('✅ New user profile created')
    } else {
      // Update existing user login timestamp
      const { error: updateError } = await supabase
        .from('users')
        .update({ 
          last_login_at: new Date().toISOString(),
          name: displayName // Update name in case it changed
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
    console.error('❌ Apple Sign In validation failed:', error)
    
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message || 'Apple Sign In validation failed'
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      }
    )
  }
})

/* Example usage from iOS:
POST /functions/v1/auth-apple
{
  "idToken": "eyJhbGciOiJSUzI1NiIs...",
  "nonce": "abc123def456...", // REQUIRED - matches the nonce used in iOS
  "user": {
    "name": {
      "firstName": "John",
      "lastName": "Doe"
    },
    "email": "john.doe@example.com"
  }
}

Response:
{
  "success": true,
  "userId": "uuid-here",
  "email": "john.doe@example.com", 
  "displayName": "John Doe",
  "isNewUser": false,
  "session": {
    "access_token": "eyJhbGciOiJIUzI1NiIs...",
    "refresh_token": "abc123...",
    "expires_at": 1640995200,
    "user": { ... }
  }
}
*/