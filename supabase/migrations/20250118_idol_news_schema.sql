-- Create idol_news table for storing aggregated news
CREATE TABLE IF NOT EXISTS idol_news (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    artist_id UUID REFERENCES artists(id) ON DELETE CASCADE,
    artist_name TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    source TEXT NOT NULL, -- 'spotify', 'rss', 'ticketmaster', 'twitter', etc.
    source_url TEXT,
    image_url TEXT,
    news_type TEXT NOT NULL, -- 'release', 'concert', 'news', 'social', 'merch'
    priority TEXT DEFAULT 'normal' CHECK (priority IN ('urgent', 'high', 'normal', 'low')),
    event_date TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    metadata JSONB DEFAULT '{}', -- Store additional source-specific data
    is_active BOOLEAN DEFAULT true,
    views_count INTEGER DEFAULT 0,
    
    -- Prevent duplicate news items
    UNIQUE(source, source_url)
);

-- News cache table for performance optimization
CREATE TABLE IF NOT EXISTS news_cache (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    cache_key TEXT NOT NULL UNIQUE,
    data JSONB NOT NULL,
    ttl INTEGER NOT NULL, -- Time to live in seconds
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Priority weights table for dynamic priority calculation
CREATE TABLE IF NOT EXISTS priority_keywords (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    keyword TEXT NOT NULL UNIQUE,
    priority_level TEXT NOT NULL CHECK (priority_level IN ('high', 'medium', 'low')),
    news_type TEXT, -- Optional: specific to news types
    weight INTEGER DEFAULT 1, -- Higher weight = higher priority
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User news preferences for personalized filtering
CREATE TABLE IF NOT EXISTS user_news_preferences (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    min_priority TEXT DEFAULT 'normal' CHECK (min_priority IN ('urgent', 'high', 'normal', 'low')),
    source_preferences JSONB DEFAULT '{}', -- {"spotify": true, "rss": false}
    keyword_filters TEXT[], -- Custom keywords for filtering
    notification_threshold TEXT DEFAULT 'high' CHECK (notification_threshold IN ('urgent', 'high', 'normal', 'low')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(user_id)
);

-- Create optimized indexes for performance
CREATE INDEX idx_idol_news_artist_id ON idol_news(artist_id);
CREATE INDEX idx_idol_news_artist_name ON idol_news(artist_name);
CREATE INDEX idx_idol_news_created_at ON idol_news(created_at DESC);
CREATE INDEX idx_idol_news_event_date ON idol_news(event_date);
CREATE INDEX idx_idol_news_news_type ON idol_news(news_type);
CREATE INDEX idx_idol_news_priority ON idol_news(priority);
CREATE INDEX idx_idol_news_priority_created ON idol_news(priority, created_at DESC);
CREATE INDEX idx_idol_news_followed_priority ON idol_news(artist_id, priority, created_at DESC);

-- Cache table indexes
CREATE INDEX idx_news_cache_key ON news_cache(cache_key);
CREATE INDEX idx_news_cache_created ON news_cache(created_at);

-- Priority keywords indexes
CREATE INDEX idx_priority_keywords_level ON priority_keywords(priority_level) WHERE is_active = true;
CREATE INDEX idx_priority_keywords_type ON priority_keywords(news_type, priority_level) WHERE is_active = true;

-- Create user_news_interactions table for tracking user engagement
CREATE TABLE IF NOT EXISTS user_news_interactions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    news_id UUID REFERENCES idol_news(id) ON DELETE CASCADE,
    interaction_type TEXT NOT NULL, -- 'view', 'like', 'save', 'dismiss'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(user_id, news_id, interaction_type)
);

-- Create news_notifications table for push notifications
CREATE TABLE IF NOT EXISTS news_notifications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    news_id UUID REFERENCES idol_news(id) ON DELETE CASCADE,
    notification_type TEXT NOT NULL, -- 'comeback', 'concert', 'urgent'
    sent_at TIMESTAMP WITH TIME ZONE,
    opened_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create news_fetch_log table for smart scheduling
CREATE TABLE IF NOT EXISTS news_fetch_log (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    artist_name TEXT NOT NULL,
    source TEXT NOT NULL, -- 'spotify', 'rss', 'ticketmaster'
    priority_level TEXT NOT NULL, -- 'high', 'medium', 'low'
    last_fetched TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    fetch_count INTEGER DEFAULT 1,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(artist_name, source, priority_level)
);

-- Create indexes for fetch log
CREATE INDEX idx_news_fetch_log_artist_source ON news_fetch_log(artist_name, source);
CREATE INDEX idx_news_fetch_log_last_fetched ON news_fetch_log(last_fetched);
CREATE INDEX idx_news_fetch_log_priority ON news_fetch_log(priority_level);

-- Insert default priority keywords
INSERT INTO priority_keywords (keyword, priority_level, weight) VALUES
-- High priority keywords
('comeback', 'high', 5),
('album', 'high', 4),
('tour', 'high', 5),
('concert', 'high', 5),
('debut', 'high', 4),
('release', 'high', 4),
('mv', 'high', 3),
('music video', 'high', 3),
('single', 'high', 3),
-- Medium priority keywords
('interview', 'medium', 2),
('performance', 'medium', 2),
('award', 'medium', 2),
('collaboration', 'medium', 2),
('collab', 'medium', 2),
('feature', 'medium', 2),
-- Low priority keywords
('mention', 'low', 1),
('spotted', 'low', 1),
('fashion', 'low', 1),
('airport', 'low', 1)
ON CONFLICT (keyword) DO NOTHING;

-- Enhanced function to get personalized news with priority filtering
CREATE OR REPLACE FUNCTION get_user_idol_news(
    p_user_id UUID,
    p_limit INTEGER DEFAULT 20,
    p_offset INTEGER DEFAULT 0,
    p_priority_filter TEXT DEFAULT 'all'
)
RETURNS TABLE (
    id UUID,
    artist_id UUID,
    artist_name TEXT,
    title TEXT,
    description TEXT,
    source TEXT,
    source_url TEXT,
    image_url TEXT,
    news_type TEXT,
    priority TEXT,
    priority_score INTEGER,
    event_date TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE,
    metadata JSONB,
    is_following BOOLEAN,
    has_viewed BOOLEAN,
    has_liked BOOLEAN
) AS $$
DECLARE
    user_prefs RECORD;
BEGIN
    -- Get user preferences
    SELECT * INTO user_prefs 
    FROM user_news_preferences 
    WHERE user_id = p_user_id;
    
    -- If no preferences exist, create default ones
    IF user_prefs IS NULL THEN
        INSERT INTO user_news_preferences (user_id) VALUES (p_user_id);
        SELECT * INTO user_prefs FROM user_news_preferences WHERE user_id = p_user_id;
    END IF;
    
    RETURN QUERY
    SELECT 
        n.id,
        n.artist_id,
        n.artist_name,
        n.title,
        n.description,
        n.source,
        n.source_url,
        n.image_url,
        n.news_type,
        n.priority,
        -- Calculate priority score for sorting
        CASE n.priority 
            WHEN 'urgent' THEN 1000 
            WHEN 'high' THEN 100 
            WHEN 'normal' THEN 10 
            ELSE 1 
        END + 
        CASE WHEN is_following_calc THEN 500 ELSE 0 END as priority_score,
        n.event_date,
        n.created_at,
        n.metadata,
        is_following_calc as is_following,
        EXISTS(
            SELECT 1 FROM user_news_interactions uni 
            WHERE uni.user_id = p_user_id 
            AND uni.news_id = n.id 
            AND uni.interaction_type = 'view'
        ) as has_viewed,
        EXISTS(
            SELECT 1 FROM user_news_interactions uni 
            WHERE uni.user_id = p_user_id 
            AND uni.news_id = n.id 
            AND uni.interaction_type = 'like'
        ) as has_liked
    FROM (
        SELECT *,
            EXISTS(
                SELECT 1 FROM user_artists ua 
                WHERE ua.user_id = p_user_id 
                AND ua.artist_id = n.artist_id
                AND ua.is_active = true
            ) as is_following_calc
        FROM idol_news n
        WHERE n.is_active = true
        AND n.created_at >= NOW() - INTERVAL '30 days' -- Only recent news
        AND (
            -- Show news for artists the user follows
            EXISTS(
                SELECT 1 FROM user_artists ua 
                WHERE ua.user_id = p_user_id 
                AND ua.artist_id = n.artist_id
                AND ua.is_active = true
            )
            OR 
            -- Show high priority news for all users
            n.priority IN ('urgent', 'high')
        )
        AND (
            -- Apply priority filter
            p_priority_filter = 'all'
            OR (p_priority_filter = 'high' AND n.priority IN ('urgent', 'high'))
            OR (p_priority_filter = 'medium_high' AND n.priority IN ('urgent', 'high', 'normal'))
        )
        AND (
            -- Apply user's minimum priority preference
            CASE user_prefs.min_priority
                WHEN 'urgent' THEN n.priority = 'urgent'
                WHEN 'high' THEN n.priority IN ('urgent', 'high')
                WHEN 'normal' THEN n.priority IN ('urgent', 'high', 'normal')
                ELSE true
            END
        )
    ) n
    ORDER BY 
        priority_score DESC,
        n.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$ LANGUAGE plpgsql;

-- Function to track news view
CREATE OR REPLACE FUNCTION track_news_view(
    p_user_id UUID,
    p_news_id UUID
)
RETURNS VOID AS $$
BEGIN
    -- Insert view interaction
    INSERT INTO user_news_interactions (user_id, news_id, interaction_type)
    VALUES (p_user_id, p_news_id, 'view')
    ON CONFLICT (user_id, news_id, interaction_type) DO NOTHING;
    
    -- Increment view count
    UPDATE idol_news 
    SET views_count = views_count + 1
    WHERE id = p_news_id;
END;
$$ LANGUAGE plpgsql;

-- RLS Policies
ALTER TABLE idol_news ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_news_interactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE news_notifications ENABLE ROW LEVEL SECURITY;

-- Anyone can read news
CREATE POLICY "Public read access to idol news" ON idol_news
    FOR SELECT USING (is_active = true);

-- Only service role can insert/update news
CREATE POLICY "Service role manage idol news" ON idol_news
    FOR ALL USING (auth.jwt() ->> 'role' = 'service_role');

-- Users can only manage their own interactions
CREATE POLICY "Users manage own interactions" ON user_news_interactions
    FOR ALL USING (auth.uid() = user_id);

-- Users can only see their own notifications
CREATE POLICY "Users see own notifications" ON news_notifications
    FOR SELECT USING (auth.uid() = user_id);

-- Cache cleanup function
CREATE OR REPLACE FUNCTION cleanup_expired_cache()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM news_cache 
    WHERE created_at + (ttl * INTERVAL '1 second') < NOW();
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- Function to calculate news priority score
CREATE OR REPLACE FUNCTION calculate_news_priority_score(
    content TEXT,
    news_type TEXT,
    is_followed_artist BOOLEAN DEFAULT false
)
RETURNS INTEGER AS $$
DECLARE
    score INTEGER := 0;
    keyword_rec RECORD;
BEGIN
    -- Base score for followed artists
    IF is_followed_artist THEN
        score := score + 100;
    END IF;
    
    -- Add points for matching keywords
    FOR keyword_rec IN 
        SELECT weight, priority_level 
        FROM priority_keywords 
        WHERE is_active = true 
        AND (news_type IS NULL OR priority_keywords.news_type = calculate_news_priority_score.news_type)
        AND position(lower(keyword) in lower(content)) > 0
    LOOP
        score := score + keyword_rec.weight * CASE keyword_rec.priority_level
            WHEN 'high' THEN 10
            WHEN 'medium' THEN 5
            WHEN 'low' THEN 1
            ELSE 1
        END;
    END LOOP;
    
    RETURN score;
END;
$$ LANGUAGE plpgsql;

-- RLS Policies for new tables
ALTER TABLE news_cache ENABLE ROW LEVEL SECURITY;
ALTER TABLE priority_keywords ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_news_preferences ENABLE ROW LEVEL SECURITY;

-- Public read access to cache (managed by service role)
CREATE POLICY "Service role manage cache" ON news_cache
    FOR ALL USING (auth.jwt() ->> 'role' = 'service_role');

-- Public read access to priority keywords
CREATE POLICY "Public read priority keywords" ON priority_keywords
    FOR SELECT USING (is_active = true);

-- Users manage their own preferences
CREATE POLICY "Users manage own preferences" ON user_news_preferences
    FOR ALL USING (auth.uid() = user_id);

-- Analytics function for top performing artists
CREATE OR REPLACE FUNCTION get_top_performing_artists(days_back INTEGER DEFAULT 7)
RETURNS TABLE (
    artist_name TEXT,
    artist_id UUID,
    total_news INTEGER,
    priority_news INTEGER,
    total_interactions INTEGER,
    follower_count INTEGER,
    engagement_score NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        n.artist_name,
        n.artist_id,
        COUNT(*)::INTEGER as total_news,
        COUNT(CASE WHEN n.priority IN ('urgent', 'high') THEN 1 END)::INTEGER as priority_news,
        COALESCE(i.interaction_count, 0)::INTEGER as total_interactions,
        COALESCE(f.follower_count, 0)::INTEGER as follower_count,
        (
            COUNT(*) * 10 +                                           -- Base news score
            COUNT(CASE WHEN n.priority = 'urgent' THEN 1 END) * 50 +   -- Urgent news bonus
            COUNT(CASE WHEN n.priority = 'high' THEN 1 END) * 20 +     -- High priority bonus
            COALESCE(i.interaction_count, 0) * 5 +                     -- Interaction bonus
            COALESCE(f.follower_count, 0) * 2                          -- Follower bonus
        )::NUMERIC as engagement_score
    FROM idol_news n
    LEFT JOIN (
        SELECT 
            news.artist_id,
            COUNT(*) as interaction_count
        FROM user_news_interactions uni
        JOIN idol_news news ON uni.news_id = news.id
        WHERE uni.created_at >= NOW() - (days_back || ' days')::INTERVAL
        GROUP BY news.artist_id
    ) i ON n.artist_id = i.artist_id
    LEFT JOIN (
        SELECT 
            artist_id,
            COUNT(*) as follower_count
        FROM user_artists
        WHERE is_active = true
        GROUP BY artist_id
    ) f ON n.artist_id = f.artist_id
    WHERE n.created_at >= NOW() - (days_back || ' days')::INTERVAL
    AND n.is_active = true
    GROUP BY n.artist_name, n.artist_id, i.interaction_count, f.follower_count
    ORDER BY engagement_score DESC
    LIMIT 20;
END;
$$ LANGUAGE plpgsql;

-- Function to get user news feed with optimized 3-artist constraint
CREATE OR REPLACE FUNCTION get_optimized_user_feed(
    p_user_id UUID,
    p_limit INTEGER DEFAULT 20
)
RETURNS TABLE (
    news_id UUID,
    artist_name TEXT,
    title TEXT,
    priority TEXT,
    news_type TEXT,
    created_at TIMESTAMP WITH TIME ZONE,
    priority_rank INTEGER
) AS $$
BEGIN
    -- Leverage the 3-artist constraint for optimized queries
    RETURN QUERY
    WITH user_top_artists AS (
        SELECT ua.artist_id, ua.priority_rank
        FROM user_artists ua
        WHERE ua.user_id = p_user_id
        AND ua.is_active = true
        ORDER BY ua.priority_rank
        LIMIT 3  -- MVP constraint: max 3 artists
    ),
    prioritized_news AS (
        SELECT 
            n.id,
            n.artist_name,
            n.title,
            n.priority,
            n.news_type,
            n.created_at,
            CASE 
                WHEN n.priority = 'urgent' THEN 1000 + (4 - COALESCE(uta.priority_rank, 4)) * 100
                WHEN n.priority = 'high' THEN 500 + (4 - COALESCE(uta.priority_rank, 4)) * 50
                WHEN n.priority = 'normal' THEN 100 + (4 - COALESCE(uta.priority_rank, 4)) * 10
                ELSE 10 + (4 - COALESCE(uta.priority_rank, 4))
            END as priority_score
        FROM idol_news n
        LEFT JOIN user_top_artists uta ON n.artist_id = uta.artist_id
        WHERE n.is_active = true
        AND n.created_at >= NOW() - INTERVAL '7 days'  -- Recent news only
        AND (
            -- News from followed artists
            uta.artist_id IS NOT NULL
            OR
            -- High priority news from all artists
            n.priority IN ('urgent', 'high')
        )
    )
    SELECT 
        pn.id,
        pn.artist_name,
        pn.title,
        pn.priority,
        pn.news_type,
        pn.created_at,
        pn.priority_score
    FROM prioritized_news pn
    ORDER BY pn.priority_score DESC, pn.created_at DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;