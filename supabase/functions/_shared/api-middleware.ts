// Enhanced API middleware for production-scale PiggyBong
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

export const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-api-version',
  'Access-Control-Allow-Methods': 'POST, GET, OPTIONS, PUT, DELETE',
}

// Rate limiting configuration for 100K+ users
export const RATE_LIMITS = {
  ANONYMOUS: { requests: 10, window: 60000 }, // 10 req/min for anonymous
  FREE: { requests: 100, window: 60000 },     // 100 req/min for free users
  PAID: { requests: 500, window: 60000 },     // 500 req/min for paid users
  ADMIN: { requests: 1000, window: 60000 },   // 1000 req/min for admins
}

// Global rate limiter store (use Redis in production)
const rateLimitStore = new Map()

interface RateLimitResult {
  allowed: boolean
  remaining: number
  resetTime: number
}

export async function checkRateLimit(
  userId: string | null, 
  userTier: 'anonymous' | 'free' | 'paid' | 'admin' = 'anonymous'
): Promise<RateLimitResult> {
  const key = userId || 'anonymous'
  const limit = RATE_LIMITS[userTier.toUpperCase() as keyof typeof RATE_LIMITS]
  
  const now = Date.now()
  const windowStart = now - limit.window
  
  let userRequests = rateLimitStore.get(key) || []
  
  // Clean old requests outside the window
  userRequests = userRequests.filter((timestamp: number) => timestamp > windowStart)
  
  const allowed = userRequests.length < limit.requests
  
  if (allowed) {
    userRequests.push(now)
    rateLimitStore.set(key, userRequests)
  }
  
  return {
    allowed,
    remaining: Math.max(0, limit.requests - userRequests.length),
    resetTime: now + limit.window
  }
}

export interface AuthenticatedRequest {
  user: any
  userTier: 'free' | 'paid' | 'admin'
}

export async function authenticateRequest(req: Request): Promise<AuthenticatedRequest> {
  const supabaseUrl = Deno.env.get('SUPABASE_URL')!
  const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  const supabase = createClient(supabaseUrl, supabaseServiceKey)

  const authHeader = req.headers.get('Authorization')
  if (!authHeader) {
    throw new Error('Authentication required')
  }

  const token = authHeader.replace('Bearer ', '')
  const { data: { user }, error: authError } = await supabase.auth.getUser(token)
  
  if (authError || !user) {
    throw new Error('Invalid authentication')
  }

  // Get user subscription tier for rate limiting
  const { data: subscription } = await supabase
    .from('user_subscriptions')
    .select('plan_type')
    .eq('user_id', user.id)
    .eq('status', 'active')
    .single()

  const userTier = subscription?.plan_type || 'free'

  return { user, userTier }
}

export function createAPIResponse<T>(
  data: T,
  status: number = 200,
  metadata?: Record<string, any>
): Response {
  const responseBody = {
    success: status < 400,
    data,
    metadata: {
      timestamp: new Date().toISOString(),
      version: 'v1',
      ...metadata
    }
  }

  return new Response(JSON.stringify(responseBody), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' }
  })
}

export function createErrorResponse(
  error: string | Error,
  status: number = 500,
  code?: string
): Response {
  const errorMessage = error instanceof Error ? error.message : error
  
  console.error('API Error:', { error: errorMessage, status, code })
  
  return new Response(JSON.stringify({
    success: false,
    error: {
      message: errorMessage,
      code: code || 'INTERNAL_ERROR',
      timestamp: new Date().toISOString()
    }
  }), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' }
  })
}

// API versioning middleware
export function validateAPIVersion(req: Request, supportedVersions: string[] = ['v1']): boolean {
  const apiVersion = req.headers.get('x-api-version') || 'v1'
  return supportedVersions.includes(apiVersion)
}

// Request validation middleware
export async function validateRequestBody<T>(
  req: Request,
  schema: (data: any) => data is T
): Promise<T> {
  try {
    const body = await req.json()
    
    if (!schema(body)) {
      throw new Error('Invalid request body format')
    }
    
    return body
  } catch (error) {
    throw new Error('Invalid JSON in request body')
  }
}

// Caching middleware for expensive operations
export async function getCachedResult<T>(
  supabase: any,
  key: string,
  ttlSeconds: number = 3600
): Promise<T | null> {
  try {
    const { data, error } = await supabase
      .from('api_cache')
      .select('data, created_at')
      .eq('cache_key', key)
      .single()

    if (error || !data) return null

    const age = (Date.now() - new Date(data.created_at).getTime()) / 1000
    if (age > ttlSeconds) {
      // Cache expired
      await supabase.from('api_cache').delete().eq('cache_key', key)
      return null
    }

    return data.data as T
  } catch {
    return null
  }
}

export async function setCachedResult<T>(
  supabase: any,
  key: string,
  data: T
): Promise<void> {
  try {
    await supabase
      .from('api_cache')
      .upsert({
        cache_key: key,
        data: data,
        created_at: new Date().toISOString()
      })
  } catch (error) {
    console.error('Cache write error:', error)
  }
}

// Health check endpoint utilities
export interface HealthCheckResult {
  status: 'healthy' | 'degraded' | 'unhealthy'
  services: Record<string, { status: string; latency?: number }>
  timestamp: string
}

export async function performHealthCheck(supabase: any): Promise<HealthCheckResult> {
  const checks = []
  const startTime = Date.now()

  // Database connectivity check
  checks.push(
    supabase
      .from('users')
      .select('id')
      .limit(1)
      .then(() => ({ service: 'database', status: 'healthy', latency: Date.now() - startTime }))
      .catch(() => ({ service: 'database', status: 'unhealthy' }))
  )

  // External API checks
  checks.push(
    fetch('https://api.spotify.com/v1/', { method: 'GET' })
      .then(() => ({ service: 'spotify', status: 'healthy' }))
      .catch(() => ({ service: 'spotify', status: 'unhealthy' }))
  )

  const results = await Promise.allSettled(checks)
  const services: Record<string, any> = {}
  
  results.forEach((result, index) => {
    if (result.status === 'fulfilled') {
      const check = result.value
      services[check.service] = {
        status: check.status,
        ...(check.latency && { latency: check.latency })
      }
    }
  })

  const overallStatus = Object.values(services).every(s => s.status === 'healthy') 
    ? 'healthy' 
    : Object.values(services).some(s => s.status === 'healthy') 
    ? 'degraded' 
    : 'unhealthy'

  return {
    status: overallStatus,
    services,
    timestamp: new Date().toISOString()
  }
}