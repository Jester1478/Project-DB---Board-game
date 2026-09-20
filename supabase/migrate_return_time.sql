ALTER TABLE public.booking
    DROP CONSTRAINT IF EXISTS chk_booking_return_time;

ALTER TABLE public.booking
    DROP CONSTRAINT IF EXISTS chk_booking_returned_has_time;

ALTER TABLE public.booking
    ADD CONSTRAINT chk_booking_returned_has_time
    CHECK (status <> 'Returned' OR actual_return_time IS NOT NULL);
