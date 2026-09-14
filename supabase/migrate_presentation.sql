ALTER TABLE public.board_game ADD COLUMN IF NOT EXISTS icon VARCHAR(16) NOT NULL DEFAULT '🎲';
ALTER TABLE public.board_game ADD COLUMN IF NOT EXISTS image_url TEXT;

CREATE TABLE IF NOT EXISTS public.how_to_play_step (
    game_id     VARCHAR(50) NOT NULL,
    step_number INTEGER NOT NULL CHECK (step_number > 0),
    step_text   TEXT NOT NULL,

    CONSTRAINT pk_how_to_play_step
        PRIMARY KEY (game_id, step_number),

    CONSTRAINT fk_how_to_play_step_game
        FOREIGN KEY (game_id)
        REFERENCES public.board_game(game_id)
        ON DELETE CASCADE
);

ALTER TABLE public.how_to_play_step ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS catalog_read ON public.how_to_play_step;
DROP POLICY IF EXISTS catalog_write_employee ON public.how_to_play_step;

CREATE POLICY catalog_read ON public.how_to_play_step
    FOR SELECT USING (true);
CREATE POLICY catalog_write_employee ON public.how_to_play_step
    FOR ALL USING (public.is_employee()) WITH CHECK (public.is_employee());

UPDATE public.board_game SET icon = '💥' WHERE game_id = 'GM-EXKIT';
UPDATE public.board_game SET icon = '🧁' WHERE game_id = 'GM-MUFFIN';
UPDATE public.board_game SET icon = '🐉' WHERE game_id = 'GM-DND';
UPDATE public.board_game SET icon = '🐺' WHERE game_id = 'GM-WEREWOLF';
UPDATE public.board_game SET icon = '🧀' WHERE game_id = 'GM-CHEESE';
UPDATE public.board_game SET icon = '💰' WHERE game_id = 'GM-RICH';

INSERT INTO public.how_to_play_step (game_id, step_number, step_text)
SELECT v.game_id, v.step_number, v.step_text
FROM (VALUES
    ('GM-EXKIT', 1, 'สับการ์ดแมวระเบิดใส่กองจั่วให้น้อยกว่าจำนวนผู้เล่น 1 ใบ และแจกการ์ดกู้ระเบิด (Defuse) ให้ทุกคนคนละ 1 ใบ'),
    ('GM-EXKIT', 2, 'ในแต่ละตา เล่นการ์ดพิเศษกี่ใบก็ได้ (ข้ามตา, โจมตี, ดูอนาคต, สับไพ่) แล้วจบตาด้วยการจั่ว 1 ใบ'),
    ('GM-EXKIT', 3, 'ถ้าจั่วโดนแมวระเบิด ต้องทิ้งการ์ดกู้ระเบิดเพื่อเอาตัวรอด แล้วแอบสอดแมวระเบิดกลับเข้ากองตรงไหนก็ได้'),
    ('GM-EXKIT', 4, 'ใครจั่วโดนแมวระเบิดแล้วไม่มีการ์ดกู้ระเบิดจะตกรอบ คนสุดท้ายที่เหลือรอดเป็นผู้ชนะ'),
    ('GM-MUFFIN', 1, 'แจกการ์ดให้ผู้เล่นคนละ 5 ใบ ที่เหลือวางเป็นกองจั่ว'),
    ('GM-MUFFIN', 2, 'ในแต่ละตา จั่ว 1 ใบ แล้วเล่นการ์ดได้ตามต้องการ ทั้งการ์ดไอเทมและการ์ดป่วนใส่คู่แข่ง'),
    ('GM-MUFFIN', 3, 'เมื่อโดนการ์ดโจมตี สามารถใช้การ์ดปฏิเสธเพื่อยกเลิกผลได้'),
    ('GM-MUFFIN', 4, 'ผู้เล่นที่ทำเงื่อนไขชนะได้สำเร็จก่อน (เช่น สะสมไอเทมครบ) เป็นผู้ชนะ'),
    ('GM-DND', 1, 'เลือกผู้เล่น 1 คนเป็นผู้คุมเกม (Dungeon Master) ทำหน้าที่เล่าเรื่องและควบคุมโลกในเกม'),
    ('GM-DND', 2, 'ผู้เล่นที่เหลือสร้างตัวละครของตัวเอง กำหนดเผ่าพันธุ์ อาชีพ และค่าความสามารถ'),
    ('GM-DND', 3, 'เมื่อจะทำสิ่งที่ผลลัพธ์ไม่แน่นอน ให้ทอยลูกเต๋า 20 หน้า (d20) บวกค่าความสามารถ เทียบกับค่าความยาก'),
    ('GM-DND', 4, 'ดำเนินเรื่องผ่านการสำรวจ พูดคุย และต่อสู้ ไปเรื่อย ๆ ตามเนื้อเรื่องที่ DM วางไว้'),
    ('GM-WEREWOLF', 1, 'แจกการ์ดบทบาทลับให้ทุกคน มีทั้งฝ่ายมนุษย์หมาป่า ชาวบ้าน และบทบาทพิเศษ เช่น หมอดู หมอ'),
    ('GM-WEREWOLF', 2, 'ช่วงกลางคืน ทุกคนหลับตา มนุษย์หมาป่าลืมตาแล้วเลือกกำจัดชาวบ้าน 1 คน บทบาทพิเศษใช้ความสามารถของตน'),
    ('GM-WEREWOLF', 3, 'ช่วงกลางวัน ทุกคนลืมตา ฟังว่าใครถูกกำจัด แล้วถกเถียงหาว่าใครคือหมาป่า ก่อนโหวตประหาร 1 คน'),
    ('GM-WEREWOLF', 4, 'ฝ่ายชาวบ้านชนะเมื่อกำจัดหมาป่าหมด ฝ่ายหมาป่าชนะเมื่อมีจำนวนเท่าหรือมากกว่าชาวบ้าน'),
    ('GM-CHEESE', 1, 'จัดวางอุปกรณ์ตามที่คู่มือกำหนด แล้วแจกการ์ดหรือหมากให้ผู้เล่นแต่ละคน'),
    ('GM-CHEESE', 2, 'ผลัดกันเล่นทีละตา ใช้การสังเกตและเบาะแสเพื่อคาดเดาว่าชีสถูกซ่อนอยู่ที่ใด'),
    ('GM-CHEESE', 3, 'เมื่อมั่นใจแล้วให้ประกาศคำตอบ หากถูกจะได้แต้ม หากผิดจะเสียโอกาสในตานั้น'),
    ('GM-CHEESE', 4, 'เล่นจนครบรอบที่กำหนด ผู้ที่ได้แต้มสูงสุดเป็นผู้ชนะ'),
    ('GM-RICH', 1, 'ผู้เล่นทุกคนเริ่มด้วยเงินทุนเท่ากัน วางหมากที่ช่องเริ่มต้น'),
    ('GM-RICH', 2, 'ผลัดกันทอยลูกเต๋าแล้วเดินหมากตามแต้มที่ได้'),
    ('GM-RICH', 3, 'หากหยุดบนที่ดินว่างสามารถซื้อได้ หากเป็นที่ดินของคนอื่นต้องจ่ายค่าเช่า'),
    ('GM-RICH', 4, 'สร้างบ้านและโรงแรมเพื่อเพิ่มค่าเช่า ใครทำให้คู่แข่งล้มละลายจนเหลือคนสุดท้ายเป็นผู้ชนะ')
) AS v(game_id, step_number, step_text)
WHERE EXISTS (SELECT 1 FROM public.board_game g WHERE g.game_id = v.game_id)
ON CONFLICT (game_id, step_number) DO NOTHING;
