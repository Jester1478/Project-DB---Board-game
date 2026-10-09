CREATE SEQUENCE IF NOT EXISTS public.fine_id_seq;

CREATE TABLE IF NOT EXISTS public.fine (
    fine_id       VARCHAR(20) PRIMARY KEY,
    booking_id    VARCHAR(20) NOT NULL UNIQUE,
    amount        NUMERIC(8,2) NOT NULL,

    status VARCHAR(10) NOT NULL DEFAULT 'Unpaid'
        CHECK (status IN (
            'Unpaid',
            'Paid',
            'Waived'
        )),

    issued_at     TIMESTAMP NOT NULL,
    settled_at    TIMESTAMP,
    settled_by_id VARCHAR(20),

    CONSTRAINT chk_fine_amount
        CHECK (amount > 0),

    CONSTRAINT chk_fine_settlement
        CHECK (
            (status = 'Unpaid') = (settled_at IS NULL)
            AND (status <> 'Unpaid' OR settled_by_id IS NULL)
        ),

    CONSTRAINT fk_fine_booking
        FOREIGN KEY (booking_id)
        REFERENCES public.booking(booking_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_fine_settled_employee
        FOREIGN KEY (settled_by_id)
        REFERENCES public.employee(employee_id)
        ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_fine_status
    ON public.fine(status);

CREATE OR REPLACE FUNCTION public.issue_late_fine()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    fine_per_late_return CONSTANT numeric := 10;
BEGIN
    IF NEW.actual_return_time > NEW.end_time THEN
        INSERT INTO public.fine (fine_id, booking_id, amount, issued_at)
        VALUES (
            'FN-' || lpad(nextval('public.fine_id_seq')::text, 4, '0'),
            NEW.booking_id,
            fine_per_late_return,
            now() AT TIME ZONE 'Asia/Bangkok'
        )
        ON CONFLICT (booking_id) DO NOTHING;
    END IF;

    RETURN NULL;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.issue_late_fine() FROM PUBLIC;

DROP TRIGGER IF EXISTS trg_issue_late_fine ON public.booking;

CREATE TRIGGER trg_issue_late_fine
    AFTER UPDATE OF status ON public.booking
    FOR EACH ROW
    WHEN (NEW.status = 'Returned' AND OLD.status IS DISTINCT FROM NEW.status)
    EXECUTE FUNCTION public.issue_late_fine();

CREATE OR REPLACE FUNCTION public.stamp_fine_settlement()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
    IF NEW.status = 'Unpaid' THEN
        NEW.settled_at    := NULL;
        NEW.settled_by_id := NULL;
    ELSIF OLD.status = 'Unpaid' THEN
        NEW.settled_at := now() AT TIME ZONE 'Asia/Bangkok';
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_stamp_fine_settlement ON public.fine;

CREATE TRIGGER trg_stamp_fine_settlement
    BEFORE UPDATE ON public.fine
    FOR EACH ROW
    EXECUTE FUNCTION public.stamp_fine_settlement();

ALTER TABLE public.fine ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS fine_read_employee ON public.fine;
DROP POLICY IF EXISTS fine_settle_employee ON public.fine;

CREATE POLICY fine_read_employee ON public.fine
    FOR SELECT USING (public.is_employee());
CREATE POLICY fine_settle_employee ON public.fine
    FOR UPDATE USING (public.is_employee()) WITH CHECK (public.is_employee());

REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON public.fine FROM anon, authenticated;
GRANT SELECT ON public.fine TO anon, authenticated;
GRANT UPDATE (status, settled_by_id) ON public.fine TO authenticated;

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
      AND  r.rn > keep
      AND  NOT EXISTS (
               SELECT 1 FROM public.fine f
               WHERE  f.booking_id = b.booking_id
                 AND  f.status = 'Unpaid'
           );

    GET DIAGNOSTICS removed = ROW_COUNT;
    RETURN removed;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.prune_returned_history(integer) FROM PUBLIC;
