ALTER TABLE public.booking
    ADD COLUMN IF NOT EXISTS booker_name  VARCHAR(201),
    ADD COLUMN IF NOT EXISTS booker_phone VARCHAR(10);

CREATE OR REPLACE FUNCTION public.snapshot_booker()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    SELECT nullif(btrim(u.first_name || ' ' || u.last_name), ''), u.phone
    INTO   NEW.booker_name, NEW.booker_phone
    FROM   public.users u
    WHERE  u.user_id = NEW.user_id;

    RETURN NEW;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.snapshot_booker() FROM PUBLIC;

DROP TRIGGER IF EXISTS trg_snapshot_booker ON public.booking;

CREATE TRIGGER trg_snapshot_booker
    BEFORE INSERT ON public.booking
    FOR EACH ROW
    EXECUTE FUNCTION public.snapshot_booker();

UPDATE public.booking b
SET    booker_name  = nullif(btrim(u.first_name || ' ' || u.last_name), ''),
       booker_phone = u.phone
FROM   public.users u
WHERE  u.user_id = b.user_id
  AND  b.booker_name IS NULL;
