-- ============================================================
-- ACTIVITY / AUDIT LOG  (applied to project wwnjrarqeunhqwsgpgem)
-- Centralized "who did what, when" across all core operations.
--
-- Populated automatically by AFTER triggers using auth.uid(), so:
--   * no app code path can forget to log
--   * direct DB / dashboard edits are captured too
--   * before/after diffs are stored for updates
--
-- Append-only. Readable by org admins (super_admin / admin) for
-- their own org; platform admin sees everything.
-- Safe to run multiple times (idempotent).
-- ============================================================

CREATE TABLE IF NOT EXISTS public.activity_logs (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id       uuid REFERENCES public.organizations(id) ON DELETE CASCADE,
  actor_id     uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  actor_name   text,
  actor_role   text,
  action       text NOT NULL,            -- created | updated | deleted | deactivated | reactivated
  entity_type  text NOT NULL,            -- office | staff | work_order | client | service | leave | attendance | payment | enquiry | document
  entity_id    uuid,
  entity_label text,
  summary      text,
  changes      jsonb,                    -- {field: {old, new}} for updates
  created_at   timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_activity_logs_org_created ON public.activity_logs(org_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_activity_logs_entity      ON public.activity_logs(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_activity_logs_actor       ON public.activity_logs(actor_id);

-- Generic logging trigger function.
-- TG_ARGV[0] = entity_type, TG_ARGV[1] = label column name.
-- SECURITY DEFINER so the INSERT bypasses activity_logs RLS.
-- Never raises: a logging failure must not break the real operation.
CREATE OR REPLACE FUNCTION public.log_activity()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_entity     text := TG_ARGV[0];
  v_label_col  text := TG_ARGV[1];
  v_actor      uuid := auth.uid();
  v_actor_name text;
  v_actor_role text;
  v_actor_org  uuid;
  v_org        uuid;
  v_action     text;
  v_label      text;
  v_changes    jsonb;
  v_rec        jsonb;
  v_old        jsonb;
  v_entity_id  uuid;
  v_summary    text;
BEGIN
  IF TG_OP = 'DELETE' THEN
    v_rec := to_jsonb(OLD); v_action := 'deleted';
  ELSIF TG_OP = 'INSERT' THEN
    v_rec := to_jsonb(NEW); v_action := 'created';
  ELSE
    v_rec := to_jsonb(NEW); v_old := to_jsonb(OLD); v_action := 'updated';
  END IF;

  v_entity_id := NULLIF(v_rec->>'id','')::uuid;
  v_label     := v_rec->>v_label_col;
  v_org       := NULLIF(v_rec->>'org_id','')::uuid;

  IF v_actor IS NOT NULL THEN
    SELECT name, role::text, org_id
      INTO v_actor_name, v_actor_role, v_actor_org
    FROM public.profiles WHERE id = v_actor;
  END IF;
  v_org       := COALESCE(v_org, v_actor_org);
  v_actor_name := COALESCE(v_actor_name, 'System');

  IF TG_OP = 'UPDATE' THEN
    SELECT jsonb_object_agg(n.key, jsonb_build_object('old', o.value, 'new', n.value))
      INTO v_changes
    FROM jsonb_each(v_rec) n
    LEFT JOIN jsonb_each(v_old) o ON o.key = n.key
    WHERE n.value IS DISTINCT FROM o.value
      AND n.key NOT IN ('updated_at', 'created_at');

    IF v_changes IS NULL THEN
      RETURN NEW;   -- nothing meaningful changed
    END IF;

    IF v_entity = 'staff' AND (v_changes ? 'is_active') THEN
      v_action := CASE WHEN (v_rec->>'is_active') = 'false'
                       THEN 'deactivated' ELSE 'reactivated' END;
    END IF;
  END IF;

  v_summary := v_action || ' ' || replace(v_entity, '_', ' ')
             || CASE WHEN v_label IS NOT NULL AND v_label <> ''
                     THEN ' "' || v_label || '"' ELSE '' END;

  INSERT INTO public.activity_logs
    (org_id, actor_id, actor_name, actor_role, action,
     entity_type, entity_id, entity_label, summary, changes)
  VALUES
    (v_org, v_actor, v_actor_name, v_actor_role, v_action,
     v_entity, v_entity_id, v_label, v_summary, v_changes);

  RETURN COALESCE(NEW, OLD);
EXCEPTION WHEN OTHERS THEN
  RETURN COALESCE(NEW, OLD);
END;
$$;

-- Attach triggers to all tracked tables.
DROP TRIGGER IF EXISTS trg_log_offices        ON public.offices;
CREATE TRIGGER trg_log_offices        AFTER INSERT OR UPDATE OR DELETE ON public.offices
  FOR EACH ROW EXECUTE FUNCTION public.log_activity('office', 'name');

DROP TRIGGER IF EXISTS trg_log_profiles       ON public.profiles;
CREATE TRIGGER trg_log_profiles       AFTER INSERT OR UPDATE OR DELETE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.log_activity('staff', 'name');

DROP TRIGGER IF EXISTS trg_log_work_orders    ON public.work_orders;
CREATE TRIGGER trg_log_work_orders    AFTER INSERT OR UPDATE OR DELETE ON public.work_orders
  FOR EACH ROW EXECUTE FUNCTION public.log_activity('work_order', 'client_name');

DROP TRIGGER IF EXISTS trg_log_clients        ON public.clients;
CREATE TRIGGER trg_log_clients        AFTER INSERT OR UPDATE OR DELETE ON public.clients
  FOR EACH ROW EXECUTE FUNCTION public.log_activity('client', 'full_name');

DROP TRIGGER IF EXISTS trg_log_services       ON public.services;
CREATE TRIGGER trg_log_services       AFTER INSERT OR UPDATE OR DELETE ON public.services
  FOR EACH ROW EXECUTE FUNCTION public.log_activity('service', 'name');

DROP TRIGGER IF EXISTS trg_log_leaves         ON public.leaves;
CREATE TRIGGER trg_log_leaves         AFTER INSERT OR UPDATE OR DELETE ON public.leaves
  FOR EACH ROW EXECUTE FUNCTION public.log_activity('leave', 'leave_type');

DROP TRIGGER IF EXISTS trg_log_attendance     ON public.attendance;
CREATE TRIGGER trg_log_attendance     AFTER INSERT OR UPDATE OR DELETE ON public.attendance
  FOR EACH ROW EXECUTE FUNCTION public.log_activity('attendance', 'location_gps');

DROP TRIGGER IF EXISTS trg_log_payments       ON public.payments;
CREATE TRIGGER trg_log_payments       AFTER INSERT OR UPDATE OR DELETE ON public.payments
  FOR EACH ROW EXECUTE FUNCTION public.log_activity('payment', 'status');

DROP TRIGGER IF EXISTS trg_log_enquiries      ON public.enquiries;
CREATE TRIGGER trg_log_enquiries      AFTER INSERT OR UPDATE OR DELETE ON public.enquiries
  FOR EACH ROW EXECUTE FUNCTION public.log_activity('enquiry', 'client_name');

DROP TRIGGER IF EXISTS trg_log_task_documents ON public.task_documents;
CREATE TRIGGER trg_log_task_documents AFTER INSERT OR UPDATE OR DELETE ON public.task_documents
  FOR EACH ROW EXECUTE FUNCTION public.log_activity('document', 'title');

-- RLS: org admins read their org's log; platform admin reads all.
-- Append-only — no INSERT/UPDATE/DELETE policies (trigger inserts via
-- SECURITY DEFINER, bypassing RLS).
ALTER TABLE public.activity_logs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS activity_logs_select ON public.activity_logs;
CREATE POLICY activity_logs_select ON public.activity_logs
  FOR SELECT USING (
    (org_id = public.get_my_org_id() AND public.is_org_admin())
    OR public.is_platform_admin()
  );

-- ============================================================
-- WORK-ORDER TIMELINE: record WHO, and auto-log status changes
-- ============================================================

-- created_by references profiles(id) (not auth.users) so PostgREST can embed
-- the actor name via `profiles:created_by(name)`. profiles.id -> auth.users(id),
-- so referential integrity is preserved.
ALTER TABLE public.task_history
  ADD COLUMN IF NOT EXISTS created_by uuid DEFAULT auth.uid();
ALTER TABLE public.task_history DROP CONSTRAINT IF EXISTS task_history_created_by_fkey;
ALTER TABLE public.task_history
  ADD CONSTRAINT task_history_created_by_fkey
  FOREIGN KEY (created_by) REFERENCES public.profiles(id) ON DELETE SET NULL;

CREATE OR REPLACE FUNCTION public.log_work_order_status_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.status IS DISTINCT FROM OLD.status THEN
    INSERT INTO public.task_history (work_order_id, title, description, status_at_time, created_by)
    VALUES (
      NEW.id,
      'Status changed to ' || NEW.status::text || ' / تم تغيير الحالة',
      'Status updated from ' || COALESCE(OLD.status::text,'-') || ' to ' || NEW.status::text,
      NEW.status,
      auth.uid()
    );
  END IF;
  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_work_order_status_history ON public.work_orders;
CREATE TRIGGER trg_work_order_status_history
  AFTER UPDATE OF status ON public.work_orders
  FOR EACH ROW EXECUTE FUNCTION public.log_work_order_status_change();
