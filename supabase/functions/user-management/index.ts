import { serve } from "https://deno.land/std@0.224.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface CreateUserRequest {
  email: string
  name: string
  monthlyBudget?: number
  authProvider: 'email' | 'apple' | 'google'
  emailVerified?: boolean
}

interface UpdateUserRequest {
  userId: string
  name?: string
  monthlyBudget?: number
  emailVerified?: boolean
}

interface DeleteUserRequest {
  userId: string
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

    const url = new URL(req.url)
    const action = url.searchParams.get('action')

    switch (action) {
      case 'create':
        return await handleCreateUser(req, supabase)
      case 'update':
        return await handleUpdateUser(req, supabase)
      case 'delete':
        return await handleDeleteUser(req, supabase)
      case 'get':
        return await handleGetUser(req, supabase)
      case 'verify-email':
        return await handleVerifyEmail(req, supabase)
      default:
        throw new Error('Invalid action. Supported: create, update, delete, get, verify-email')
    }

  } catch (error) {
    console.error('❌ User management error:', error)
    
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message || 'User management operation failed'
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      }
    )
  }
})

async function handleCreateUser(req: Request, supabase: any) {
  const { email, name, monthlyBudget = 0, authProvider, emailVerified = false } = await req.json() as CreateUserRequest

  console.log('👤 Creating user:', { email, name, authProvider })

  // Check if user already exists
  const { data: existingUser } = await supabase
    .from('users')
    .select('id')
    .eq('email', email)
    .single()

  if (existingUser) {
    throw new Error('User already exists with this email')
  }

  // Create new user
  const { data: newUser, error: createError } = await supabase
    .from('users')
    .insert({
      name: name,
      email: email,
      monthly_budget: monthlyBudget,
      auth_provider: authProvider,
      email_verified: emailVerified,
      created_at: new Date().toISOString(),
      last_login_at: new Date().toISOString()
    })
    .select()
    .single()

  if (createError || !newUser) {
    console.error('❌ Error creating user:', createError)
    throw new Error('Failed to create user account')
  }

  // If email auth, send verification email
  if (authProvider === 'email' && !emailVerified) {
    const { error: emailError } = await supabase.auth.admin.generateLink({
      type: 'signup',
      email: email,
      password: 'temp-password', // Will be reset on verification
      options: {
        redirectTo: `${Deno.env.get('SUPABASE_URL')}/auth/v1/verify`,
      }
    })

    if (emailError) {
      console.warn('⚠️ Failed to send verification email:', emailError)
      // Don't fail user creation if email fails
    }
  }

  console.log('✅ User created successfully:', newUser.id)

  return new Response(
    JSON.stringify({
      success: true,
      user: {
        id: newUser.id,
        email: newUser.email,
        name: newUser.name,
        monthlyBudget: newUser.monthly_budget,
        emailVerified: newUser.email_verified,
        createdAt: newUser.created_at
      }
    }),
    {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 201,
    }
  )
}

async function handleUpdateUser(req: Request, supabase: any) {
  const { userId, name, monthlyBudget, emailVerified } = await req.json() as UpdateUserRequest

  console.log('📝 Updating user:', userId)

  const updateData: any = {
    updated_at: new Date().toISOString()
  }

  if (name !== undefined) updateData.name = name
  if (monthlyBudget !== undefined) updateData.monthly_budget = monthlyBudget
  if (emailVerified !== undefined) updateData.email_verified = emailVerified

  const { data: updatedUser, error: updateError } = await supabase
    .from('users')
    .update(updateData)
    .eq('id', userId)
    .select()
    .single()

  if (updateError || !updatedUser) {
    console.error('❌ Error updating user:', updateError)
    throw new Error('Failed to update user')
  }

  console.log('✅ User updated successfully:', userId)

  return new Response(
    JSON.stringify({
      success: true,
      user: {
        id: updatedUser.id,
        email: updatedUser.email,
        name: updatedUser.name,
        monthlyBudget: updatedUser.monthly_budget,
        emailVerified: updatedUser.email_verified,
        updatedAt: updatedUser.updated_at
      }
    }),
    {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    }
  )
}

async function handleDeleteUser(req: Request, supabase: any) {
  const { userId } = await req.json() as DeleteUserRequest

  console.log('🗑️ Deleting user:', userId)

  // Delete user's related data first
  await supabase.from('user_goals').delete().eq('user_id', userId)
  await supabase.from('user_artists').delete().eq('user_id', userId)
  await supabase.from('user_preferences').delete().eq('user_id', userId)

  // Delete the user
  const { error: deleteError } = await supabase
    .from('users')
    .delete()
    .eq('id', userId)

  if (deleteError) {
    console.error('❌ Error deleting user:', deleteError)
    throw new Error('Failed to delete user')
  }

  console.log('✅ User deleted successfully:', userId)

  return new Response(
    JSON.stringify({
      success: true,
      message: 'User account deleted successfully'
    }),
    {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    }
  )
}

async function handleGetUser(req: Request, supabase: any) {
  const url = new URL(req.url)
  const userId = url.searchParams.get('userId')
  const email = url.searchParams.get('email')

  if (!userId && !email) {
    throw new Error('Either userId or email parameter is required')
  }

  console.log('👀 Getting user:', userId || email)

  let query = supabase.from('users').select('*')

  if (userId) {
    query = query.eq('id', userId)
  } else {
    query = query.eq('email', email)
  }

  const { data: user, error } = await query.single()

  if (error || !user) {
    throw new Error('User not found')
  }

  return new Response(
    JSON.stringify({
      success: true,
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        monthlyBudget: user.monthly_budget,
        emailVerified: user.email_verified,
        authProvider: user.auth_provider,
        createdAt: user.created_at,
        lastLoginAt: user.last_login_at
      }
    }),
    {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    }
  )
}

async function handleVerifyEmail(req: Request, supabase: any) {
  const { email } = await req.json()

  console.log('✉️ Verifying email for:', email)

  const { error: updateError } = await supabase
    .from('users')
    .update({ 
      email_verified: true,
      updated_at: new Date().toISOString()
    })
    .eq('email', email)

  if (updateError) {
    console.error('❌ Error verifying email:', updateError)
    throw new Error('Failed to verify email')
  }

  console.log('✅ Email verified successfully:', email)

  return new Response(
    JSON.stringify({
      success: true,
      message: 'Email verified successfully'
    }),
    {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    }
  )
}

/* Example usage:

Create user:
POST /functions/v1/user-management?action=create
{
  "email": "user@example.com",
  "name": "Fan User",
  "monthlyBudget": 100,
  "authProvider": "email",
  "emailVerified": false
}

Update user:
POST /functions/v1/user-management?action=update
{
  "userId": "uuid-here",
  "name": "Updated Name",
  "monthlyBudget": 200
}

Get user:
GET /functions/v1/user-management?action=get&userId=uuid-here
GET /functions/v1/user-management?action=get&email=user@example.com

Delete user:
POST /functions/v1/user-management?action=delete
{
  "userId": "uuid-here"
}

Verify email:
POST /functions/v1/user-management?action=verify-email
{
  "email": "user@example.com"
}
*/