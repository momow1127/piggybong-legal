-- PiggyBong Database Schema
-- This SQL file sets up the complete database structure for PiggyBong

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

-- Users table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    monthly_budget DECIMAL(10,2) DEFAULT 0.00,
    currency TEXT DEFAULT 'USD',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Artists table
CREATE TABLE artists (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    group_name TEXT,
    image_url TEXT,
    spotify_id TEXT,
    is_following BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Purchases table
CREATE TABLE purchases (
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
CREATE TABLE budgets (
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
CREATE TABLE artist_budget_allocations (
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
CREATE INDEX idx_purchases_user_id ON purchases(user_id);
CREATE INDEX idx_purchases_artist_id ON purchases(artist_id);
CREATE INDEX idx_purchases_date ON purchases(purchase_date);
CREATE INDEX idx_purchases_category ON purchases(category);
CREATE INDEX idx_budgets_user_month_year ON budgets(user_id, month, year);
CREATE INDEX idx_artist_allocations_budget ON artist_budget_allocations(budget_id);
CREATE INDEX idx_artists_name ON artists(name);

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

-- Function to automatically update budget spent amount when purchases are added/updated/deleted
CREATE OR REPLACE FUNCTION update_budget_spent()
RETURNS TRIGGER AS $$
DECLARE
    budget_record RECORD;
    total_spent DECIMAL(10,2);
BEGIN
    -- Get the budget for the user and the purchase month/year
    IF TG_OP = 'DELETE' THEN
        SELECT * INTO budget_record 
        FROM budgets 
        WHERE user_id = OLD.user_id 
        AND month = EXTRACT(MONTH FROM OLD.purchase_date)
        AND year = EXTRACT(YEAR FROM OLD.purchase_date);
    ELSE
        SELECT * INTO budget_record 
        FROM budgets 
        WHERE user_id = NEW.user_id 
        AND month = EXTRACT(MONTH FROM NEW.purchase_date)
        AND year = EXTRACT(YEAR FROM NEW.purchase_date);
    END IF;
    
    -- If budget exists, update the spent amount
    IF budget_record.id IS NOT NULL THEN
        SELECT COALESCE(SUM(amount), 0) INTO total_spent
        FROM purchases 
        WHERE user_id = budget_record.user_id
        AND EXTRACT(MONTH FROM purchase_date) = budget_record.month
        AND EXTRACT(YEAR FROM purchase_date) = budget_record.year;
        
        UPDATE budgets 
        SET spent = total_spent, updated_at = NOW()
        WHERE id = budget_record.id;
    END IF;
    
    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ language 'plpgsql';

-- Create triggers to automatically update budget spent amounts
CREATE TRIGGER update_budget_on_purchase_insert
    AFTER INSERT ON purchases
    FOR EACH ROW EXECUTE FUNCTION update_budget_spent();

CREATE TRIGGER update_budget_on_purchase_update
    AFTER UPDATE ON purchases
    FOR EACH ROW EXECUTE FUNCTION update_budget_spent();

CREATE TRIGGER update_budget_on_purchase_delete
    AFTER DELETE ON purchases
    FOR EACH ROW EXECUTE FUNCTION update_budget_spent();

-- Function to update artist allocation spent amounts
CREATE OR REPLACE FUNCTION update_artist_allocation_spent()
RETURNS TRIGGER AS $$
DECLARE
    allocation_record RECORD;
    total_spent DECIMAL(10,2);
    budget_id_var UUID;
BEGIN
    -- Get the budget ID for the user and purchase month/year
    IF TG_OP = 'DELETE' THEN
        SELECT id INTO budget_id_var
        FROM budgets 
        WHERE user_id = OLD.user_id 
        AND month = EXTRACT(MONTH FROM OLD.purchase_date)
        AND year = EXTRACT(YEAR FROM OLD.purchase_date);
        
        -- Check if allocation exists
        SELECT * INTO allocation_record
        FROM artist_budget_allocations
        WHERE budget_id = budget_id_var AND artist_id = OLD.artist_id;
    ELSE
        SELECT id INTO budget_id_var
        FROM budgets 
        WHERE user_id = NEW.user_id 
        AND month = EXTRACT(MONTH FROM NEW.purchase_date)
        AND year = EXTRACT(YEAR FROM NEW.purchase_date);
        
        -- Check if allocation exists
        SELECT * INTO allocation_record
        FROM artist_budget_allocations
        WHERE budget_id = budget_id_var AND artist_id = NEW.artist_id;
    END IF;
    
    -- If allocation exists, update the spent amount
    IF allocation_record.id IS NOT NULL THEN
        SELECT COALESCE(SUM(amount), 0) INTO total_spent
        FROM purchases 
        WHERE user_id = (SELECT user_id FROM budgets WHERE id = budget_id_var)
        AND artist_id = allocation_record.artist_id
        AND EXTRACT(MONTH FROM purchase_date) = (SELECT month FROM budgets WHERE id = budget_id_var)
        AND EXTRACT(YEAR FROM purchase_date) = (SELECT year FROM budgets WHERE id = budget_id_var);
        
        UPDATE artist_budget_allocations 
        SET spent_amount = total_spent, updated_at = NOW()
        WHERE id = allocation_record.id;
    END IF;
    
    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ language 'plpgsql';

-- Create triggers to automatically update artist allocation spent amounts
CREATE TRIGGER update_allocation_on_purchase_insert
    AFTER INSERT ON purchases
    FOR EACH ROW EXECUTE FUNCTION update_artist_allocation_spent();

CREATE TRIGGER update_allocation_on_purchase_update
    AFTER UPDATE ON purchases
    FOR EACH ROW EXECUTE FUNCTION update_artist_allocation_spent();

CREATE TRIGGER update_allocation_on_purchase_delete
    AFTER DELETE ON purchases
    FOR EACH ROW EXECUTE FUNCTION update_artist_allocation_spent();

-- Row Level Security (RLS) policies
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE purchases ENABLE ROW LEVEL SECURITY;
ALTER TABLE budgets ENABLE ROW LEVEL SECURITY;
ALTER TABLE artist_budget_allocations ENABLE ROW LEVEL SECURITY;

-- Users can only see and modify their own data
CREATE POLICY "Users can view own profile" ON users
    FOR SELECT USING (auth.uid()::text = id::text);

CREATE POLICY "Users can update own profile" ON users
    FOR UPDATE USING (auth.uid()::text = id::text);

CREATE POLICY "Users can view own purchases" ON purchases
    FOR ALL USING (auth.uid()::text = user_id::text);

CREATE POLICY "Users can view own budgets" ON budgets
    FOR ALL USING (auth.uid()::text = user_id::text);

CREATE POLICY "Users can view own allocations" ON artist_budget_allocations
    FOR ALL USING (
        budget_id IN (
            SELECT id FROM budgets WHERE user_id::text = auth.uid()::text
        )
    );

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
    ('ENHYPEN', 'ENHYPEN');

-- Create a view for user spending analytics
CREATE VIEW user_spending_analytics AS
SELECT 
    u.id as user_id,
    u.name as user_name,
    COUNT(p.id) as total_purchases,
    COALESCE(SUM(p.amount), 0) as total_spent,
    COALESCE(AVG(p.amount), 0) as average_purchase,
    COUNT(DISTINCT p.artist_id) as unique_artists,
    p.category as favorite_category,
    COUNT(*) as category_count
FROM users u
LEFT JOIN purchases p ON u.id = p.user_id
GROUP BY u.id, u.name, p.category
ORDER BY category_count DESC;