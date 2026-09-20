CREATE OR REPLACE FUNCTION public.prune_returned_history(keep integer DEFAULT 200)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    removed integer;
BEGIN
    WITH ranked AS (
        SELECT booking_id,
               row_number() OVER (
                   ORDER BY actual_return_time DESC NULLS LAST, booking_id DESC
               ) AS rn
        FROM   public.booking
        WHERE  status = 'Returned'
    )
    DELETE FROM public.booking b
    USING  ranked r
    WHERE  b.booking_id = r.booking_id
      AND  r.rn > keep;

    GET DIAGNOSTICS removed = ROW_COUNT;
    RETURN removed;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.prune_returned_history(integer) FROM PUBLIC;

SELECT cron.schedule(
    'prune-returned-history',
    '7 * * * *',
    $job$SELECT public.prune_returned_history(200)$job$
);
