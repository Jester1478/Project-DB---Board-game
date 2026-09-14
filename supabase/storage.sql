INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'game-images',
    'game-images',
    true,
    5242880,
    ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET
    public             = EXCLUDED.public,
    file_size_limit    = EXCLUDED.file_size_limit,
    allowed_mime_types = EXCLUDED.allowed_mime_types;

DROP POLICY IF EXISTS game_images_select_employee ON storage.objects;
DROP POLICY IF EXISTS game_images_insert_employee ON storage.objects;
DROP POLICY IF EXISTS game_images_update_employee ON storage.objects;
DROP POLICY IF EXISTS game_images_delete_employee ON storage.objects;

CREATE POLICY game_images_select_employee ON storage.objects
    FOR SELECT USING (bucket_id = 'game-images' AND public.is_employee());

CREATE POLICY game_images_insert_employee ON storage.objects
    FOR INSERT WITH CHECK (bucket_id = 'game-images' AND public.is_employee());

CREATE POLICY game_images_update_employee ON storage.objects
    FOR UPDATE
    USING (bucket_id = 'game-images' AND public.is_employee())
    WITH CHECK (bucket_id = 'game-images' AND public.is_employee());

CREATE POLICY game_images_delete_employee ON storage.objects
    FOR DELETE USING (bucket_id = 'game-images' AND public.is_employee());
