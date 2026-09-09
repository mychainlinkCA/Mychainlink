-- ============================================================
-- SEARCH HISTORY TABLE
-- Saves user search queries for autocomplete/recent searches
-- ============================================================

DROP TABLE IF EXISTS search_history CASCADE;

CREATE TABLE search_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  query TEXT NOT NULL,
  result_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE search_history ENABLE ROW LEVEL SECURITY;

-- Users can only see their own search history
CREATE POLICY "Users can view own search history"
  ON search_history FOR SELECT USING (auth.uid() = user_id);

-- Users can only insert their own search history
CREATE POLICY "Users can insert own search history"
  ON search_history FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can only delete their own search history
CREATE POLICY "Users can delete own search history"
  ON search_history FOR DELETE USING (auth.uid() = user_id);

-- Index for fast recent-search lookups
CREATE INDEX idx_search_history_user_id ON search_history(user_id);
CREATE INDEX idx_search_history_created_at ON search_history(created_at DESC);

-- ============================================================
-- FULL-TEXT SEARCH SUPPORT ON PROFILES
-- ============================================================

-- Add a generated column for full-text search (if not exists)
ALTER TABLE profiles 
  ADD COLUMN IF NOT EXISTS search_vector tsvector 
  GENERATED ALWAYS AS (
    to_tsvector('english', 
      coalesce(display_name, '') || ' ' || 
      coalesce(handle, '') || ' ' || 
      coalesce(bio, '')
    )
  ) STORED;

CREATE INDEX IF NOT EXISTS idx_profiles_search ON profiles USING GIN(search_vector);

-- Function to search profiles with full-text
CREATE OR REPLACE FUNCTION search_profiles(search_term TEXT)
RETURNS TABLE (
  id UUID,
  display_name TEXT,
  handle TEXT,
  avatar_url TEXT,
  bio TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.id,
    p.display_name,
    p.handle,
    p.avatar_url,
    p.bio
  FROM profiles p
  WHERE 
    p.display_name ILIKE '%' || search_term || '%'
    OR p.handle ILIKE '%' || search_term || '%'
    OR p.search_vector @@ plainto_tsquery('english', search_term)
  ORDER BY 
    CASE 
      WHEN p.display_name ILIKE search_term || '%' THEN 0
      WHEN p.handle ILIKE search_term || '%' THEN 1
      ELSE 2
    END,
    p.display_name
  LIMIT 50;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
