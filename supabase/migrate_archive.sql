ALTER TABLE public.board_game ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP;

DROP POLICY IF EXISTS booking_insert_reserved ON public.booking;

CREATE POLICY booking_insert_reserved ON public.booking
    FOR INSERT WITH CHECK (
        status = 'Reserved'
        AND actual_return_time IS NULL
        AND checkout_by_id IS NULL
        AND return_by_id IS NULL
        AND EXISTS (
            SELECT 1
            FROM public.game_copy c
            JOIN public.board_game g ON g.game_id = c.game_id
            WHERE c.copy_id = booking.copy_id
              AND g.deleted_at IS NULL
              AND c.condition_status IN ('Good', 'Fair')
        )
    );
