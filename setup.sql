-- Drop existing objects
DO $$ 
DECLARE
    _sql text;
BEGIN
    -- Drop realtime publication if it exists
    DROP PUBLICATION IF EXISTS supabase_realtime;

    -- Drop functions with their dependencies
    DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
    DROP FUNCTION IF EXISTS public.update_updated_at_column() CASCADE;
    DROP FUNCTION IF EXISTS public.check_available_seats() CASCADE;

    -- Drop tables if they exist (in correct order to handle foreign keys)
    DROP TABLE IF EXISTS ratings CASCADE;
    DROP TABLE IF EXISTS chat_messages CASCADE;
    DROP TABLE IF EXISTS bookings CASCADE;
    DROP TABLE IF EXISTS rides CASCADE;
    DROP TABLE IF EXISTS profiles CASCADE;

    -- Drop policies only if the tables exist
    FOR _sql IN
        SELECT FORMAT('DROP POLICY IF EXISTS %I ON %I', policyname, tablename::text)
        FROM pg_policies
        WHERE schemaname = 'public'
    LOOP
        EXECUTE _sql;
    END LOOP;

END
$$;

-- Create realtime publication
CREATE PUBLICATION supabase_realtime;

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Note: Execute the following files in order:
-- 1. Run this setup.sql first (drops existing objects)
-- 2. Run schema.sql second (creates tables and policies)
-- 3. Run test_data.sql last (inserts test data)

-- You can also combine all files into one if needed
-- Just copy the contents of schema.sql and test_data.sql below this line
