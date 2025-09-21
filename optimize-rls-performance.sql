-- Optimize RLS policies for better performance
-- Replace auth.uid() with (select auth.uid()) to avoid re-evaluation per row

-- Drop existing policies
DROP POLICY IF EXISTS "Users can insert their own feedback" ON insight_feedback;
DROP POLICY IF EXISTS "Users can view their own feedback" ON insight_feedback;
DROP POLICY IF EXISTS "Users can update their own feedback" ON insight_feedback;

-- Create optimized RLS policies
CREATE POLICY "Users can insert their own feedback" ON insight_feedback
    FOR INSERT WITH CHECK (user_id = (select auth.uid()));

CREATE POLICY "Users can view their own feedback" ON insight_feedback
    FOR SELECT USING (user_id = (select auth.uid()));

CREATE POLICY "Users can update their own feedback" ON insight_feedback
    FOR UPDATE USING (user_id = (select auth.uid()));