-- Push Notifications Schema for PiggyBong
-- This creates the necessary tables for managing push notifications

-- Table to store user device tokens
CREATE TABLE IF NOT EXISTS user_device_tokens (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    device_token TEXT NOT NULL,
    platform TEXT NOT NULL CHECK (platform IN ('ios', 'android')),
    app_version TEXT,
    device_model TEXT,
    os_version TEXT,
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    last_used_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),

    -- Unique constraint to prevent duplicate tokens
    UNIQUE(user_id, device_token)
);

-- Table to log all sent notifications for analytics
CREATE TABLE IF NOT EXISTS notification_logs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    notification_type TEXT NOT NULL CHECK (notification_type IN ('concert', 'album', 'news', 'ticket', 'general')),
    artist_name TEXT,
    data JSONB,
    sent_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    success_count INTEGER DEFAULT 0,
    fail_count INTEGER DEFAULT 0,

    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Create indexes for efficient querying
CREATE INDEX IF NOT EXISTS idx_notification_logs_user_sent_at ON notification_logs (user_id, sent_at DESC);
CREATE INDEX IF NOT EXISTS idx_notification_logs_type ON notification_logs (notification_type);
CREATE INDEX IF NOT EXISTS idx_notification_logs_artist ON notification_logs (artist_name);

-- Table for notification preferences per user
CREATE TABLE IF NOT EXISTS notification_preferences (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,

    -- Global notification settings
    push_notifications_enabled BOOLEAN DEFAULT true,
    email_notifications_enabled BOOLEAN DEFAULT true,

    -- Specific notification types
    concert_notifications BOOLEAN DEFAULT true,
    album_notifications BOOLEAN DEFAULT true,
    news_notifications BOOLEAN DEFAULT true,
    ticket_notifications BOOLEAN DEFAULT true,

    -- Timing preferences
    quiet_hours_start TIME,
    quiet_hours_end TIME,
    timezone TEXT DEFAULT 'UTC',

    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Table for artist-specific notification preferences
CREATE TABLE IF NOT EXISTS artist_notification_preferences (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    artist_name TEXT NOT NULL,

    -- Artist-specific settings
    concert_notifications BOOLEAN DEFAULT true,
    album_notifications BOOLEAN DEFAULT true,
    news_notifications BOOLEAN DEFAULT false, -- Default off to prevent spam

    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,

    -- Ensure one record per user-artist combination
    UNIQUE(user_id, artist_name)
);

-- Table to track notification templates for consistency
CREATE TABLE IF NOT EXISTS notification_templates (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    template_type TEXT NOT NULL CHECK (template_type IN ('concert', 'album', 'news', 'ticket')),
    title_template TEXT NOT NULL,
    body_template TEXT NOT NULL,
    category TEXT, -- iOS notification category
    sound TEXT DEFAULT 'default',

    -- Template variables documentation
    variables JSONB, -- e.g., {"artist_name": "string", "event_date": "date"}

    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Insert default notification templates
INSERT INTO notification_templates (template_type, title_template, body_template, category, variables) VALUES
('concert', '{artist_name} Concert Alert! 🎵', '{artist_name} announced new tour dates! Get your tickets before they sell out.', 'CONCERT_ALERT', '{"artist_name": "string", "venue": "string", "date": "date"}'),
('album', 'New {artist_name} Release! 💿', '{artist_name} just dropped a new {release_type}! Listen now on your favorite platform.', 'ALBUM_RELEASE', '{"artist_name": "string", "release_type": "string", "album_name": "string"}'),
('news', '{artist_name} Update 📰', 'Latest news from {artist_name}: {preview_text}', 'NEWS_UPDATE', '{"artist_name": "string", "preview_text": "string"}'),
('ticket', 'Ticket Sale Alert! 🎫', '{artist_name} tickets are now available! Presale starts {sale_date}.', 'TICKET_SALE', '{"artist_name": "string", "sale_date": "date", "venue": "string"}')
ON CONFLICT DO NOTHING;

-- Enable Row Level Security (RLS)
ALTER TABLE user_device_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE artist_notification_preferences ENABLE ROW LEVEL SECURITY;

-- RLS Policies for user_device_tokens
CREATE POLICY "Users can manage their own device tokens" ON user_device_tokens
    FOR ALL USING (auth.uid() = user_id);

-- RLS Policies for notification_logs
CREATE POLICY "Users can view their own notification logs" ON notification_logs
    FOR SELECT USING (auth.uid() = user_id);

-- Service role can insert notification logs
CREATE POLICY "Service role can insert notification logs" ON notification_logs
    FOR INSERT WITH CHECK (auth.role() = 'service_role');

-- RLS Policies for notification_preferences
CREATE POLICY "Users can manage their own notification preferences" ON notification_preferences
    FOR ALL USING (auth.uid() = user_id);

-- RLS Policies for artist_notification_preferences
CREATE POLICY "Users can manage their own artist notification preferences" ON artist_notification_preferences
    FOR ALL USING (auth.uid() = user_id);

-- Create or replace function for updating timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at timestamps (only if they don't exist)
DROP TRIGGER IF EXISTS update_user_device_tokens_updated_at ON user_device_tokens;
CREATE TRIGGER update_user_device_tokens_updated_at
    BEFORE UPDATE ON user_device_tokens
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_notification_preferences_updated_at ON notification_preferences;
CREATE TRIGGER update_notification_preferences_updated_at
    BEFORE UPDATE ON notification_preferences
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_notification_templates_updated_at ON notification_templates;
CREATE TRIGGER update_notification_templates_updated_at
    BEFORE UPDATE ON notification_templates
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON user_device_tokens TO authenticated;
GRANT SELECT ON notification_logs TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON notification_preferences TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON artist_notification_preferences TO authenticated;
GRANT SELECT ON notification_templates TO authenticated, anon;