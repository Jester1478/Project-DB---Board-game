-- ============================================================
-- Optional seed data — mirrors the games currently hardcoded in
-- web/app/composables/useBoardGameStore.ts, so the database
-- starts with the same catalog the frontend already shows.
-- Run this after schema.sql, in the Supabase SQL Editor.
-- ============================================================

INSERT INTO CATEGORY (Categories_ID, Categories_Name) VALUES
    ('CAT-STRAT', 'Strategy'),
    ('CAT-PARTY', 'Party'),
    ('CAT-FAM',   'Family');

INSERT INTO BOARD_GAME (Game_ID, Game_Name, Description, Min_Players, Max_Players, Play_Time_Mins) VALUES
    ('GM-CATAN', 'Catan',           'สร้างถนน หมู่บ้าน และเมือง แข่งกันสะสมแต้มชัยชนะจากทรัพยากร', 3, 4, 90),
    ('GM-CODE',  'Codenames',       'สองทีมทายคำใบ้จากหัวหน้าสายลับ ระวังคำมือสังหาร',              4, 8, 20),
    ('GM-SPLEN', 'Splendor',        'เก็บโทเคนอัญมณีเพื่อซื้อการ์ดพัฒนาและสะสมแต้มเกียรติยศ',        2, 4, 30),
    ('GM-COUP',  'Coup',            'บลัฟและใช้ความสามารถตัวละครลับเพื่อกำจัดอิทธิพลของคู่แข่ง',      2, 6, 15),
    ('GM-TTR',   'Ticket to Ride',  'เก็บการ์ดรถไฟเพื่อยึดครองเส้นทางและทำภารกิจให้สำเร็จ',           2, 5, 60),
    ('GM-SUSHI', 'Sushi Go!',       'ดราฟต์การ์ดซูชิแต่ละรอบเพื่อทำคอมโบให้ได้แต้มสูงสุด',            2, 5, 20);

INSERT INTO GAME_CATEGORY (Game_ID, Categories_ID) VALUES
    ('GM-CATAN', 'CAT-STRAT'),
    ('GM-SPLEN', 'CAT-STRAT'),
    ('GM-CODE',  'CAT-PARTY'),
    ('GM-COUP',  'CAT-PARTY'),
    ('GM-TTR',   'CAT-FAM'),
    ('GM-SUSHI', 'CAT-FAM');

INSERT INTO GAME_COPY (Copy_ID, Copy_Code, Condition_Status, Copy_Numbers, Game_ID) VALUES
    ('CP-CATAN-01', 'CATAN-01', 'Good', 1, 'GM-CATAN'),
    ('CP-CATAN-02', 'CATAN-02', 'Good', 2, 'GM-CATAN'),
    ('CP-CODE-01',  'CODE-01',  'Good', 1, 'GM-CODE'),
    ('CP-SPLEN-01', 'SPLEN-01', 'Good', 1, 'GM-SPLEN'),
    ('CP-SPLEN-02', 'SPLEN-02', 'Good', 2, 'GM-SPLEN'),
    ('CP-COUP-01',  'COUP-01',  'Good', 1, 'GM-COUP'),
    ('CP-TTR-01',   'TTR-01',   'Good', 1, 'GM-TTR'),
    ('CP-SUSHI-01', 'SUSHI-01', 'Good', 1, 'GM-SUSHI'),
    ('CP-SUSHI-02', 'SUSHI-02', 'Good', 2, 'GM-SUSHI');
