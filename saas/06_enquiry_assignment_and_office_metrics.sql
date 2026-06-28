-- ============================================================
-- ENQUIRY ASSIGNMENT + LIVE OFFICE METRICS
-- (applied to project wwnjrarqeunhqwsgpgem)
-- Safe to run multiple times (idempotent).
-- ============================================================

-- --------------------------------
-- 1. Enquiries can be assigned to an office / location (branch),
--    alongside the existing responsible_staff_id. Transfer between
--    staff = updating responsible_staff_id (allowed for org admins, or
--    the currently-responsible staff, per existing enquiries RLS).
--    All changes are captured by the activity_logs trigger (see 05).
-- --------------------------------
ALTER TABLE public.enquiries
  ADD COLUMN IF NOT EXISTS assigned_office_id uuid REFERENCES public.offices(id) ON DELETE SET NULL;
CREATE INDEX IF NOT EXISTS idx_enquiries_assigned_office ON public.enquiries(assigned_office_id);

-- --------------------------------
-- 2. Live per-office metrics. The offices table has stale stored columns
--    (staff_count / revenue / workload_percentage) that were only ever set
--    to 0 at creation. This RPC derives them on read instead:
--      staff_count         = profiles assigned to the office
--      revenue             = collected payments on the office's work orders
--      workload_percentage = active (Pending/In-Progress) ÷ total work orders
--    Scoped to the caller's org; SECURITY DEFINER to read across tables, with
--    the WHERE clause enforcing tenant isolation.
-- --------------------------------
CREATE OR REPLACE FUNCTION public.get_office_metrics()
RETURNS TABLE(
  office_id           uuid,
  staff_count         int,
  revenue             numeric,
  active_work_orders  int,
  total_work_orders   int,
  workload_percentage int
)
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    o.id,
    (SELECT count(*) FROM profiles pr WHERE pr.office_id = o.id)::int,
    COALESCE((
      SELECT sum(p.paid_amount)
      FROM payments p JOIN work_orders w ON w.id = p.work_order_id
      WHERE w.assigned_office_id = o.id
    ), 0),
    (SELECT count(*) FROM work_orders w
      WHERE w.assigned_office_id = o.id AND w.status::text IN ('Pending','In-Progress'))::int,
    (SELECT count(*) FROM work_orders w WHERE w.assigned_office_id = o.id)::int,
    CASE
      WHEN (SELECT count(*) FROM work_orders w WHERE w.assigned_office_id = o.id) = 0 THEN 0
      ELSE round(
        (SELECT count(*) FROM work_orders w
           WHERE w.assigned_office_id = o.id AND w.status::text IN ('Pending','In-Progress'))::numeric
        * 100
        / (SELECT count(*) FROM work_orders w WHERE w.assigned_office_id = o.id)
      )::int
    END
  FROM offices o
  WHERE o.org_id = public.get_my_org_id();
$$;

REVOKE EXECUTE ON FUNCTION public.get_office_metrics() FROM public, anon;
GRANT  EXECUTE ON FUNCTION public.get_office_metrics() TO authenticated;

-- --------------------------------
-- 3. Hardening: the audit trigger functions from 05 should not be callable
--    as REST RPCs (they only make sense as triggers). Triggers still fire.
-- --------------------------------
REVOKE EXECUTE ON FUNCTION public.log_activity() FROM public, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.log_work_order_status_change() FROM public, anon, authenticated;
