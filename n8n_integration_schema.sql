-- Artist Updates Table
CREATE TABLE IF NOT EXISTS artist_updates (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  artist_name TEXT NOT NULL,
  update_type TEXT NOT NULL, -- 'new_music', 'concert', 'social_media', 'news', 'breaking'
  content TEXT NOT NULL,
  source_url TEXT,
  image_url TEXT,
  timestamp TIMESTAMPTZ DEFAULT NOW(),
  priority TEXT DEFAULT 'normal', -- 'low', 'normal', 'high', 'breaking'
  is_processed BOOLEAN DEFAULT FALSE,
  metadata JSONB, -- Additional data from n8n
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Artist Subscriptions Table
CREATE TABLE IF NOT EXISTS artist_subscriptions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  artist_name TEXT NOT NULL,
  is_active BOOLEAN DEFAULT TRUE,
  notification_settings JSONB DEFAULT '{
    "new_music": true,
    "concerts": true,
    "social_media": true,
    "news": true,
    "breaking": true
  }'::jsonb,
  subscribed_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, artist_name)
);

-- Push Notifications Queue Table
CREATE TABLE IF NOT EXISTS push_notifications (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  data JSONB, -- Additional payload data
  is_sent BOOLEAN DEFAULT FALSE,
  sent_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_artist_updates_artist_time ON artist_updates(artist_name, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_artist_updates_priority ON artist_updates(priority, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_artist_subscriptions_user ON artist_subscriptions(user_id) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_artist_subscriptions_artist ON artist_subscriptions(artist_name) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_push_notifications_user ON push_notifications(user_id) WHERE is_sent = FALSE;

-- Row Level Security (RLS) Policies
ALTER TABLE artist_updates ENABLE ROW LEVEL SECURITY;
ALTER TABLE artist_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE push_notifications ENABLE ROW LEVEL SECURITY;

-- RLS Policies for artist_updates (read-only for authenticated users)
CREATE POLICY "Users can view artist updates" ON artist_updates
  FOR SELECT TO authenticated
  USING (TRUE);

-- RLS Policies for artist_subscriptions
CREATE POLICY "Users can manage their own subscriptions" ON artist_subscriptions
  FOR ALL TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- RLS Policies for push_notifications
CREATE POLICY "Users can view their own notifications" ON push_notifications
  FOR SELECT TO authenticated
  USING (auth.uid() = user_id);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger for artist_subscriptions
CREATE TRIGGER update_artist_subscriptions_updated_at 
  BEFORE UPDATE ON artist_subscriptions 
  FOR EACH ROW 
  EXECUTE FUNCTION update_updated_at_column();