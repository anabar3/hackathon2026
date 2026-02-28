-- Allow users to insert their own encounters
CREATE POLICY "Allow users to insert their own encounters"
ON encuentros FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Allow users to update their own encounters
CREATE POLICY "Allow users to update their own encounters"
ON encuentros FOR UPDATE
USING (auth.uid() = user_id);

-- Allow users to read their own encounters
CREATE POLICY "Allow users to read their own encounters"
ON encuentros FOR SELECT
USING (auth.uid() = user_id);

-- Ensure RLS is enabled
ALTER TABLE encuentros ENABLE ROW LEVEL SECURITY;
