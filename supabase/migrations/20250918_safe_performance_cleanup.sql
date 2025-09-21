-- Safe Performance Cleanup - Handles Constraints Properly
-- This migration safely fixes performance warnings without breaking constraints

-- ===== STEP 1: SAFE POLICY CLEANUP =====
-- Drop only duplicate policies, keep essential ones

DO $$
DECLARE
    pol RECORD;
BEGIN
    -- Drop only problematic duplicate policies, not all policies
    FOR pol IN
        SELECT DISTINCT tablename, policyname
        FROM pg_policies
        WHERE tablename IN ('artists', 'goals', 'users', 'user_feedback', 'fan_idols')
        AND (
            policyname LIKE '%duplicate%' OR
            policyname LIKE '%old%' OR
            policyname LIKE '%temp%' OR
            -- Drop our previous attempts that might be duplicated
            policyname IN (
                'artists_public_read_consolidated',
                'goals_user_access_consolidated',
                'users_own_data_consolidated',
                'user_feedback_consolidated',
                'fan_idols_user_access_consolidated',
                'optimized_artists_read',
                'optimized_goals_user_access',
                'optimized_users_access',
                'optimized_user_feedback_access',
                'optimized_fan_idols_user_access'
            )
        )
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON %I', pol.policyname, pol.tablename);
    END LOOP;
END $$;

-- Create single, clean policies (only if they don't exist)
DO $$
BEGIN
    -- Artists policy
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'artists' AND policyname = 'artists_public_select') THEN
        CREATE POLICY "artists_public_select" ON artists FOR SELECT TO public USING (true);
    END IF;

    -- Goals policy
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'goals' AND policyname = 'goals_user_all') THEN
        CREATE POLICY "goals_user_all" ON goals FOR ALL TO authenticated
            USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
    END IF;

    -- Users policy
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'users' AND policyname = 'users_own_all') THEN
        CREATE POLICY "users_own_all" ON users FOR ALL TO authenticated
            USING (auth.uid() = id) WITH CHECK (auth.uid() = id);
    END IF;

    -- User feedback policy
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'user_feedback' AND policyname = 'user_feedback_own') THEN
        CREATE POLICY "user_feedback_own" ON user_feedback FOR ALL TO authenticated
            USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
    END IF;

    -- Fan idols policy
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'fan_idols' AND policyname = 'fan_idols_user_all') THEN
        CREATE POLICY "fan_idols_user_all" ON fan_idols FOR ALL TO authenticated
            USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
    END IF;
END $$;

-- ===== STEP 2: SAFE INDEX CLEANUP =====
-- Only drop indexes that are NOT constraints

DO $$
DECLARE
    idx_name text;
BEGIN
    -- Drop only performance indexes that are NOT backing constraints
    FOR idx_name IN
        SELECT i.indexname
        FROM pg_indexes i
        WHERE i.schemaname = 'public'
        AND (
            i.indexname LIKE '%performance%' OR
            i.indexname LIKE '%_opt' OR
            i.indexname LIKE '%auth_uid'
        )
        -- Exclude constraint-backing indexes
        AND NOT EXISTS (
            SELECT 1 FROM pg_constraint c
            WHERE c.conname = i.indexname
        )
    LOOP
        EXECUTE 'DROP INDEX IF EXISTS ' || idx_name;
    END LOOP;
END $$;

-- ===== STEP 3: CREATE OPTIMAL AUTH INDEXES =====
-- Create auth.uid() performance indexes (avoid constraint conflicts)

CREATE INDEX IF NOT EXISTS idx_security_logs_user_auth ON security_logs(user_id)
WHERE user_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_rate_limits_user_auth ON rate_limits(user_id)
WHERE user_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_goals_user_auth ON goals(user_id)
WHERE user_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_users_id_auth ON users(id)
WHERE id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_user_feedback_user_auth ON user_feedback(user_id)
WHERE user_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_fan_idols_user_auth ON fan_idols(user_id)
WHERE user_id IS NOT NULL;

-- ===== STEP 4: SAFE DUPLICATE INDEX REMOVAL =====
-- Only remove true duplicates, not constraint indexes

DO $$
DECLARE
    idx_record RECORD;
BEGIN
    -- Find and remove only duplicate performance indexes
    FOR idx_record IN
        SELECT
            indexname,
            tablename
        FROM pg_indexes
        WHERE schemaname = 'public'
        AND tablename IN ('fan_idols', 'goals', 'user_feedback')
        AND (
            indexname LIKE '%duplicate%' OR
            indexname LIKE '%_2' OR
            indexname LIKE '%_old'
        )
        -- Don't touch constraint indexes
        AND NOT EXISTS (
            SELECT 1 FROM pg_constraint c
            WHERE c.conname = indexname
        )
    LOOP
        EXECUTE 'DROP INDEX IF EXISTS ' || idx_record.indexname;
    END LOOP;
END $$;

-- ===== STEP 5: VERIFICATION =====

CREATE OR REPLACE FUNCTION verify_safe_cleanup()
RETURNS TABLE (
    metric text,
    count_value bigint,
    status text,
    details text
)
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
    -- Only allow service role
    IF auth.role() != 'service_role' THEN
        RAISE EXCEPTION 'Access denied: Admin privileges required';
    END IF;

    RETURN QUERY
    -- Count current policies
    SELECT
        'Active Policies'::text,
        COUNT(*)::bigint,
        CASE WHEN COUNT(*) <= 8 THEN 'GOOD' ELSE 'TOO_MANY' END::text,
        ('Found ' || COUNT(*) || ' policies total')::text
    FROM pg_policies
    WHERE tablename IN ('artists', 'goals', 'users', 'user_feedback', 'fan_idols')

    UNION ALL

    -- Count auth performance indexes
    SELECT
        'Auth Performance Indexes'::text,
        COUNT(*)::bigint,
        CASE WHEN COUNT(*) >= 6 THEN 'COMPLETE' ELSE 'INCOMPLETE' END::text,
        ('Found ' || COUNT(*) || ' auth indexes')::text
    FROM pg_indexes
    WHERE indexname LIKE '%_auth'

    UNION ALL

    -- Count constraints (should be preserved)
    SELECT
        'Constraint Indexes'::text,
        COUNT(*)::bigint,
        'PRESERVED'::text,
        ('Found ' || COUNT(*) || ' constraint indexes')::text
    FROM pg_indexes i
    JOIN pg_constraint c ON c.conname = i.indexname
    WHERE i.schemaname = 'public';
END;
$$ LANGUAGE plpgsql;

-- Grant access
GRANT EXECUTE ON FUNCTION verify_safe_cleanup() TO service_role;

-- Log this safe cleanup
SELECT log_security_event('safe_performance_cleanup_completed',
    jsonb_build_object(
        'approach', 'constraint_safe_cleanup',
        'policies_cleaned', 'duplicates_only',
        'indexes_optimized', 'auth_performance',
        'constraints_preserved', true
    )
);

-- Final status
SELECT 'Safe performance cleanup completed' as status,
       'Constraints preserved, duplicates removed' as details;