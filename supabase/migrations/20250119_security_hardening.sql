-- Security Hardening for Production PiggyBong
-- This migration implements enterprise-grade security measures

-- 1. Audit logging system
CREATE TABLE IF NOT EXISTS security_audit_log (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    action TEXT NOT NULL,
    table_name TEXT,
    record_id UUID,
    old_values JSONB,
    new_values JSONB,
    ip_address INET,
    user_agent TEXT,
    timestamp TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Failed login attempts tracking
CREATE TABLE IF NOT EXISTS failed_login_attempts (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    email TEXT NOT NULL,
    ip_address INET NOT NULL,
    attempted_at TIMESTAMPTZ DEFAULT NOW(),
    user_agent TEXT,
    failure_reason TEXT
);

-- 3. User sessions and device management
CREATE TABLE IF NOT EXISTS user_sessions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    session_token TEXT NOT NULL UNIQUE,
    device_fingerprint TEXT,
    device_name TEXT,
    ip_address INET,
    user_agent TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    last_activity TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ DEFAULT NOW() + INTERVAL '7 days',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. API key management for external integrations
CREATE TABLE IF NOT EXISTS api_keys (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    key_name TEXT NOT NULL,
    api_key TEXT NOT NULL UNIQUE,
    permissions JSONB DEFAULT '{}',
    rate_limit INTEGER DEFAULT 1000,
    is_active BOOLEAN DEFAULT TRUE,
    last_used TIMESTAMPTZ,
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. Data anonymization for GDPR compliance
CREATE TABLE IF NOT EXISTS data_deletion_requests (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    request_type TEXT NOT NULL CHECK (request_type IN ('anonymize', 'delete', 'export')),
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed')),
    requested_at TIMESTAMPTZ DEFAULT NOW(),
    processed_at TIMESTAMPTZ,
    data_export JSONB,
    deletion_log JSONB
);

-- 6. Enhanced RLS policies with IP filtering and device checks
-- Create function to check for suspicious activity
CREATE OR REPLACE FUNCTION is_suspicious_activity(p_user_id UUID, p_ip_address TEXT)
RETURNS BOOLEAN AS $$
DECLARE
    recent_ips INTEGER;
    failed_attempts INTEGER;
BEGIN
    -- Check for too many different IP addresses in last hour
    SELECT COUNT(DISTINCT ip_address) INTO recent_ips
    FROM request_logs
    WHERE user_id = p_user_id
    AND created_at >= NOW() - INTERVAL '1 hour';
    
    -- Check for recent failed login attempts from this IP
    SELECT COUNT(*) INTO failed_attempts
    FROM failed_login_attempts
    WHERE ip_address = p_ip_address::INET
    AND attempted_at >= NOW() - INTERVAL '15 minutes';
    
    RETURN recent_ips > 5 OR failed_attempts > 3;
END;
$$ LANGUAGE plpgsql;

-- 7. Secure audit trigger function
CREATE OR REPLACE FUNCTION audit_trigger_function()
RETURNS TRIGGER AS $$
DECLARE
    user_id_val UUID;
    ip_addr TEXT;
BEGIN
    -- Get current user ID from JWT
    user_id_val := (auth.jwt() ->> 'sub')::UUID;
    
    -- Get IP address from request headers (if available)
    ip_addr := COALESCE(
        current_setting('request.headers', true)::JSON ->> 'x-forwarded-for',
        current_setting('request.headers', true)::JSON ->> 'x-real-ip',
        '0.0.0.0'
    );
    
    IF TG_OP = 'DELETE' THEN
        INSERT INTO security_audit_log (
            user_id, action, table_name, record_id, old_values, ip_address
        ) VALUES (
            user_id_val, 'DELETE', TG_TABLE_NAME, OLD.id, to_jsonb(OLD), ip_addr::INET
        );
        RETURN OLD;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO security_audit_log (
            user_id, action, table_name, record_id, old_values, new_values, ip_address
        ) VALUES (
            user_id_val, 'UPDATE', TG_TABLE_NAME, NEW.id, to_jsonb(OLD), to_jsonb(NEW), ip_addr::INET
        );
        RETURN NEW;
    ELSIF TG_OP = 'INSERT' THEN
        INSERT INTO security_audit_log (
            user_id, action, table_name, record_id, new_values, ip_address
        ) VALUES (
            user_id_val, 'INSERT', TG_TABLE_NAME, NEW.id, to_jsonb(NEW), ip_addr::INET
        );
        RETURN NEW;
    END IF;
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- 8. Apply audit triggers to sensitive tables
CREATE TRIGGER audit_users_changes
    AFTER INSERT OR UPDATE OR DELETE ON users
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();

CREATE TRIGGER audit_purchases_changes
    AFTER INSERT OR UPDATE OR DELETE ON purchases
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();

CREATE TRIGGER audit_budgets_changes
    AFTER INSERT OR UPDATE OR DELETE ON budgets
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();

CREATE TRIGGER audit_subscriptions_changes
    AFTER INSERT OR UPDATE OR DELETE ON user_subscriptions
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();

-- 9. Enhanced RLS policies with security checks
-- Users table with enhanced security
DROP POLICY IF EXISTS "Users can view own profile" ON users;
DROP POLICY IF EXISTS "Users can update own profile" ON users;

CREATE POLICY "Secure user profile access" ON users
    FOR SELECT USING (
        auth.uid() = id 
        AND NOT is_suspicious_activity(auth.uid(), 
            COALESCE(current_setting('request.headers', true)::JSON ->> 'x-real-ip', '0.0.0.0')
        )
    );

CREATE POLICY "Secure user profile updates" ON users
    FOR UPDATE USING (
        auth.uid() = id 
        AND NOT is_suspicious_activity(auth.uid(), 
            COALESCE(current_setting('request.headers', true)::JSON ->> 'x-real-ip', '0.0.0.0')
        )
    );

-- 10. Financial data protection (purchases, budgets)
CREATE POLICY "Secure purchase access" ON purchases
    FOR ALL USING (
        auth.uid() = user_id 
        AND EXISTS (
            SELECT 1 FROM user_sessions 
            WHERE user_id = auth.uid() 
            AND is_active = TRUE 
            AND expires_at > NOW()
        )
    );

-- 11. Data retention and cleanup functions
CREATE OR REPLACE FUNCTION cleanup_security_data()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER := 0;
    temp_count INTEGER;
BEGIN
    -- Clean old audit logs (keep 1 year)
    DELETE FROM security_audit_log 
    WHERE timestamp < NOW() - INTERVAL '1 year';
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_count := deleted_count + temp_count;
    
    -- Clean old failed login attempts (keep 30 days)
    DELETE FROM failed_login_attempts 
    WHERE attempted_at < NOW() - INTERVAL '30 days';
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_count := deleted_count + temp_count;
    
    -- Clean expired sessions
    DELETE FROM user_sessions 
    WHERE expires_at < NOW() OR last_activity < NOW() - INTERVAL '30 days';
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_count := deleted_count + temp_count;
    
    -- Clean expired API keys
    DELETE FROM api_keys 
    WHERE expires_at < NOW() AND expires_at IS NOT NULL;
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_count := deleted_count + temp_count;
    
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- 12. User data anonymization for GDPR
CREATE OR REPLACE FUNCTION anonymize_user_data(p_user_id UUID)
RETURNS JSONB AS $$
DECLARE
    anonymized_data JSONB;
BEGIN
    -- Create anonymized backup
    SELECT jsonb_build_object(
        'user', to_jsonb(u.*),
        'purchases', COALESCE(
            (SELECT jsonb_agg(to_jsonb(p.*)) FROM purchases p WHERE p.user_id = p_user_id), 
            '[]'::JSONB
        ),
        'budgets', COALESCE(
            (SELECT jsonb_agg(to_jsonb(b.*)) FROM budgets b WHERE b.user_id = p_user_id), 
            '[]'::JSONB
        ),
        'goals', COALESCE(
            (SELECT jsonb_agg(to_jsonb(g.*)) FROM goals g WHERE g.user_id = p_user_id), 
            '[]'::JSONB
        )
    ) INTO anonymized_data
    FROM users u WHERE u.id = p_user_id;
    
    -- Anonymize user data
    UPDATE users 
    SET 
        email = 'anonymized_' || id || '@deleted.local',
        name = 'Deleted User',
        updated_at = NOW()
    WHERE id = p_user_id;
    
    -- Keep purchase data for analytics but anonymize descriptions
    UPDATE purchases 
    SET 
        description = 'Anonymized Purchase',
        notes = NULL
    WHERE user_id = p_user_id;
    
    -- Mark goals as anonymized
    UPDATE goals 
    SET 
        title = 'Anonymized Goal',
        description = NULL
    WHERE user_id = p_user_id;
    
    RETURN anonymized_data;
END;
$$ LANGUAGE plpgsql;

-- 13. Security monitoring functions
CREATE OR REPLACE FUNCTION detect_anomalous_activity()
RETURNS TABLE(
    user_id UUID,
    anomaly_type TEXT,
    severity TEXT,
    details JSONB,
    detected_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    -- Detect users with unusual spending patterns
    WITH spending_anomalies AS (
        SELECT 
            p.user_id,
            'unusual_spending' as anomaly_type,
            CASE 
                WHEN SUM(p.amount) > avg_spending * 5 THEN 'high'
                WHEN SUM(p.amount) > avg_spending * 3 THEN 'medium'
                ELSE 'low'
            END as severity,
            jsonb_build_object(
                'current_spending', SUM(p.amount),
                'average_spending', avg_spending,
                'multiplier', ROUND(SUM(p.amount) / avg_spending, 2)
            ) as details,
            NOW() as detected_at
        FROM purchases p
        CROSS JOIN (
            SELECT AVG(monthly_total) as avg_spending
            FROM (
                SELECT user_id, DATE_TRUNC('month', purchase_date) as month, SUM(amount) as monthly_total
                FROM purchases
                WHERE purchase_date >= NOW() - INTERVAL '6 months'
                GROUP BY user_id, month
            ) monthly_spending
        ) avg_calc
        WHERE p.purchase_date >= DATE_TRUNC('month', NOW())
        GROUP BY p.user_id, avg_spending
        HAVING SUM(p.amount) > avg_spending * 2
    )
    SELECT * FROM spending_anomalies
    
    UNION ALL
    
    -- Detect users with multiple login failures
    SELECT 
        u.id as user_id,
        'multiple_login_failures' as anomaly_type,
        'high' as severity,
        jsonb_build_object(
            'failure_count', COUNT(fla.id),
            'unique_ips', COUNT(DISTINCT fla.ip_address)
        ) as details,
        NOW() as detected_at
    FROM users u
    JOIN failed_login_attempts fla ON u.email = fla.email
    WHERE fla.attempted_at >= NOW() - INTERVAL '1 hour'
    GROUP BY u.id
    HAVING COUNT(fla.id) >= 5;
END;
$$ LANGUAGE plpgsql;

-- 14. Input validation and sanitization functions
CREATE OR REPLACE FUNCTION sanitize_user_input(input_text TEXT)
RETURNS TEXT AS $$
BEGIN
    -- Remove potential SQL injection patterns
    input_text := regexp_replace(input_text, '[;<>()''"]', '', 'g');
    
    -- Limit length
    input_text := LEFT(input_text, 500);
    
    -- Trim whitespace
    input_text := TRIM(input_text);
    
    RETURN input_text;
END;
$$ LANGUAGE plpgsql;

-- 15. Create indexes for security tables
CREATE INDEX IF NOT EXISTS idx_security_audit_user_time ON security_audit_log(user_id, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_security_audit_table_action ON security_audit_log(table_name, action);
CREATE INDEX IF NOT EXISTS idx_failed_logins_email_time ON failed_login_attempts(email, attempted_at DESC);
CREATE INDEX IF NOT EXISTS idx_failed_logins_ip_time ON failed_login_attempts(ip_address, attempted_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_sessions_user_active ON user_sessions(user_id, is_active, expires_at);
CREATE INDEX IF NOT EXISTS idx_api_keys_user_active ON api_keys(user_id, is_active, expires_at);

-- 16. RLS policies for security tables
ALTER TABLE security_audit_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE failed_login_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE api_keys ENABLE ROW LEVEL SECURITY;
ALTER TABLE data_deletion_requests ENABLE ROW LEVEL SECURITY;

-- Users can only see their own audit logs (limited)
CREATE POLICY "Users see own basic audit logs" ON security_audit_log
    FOR SELECT USING (
        auth.uid() = user_id 
        AND action IN ('UPDATE', 'INSERT')
        AND timestamp >= NOW() - INTERVAL '30 days'
    );

-- Users can manage their own sessions
CREATE POLICY "Users manage own sessions" ON user_sessions
    FOR ALL USING (auth.uid() = user_id);

-- Users can manage their own API keys
CREATE POLICY "Users manage own API keys" ON api_keys
    FOR ALL USING (auth.uid() = user_id);

-- Users can create and view their own deletion requests
CREATE POLICY "Users manage own deletion requests" ON data_deletion_requests
    FOR ALL USING (auth.uid() = user_id);

-- Service role has full access to security data
CREATE POLICY "Service role manages security data" ON security_audit_log
    FOR ALL USING (auth.jwt() ->> 'role' = 'service_role');

CREATE POLICY "Service role manages failed logins" ON failed_login_attempts
    FOR ALL USING (auth.jwt() ->> 'role' = 'service_role');

-- 17. Notification system for security events
CREATE TABLE IF NOT EXISTS security_notifications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    notification_type TEXT NOT NULL,
    severity TEXT NOT NULL CHECK (severity IN ('low', 'medium', 'high', 'critical')),
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    metadata JSONB DEFAULT '{}',
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_security_notifications_user_unread ON security_notifications(user_id, is_read, created_at DESC);

ALTER TABLE security_notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users see own security notifications" ON security_notifications
    FOR ALL USING (auth.uid() = user_id);

COMMIT;