CREATE OR REPLACE FUNCTION public.find_or_create_user(
    p_email text,
    p_first text,
    p_last  text,
    p_phone text DEFAULT NULL
)
RETURNS TABLE (out_user_id varchar, out_was_created boolean)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_email text := lower(btrim(coalesce(p_email, '')));
    v_phone text := nullif(regexp_replace(coalesce(p_phone, ''), '\D', '', 'g'), '');
    v_id    varchar(20);
    v_num   integer;
BEGIN
    IF v_email = '' THEN
        RAISE EXCEPTION 'BR-06: กรุณากรอกอีเมล';
    END IF;

    IF v_phone IS NOT NULL AND length(v_phone) NOT BETWEEN 9 AND 10 THEN
        RAISE EXCEPTION 'BR-07: เบอร์โทรต้องมี 9-10 หลัก';
    END IF;

    SELECT u.user_id INTO v_id
    FROM   public.users u
    WHERE  lower(u.email) = v_email;

    IF v_id IS NOT NULL THEN
        UPDATE public.users u
        SET    first_name = coalesce(nullif(btrim(coalesce(p_first, '')), ''), u.first_name),
               last_name  = coalesce(nullif(btrim(coalesce(p_last, '')), ''), u.last_name),
               phone      = coalesce(v_phone, u.phone)
        WHERE  u.user_id = v_id;

        RETURN QUERY SELECT v_id, false;
        RETURN;
    END IF;

    PERFORM pg_advisory_xact_lock(hashtext('public.users.user_id'));

    SELECT coalesce(max(nullif(regexp_replace(u.user_id, '\D', '', 'g'), '')::integer), 0) + 1
    INTO   v_num
    FROM   public.users u
    WHERE  u.user_id LIKE 'U%';

    v_id := 'U' || lpad(v_num::text, 3, '0');

    INSERT INTO public.users (user_id, first_name, last_name, email, phone)
    VALUES (v_id, btrim(coalesce(p_first, '')), btrim(coalesce(p_last, '')), v_email, v_phone);

    RETURN QUERY SELECT v_id, true;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.find_or_create_user(text, text, text, text) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.find_or_create_user(text, text, text, text) TO anon, authenticated;

DROP POLICY IF EXISTS users_read ON public.users;
DROP POLICY IF EXISTS users_read_employee ON public.users;
DROP POLICY IF EXISTS users_insert ON public.users;
DROP POLICY IF EXISTS users_delete_unbooked ON public.users;

CREATE POLICY users_read_employee ON public.users
    FOR SELECT USING (public.is_employee());

CREATE POLICY users_delete_unbooked ON public.users
    FOR DELETE USING (
        public.is_employee()
        OR NOT EXISTS (
            SELECT 1 FROM public.booking b WHERE b.user_id = users.user_id
        )
    );
