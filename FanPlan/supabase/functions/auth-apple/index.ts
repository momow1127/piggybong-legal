import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { decode } from "https://deno.land/x/djwt@v2.8/mod.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface AppleTokenPayload {
  iss: string
  aud: string
  exp: number
  iat: number
  sub: string
  email?: string
  email_verified?: boolean
}

interface AppleAuthRequest {
  idToken: string
  authorizationCode: string
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

    const { idToken, authorizationCode, user, fullName } = await req.json() as AppleAuthRequest

    console.log('🍎 Apple Sign In validation started')

    // Decode Apple ID token (without verification for now - in production you'd verify signature)
    const [header, payload, signature] = decode(idToken)
    const tokenPayload = payload as AppleTokenPayload

    console.log('🔐 Token payload:', { 
      sub: tokenPayload.sub,
      email: tokenPayload.email,
      iss: tokenPayload.iss,
      aud: tokenPayload.aud 
    })

    // Validate token basics
    if (tokenPayload.iss !== 'https://appleid.apple.com') {
      throw new Error('Invalid token issuer')
    }

    if (tokenPayload.exp < Date.now() / 1000) {
      throw new Error('Token expired')
    }

    // Extract user information
    const appleUserId = tokenPayload.sub
    const email = tokenPayload.email || user?.email || `${appleUserId}@appleid.private`
    
    // Create display name from available data
    let displayName = 'Fan User'
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

    console.log('👤 User info extracted:', { appleUserId, email, displayName })

    // Check if user already exists
    const { data: existingUser, error: userError } = await supabase
      .from('users')
      .select('*')
      .eq('email', email)
      .single()

    let userId: string

    if (existingUser) {
      // User exists, update login timestamp
      userId = existingUser.id
      
      const { error: updateError } = await supabase
        .from('users')
        .update({ 
          last_login_at: new Date().toISOString(),
          apple_user_id: appleUserId
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
          apple_user_id: appleUserId,
          auth_provider: 'apple',
          email_verified: tokenPayload.email_verified || false,
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

    // Create or update user in Supabase Auth
    const { data: authData, error: authError } = await supabase.auth.admin.createUser({
      email: email,
      user_metadata: {
        provider: 'apple',
        apple_user_id: appleUserId,
        full_name: displayName,
        email_verified: tokenPayload.email_verified || false
      },
      email_confirm: true // Skip email confirmation for Apple users
    })

    if (authError && authError.message !== 'User already registered') {
      console.error('❌ Auth user creation error:', authError)
      throw new Error('Failed to create auth user')
    }
    
    // Generate access token for immediate login
    const { data: sessionData, error: sessionError } = await supabase.auth.admin.generateLink({
      type: 'signup',
      email: email,
      options: {
        redirectTo: `${Deno.env.get('SUPABASE_URL')}/auth/v1/callback`
      }
    })
    
    if (sessionError) {
      console.error('❌ Session generation error:', sessionError)
      throw new Error('Failed to generate session')
    }

    // Return success response
    return new Response(
      JSON.stringify({
        success: true,
        userId: userId,
        email: email,
        displayName: displayName,
        isNewUser: !existingUser,
        sessionUrl: sessionData.properties?.action_link,
        accessToken: authData?.session?.access_token
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
  "authorizationCode": "c1234567890abcdef...",
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
  "sessionUrl": "https://your-project.supabase.co/auth/v1/verify?token=..."
}
*/