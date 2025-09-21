-- Complete PiggyBong Database Schema with OAuth Support
-- Run this in your Supabase SQL Editor to create all tables

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create enum types
CREATE TYPE purchase_category AS ENUM (
    'album',
    'concert', 
    'merchandise',
    'digital',
    'photocard',
    'other'
);

-- Users table with OAuth support
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    monthly_budget DECIMAL(10,2) DEFAULT 0.00,
    currency TEXT DEFAULT 'USD',
    -- OAuth fields for Apple/Google Sign-In
    google_user_id TEXT,
    apple_user_id TEXT,  
    auth_provider TEXT DEFAULT 'email',
    email_verified BOOLEAN DEFAULT FALSE,
    profile_picture_url TEXT,
    last_login_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Artists table
CREATE TABLE IF NOT EXISTS artists (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    group_name TEXT,
    image_url TEXT,
    spotify_id TEXT,
    is_following BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Fan Artists Table (for fan activities)
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

-- Fan Activities Table
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

-- Purchases table
CREATE TABLE IF NOT EXISTS purchases (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    artist_id UUID NOT NULL REFERENCES artists(id) ON DELETE CASCADE,
    amount DECIMAL(10,2) NOT NULL,
    category purchase_category NOT NULL,
    description TEXT NOT NULL,
    notes TEXT,
    purchase_date DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Budgets table
CREATE TABLE IF NOT EXISTS budgets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    month INTEGER NOT NULL CHECK (month >= 1 AND month <= 12),
    year INTEGER NOT NULL CHECK (year >= 2024),
    total_budget DECIMAL(10,2) NOT NULL,
    spent DECIMAL(10,2) DEFAULT 0.00,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, month, year)
);

-- Artist budget allocations table
CREATE TABLE IF NOT EXISTS artist_budget_allocations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    budget_id UUID NOT NULL REFERENCES budgets(id) ON DELETE CASCADE,
    artist_id UUID NOT NULL REFERENCES artists(id) ON DELETE CASCADE,
    allocated_amount DECIMAL(10,2) NOT NULL,
    spent_amount DECIMAL(10,2) DEFAULT 0.00,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(budget_id, artist_id)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_google_user_id ON users(google_user_id);
CREATE INDEX IF NOT EXISTS idx_users_apple_user_id ON users(apple_user_id);
CREATE INDEX IF NOT EXISTS idx_users_auth_provider ON users(auth_provider);

CREATE INDEX IF NOT EXISTS idx_purchases_user_id ON purchases(user_id);
CREATE INDEX IF NOT EXISTS idx_purchases_artist_id ON purchases(artist_id);
CREATE INDEX IF NOT EXISTS idx_purchases_date ON purchases(purchase_date);
CREATE INDEX IF NOT EXISTS idx_purchases_category ON purchases(category);
CREATE INDEX IF NOT EXISTS idx_budgets_user_month_year ON budgets(user_id, month, year);
CREATE INDEX IF NOT EXISTS idx_artist_allocations_budget ON artist_budget_allocations(budget_id);
CREATE INDEX IF NOT EXISTS idx_artists_name ON artists(name);

-- Fan activities indexes
CREATE INDEX IF NOT EXISTS idx_fan_activities_user_id ON fan_activities(user_id);
CREATE INDEX IF NOT EXISTS idx_fan_activities_created_at ON fan_activities(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_fan_activities_category_id ON fan_activities(category_id);
CREATE INDEX IF NOT EXISTS idx_user_priorities_user_id ON user_priorities(user_id);
CREATE INDEX IF NOT EXISTS idx_fan_artists_user_id ON fan_artists(user_id);

-- Create functions for automatic timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for automatic timestamp updates
CREATE TRIGGER update_users_updated_at 
    BEFORE UPDATE ON users 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_budgets_updated_at 
    BEFORE UPDATE ON budgets 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_allocations_updated_at 
    BEFORE UPDATE ON artist_budget_allocations 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_fan_activities_updated_at
    BEFORE UPDATE ON fan_activities
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_priorities_updated_at
    BEFORE UPDATE ON user_priorities
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_fan_artists_updated_at
    BEFORE UPDATE ON fan_artists
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Row Level Security (RLS) policies
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE purchases ENABLE ROW LEVEL SECURITY;
ALTER TABLE budgets ENABLE ROW LEVEL SECURITY;
ALTER TABLE artist_budget_allocations ENABLE ROW LEVEL SECURITY;
ALTER TABLE fan_activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_priorities ENABLE ROW LEVEL SECURITY;
ALTER TABLE fan_artists ENABLE ROW LEVEL SECURITY;

-- Users RLS policies (OAuth compatible)
CREATE POLICY "Users can view own profile" ON users
    FOR SELECT USING (auth.uid()::text = id::text);

CREATE POLICY "Users can update own profile" ON users
    FOR UPDATE USING (auth.uid()::text = id::text);

CREATE POLICY "Users can insert own profile" ON users
    FOR INSERT WITH CHECK (auth.uid()::text = id::text);

-- Purchases RLS policies
CREATE POLICY "Users can view own purchases" ON purchases
    FOR ALL USING (auth.uid()::text = user_id::text);

-- Budgets RLS policies
CREATE POLICY "Users can view own budgets" ON budgets
    FOR ALL USING (auth.uid()::text = user_id::text);

CREATE POLICY "Users can view own allocations" ON artist_budget_allocations
    FOR ALL USING (
        budget_id IN (
            SELECT id FROM budgets WHERE user_id::text = auth.uid()::text
        )
    );

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

-- Artists table is public (read-only for users)
CREATE POLICY "Artists are viewable by everyone" ON artists
    FOR SELECT USING (true);

-- Insert some sample artists for testing
INSERT INTO artists (name, group_name) VALUES
    ('BTS', 'BTS'),
    ('BLACKPINK', 'BLACKPINK'),
    ('NewJeans', 'NewJeans'),
    ('IVE', 'IVE'),
    ('aespa', 'aespa'),
    ('TWICE', 'TWICE'),
    ('Red Velvet', 'Red Velvet'),
    ('ITZY', 'ITZY'),
    ('NMIXX', 'NMIXX'),
    ('LE SSERAFIM', 'LE SSERAFIM'),
    ('(G)I-DLE', '(G)I-DLE'),
    ('STRAY KIDS', 'STRAY KIDS'),
    ('SEVENTEEN', 'SEVENTEEN'),
    ('NCT', 'NCT'),
    ('ENHYPEN', 'ENHYPEN')
ON CONFLICT (name) DO NOTHING;

-- Create view for fan activities with computed fields
CREATE OR REPLACE VIEW fan_activities_with_insights AS
SELECT 
    fa.*,
    EXTRACT(EPOCH FROM (NOW() - fa.created_at)) / 86400 AS days_ago,
    up.priority_level
FROM fan_activities fa
LEFT JOIN user_priorities up ON fa.category_id = up.category_id AND fa.user_id = up.user_id;

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
    SELECT COALESCE(SUM(amount), 0) INTO total_spending
    FROM fan_activities 
    WHERE user_id = user_uuid;
    
    IF total_spending = 0 THEN
        RETURN json_build_object(
            'total_spending', 0,
            'insights', '[]'::json
        );
    END IF;
    
    SELECT json_object_agg(category_id, amount_sum) INTO category_spending
    FROM (
        SELECT category_id, SUM(amount) as amount_sum
        FROM fan_activities 
        WHERE user_id = user_uuid
        GROUP BY category_id
    ) t;
    
    SELECT json_object_agg(category_id, priority_level) INTO priorities
    FROM user_priorities 
    WHERE user_id = user_uuid;
    
    insights := ARRAY[]::JSON[];
    
    FOR category_record IN 
        SELECT category_id, priority_level
        FROM user_priorities 
        WHERE user_id = user_uuid
    LOOP
        actual_percentage := COALESCE(
            (category_spending->>category_record.category_id)::DECIMAL / total_spending * 100,
            0
        );
        
        expected_percentage := CASE 
            WHEN category_record.priority_level = 'high' THEN 50.0
            WHEN category_record.priority_level = 'medium' THEN 30.0  
            WHEN category_record.priority_level = 'low' THEN 20.0
            ELSE 0
        END;
        
        deviation := actual_percentage - expected_percentage;
        
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
    
    RETURN json_build_object(
        'total_spending', total_spending,
        'category_spending', category_spending,
        'priorities', priorities,
        'insights', array_to_json(insights)
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Verify the schema
SELECT 'Schema created successfully! Tables:' as status;
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' AND table_type = 'BASE TABLE' 
ORDER BY table_name;