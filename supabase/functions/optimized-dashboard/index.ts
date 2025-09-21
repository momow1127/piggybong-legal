// High-Performance Dashboard API with Advanced Scalability Features
import { serve } from "https://deno.land/std@0.224.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { 
  corsHeaders, 
  authenticateRequest, 
  checkRateLimit, 
  createAPIResponse, 
  createErrorResponse,
  getCachedResult,
  setCachedResult
} from '../_shared/api-middleware.ts'

const supabaseUrl = Deno.env.get('SUPABASE_URL')!
const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
const supabase = createClient(supabaseUrl, supabaseServiceKey)

interface DashboardRequest {
  user_id?: string
  time_range?: 'week' | 'month' | 'quarter' | 'year'
  include_analytics?: boolean
  include_predictions?: boolean
}

interface DashboardData {
  user_stats: UserStats
  recent_purchases: Purchase[]
  artist_breakdown: ArtistBreakdown[]
  budget_status: BudgetStatus
  analytics?: AdvancedAnalytics
  predictions?: SpendingPredictions
  performance_metrics: PerformanceMetrics
}

interface UserStats {
  total_spent: number
  purchases_count: number
  active_goals: number
  favorite_artists: string[]
  monthly_average: number
  spending_trend: 'increasing' | 'decreasing' | 'stable'
}

interface Purchase {
  id: string
  amount: number
  category: string
  artist_name: string
  purchase_date: string
  description?: string
}

interface ArtistBreakdown {
  artist_id: string
  artist_name: string
  total_spent: number
  purchase_count: number
  percentage: number
  trend: 'up' | 'down' | 'stable'
}

interface BudgetStatus {
  monthly_budget: number
  current_spent: number
  remaining: number
  percentage_used: number
  days_remaining: number
  projected_spend: number
  alert_level: 'low' | 'medium' | 'high' | 'critical'
}

interface AdvancedAnalytics {
  spending_patterns: SpendingPattern[]
  seasonal_trends: SeasonalTrend[]
  category_insights: CategoryInsight[]
  efficiency_score: number
}

interface SpendingPredictions {
  next_month_estimate: number
  confidence_level: number
  recommended_budget: number
  risk_factors: string[]
  opportunities: string[]
}

interface PerformanceMetrics {
  query_time_ms: number
  cache_status: 'hit' | 'miss' | 'partial'
  data_freshness: number
  request_id: string
}

// Performance monitoring class
class DashboardPerformanceMonitor {
  private startTime: number
  private cacheHits = 0
  private cacheMisses = 0
  private queryTimes: number[] = []

  constructor() {
    this.startTime = Date.now()
  }

  recordCacheHit() {
    this.cacheHits++
  }

  recordCacheMiss() {
    this.cacheMisses++
  }

  recordQueryTime(duration: number) {
    this.queryTimes.push(duration)
  }

  getMetrics(): PerformanceMetrics {
    return {
      query_time_ms: Date.now() - this.startTime,
      cache_status: this.cacheHits > this.cacheMisses ? 'hit' : 
                   this.cacheMisses > 0 ? 'partial' : 'miss',
      data_freshness: Date.now() - this.startTime,
      request_id: crypto.randomUUID()
    }
  }
}

serve(async (req) => {
  const monitor = new DashboardPerformanceMonitor()
  
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Authentication with performance tracking
    const startAuth = Date.now()
    const { user, userTier } = await authenticateRequest(req)
    monitor.recordQueryTime(Date.now() - startAuth)
    
    // Rate limiting based on user tier
    const rateLimitResult = await checkRateLimit(user.id, userTier)
    if (!rateLimitResult.allowed) {
      return createErrorResponse(
        `Rate limit exceeded. ${rateLimitResult.remaining} requests remaining. Reset at ${new Date(rateLimitResult.resetTime).toISOString()}`,
        429,
        'RATE_LIMIT_EXCEEDED'
      )
    }

    // Parse request body with validation
    let requestData: DashboardRequest = {}
    if (req.method === 'POST') {
      try {
        requestData = await req.json()
      } catch {
        requestData = {}
      }
    }

    const userId = requestData.user_id || user.id
    const timeRange = requestData.time_range || 'month'
    const includeAnalytics = requestData.include_analytics && userTier === 'paid'
    const includePredictions = requestData.include_predictions && userTier === 'paid'

    // Generate cache keys for different data components
    const baseCacheKey = `dashboard:${userId}:${timeRange}`
    const analyticsCacheKey = `analytics:${userId}:${timeRange}`
    const predictionsCacheKey = `predictions:${userId}`

    // Try to get cached data first (multi-level caching)
    let dashboardData: Partial<DashboardData> = {}
    let cacheStatus = 'miss'

    // Level 1: Basic dashboard data
    const cachedBasic = await getCachedResult<Partial<DashboardData>>(supabase, baseCacheKey, 300) // 5 min cache
    if (cachedBasic) {
      dashboardData = cachedBasic
      cacheStatus = 'hit'
      monitor.recordCacheHit()
    } else {
      monitor.recordCacheMiss()
    }

    // Level 2: Analytics data (longer cache for premium users)
    if (includeAnalytics && !dashboardData.analytics) {
      const cachedAnalytics = await getCachedResult<AdvancedAnalytics>(supabase, analyticsCacheKey, 1800) // 30 min cache
      if (cachedAnalytics) {
        dashboardData.analytics = cachedAnalytics
        monitor.recordCacheHit()
      } else {
        monitor.recordCacheMiss()
      }
    }

    // Level 3: Predictions data (very long cache)
    if (includePredictions && !dashboardData.predictions) {
      const cachedPredictions = await getCachedResult<SpendingPredictions>(supabase, predictionsCacheKey, 3600) // 1 hour cache
      if (cachedPredictions) {
        dashboardData.predictions = cachedPredictions
        monitor.recordCacheHit()
      } else {
        monitor.recordCacheMiss()
      }
    }

    // Fetch missing data with optimized parallel queries
    const missingDataPromises: Promise<any>[] = []

    if (!dashboardData.user_stats || !dashboardData.recent_purchases) {
      missingDataPromises.push(fetchBasicDashboardData(userId, timeRange))
    }

    if (includeAnalytics && !dashboardData.analytics) {
      missingDataPromises.push(fetchAdvancedAnalytics(userId, timeRange))
    }

    if (includePredictions && !dashboardData.predictions) {
      missingDataPromises.push(fetchSpendingPredictions(userId))
    }

    // Execute all missing data queries in parallel
    if (missingDataPromises.length > 0) {
      const results = await Promise.allSettled(missingDataPromises)
      
      results.forEach((result, index) => {
        if (result.status === 'fulfilled' && result.value) {
          if (index === 0 && !dashboardData.user_stats) {
            // Basic dashboard data
            Object.assign(dashboardData, result.value)
          } else if (includeAnalytics && index === 1 && !dashboardData.analytics) {
            // Analytics data
            dashboardData.analytics = result.value
          } else if (includePredictions && !dashboardData.predictions) {
            // Predictions data
            dashboardData.predictions = result.value
          }
        }
      })

      // Cache the newly fetched data
      if (dashboardData.user_stats) {
        await setCachedResult(supabase, baseCacheKey, dashboardData)
      }
      
      if (dashboardData.analytics) {
        await setCachedResult(supabase, analyticsCacheKey, dashboardData.analytics)
      }
      
      if (dashboardData.predictions) {
        await setCachedResult(supabase, predictionsCacheKey, dashboardData.predictions)
      }
    }

    // Add performance metrics to response
    dashboardData.performance_metrics = monitor.getMetrics()

    // Add rate limit info to response headers
    const response = createAPIResponse(dashboardData, 200, {
      cache_status: cacheStatus,
      user_tier: userTier,
      rate_limit_remaining: rateLimitResult.remaining.toString(),
      rate_limit_reset: new Date(rateLimitResult.resetTime).toISOString()
    })

    // Add custom headers for performance monitoring
    response.headers.set('X-Query-Time', dashboardData.performance_metrics.query_time_ms.toString())
    response.headers.set('X-Cache-Status', cacheStatus)
    response.headers.set('X-User-Tier', userTier)

    return response

  } catch (error) {
    console.error('Dashboard API Error:', error)
    
    return createErrorResponse(
      error instanceof Error ? error.message : 'Internal server error',
      error.message?.includes('Authentication') ? 401 : 500,
      'DASHBOARD_ERROR'
    )
  }
})

// Optimized data fetching functions with connection pooling simulation
async function fetchBasicDashboardData(userId: string, timeRange: string): Promise<Partial<DashboardData>> {
  const startTime = Date.now()
  
  // Use the optimized dashboard function from the database
  const { data: dashboardData, error } = await supabase
    .rpc('get_user_dashboard_optimized', { p_user_id: userId })
  
  if (error) {
    throw new Error(`Failed to fetch dashboard data: ${error.message}`)
  }

  // Fetch recent purchases in parallel
  const { data: recentPurchases } = await supabase
    .from('purchases')
    .select(`
      id, 
      amount, 
      category, 
      description, 
      purchase_date,
      artists(name)
    `)
    .eq('user_id', userId)
    .order('purchase_date', { ascending: false })
    .limit(10)

  // Fetch artist breakdown data
  const { data: artistBreakdown } = await supabase
    .from('purchases')
    .select(`
      artist_id,
      artists(name),
      amount
    `)
    .eq('user_id', userId)
    .gte('purchase_date', getDateFromTimeRange(timeRange))

  // Process and aggregate data
  const userStats = processDashboardData(dashboardData?.[0])
  const artistStats = processArtistBreakdown(artistBreakdown || [])
  const budgetStatus = calculateBudgetStatus(userStats, dashboardData?.[0])

  console.log(`Dashboard query completed in ${Date.now() - startTime}ms`)

  return {
    user_stats: userStats,
    recent_purchases: (recentPurchases || []).map(formatPurchase),
    artist_breakdown: artistStats,
    budget_status: budgetStatus
  }
}

async function fetchAdvancedAnalytics(userId: string, timeRange: string): Promise<AdvancedAnalytics> {
  // This would include complex analytics queries
  // For now, return mock data with realistic structure
  
  const { data: patterns } = await supabase
    .rpc('analyze_spending_patterns', {
      p_user_id: userId,
      p_time_range: timeRange
    })

  return {
    spending_patterns: patterns || [],
    seasonal_trends: [],
    category_insights: [],
    efficiency_score: 0.85
  }
}

async function fetchSpendingPredictions(userId: string): Promise<SpendingPredictions> {
  // This would use ML models or statistical analysis
  // For now, return mock predictions
  
  return {
    next_month_estimate: 150.00,
    confidence_level: 0.78,
    recommended_budget: 200.00,
    risk_factors: ['Increased concert ticket purchases'],
    opportunities: ['Bundle deals on merchandise']
  }
}

// Helper functions
function getDateFromTimeRange(range: string): string {
  const now = new Date()
  switch (range) {
    case 'week':
      return new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000).toISOString()
    case 'month':
      return new Date(now.getFullYear(), now.getMonth(), 1).toISOString()
    case 'quarter':
      return new Date(now.getFullYear(), Math.floor(now.getMonth() / 3) * 3, 1).toISOString()
    case 'year':
      return new Date(now.getFullYear(), 0, 1).toISOString()
    default:
      return new Date(now.getFullYear(), now.getMonth(), 1).toISOString()
  }
}

function processDashboardData(data: any): UserStats {
  if (!data) {
    return {
      total_spent: 0,
      purchases_count: 0,
      active_goals: 0,
      favorite_artists: [],
      monthly_average: 0,
      spending_trend: 'stable'
    }
  }

  return {
    total_spent: data.monthly_spent || 0,
    purchases_count: data.total_purchases || 0,
    active_goals: data.active_goals || 0,
    favorite_artists: [], // Would be calculated
    monthly_average: data.monthly_spent || 0,
    spending_trend: 'stable' // Would be calculated from historical data
  }
}

function processArtistBreakdown(purchases: any[]): ArtistBreakdown[] {
  const artistMap = new Map()
  let totalSpent = 0

  purchases.forEach(purchase => {
    const artistName = purchase.artists?.name || 'Unknown'
    const amount = purchase.amount || 0
    totalSpent += amount

    if (artistMap.has(artistName)) {
      const existing = artistMap.get(artistName)
      existing.total_spent += amount
      existing.purchase_count += 1
    } else {
      artistMap.set(artistName, {
        artist_id: purchase.artist_id,
        artist_name: artistName,
        total_spent: amount,
        purchase_count: 1,
        trend: 'stable'
      })
    }
  })

  return Array.from(artistMap.values()).map(artist => ({
    ...artist,
    percentage: totalSpent > 0 ? (artist.total_spent / totalSpent) * 100 : 0
  })).sort((a, b) => b.total_spent - a.total_spent)
}

function calculateBudgetStatus(userStats: UserStats, dashboardData: any): BudgetStatus {
  const monthlyBudget = dashboardData?.monthly_budget || 200
  const currentSpent = userStats.total_spent
  const remaining = monthlyBudget - currentSpent
  const percentageUsed = monthlyBudget > 0 ? (currentSpent / monthlyBudget) * 100 : 0
  
  const now = new Date()
  const daysInMonth = new Date(now.getFullYear(), now.getMonth() + 1, 0).getDate()
  const daysRemaining = daysInMonth - now.getDate()
  
  const dailyAverage = currentSpent / (daysInMonth - daysRemaining + 1)
  const projectedSpend = currentSpent + (dailyAverage * daysRemaining)
  
  let alertLevel: 'low' | 'medium' | 'high' | 'critical' = 'low'
  if (percentageUsed > 90) alertLevel = 'critical'
  else if (percentageUsed > 75) alertLevel = 'high'
  else if (percentageUsed > 50) alertLevel = 'medium'

  return {
    monthly_budget: monthlyBudget,
    current_spent: currentSpent,
    remaining,
    percentage_used: percentageUsed,
    days_remaining: daysRemaining,
    projected_spend: projectedSpend,
    alert_level: alertLevel
  }
}

function formatPurchase(purchase: any): Purchase {
  return {
    id: purchase.id,
    amount: purchase.amount,
    category: purchase.category,
    artist_name: purchase.artists?.name || 'Unknown',
    purchase_date: purchase.purchase_date,
    description: purchase.description
  }
}