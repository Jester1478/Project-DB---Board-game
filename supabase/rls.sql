-- ============================================================
-- Row Level Security — Supabase-specific addition, not part of
-- the graded schema.sql. Run this after schema.sql (and
-- optionally seed.sql).
--
-- schema.sql is plain PostgreSQL and doesn't mention RLS at all.
-- Supabase enforces RLS on every table reachable through its
-- public API: with RLS off, anyone holding the anon key (which
-- is embedded in the frontend bundle, so effectively "anyone")
-- can read/write freely; with RLS on and no policy, everyone is
-- blocked, including your own app. The current frontend has no
-- login yet and calls Supabase directly from the browser, so it
-- needs an explicit (wide-open, for now) policy per table just
-- to keep working.
--
-- This is intentionally permissive and NOT safe for a real
-- deployment. Once there's real student/staff auth, replace
-- these with policies scoped to auth.uid() (e.g. a student can
-- only insert/update their own bookings, only staff can call
-- checkout/return).
-- ============================================================

ALTER TABLE USERS         ENABLE ROW LEVEL SECURITY;
ALTER TABLE EMPLOYEE      ENABLE ROW LEVEL SECURITY;
ALTER TABLE CATEGORY      ENABLE ROW LEVEL SECURITY;
ALTER TABLE BOARD_GAME    ENABLE ROW LEVEL SECURITY;
ALTER TABLE GAME_CATEGORY ENABLE ROW LEVEL SECURITY;
ALTER TABLE GAME_COPY     ENABLE ROW LEVEL SECURITY;
ALTER TABLE BOOKING       ENABLE ROW LEVEL SECURITY;

CREATE POLICY "public read/write (prototype only)" ON USERS
    FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "public read/write (prototype only)" ON EMPLOYEE
    FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "public read/write (prototype only)" ON CATEGORY
    FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "public read/write (prototype only)" ON BOARD_GAME
    FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "public read/write (prototype only)" ON GAME_CATEGORY
    FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "public read/write (prototype only)" ON GAME_COPY
    FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "public read/write (prototype only)" ON BOOKING
    FOR ALL USING (true) WITH CHECK (true);
