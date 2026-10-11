REVOKE EXECUTE ON FUNCTION public.sweep_booking_statuses()        FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.prune_returned_history(integer) FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.enforce_booking_rules()         FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.snapshot_booker()               FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.issue_late_fine()               FROM PUBLIC, anon, authenticated;
