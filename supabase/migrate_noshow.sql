CREATE EXTENSION IF NOT EXISTS pg_cron;

CREATE OR REPLACE FUNCTION public.sweep_booking_statuses()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    UPDATE public.booking
    SET    status = 'Cancelled'
    WHERE  status = 'Reserved'
      AND  start_time < (now() AT TIME ZONE 'Asia/Bangkok') - INTERVAL '10 minutes';

    UPDATE public.booking
    SET    status = 'Overdue'
    WHERE  status = 'In_Use'
      AND  end_time < (now() AT TIME ZONE 'Asia/Bangkok');
END;
$$;

REVOKE EXECUTE ON FUNCTION public.sweep_booking_statuses() FROM PUBLIC;

SELECT cron.schedule(
    'sweep-booking-statuses',
    '*/5 * * * *',
    $job$SELECT public.sweep_booking_statuses()$job$
);
