-- ============================================================
-- MYCHAINLINK.CA — CLEAN SCHEMA (matches codebase 100%)
-- Run this in Supabase SQL Editor (all at once)
-- ============================================================

-- ============================================================
-- 1. PROFILES TABLE (extends auth.users)
-- ============================================================
DROP TABLE IF EXISTS profiles CASCADE;
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name TEXT,
  handle TEXT UNIQUE,
  bio TEXT,
  avatar_url TEXT,
  subscription_price INTEGER,
  conversation_theme TEXT,
  conversation_color TEXT,
  is_premium BOOLEAN DEFAULT FALSE,
  premium_until TIMESTAMPTZ,
  song_title TEXT,
  song_artist TEXT,
  song_url TEXT,
  tutorial_seen BOOLEAN DEFAULT FALSE,
  is_creator BOOLEAN DEFAULT FALSE,
  location TEXT,
  website TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public profiles are viewable by everyone"
  ON profiles FOR SELECT USING (true);

CREATE POLICY "Users can insert own profile"
  ON profiles FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE USING (auth.uid() = id);

CREATE INDEX idx_profiles_handle ON profiles(handle);
CREATE INDEX idx_profiles_display_name ON profiles(display_name);

-- ============================================================
-- 2. POSTS TABLE
-- ============================================================
DROP TABLE IF EXISTS posts CASCADE;
CREATE TABLE posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name TEXT,
  handle TEXT,
  avatar_url TEXT,
  text TEXT,
  font_class TEXT DEFAULT 'font-inter',
  text_color TEXT DEFAULT '#DEDAD2',
  media_url TEXT,
  is_video BOOLEAN DEFAULT FALSE,
  location TEXT,
  tags TEXT,
  comments_enabled BOOLEAN DEFAULT TRUE,
  subscribers_only BOOLEAN DEFAULT FALSE,
  likes UUID[] DEFAULT '{}',
  dislikes UUID[] DEFAULT '{}',
  comments JSONB[] DEFAULT '{}',
  loves UUID[] DEFAULT '{}',
  photos TEXT[],
  repost_of UUID REFERENCES posts(id) ON DELETE SET NULL,
  repost_from_uid UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE posts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read posts"
  ON posts FOR SELECT USING (true);

CREATE POLICY "Authenticated users can create posts"
  ON posts FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own posts"
  ON posts FOR DELETE USING (auth.uid() = user_id);

CREATE INDEX idx_posts_user_id ON posts(user_id);
CREATE INDEX idx_posts_created_at ON posts(created_at DESC);

-- ============================================================
-- 3. FOLLOWS TABLE (connections)
-- ============================================================
DROP TABLE IF EXISTS follows CASCADE;
CREATE TABLE follows (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  follower_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  following_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  subscribed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(follower_id, following_id)
);

ALTER TABLE follows ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read follows"
  ON follows FOR SELECT USING (true);

CREATE POLICY "Authenticated users can follow"
  ON follows FOR INSERT WITH CHECK (auth.uid() = follower_id);

CREATE POLICY "Users can unfollow"
  ON follows FOR DELETE USING (auth.uid() = follower_id);

CREATE INDEX idx_follows_follower ON follows(follower_id);
CREATE INDEX idx_follows_following ON follows(following_id);

-- ============================================================
-- 4. CONVERSATIONS TABLE
-- ============================================================
DROP TABLE IF EXISTS conversations CASCADE;
CREATE TABLE conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  participant_1 UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  participant_2 UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  last_message_text TEXT,
  last_message_at TIMESTAMPTZ,
  UNIQUE(participant_1, participant_2)
);

ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own conversations"
  ON conversations FOR SELECT
  USING (auth.uid() = participant_1 OR auth.uid() = participant_2);

CREATE POLICY "Users can create conversations"
  ON conversations FOR INSERT WITH CHECK (auth.uid() = participant_1 OR auth.uid() = participant_2);

CREATE POLICY "Users can update own conversations"
  ON conversations FOR UPDATE
  USING (auth.uid() = participant_1 OR auth.uid() = participant_2);

CREATE INDEX idx_conv_p1 ON conversations(participant_1);
CREATE INDEX idx_conv_p2 ON conversations(participant_2);
CREATE INDEX idx_conv_updated ON conversations(updated_at DESC);

-- ============================================================
-- 5. MESSAGES TABLE
-- ============================================================
DROP TABLE IF EXISTS messages CASCADE;
CREATE TABLE messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE,
  sender_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read messages in their conversations"
  ON messages FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM conversations c
      WHERE c.id = messages.conversation_id
      AND (c.participant_1 = auth.uid() OR c.participant_2 = auth.uid())
    )
  );

CREATE POLICY "Users can send messages"
  ON messages FOR INSERT WITH CHECK (auth.uid() = sender_id);

CREATE INDEX idx_messages_conv ON messages(conversation_id);
CREATE INDEX idx_messages_created ON messages(created_at DESC);

-- ============================================================
-- 6. STORIES TABLE
-- ============================================================
DROP TABLE IF EXISTS stories CASCADE;
CREATE TABLE stories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  media_url TEXT,
  type TEXT,
  viewers UUID[] DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ
);

ALTER TABLE stories ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read stories"
  ON stories FOR SELECT USING (true);

CREATE POLICY "Users can create own stories"
  ON stories FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own stories"
  ON stories FOR UPDATE USING (auth.uid() = user_id);

CREATE INDEX idx_stories_user ON stories(user_id);
CREATE INDEX idx_stories_expires ON stories(expires_at);

-- ============================================================
-- 7. TRANSACTIONS TABLE
-- ============================================================
DROP TABLE IF EXISTS transactions CASCADE;
CREATE TABLE transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  payer_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  creator_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  amount NUMERIC(10,2),
  currency TEXT DEFAULT 'USD',
  status TEXT DEFAULT 'pending',
  paypal_order_id TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ,
  type TEXT,
  platform_fee NUMERIC(10,2),
  creator_amount NUMERIC(10,2),
  paypal_subscription_id TEXT
);

ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own transactions"
  ON transactions FOR SELECT
  USING (auth.uid() = payer_id OR auth.uid() = creator_id);

CREATE INDEX idx_tx_payer ON transactions(payer_id);
CREATE INDEX idx_tx_creator ON transactions(creator_id);

-- ============================================================
-- 8. USER_SONGS TABLE
-- ============================================================
DROP TABLE IF EXISTS user_songs CASCADE;
CREATE TABLE user_songs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT,
  artist TEXT,
  song_url TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id)
);

ALTER TABLE user_songs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read user_songs"
  ON user_songs FOR SELECT USING (true);

CREATE POLICY "Users can insert own songs"
  ON user_songs FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own songs"
  ON user_songs FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own songs"
  ON user_songs FOR DELETE USING (auth.uid() = user_id);

CREATE INDEX idx_user_songs_user ON user_songs(user_id);

-- ============================================================
-- 9. NOTIFICATIONS TABLE
-- ============================================================
DROP TABLE IF EXISTS notifications CASCADE;
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  type TEXT,
  content TEXT,
  related_id UUID,
  read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  actor_id UUID,
  actor_name TEXT,
  actor_handle TEXT,
  actor_avatar TEXT,
  post_id UUID
);

ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own notifications"
  ON notifications FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own notifications"
  ON notifications FOR DELETE USING (auth.uid() = user_id);

CREATE INDEX idx_notif_user ON notifications(user_id);
CREATE INDEX idx_notif_read ON notifications(read);
CREATE INDEX idx_notif_created ON notifications(created_at DESC);

-- ============================================================
-- 10. REPORTS TABLE
-- ============================================================
DROP TABLE IF EXISTS reports CASCADE;
CREATE TABLE reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  target_id UUID,
  target_type TEXT,
  reason TEXT,
  details TEXT,
  status TEXT DEFAULT 'pending',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE reports ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can submit reports"
  ON reports FOR INSERT WITH CHECK (true);

CREATE POLICY "Only admins can read reports"
  ON reports FOR SELECT USING (false);

-- ============================================================
-- 11. AUTH TRIGGER — auto-create profile on signup
-- ============================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, display_name, handle)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'display_name', NEW.email),
    COALESCE(NEW.raw_user_meta_data->>'handle', '@user_' || substr(NEW.id::text, 1, 8))
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================================
-- 12. AVATARS STORAGE BUCKET
-- ============================================================
-- Create bucket if it doesn't exist (run via SQL or Supabase UI)
-- Note: Bucket creation usually requires service_role or UI
-- INSERT INTO storage.buckets (id, name, public) VALUES ('avatars', 'avatars', true);

-- Storage policies for avatars bucket (apply via Supabase UI or SQL if you have permissions)
-- CREATE POLICY "Avatar images are publicly accessible"
--   ON storage.objects FOR SELECT USING (bucket_id = 'avatars');
-- CREATE POLICY "Anyone can upload an avatar"
--   ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'avatars');

-- ============================================================
-- DONE — Schema matches codebase 100%
-- ============================================================
