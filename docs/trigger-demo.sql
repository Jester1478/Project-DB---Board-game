-- สาธิตและถ่ายภาพ Trigger ทั้ง 4 ตัว
-- วิธีใช้: เปิด Supabase > SQL Editor แล้วคัดลอกไปรันทีละขั้น (อย่ารันทั้งไฟล์พร้อมกัน)
-- ขั้นที่ 4, 8, 10 ต้องขึ้น ERROR ซึ่งคือผลที่ถูกต้อง
-- ทำขั้นที่ 14 ทุกครั้งเมื่อเสร็จ เพื่อลบข้อมูลทดสอบ

-- ============================================================
-- ขั้นที่ 1: ดูรายชื่อ Trigger ทั้งหมด (ภาพที่ 1)
-- ============================================================
SELECT trigger_name, event_object_table AS table_name, action_timing, event_manipulation AS event
FROM information_schema.triggers
WHERE trigger_schema = 'public'
ORDER BY event_object_table, trigger_name;

-- ============================================================
-- ขั้นที่ 2: ดูโค้ดของฟังก์ชันที่ Trigger เรียก (ภาพที่ 2) เปลี่ยนชื่อฟังก์ชันเป็น snapshot_booker, issue_late_fine, stamp_fine_settlement ได้
-- ============================================================
SELECT pg_get_functiondef('public.enforce_booking_rules'::regproc);

-- ============================================================
-- ขั้นที่ 3: สร้างผู้ใช้ทดสอบ (ไม่ต้องถ่ายภาพ)
-- ============================================================
INSERT INTO public.users (user_id, first_name, last_name, email, phone)
VALUES ('U-TEST', 'ทดสอบ', 'ทริกเกอร์', 'trigger-test@example.com', '0800000000');

-- ============================================================
-- ขั้นที่ 4: Trigger 1: จองย้อนหลัง ต้องได้ ERROR BR-05 (ภาพที่ 3)
-- ============================================================
INSERT INTO public.booking (booking_id, start_time, end_time, user_id, copy_id)
VALUES ('BK-TEST1',
        (now() AT TIME ZONE 'Asia/Bangkok') - INTERVAL '2 hours',
        (now() AT TIME ZONE 'Asia/Bangkok') - INTERVAL '1 hour',
        'U-TEST', 'CP-WW-01');

-- ============================================================
-- ขั้นที่ 5: Trigger 2: จองปกติ ดูว่า booker_name และ booker_phone ถูกเติมให้เอง (ภาพที่ 4)
-- ============================================================
INSERT INTO public.booking (booking_id, start_time, end_time, user_id, copy_id)
VALUES ('BK-TEST1',
        date_trunc('day', now() AT TIME ZONE 'Asia/Bangkok') + INTERVAL '1 day 3 hours',
        date_trunc('day', now() AT TIME ZONE 'Asia/Bangkok') + INTERVAL '1 day 4 hours',
        'U-TEST', 'CP-WW-01')
RETURNING booking_id, user_id, booker_name, booker_phone, status;

-- ============================================================
-- ขั้นที่ 6: Trigger 2: เปลี่ยนชื่อผู้ใช้ แล้วดูว่าการจองเดิมยังเป็นชื่อเดิม
-- ============================================================
UPDATE public.users SET last_name = 'เปลี่ยนชื่อแล้ว' WHERE user_id = 'U-TEST';
SELECT b.booking_id, b.booker_name AS name_on_booking, u.first_name || ' ' || u.last_name AS name_now
FROM public.booking b JOIN public.users u ON u.user_id = b.user_id
WHERE b.booking_id = 'BK-TEST1';

-- ============================================================
-- ขั้นที่ 7: Trigger 2: การจองใหม่ได้ชื่อใหม่
-- ============================================================
INSERT INTO public.booking (booking_id, start_time, end_time, user_id, copy_id)
VALUES ('BK-TEST2',
        date_trunc('day', now() AT TIME ZONE 'Asia/Bangkok') + INTERVAL '1 day 4 hours',
        date_trunc('day', now() AT TIME ZONE 'Asia/Bangkok') + INTERVAL '1 day 5 hours',
        'U-TEST', 'CP-WW-01')
RETURNING booking_id, booker_name;

-- ============================================================
-- ขั้นที่ 8: Trigger 1: จองรายการที่ 3 ต้องได้ ERROR BR-01
-- ============================================================
INSERT INTO public.booking (booking_id, start_time, end_time, user_id, copy_id)
VALUES ('BK-TEST3',
        date_trunc('day', now() AT TIME ZONE 'Asia/Bangkok') + INTERVAL '1 day 5 hours',
        date_trunc('day', now() AT TIME ZONE 'Asia/Bangkok') + INTERVAL '1 day 6 hours',
        'U-TEST', 'CP-WW-01');

-- ============================================================
-- ขั้นที่ 9: ทำให้ BK-TEST1 เป็นเกมที่ยืมอยู่และเลยกำหนดคืน (ไม่ต้องถ่ายภาพ)
-- ============================================================
UPDATE public.booking
SET status = 'In_Use',
    start_time = (now() AT TIME ZONE 'Asia/Bangkok') - INTERVAL '2 hours',
    end_time   = (now() AT TIME ZONE 'Asia/Bangkok') - INTERVAL '1 hour'
WHERE booking_id = 'BK-TEST1';

-- ============================================================
-- ขั้นที่ 10: Trigger 1: มีเกมค้างคืนแล้วจองใหม่ ต้องได้ ERROR BR-04
-- ============================================================
INSERT INTO public.booking (booking_id, start_time, end_time, user_id, copy_id)
VALUES ('BK-TEST3',
        date_trunc('day', now() AT TIME ZONE 'Asia/Bangkok') + INTERVAL '1 day 5 hours',
        date_trunc('day', now() AT TIME ZONE 'Asia/Bangkok') + INTERVAL '1 day 6 hours',
        'U-TEST', 'CP-WW-01');

-- ============================================================
-- ขั้นที่ 11: Trigger 3: รับคืนช้า ต้องมีค่าปรับ 10 บาทเกิดขึ้นเอง (ภาพที่ 7)
-- ============================================================
UPDATE public.booking
SET status = 'Returned', actual_return_time = now() AT TIME ZONE 'Asia/Bangkok'
WHERE booking_id = 'BK-TEST1';
SELECT * FROM public.fine WHERE booking_id = 'BK-TEST1';

-- ============================================================
-- ขั้นที่ 12: Trigger 4: ชำระค่าปรับ ดูว่า settled_at ถูกประทับเวลาให้เอง (ภาพที่ 9)
-- ============================================================
UPDATE public.fine SET status = 'Paid', settled_by_id = (SELECT employee_id FROM public.employee LIMIT 1)
WHERE booking_id = 'BK-TEST1'
RETURNING fine_id, status, settled_at, settled_by_id;

-- ============================================================
-- ขั้นที่ 13: Trigger 4: ย้อนกลับเป็นค้างชำระ ดูว่าเวลาและผู้บันทึกถูกล้าง
-- ============================================================
UPDATE public.fine SET status = 'Unpaid' WHERE booking_id = 'BK-TEST1'
RETURNING fine_id, status, settled_at, settled_by_id;

-- ============================================================
-- ขั้นที่ 14: ลบข้อมูลทดสอบทั้งหมด ผลต้องเป็น 0 ทั้งสามช่อง
-- ============================================================
DELETE FROM public.booking WHERE booking_id IN ('BK-TEST1', 'BK-TEST2', 'BK-TEST3');
DELETE FROM public.users WHERE user_id = 'U-TEST';
SELECT (SELECT count(*) FROM public.booking WHERE booking_id LIKE 'BK-TEST%') AS bookings_left,
       (SELECT count(*) FROM public.fine f JOIN public.booking b USING (booking_id) WHERE b.booking_id LIKE 'BK-TEST%') AS fines_left,
       (SELECT count(*) FROM public.users WHERE user_id = 'U-TEST') AS users_left;
