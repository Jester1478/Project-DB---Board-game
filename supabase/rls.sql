ALTER TABLE public.users         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.employee      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.category      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.board_game    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.game_category ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.game_copy     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.booking       ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS prototype_public_access ON public.users;
DROP POLICY IF EXISTS prototype_public_access ON public.employee;
DROP POLICY IF EXISTS prototype_public_access ON public.category;
DROP POLICY IF EXISTS prototype_public_access ON public.board_game;
DROP POLICY IF EXISTS prototype_public_access ON public.game_category;
DROP POLICY IF EXISTS prototype_public_access ON public.game_copy;
DROP POLICY IF EXISTS prototype_public_access ON public.booking;

CREATE POLICY prototype_public_access ON public.users
    FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY prototype_public_access ON public.employee
    FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY prototype_public_access ON public.category
    FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY prototype_public_access ON public.board_game
    FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY prototype_public_access ON public.game_category
    FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY prototype_public_access ON public.game_copy
    FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY prototype_public_access ON public.booking
    FOR ALL USING (true) WITH CHECK (true);
