CREATE OR REPLACE FUNCTION public.enforce_booking_rules()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    now_local     timestamp := now() AT TIME ZONE 'Asia/Bangkok';
    overdue_count integer;
    active_count  integer;
BEGIN
    IF NEW.start_time < now_local - INTERVAL '1 minute' THEN
        RAISE EXCEPTION 'BR-05: จองย้อนหลังไม่ได้ กรุณาเลือกเวลาที่ยังมาไม่ถึง';
    END IF;

    SELECT count(*) INTO overdue_count
    FROM   public.booking
    WHERE  user_id = NEW.user_id
      AND  (
             status = 'Overdue'
             OR (status = 'In_Use' AND end_time < now_local)
           );

    IF overdue_count > 0 THEN
        RAISE EXCEPTION 'BR-04: คุณมีรายการค้างเกินกำหนดคืน โปรดคืนเกมก่อนจองใหม่';
    END IF;

    SELECT count(*) INTO active_count
    FROM   public.booking
    WHERE  user_id = NEW.user_id
      AND  (
             status IN ('In_Use', 'Overdue')
             OR (status = 'Reserved' AND start_time >= now_local - INTERVAL '10 minutes')
           );

    IF active_count >= 2 THEN
        RAISE EXCEPTION 'BR-01: คุณมีรายการจองที่ยังไม่จบครบ 2 รายการแล้ว กรุณาคืนเกมก่อนจองเพิ่ม';
    END IF;

    RETURN NEW;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.enforce_booking_rules() FROM PUBLIC;

DROP TRIGGER IF EXISTS trg_enforce_booking_rules ON public.booking;

CREATE TRIGGER trg_enforce_booking_rules
    BEFORE INSERT ON public.booking
    FOR EACH ROW
    EXECUTE FUNCTION public.enforce_booking_rules();
