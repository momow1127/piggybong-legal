-- Production Scalability Improvements for 100K+ Users
-- This migration adds critical performance and scalability enhancements

-- 1. API Cache table for response caching
CREATE TABLE IF NOT EXISTS api_cache (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    cache_key TEXT NOT NULL UNIQUE,
    data JSONB NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ DEFAULT NOW() + INTERVAL '1 hour'
);

-- 2. Performance monitoring table
CREATE TABLE IF NOT EXISTS performance_metrics (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    metric_name TEXT NOT NULL,
    metric_value NUMERIC NOT NULL,
    labels JSONB DEFAULT '{}',
    recorded_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Request logs for API monitoring
CREATE TABLE IF NOT EXISTS request_logs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    endpoint TEXT NOT NULL,
    method TEXT NOT NULL,
    status_code INTEGER NOT NULL,
    response_time_ms INTEGER,
    user_agent TEXT,
    ip_address INET,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Database connection pooling optimization
-- Optimize existing tables for high concurrency

-- Add partial indexes for active data only (most queries focus on active records)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_user_artists_active_user 
ON user_artists(user_id, created_at DESC) 
WHERE is_active = TRUE;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_goals_active_user 
ON goals(user_id, target_date) 
WHERE is_active = TRUE;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_purchases_recent_user 
ON purchases(user_id, purchase_date DESC) 
WHERE purchase_date >= CURRENT_DATE - INTERVAL '90 days';

-- Optimize news queries with composite indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_idol_news_feed_optimization 
ON idol_news(created_at DESC, priority, is_active) 
WHERE created_at >= NOW() - INTERVAL '30 days' AND is_active = TRUE;

-- 5. Read replica optimization views
-- Create materialized views for expensive analytics queries
CREATE MATERIALIZED VIEW IF NOT EXISTS user_spending_summary AS
SELECT 
    u.id as user_id,
    u.name,
    COUNT(p.id) as total_purchases,
    COALESCE(SUM(p.amount), 0) as total_spent,
    COALESCE(AVG(p.amount), 0) as avg_purchase,
    COUNT(DISTINCT p.artist_id) as unique_artists,
    MAX(p.purchase_date) as last_purchase_date,
    date_trunc('month', CURRENT_DATE) as summary_month
FROM users u
LEFT JOIN purchases p ON u.id = p.user_id
WHERE p.purchase_date >= date_trunc('month', CURRENT_DATE)
GROUP BY u.id, u.name;

-- Refresh materialized view daily
CREATE UNIQUE INDEX IF NOT EXISTS idx_user_spending_summary_user_month 
ON user_spending_summary(user_id, summary_month);

-- 6. Partitioning for high-volume tables
-- Partition request logs by month for better performance
CREATE TABLE IF NOT EXISTS request_logs_template (
    LIKE request_logs INCLUDING ALL
);

-- Create partitions for the next 12 months (automation recommended)
DO $$
DECLARE
    partition_date DATE;
    table_name TEXT;
BEGIN
    FOR i IN 0..11 LOOP
        partition_date := DATE_TRUNC('month', CURRENT_DATE) + (i || ' months')::INTERVAL;
        table_name := 'request_logs_' || TO_CHAR(partition_date, 'YYYY_MM');
        
        EXECUTE FORMAT('
            CREATE TABLE IF NOT EXISTS %I 
            PARTITION OF request_logs 
            FOR VALUES FROM (%L) TO (%L)',
            table_name,
            partition_date,
            partition_date + INTERVAL '1 month'
        );
    END LOOP;
END $$;

-- 7. Connection pooling configuration
-- These settings should be applied at the database level

-- Optimize for high concurrency
-- max_connections = 200 (for production)
-- shared_buffers = 256MB
-- effective_cache_size = 1GB
-- work_mem = 4MB
-- maintenance_work_mem = 64MB
-- checkpoint_completion_target = 0.9
-- wal_buffers = 16MB
-- default_statistics_target = 100

-- 8. Query performance optimization functions
CREATE OR REPLACE FUNCTION get_user_dashboard_optimized(p_user_id UUID)
RETURNS TABLE(
    plan_type TEXT,
    artist_count INTEGER,
    active_goals INTEGER,
    monthly_spent DECIMAL(10,2),
    recent_news_count INTEGER,
    performance_score NUMERIC
) AS $$
DECLARE
    cache_key TEXT := 'dashboard:' || p_user_id;
    cached_result RECORD;
BEGIN
    -- Try to get from cache first
    SELECT data INTO cached_result
    FROM api_cache 
    WHERE cache_key = get_user_dashboard_optimized.cache_key
    AND expires_at > NOW();
    
    IF cached_result IS NOT NULL THEN
        RETURN QUERY SELECT 
            (cached_result.data->>'plan_type')::TEXT,
            (cached_result.data->>'artist_count')::INTEGER,
            (cached_result.data->>'active_goals')::INTEGER,
            (cached_result.data->>'monthly_spent')::DECIMAL(10,2),
            (cached_result.data->>'recent_news_count')::INTEGER,
            (cached_result.data->>'performance_score')::NUMERIC;
        RETURN;
    END IF;
    
    -- Calculate fresh data if not cached
    RETURN QUERY
    WITH user_stats AS (
        SELECT 
            COALESCE(us.plan_type, 'free') as plan_type,
            (SELECT COUNT(*) FROM user_artists ua WHERE ua.user_id = p_user_id AND ua.is_active = TRUE) as artist_count,
            (SELECT COUNT(*) FROM goals g WHERE g.user_id = p_user_id AND g.is_active = TRUE) as active_goals,
            (SELECT COALESCE(SUM(amount), 0) 
             FROM purchases p 
             WHERE p.user_id = p_user_id 
             AND p.purchase_date >= date_trunc('month', CURRENT_DATE)) as monthly_spent,
            (SELECT COUNT(*) 
             FROM idol_news n 
             JOIN user_artists ua ON n.artist_id = ua.artist_id 
             WHERE ua.user_id = p_user_id 
             AND n.created_at >= NOW() - INTERVAL '7 days') as recent_news_count
        FROM users u
        LEFT JOIN user_subscriptions us ON u.id = us.user_id AND us.status = 'active'
        WHERE u.id = p_user_id
    )
    SELECT 
        stats.plan_type,
        stats.artist_count,
        stats.active_goals,
        stats.monthly_spent,
        stats.recent_news_count,
        -- Performance score based on engagement
        (stats.artist_count * 10 + stats.active_goals * 5 + LEAST(stats.monthly_spent, 100) + stats.recent_news_count)::NUMERIC as performance_score
    FROM user_stats stats;
    
    -- Cache the result for 10 minutes
    INSERT INTO api_cache (cache_key, data, expires_at)
    VALUES (
        get_user_dashboard_optimized.cache_key,
        jsonb_build_object(
            'plan_type', (SELECT plan_type FROM user_stats LIMIT 1),
            'artist_count', (SELECT artist_count FROM user_stats LIMIT 1),
            'active_goals', (SELECT active_goals FROM user_stats LIMIT 1),
            'monthly_spent', (SELECT monthly_spent FROM user_stats LIMIT 1),
            'recent_news_count', (SELECT recent_news_count FROM user_stats LIMIT 1),
            'performance_score', (SELECT 
                (artist_count * 10 + active_goals * 5 + LEAST(monthly_spent, 100) + recent_news_count)::NUMERIC 
                FROM user_stats LIMIT 1)
        ),
        NOW() + INTERVAL '10 minutes'
    )
    ON CONFLICT (cache_key) DO UPDATE SET
        data = EXCLUDED.data,
        expires_at = EXCLUDED.expires_at;
END;
$$ LANGUAGE plpgsql;

-- 9. Automated cleanup jobs
CREATE OR REPLACE FUNCTION cleanup_old_data()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER := 0;
    temp_count INTEGER;
BEGIN
    -- Clean expired cache entries
    DELETE FROM api_cache WHERE expires_at < NOW();
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_count := deleted_count + temp_count;
    
    -- Clean old request logs (keep last 90 days)
    DELETE FROM request_logs 
    WHERE created_at < NOW() - INTERVAL '90 days';
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_count := deleted_count + temp_count;
    
    -- Clean old performance metrics (keep last 30 days)
    DELETE FROM performance_metrics 
    WHERE recorded_at < NOW() - INTERVAL '30 days';
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_count := deleted_count + temp_count;
    
    -- Clean old news cache entries
    DELETE FROM news_cache 
    WHERE created_at + (ttl * INTERVAL '1 second') < NOW();
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_count := deleted_count + temp_count;
    
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- 10. Database monitoring functions
CREATE OR REPLACE FUNCTION record_performance_metric(
    p_metric_name TEXT,
    p_value NUMERIC,
    p_labels JSONB DEFAULT '{}'::JSONB
)
RETURNS VOID AS $$
BEGIN
    INSERT INTO performance_metrics (metric_name, metric_value, labels)
    VALUES (p_metric_name, p_value, p_labels);
END;
$$ LANGUAGE plpgsql;

-- 11. Connection and query monitoring
CREATE OR REPLACE VIEW database_health AS
SELECT 
    'active_connections' as metric,
    COUNT(*) as value,
    NOW() as timestamp
FROM pg_stat_activity
WHERE state = 'active'

UNION ALL

SELECT 
    'idle_connections' as metric,
    COUNT(*) as value,
    NOW() as timestamp
FROM pg_stat_activity
WHERE state = 'idle'

UNION ALL

SELECT 
    'slow_queries' as metric,
    COUNT(*) as value,
    NOW() as timestamp
FROM pg_stat_activity
WHERE state = 'active' 
AND query_start < NOW() - INTERVAL '30 seconds'

UNION ALL

SELECT 
    'cache_hit_ratio' as metric,
    ROUND(
        100.0 * sum(blks_hit) / (sum(blks_hit) + sum(blks_read)), 2
    ) as value,
    NOW() as timestamp
FROM pg_stat_database;

-- 12. Automated maintenance tasks
-- Schedule these with pg_cron extension

-- Daily cleanup (run at 2 AM)
-- SELECT cron.schedule('cleanup-old-data', '0 2 * * *', 'SELECT cleanup_old_data();');

-- Weekly statistics update (run Sunday at 3 AM)
-- SELECT cron.schedule('update-statistics', '0 3 * * 0', 'ANALYZE;');

-- Refresh materialized views (run every hour)
-- SELECT cron.schedule('refresh-spending-summary', '0 * * * *', 
--   'REFRESH MATERIALIZED VIEW user_spending_summary;');

-- 13. RLS policies for new tables
ALTER TABLE api_cache ENABLE ROW LEVEL SECURITY;
ALTER TABLE performance_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE request_logs ENABLE ROW LEVEL SECURITY;

-- Service role can manage all monitoring data
CREATE POLICY "Service role manages cache" ON api_cache
    FOR ALL USING (auth.jwt() ->> 'role' = 'service_role');

CREATE POLICY "Service role manages metrics" ON performance_metrics
    FOR ALL USING (auth.jwt() ->> 'role' = 'service_role');

CREATE POLICY "Service role manages request logs" ON request_logs
    FOR ALL USING (auth.jwt() ->> 'role' = 'service_role');

-- 14. Indexes for new tables
CREATE INDEX IF NOT EXISTS idx_api_cache_expires_at ON api_cache(expires_at);
CREATE INDEX IF NOT EXISTS idx_performance_metrics_name_time ON performance_metrics(metric_name, recorded_at DESC);
CREATE INDEX IF NOT EXISTS idx_request_logs_user_time ON request_logs(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_request_logs_endpoint_status ON request_logs(endpoint, status_code);

COMMIT;