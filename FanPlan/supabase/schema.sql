-- Supabase Database Schema for Fan Activity System
-- Run this in your Supabase SQL Editor

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Fan Artists Table (create first since fan_activities references it)
CREATE TABLE IF NOT EXISTS fan_artists (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    image_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User Priorities Table
CREATE TABLE IF NOT EXISTS user_priorities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    category_id TEXT NOT NULL,
    priority_level TEXT NOT NULL CHECK (priority_level IN ('high', 'medium', 'low')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, category_id)
);

-- Fan Activities Table (create after fan_artists)
CREATE TABLE IF NOT EXISTS fan_activities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    amount DECIMAL(10,2) NOT NULL CHECK (amount > 0),
    category_id TEXT NOT NULL,
    category_title TEXT NOT NULL,
    category_icon TEXT NOT NULL,
    idol_id UUID REFERENCES fan_artists(id) ON DELETE SET NULL,
    idol_name TEXT,
    note TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_fan_activities_user_id ON fan_activities(user_id);
CREATE INDEX IF NOT EXISTS idx_fan_activities_created_at ON fan_activities(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_fan_activities_category_id ON fan_activities(category_id);
CREATE INDEX IF NOT EXISTS idx_user_priorities_user_id ON user_priorities(user_id);
CREATE INDEX IF NOT EXISTS idx_fan_artists_user_id ON fan_artists(user_id);

-- Updated at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply updated_at triggers
CREATE TRIGGER update_fan_activities_updated_at
    BEFORE UPDATE ON fan_activities
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_priorities_updated_at
    BEFORE UPDATE ON user_priorities
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_fan_artists_updated_at
    BEFORE UPDATE ON fan_artists
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Row Level Security (RLS) Policies
ALTER TABLE fan_activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_priorities ENABLE ROW LEVEL SECURITY;
ALTER TABLE fan_artists ENABLE ROW LEVEL SECURITY;

-- Fan Activities RLS Policies
CREATE POLICY "Users can view own fan activities" ON fan_activities
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own fan activities" ON fan_activities
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own fan activities" ON fan_activities
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own fan activities" ON fan_activities
    FOR DELETE USING (auth.uid() = user_id);

-- User Priorities RLS Policies
CREATE POLICY "Users can view own priorities" ON user_priorities
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own priorities" ON user_priorities
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own priorities" ON user_priorities
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own priorities" ON user_priorities
    FOR DELETE USING (auth.uid() = user_id);

-- Fan Artists RLS Policies  
CREATE POLICY "Users can view own fan artists" ON fan_artists
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own fan artists" ON fan_artists
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own fan artists" ON fan_artists
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own fan artists" ON fan_artists
    FOR DELETE USING (auth.uid() = user_id);

-- Create view for fan activities with computed fields
CREATE OR REPLACE VIEW fan_activities_with_insights AS
SELECT 
    fa.*,
    EXTRACT(EPOCH FROM (NOW() - fa.created_at)) / 86400 AS days_ago,
    up.priority_level
FROM fan_activities fa
LEFT JOIN user_priorities up ON fa.category_id = up.category_id AND fa.user_id = up.user_id;

-- Note: Sample data will be created automatically when users first use the app
-- Default priorities are handled in the Swift app code

-- Analytics function for priority insights
CREATE OR REPLACE FUNCTION get_priority_insights(user_uuid UUID)
RETURNS JSON AS $$
DECLARE
    total_spending DECIMAL;
    category_spending JSON;
    priorities JSON;
    insights JSON[];
    insight JSON;
    actual_percentage DECIMAL;
    expected_percentage DECIMAL;
    deviation DECIMAL;
    category_record RECORD;
BEGIN
    -- Calculate total spending
    SELECT COALESCE(SUM(amount), 0) INTO total_spending
    FROM fan_activities 
    WHERE user_id = user_uuid;
    
    -- If no spending, return empty insights
    IF total_spending = 0 THEN
        RETURN json_build_object(
            'total_spending', 0,
            'insights', '[]'::json
        );
    END IF;
    
    -- Calculate spending by category
    SELECT json_object_agg(category_id, amount_sum) INTO category_spending
    FROM (
        SELECT category_id, SUM(amount) as amount_sum
        FROM fan_activities 
        WHERE user_id = user_uuid
        GROUP BY category_id
    ) t;
    
    -- Get priorities
    SELECT json_object_agg(category_id, priority_level) INTO priorities
    FROM user_priorities 
    WHERE user_id = user_uuid;
    
    -- Calculate insights for each category
    insights := ARRAY[]::JSON[];
    
    FOR category_record IN 
        SELECT category_id, priority_level
        FROM user_priorities 
        WHERE user_id = user_uuid
    LOOP
        -- Calculate actual percentage
        actual_percentage := COALESCE(
            (category_spending->>category_record.category_id)::DECIMAL / total_spending * 100,
            0
        );
        
        -- Calculate expected percentage based on priority weights
        expected_percentage := CASE 
            WHEN category_record.priority_level = 'high' THEN 50.0
            WHEN category_record.priority_level = 'medium' THEN 30.0  
            WHEN category_record.priority_level = 'low' THEN 20.0
            ELSE 0
        END;
        
        deviation := actual_percentage - expected_percentage;
        
        -- Generate insight if deviation > 20%
        IF ABS(deviation) > 20 THEN
            insight := json_build_object(
                'category_id', category_record.category_id,
                'type', CASE 
                    WHEN deviation > 0 THEN 'overspending'
                    ELSE 'underspending'
                END,
                'actual_percentage', actual_percentage,
                'expected_percentage', expected_percentage,
                'deviation', deviation
            );
            insights := insights || insight;
        END IF;
    END LOOP;
    
    -- Return results
    RETURN json_build_object(
        'total_spending', total_spending,
        'category_spending', category_spending,
        'priorities', priorities,
        'insights', array_to_json(insights)
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;