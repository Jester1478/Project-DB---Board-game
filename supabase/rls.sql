CREATE OR REPLACE FUNCTION public.is_employee()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.employee e
        WHERE lower(e.email) = lower(auth.jwt() ->> 'email')
    );
$$;

GRANT EXECUTE ON FUNCTION public.is_employee() TO anon, authenticated;

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

DROP POLICY IF EXISTS catalog_read ON public.category;
DROP POLICY IF EXISTS catalog_read ON public.board_game;
DROP POLICY IF EXISTS catalog_read ON public.game_category;
DROP POLICY IF EXISTS catalog_read ON public.game_copy;
DROP POLICY IF EXISTS catalog_write_employee ON public.category;
DROP POLICY IF EXISTS catalog_write_employee ON public.board_game;
DROP POLICY IF EXISTS catalog_write_employee ON public.game_category;
DROP POLICY IF EXISTS catalog_write_employee ON public.game_copy;
DROP POLICY IF EXISTS employee_read_self ON public.employee;
DROP POLICY IF EXISTS users_read ON public.users;
DROP POLICY IF EXISTS users_insert ON public.users;
DROP POLICY IF EXISTS users_update_employee ON public.users;
DROP POLICY IF EXISTS users_delete_unbooked ON public.users;
DROP POLICY IF EXISTS booking_read ON public.booking;
DROP POLICY IF EXISTS booking_insert_reserved ON public.booking;
DROP POLICY IF EXISTS booking_update_employee ON public.booking;
DROP POLICY IF EXISTS booking_delete_employee ON public.booking;

CREATE POLICY catalog_read ON public.category      FOR SELECT USING (true);
CREATE POLICY catalog_read ON public.board_game    FOR SELECT USING (true);
CREATE POLICY catalog_read ON public.game_category FOR SELECT USING (true);
CREATE POLICY catalog_read ON public.game_copy     FOR SELECT USING (true);

CREATE POLICY catalog_write_employee ON public.category
    FOR ALL USING (public.is_employee()) WITH CHECK (public.is_employee());
CREATE POLICY catalog_write_employee ON public.board_game
    FOR ALL USING (public.is_employee()) WITH CHECK (public.is_employee());
CREATE POLICY catalog_write_employee ON public.game_category
    FOR ALL USING (public.is_employee()) WITH CHECK (public.is_employee());
CREATE POLICY catalog_write_employee ON public.game_copy
    FOR ALL USING (public.is_employee()) WITH CHECK (public.is_employee());

CREATE POLICY employee_read_self ON public.employee
    FOR SELECT USING (lower(email) = lower(auth.jwt() ->> 'email'));

CREATE POLICY users_read ON public.users
    FOR SELECT USING (true);
CREATE POLICY users_insert ON public.users
    FOR INSERT WITH CHECK (true);
CREATE POLICY users_update_employee ON public.users
    FOR UPDATE USING (public.is_employee()) WITH CHECK (public.is_employee());
CREATE POLICY users_delete_unbooked ON public.users
    FOR DELETE USING (
        public.is_employee()
        OR NOT EXISTS (SELECT 1 FROM public.booking b WHERE b.user_id = users.user_id)
    );

CREATE POLICY booking_read ON public.booking
    FOR SELECT USING (true);
CREATE POLICY booking_insert_reserved ON public.booking
    FOR INSERT WITH CHECK (
        status = 'Reserved'
        AND actual_return_time IS NULL
        AND checkout_by_id IS NULL
        AND return_by_id IS NULL
    );
CREATE POLICY booking_update_employee ON public.booking
    FOR UPDATE USING (public.is_employee()) WITH CHECK (public.is_employee());
CREATE POLICY booking_delete_employee ON public.booking
    FOR DELETE USING (public.is_employee());
