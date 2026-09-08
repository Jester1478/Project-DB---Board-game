DELETE FROM public.game_category;
DELETE FROM public.game_copy;
DELETE FROM public.board_game;
DELETE FROM public.category;

INSERT INTO public.category (category_id, category_name) VALUES
    ('CAT-STRAT', 'Strategy'),
    ('CAT-PARTY', 'Party'),
    ('CAT-FAM',   'Family');

INSERT INTO public.board_game (game_id, game_name, description, min_players, max_players, play_time_mins) VALUES
    ('GM-EXKIT',  'เหมียวระเบิด',           'เกมการ์ดจั่วเอาตัวรอด ใครจั่วโดนแมวระเบิดแล้วไม่มีการ์ดกู้ระเบิดถือว่าตกรอบ',   2, 5, 15),
    ('GM-MUFFIN', 'มัฟฟินไทม์',              'เกมการ์ดป่วน ๆ สะสมไอเทมและขัดขาคู่แข่ง ใครทำเงื่อนไขชนะได้ก่อนเป็นผู้ชนะ',      2, 6, 30),
    ('GM-DND',    'ดันเจี้ยนแอนดรากอนส์',    'เกมสวมบทบาทผจญภัย มีผู้คุมเกม (DM) เล่าเรื่องและผู้เล่นสร้างตัวละครของตัวเอง',  3, 6, 240),
    ('GM-WEREWOLF','คืนล่ามนุษย์หมาป่า',     'เกมจับผิดหาตัวมนุษย์หมาป่าที่แฝงตัวในหมู่บ้าน สลับกลางวัน-กลางคืนจนกว่าจะจบ',  5, 12, 30),
    ('GM-CHEESE', 'ชีสหายไหไหน',             'เกมปาร์ตี้ตามหาชีสที่หายไป ใช้การสังเกตและการเดาเพื่อหาคำตอบก่อนใคร',          2, 6, 20),
    ('GM-RICH',   'เกมเศรษฐี',               'เกมกระดานคลาสสิก ทอยเต๋าเดินซื้อที่ดิน เก็บค่าเช่า ใครรวยที่สุดเป็นผู้ชนะ',      2, 6, 90);

INSERT INTO public.game_category (game_id, category_id) VALUES
    ('GM-EXKIT',   'CAT-PARTY'),
    ('GM-MUFFIN',  'CAT-PARTY'),
    ('GM-WEREWOLF','CAT-PARTY'),
    ('GM-DND',     'CAT-STRAT'),
    ('GM-CHEESE',  'CAT-FAM'),
    ('GM-RICH',    'CAT-FAM');

INSERT INTO public.game_copy (copy_id, copy_code, condition_status, copy_number, game_id) VALUES
    ('CP-EXKIT-01',  'EXKIT-01',  'Good', 1, 'GM-EXKIT'),
    ('CP-EXKIT-02',  'EXKIT-02',  'Good', 2, 'GM-EXKIT'),
    ('CP-MUFFIN-01', 'MUFFIN-01', 'Good', 1, 'GM-MUFFIN'),
    ('CP-DND-01',    'DND-01',    'Good', 1, 'GM-DND'),
    ('CP-WW-01',     'WW-01',     'Good', 1, 'GM-WEREWOLF'),
    ('CP-WW-02',     'WW-02',     'Good', 2, 'GM-WEREWOLF'),
    ('CP-CHEESE-01', 'CHEESE-01', 'Good', 1, 'GM-CHEESE'),
    ('CP-CHEESE-02', 'CHEESE-02', 'Good', 2, 'GM-CHEESE'),
    ('CP-RICH-01',   'RICH-01',   'Good', 1, 'GM-RICH');
