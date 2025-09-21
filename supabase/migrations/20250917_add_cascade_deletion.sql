-- Add CASCADE deletion to all foreign key constraints
-- This ensures when a user is deleted, all their related data is automatically deleted

-- 1. Drop existing foreign key constraints and recreate with CASCADE

-- fan_activities table
ALTER TABLE IF EXISTS fan_activities
DROP CONSTRAINT IF EXISTS fan_activities_user_id_fkey;

ALTER TABLE IF EXISTS fan_activities
ADD CONSTRAINT fan_activities_user_id_fkey
  FOREIGN KEY (user_id)
  REFERENCES users(id)
  ON DELETE CASCADE;

-- user_artists table
ALTER TABLE IF EXISTS user_artists
DROP CONSTRAINT IF EXISTS user_artists_user_id_fkey;

ALTER TABLE IF EXISTS user_artists
ADD CONSTRAINT user_artists_user_id_fkey
  FOREIGN KEY (user_id)
  REFERENCES users(id)
  ON DELETE CASCADE;

-- user_priorities table
ALTER TABLE IF EXISTS user_priorities
DROP CONSTRAINT IF EXISTS user_priorities_user_id_fkey;

ALTER TABLE IF EXISTS user_priorities
ADD CONSTRAINT user_priorities_user_id_fkey
  FOREIGN KEY (user_id)
  REFERENCES users(id)
  ON DELETE CASCADE;

-- insight_feedback table
ALTER TABLE IF EXISTS insight_feedback
DROP CONSTRAINT IF EXISTS insight_feedback_user_id_fkey;

ALTER TABLE IF EXISTS insight_feedback
ADD CONSTRAINT insight_feedback_user_id_fkey
  FOREIGN KEY (user_id)
  REFERENCES users(id)
  ON DELETE CASCADE;

-- 2. Add RLS policy for users to delete their own account
DROP POLICY IF EXISTS "Users can delete own account" ON users;

CREATE POLICY "Users can delete own account"
ON users
FOR DELETE
USING (
  auth.uid() = auth_user_id
  OR
  id = auth.uid()
);

-- 3. Add comment for documentation
COMMENT ON POLICY "Users can delete own account" ON users IS
'Allows users to delete their own account. Checks both auth_user_id and id for compatibility.';

-- 4. Ensure RLS is enabled on all user-related tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE fan_activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_artists ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_priorities ENABLE ROW LEVEL SECURITY;
ALTER TABLE insight_feedback ENABLE ROW LEVEL SECURITY;