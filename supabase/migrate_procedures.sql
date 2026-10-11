CREATE OR REPLACE PROCEDURE public.register_employee(
    p_first text,
    p_last  text,
    p_email text,
    p_phone text DEFAULT NULL,
    INOUT out_employee_id varchar DEFAULT NULL
)
LANGUAGE plpgsql
SET search_path = ''
AS $$
DECLARE
    v_first text := btrim(coalesce(p_first, ''));
    v_last  text := btrim(coalesce(p_last, ''));
    v_email text := lower(btrim(coalesce(p_email, '')));
    v_phone text := nullif(regexp_replace(coalesce(p_phone, ''), '\D', '', 'g'), '');
    v_num   integer;
BEGIN
    IF v_first = '' OR v_last = '' OR v_email = '' THEN
        RAISE EXCEPTION 'BR-08: ต้องกรอกชื่อ นามสกุล และอีเมลของพนักงานให้ครบ';
    END IF;

    IF v_phone IS NOT NULL AND length(v_phone) NOT BETWEEN 9 AND 10 THEN
        RAISE EXCEPTION 'BR-07: เบอร์โทรต้องมี 9-10 หลัก';
    END IF;

    IF EXISTS (SELECT 1 FROM public.employee e WHERE lower(e.email) = v_email) THEN
        RAISE EXCEPTION 'BR-09: อีเมล % เป็นพนักงานอยู่แล้ว', v_email;
    END IF;

    PERFORM pg_advisory_xact_lock(hashtext('public.employee.employee_id'));

    SELECT coalesce(max(nullif(regexp_replace(e.employee_id, '\D', '', 'g'), '')::integer), 0) + 1
    INTO   v_num
    FROM   public.employee e;

    out_employee_id := 'E' || lpad(v_num::text, 3, '0');

    INSERT INTO public.employee (employee_id, first_name, last_name, email, phone)
    VALUES (out_employee_id, v_first, v_last, v_email, v_phone);
END;
$$;

REVOKE EXECUTE ON PROCEDURE public.register_employee(text, text, text, text, varchar) FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE PROCEDURE public.erase_customer(
    p_email text,
    INOUT out_bookings_removed integer DEFAULT NULL,
    INOUT out_fines_removed    integer DEFAULT NULL
)
LANGUAGE plpgsql
SET search_path = ''
AS $$
DECLARE
    v_email text := lower(btrim(coalesce(p_email, '')));
    v_id    varchar(20);
BEGIN
    SELECT u.user_id INTO v_id
    FROM   public.users u
    WHERE  lower(u.email) = v_email;

    IF v_id IS NULL THEN
        RAISE EXCEPTION 'BR-10: ไม่พบลูกค้าที่ใช้อีเมล %', v_email;
    END IF;

    IF EXISTS (
        SELECT 1 FROM public.booking b
        WHERE  b.user_id = v_id
          AND  b.status IN ('Reserved', 'In_Use', 'Overdue')
    ) THEN
        RAISE EXCEPTION 'BR-11: ลูกค้ายังมีการจองที่ยังไม่เสร็จสิ้น ลบข้อมูลไม่ได้';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM   public.fine f
        JOIN   public.booking b ON b.booking_id = f.booking_id
        WHERE  b.user_id = v_id
          AND  f.status = 'Unpaid'
    ) THEN
        RAISE EXCEPTION 'BR-12: ลูกค้ายังมีค่าปรับค้างชำระ ลบข้อมูลไม่ได้';
    END IF;

    SELECT count(*) INTO out_fines_removed
    FROM   public.fine f
    JOIN   public.booking b ON b.booking_id = f.booking_id
    WHERE  b.user_id = v_id;

    DELETE FROM public.booking b WHERE b.user_id = v_id;
    GET DIAGNOSTICS out_bookings_removed = ROW_COUNT;

    DELETE FROM public.users u WHERE u.user_id = v_id;
END;
$$;

REVOKE EXECUTE ON PROCEDURE public.erase_customer(text, integer, integer) FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE PROCEDURE public.run_maintenance(
    p_keep integer DEFAULT 200,
    INOUT out_cancelled integer DEFAULT NULL,
    INOUT out_overdue   integer DEFAULT NULL,
    INOUT out_pruned    integer DEFAULT NULL
)
LANGUAGE plpgsql
SET search_path = ''
AS $$
DECLARE
    v_cancelled_before integer;
    v_overdue_before   integer;
BEGIN
    IF p_keep IS NULL OR p_keep < 50 THEN
        RAISE EXCEPTION 'BR-13: ต้องเก็บประวัติการคืนอย่างน้อย 50 รายการ';
    END IF;

    SELECT count(*) FILTER (WHERE b.status = 'Cancelled'),
           count(*) FILTER (WHERE b.status = 'Overdue')
    INTO   v_cancelled_before, v_overdue_before
    FROM   public.booking b;

    PERFORM public.sweep_booking_statuses();

    SELECT count(*) FILTER (WHERE b.status = 'Cancelled') - v_cancelled_before,
           count(*) FILTER (WHERE b.status = 'Overdue')   - v_overdue_before
    INTO   out_cancelled, out_overdue
    FROM   public.booking b;

    out_pruned := public.prune_returned_history(p_keep);
END;
$$;

REVOKE EXECUTE ON PROCEDURE public.run_maintenance(integer, integer, integer, integer) FROM PUBLIC, anon, authenticated;
