-- ============================================================
-- SAAS MIGRATION — Step 4: Multi-Tenant RLS Policies
-- Run LAST, after 01, 02, and 03.
--
-- WARNING: This REPLACES all existing RLS policies.
-- Your existing single-tenant app will stop working until
-- the Flutter app is updated to pass org_id. The auto-fill
-- trigger in step 02 softens this for INSERTs.
--
-- Role hierarchy per org:
--   super_admin → org owner  (full control, billing, user mgmt)
--   admin       → org admin  (work orders, staff, offices)
--   staff       → staff      (own assigned work, attendance, leaves)
--   agent       → external   (own assigned work orders only)
--
-- is_platform_admin → SaaS operator (you); can see everything
-- ============================================================

-- ============================================================
-- HELPER FUNCTIONS (inline here so this file is self-contained)
-- These are also defined in 03_functions.sql — CREATE OR REPLACE
-- means it's safe to run them again.
-- ============================================================

CREATE OR REPLACE FUNCTION public.get_my_org_id()
RETURNS UUID
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public AS $$
  SELECT org_id FROM public.profiles WHERE id = auth.uid();
$$;

CREATE OR REPLACE FUNCTION public.get_my_role()
RETURNS TEXT
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public AS $$
  SELECT role::TEXT FROM public.profiles WHERE id = auth.uid();
$$;

CREATE OR REPLACE FUNCTION public.is_platform_admin()
RETURNS BOOLEAN
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public AS $$
  SELECT COALESCE(is_platform_admin, FALSE) FROM public.profiles WHERE id = auth.uid();
$$;

CREATE OR REPLACE FUNCTION public.is_org_admin()
RETURNS BOOLEAN
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public AS $$
  SELECT role::TEXT IN ('super_admin', 'admin') FROM public.profiles WHERE id = auth.uid();
$$;

-- ============================================================
-- 1. ORGANIZATIONS
-- ============================================================

ALTER TABLE public.organizations ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "org_select"          ON public.organizations;
DROP POLICY IF EXISTS "org_update"          ON public.organizations;
DROP POLICY IF EXISTS "org_delete"          ON public.organizations;

CREATE POLICY "org_select" ON public.organizations
  FOR SELECT USING (
    id = public.get_my_org_id()
    OR public.is_platform_admin()
  );

CREATE POLICY "org_update" ON public.organizations
  FOR UPDATE USING (
    id = public.get_my_org_id()
    AND public.get_my_role() = 'super_admin'
  );

-- Only the platform admin can delete orgs (dangerous operation)
CREATE POLICY "org_delete" ON public.organizations
  FOR DELETE USING (public.is_platform_admin());

-- ============================================================
-- 2. PLANS (public read; platform admin manages)
-- ============================================================

ALTER TABLE public.plans ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "plans_read_all"       ON public.plans;
DROP POLICY IF EXISTS "plans_manage_platform" ON public.plans;

CREATE POLICY "plans_read_all" ON public.plans
  FOR SELECT USING (is_active = TRUE OR public.is_platform_admin());

CREATE POLICY "plans_manage_platform" ON public.plans
  FOR ALL USING (public.is_platform_admin());

-- ============================================================
-- 3. SUBSCRIPTIONS (org owner + platform admin)
-- ============================================================

ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "sub_select"          ON public.subscriptions;
DROP POLICY IF EXISTS "sub_manage_platform" ON public.subscriptions;

CREATE POLICY "sub_select" ON public.subscriptions
  FOR SELECT USING (
    (org_id = public.get_my_org_id() AND public.get_my_role() = 'super_admin')
    OR public.is_platform_admin()
  );

-- Stripe webhooks use service_role key which bypasses RLS;
-- direct modification is restricted to platform admins.
CREATE POLICY "sub_manage_platform" ON public.subscriptions
  FOR ALL USING (public.is_platform_admin());

-- ============================================================
-- 4. ORG INVITATIONS
-- ============================================================

ALTER TABLE public.org_invitations ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "inv_select"  ON public.org_invitations;
DROP POLICY IF EXISTS "inv_manage"  ON public.org_invitations;

CREATE POLICY "inv_select" ON public.org_invitations
  FOR SELECT USING (
    (org_id = public.get_my_org_id() AND public.is_org_admin())
    OR public.is_platform_admin()
  );

CREATE POLICY "inv_manage" ON public.org_invitations
  FOR ALL USING (
    (org_id = public.get_my_org_id() AND public.is_org_admin())
    OR public.is_platform_admin()
  );

-- ============================================================
-- 5. PROFILES
-- ============================================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Drop all old policies
DO $$ DECLARE r RECORD; BEGIN
  FOR r IN SELECT policyname FROM pg_policies WHERE tablename = 'profiles' AND schemaname = 'public' LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.profiles', r.policyname);
  END LOOP;
END $$;

-- All org members can read profiles within their org; users always see their own
CREATE POLICY "profiles_select" ON public.profiles
  FOR SELECT USING (
    org_id = public.get_my_org_id()
    OR id = auth.uid()
    OR public.is_platform_admin()
  );

-- Users update their own profile (name, phone, whatsapp only)
-- Cannot change role, org_id, or is_platform_admin
CREATE POLICY "profiles_update_own" ON public.profiles
  FOR UPDATE
  USING (id = auth.uid())
  WITH CHECK (
    id              = auth.uid()
    AND org_id      = public.get_my_org_id()
    AND role        = (SELECT role FROM public.profiles WHERE id = auth.uid())
    AND is_platform_admin = FALSE
  );

-- Admins can update profiles in their org, but cannot promote to super_admin or set is_platform_admin
CREATE POLICY "profiles_update_admin" ON public.profiles
  FOR UPDATE
  USING (
    org_id = public.get_my_org_id() AND public.is_org_admin()
  )
  WITH CHECK (
    org_id = public.get_my_org_id()
    AND public.is_org_admin()
    AND (role != 'super_admin' OR public.get_my_role() = 'super_admin')
    AND is_platform_admin = FALSE
  );

-- Only service_role can set is_platform_admin; revoke from authenticated users
REVOKE UPDATE (is_platform_admin) ON public.profiles FROM authenticated;

-- Only the org owner can remove members (sets is_active = false; hard delete below)
CREATE POLICY "profiles_delete_owner" ON public.profiles
  FOR DELETE USING (
    org_id = public.get_my_org_id() AND public.get_my_role() = 'super_admin'
    OR public.is_platform_admin()
  );

-- ============================================================
-- 6. OFFICES
-- ============================================================

ALTER TABLE public.offices ENABLE ROW LEVEL SECURITY;

DO $$ DECLARE r RECORD; BEGIN
  FOR r IN SELECT policyname FROM pg_policies WHERE tablename = 'offices' AND schemaname = 'public' LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.offices', r.policyname);
  END LOOP;
END $$;

CREATE POLICY "offices_select" ON public.offices
  FOR SELECT USING (org_id = public.get_my_org_id() OR public.is_platform_admin());

CREATE POLICY "offices_insert" ON public.offices
  FOR INSERT WITH CHECK (org_id = public.get_my_org_id() AND public.is_org_admin());

CREATE POLICY "offices_update" ON public.offices
  FOR UPDATE USING (org_id = public.get_my_org_id() AND public.is_org_admin());

CREATE POLICY "offices_delete" ON public.offices
  FOR DELETE USING (
    org_id = public.get_my_org_id() AND public.get_my_role() = 'super_admin'
    OR public.is_platform_admin()
  );

-- ============================================================
-- 7. WORK ORDERS
-- ============================================================

ALTER TABLE public.work_orders ENABLE ROW LEVEL SECURITY;

DO $$ DECLARE r RECORD; BEGIN
  FOR r IN SELECT policyname FROM pg_policies WHERE tablename = 'work_orders' AND schemaname = 'public' LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.work_orders', r.policyname);
  END LOOP;
END $$;

-- Admins see all org work orders; staff/agents see only their assigned ones
CREATE POLICY "work_orders_select" ON public.work_orders
  FOR SELECT USING (
    (
      org_id = public.get_my_org_id()
      AND (
        public.is_org_admin()
        OR assigned_staff_id = auth.uid()
        OR agent_id = auth.uid()
      )
    )
    OR public.is_platform_admin()
  );

CREATE POLICY "work_orders_insert" ON public.work_orders
  FOR INSERT WITH CHECK (org_id = public.get_my_org_id() AND public.is_org_admin());

-- Admins can update all fields; assigned staff can update status only (enforced in app layer)
CREATE POLICY "work_orders_update" ON public.work_orders
  FOR UPDATE USING (
    org_id = public.get_my_org_id()
    AND (public.is_org_admin() OR assigned_staff_id = auth.uid())
  );

CREATE POLICY "work_orders_delete" ON public.work_orders
  FOR DELETE USING (
    org_id = public.get_my_org_id() AND public.get_my_role() = 'super_admin'
    OR public.is_platform_admin()
  );

-- ============================================================
-- 8. PAYMENTS (access via parent work order)
-- ============================================================

ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;

DO $$ DECLARE r RECORD; BEGIN
  FOR r IN SELECT policyname FROM pg_policies WHERE tablename = 'payments' AND schemaname = 'public' LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.payments', r.policyname);
  END LOOP;
END $$;

CREATE POLICY "payments_select" ON public.payments
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.work_orders w
      WHERE w.id = work_order_id
        AND w.org_id = public.get_my_org_id()
        AND (public.is_org_admin() OR w.assigned_staff_id = auth.uid())
    )
    OR public.is_platform_admin()
  );

CREATE POLICY "payments_insert" ON public.payments
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.work_orders w
      WHERE w.id = work_order_id AND w.org_id = public.get_my_org_id()
    )
    AND public.is_org_admin()
  );

CREATE POLICY "payments_update" ON public.payments
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.work_orders w
      WHERE w.id = work_order_id AND w.org_id = public.get_my_org_id()
    )
    AND public.is_org_admin()
  );

CREATE POLICY "payments_delete" ON public.payments
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM public.work_orders w
      WHERE w.id = work_order_id AND w.org_id = public.get_my_org_id()
    )
    AND public.get_my_role() = 'super_admin'
    OR public.is_platform_admin()
  );

-- ============================================================
-- 9. CLIENTS
-- ============================================================

ALTER TABLE public.clients ENABLE ROW LEVEL SECURITY;

DO $$ DECLARE r RECORD; BEGIN
  FOR r IN SELECT policyname FROM pg_policies WHERE tablename = 'clients' AND schemaname = 'public' LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.clients', r.policyname);
  END LOOP;
END $$;

CREATE POLICY "clients_select" ON public.clients
  FOR SELECT USING (org_id = public.get_my_org_id() OR public.is_platform_admin());

CREATE POLICY "clients_insert" ON public.clients
  FOR INSERT WITH CHECK (org_id = public.get_my_org_id() AND public.is_org_admin());

CREATE POLICY "clients_update" ON public.clients
  FOR UPDATE USING (org_id = public.get_my_org_id() AND public.is_org_admin());

CREATE POLICY "clients_delete" ON public.clients
  FOR DELETE USING (org_id = public.get_my_org_id() AND public.is_org_admin());

-- ============================================================
-- 10. SERVICES
-- ============================================================

ALTER TABLE public.services ENABLE ROW LEVEL SECURITY;

DO $$ DECLARE r RECORD; BEGIN
  FOR r IN SELECT policyname FROM pg_policies WHERE tablename = 'services' AND schemaname = 'public' LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.services', r.policyname);
  END LOOP;
END $$;

-- All org members can view the service catalogue
CREATE POLICY "services_select" ON public.services
  FOR SELECT USING (org_id = public.get_my_org_id() OR public.is_platform_admin());

CREATE POLICY "services_insert" ON public.services
  FOR INSERT WITH CHECK (org_id = public.get_my_org_id() AND public.is_org_admin());

CREATE POLICY "services_update" ON public.services
  FOR UPDATE USING (org_id = public.get_my_org_id() AND public.is_org_admin());

CREATE POLICY "services_delete" ON public.services
  FOR DELETE USING (
    org_id = public.get_my_org_id() AND public.get_my_role() = 'super_admin'
    OR public.is_platform_admin()
  );

-- ============================================================
-- 11. ATTENDANCE
-- ============================================================

ALTER TABLE public.attendance ENABLE ROW LEVEL SECURITY;

DO $$ DECLARE r RECORD; BEGIN
  FOR r IN SELECT policyname FROM pg_policies WHERE tablename = 'attendance' AND schemaname = 'public' LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.attendance', r.policyname);
  END LOOP;
END $$;

-- Staff see own; admins see all in org
CREATE POLICY "attendance_select" ON public.attendance
  FOR SELECT USING (
    (org_id = public.get_my_org_id() AND (user_id = auth.uid() OR public.is_org_admin()))
    OR public.is_platform_admin()
  );

-- Staff check themselves in (org_id auto-filled by trigger)
CREATE POLICY "attendance_insert" ON public.attendance
  FOR INSERT WITH CHECK (
    user_id = auth.uid() AND org_id = public.get_my_org_id()
  );

-- Staff check themselves out; admins can correct records
CREATE POLICY "attendance_update" ON public.attendance
  FOR UPDATE USING (
    org_id = public.get_my_org_id()
    AND (user_id = auth.uid() OR public.is_org_admin())
  );

CREATE POLICY "attendance_delete" ON public.attendance
  FOR DELETE USING (org_id = public.get_my_org_id() AND public.is_org_admin());

-- ============================================================
-- 12. LEAVES
-- ============================================================

ALTER TABLE public.leaves ENABLE ROW LEVEL SECURITY;

DO $$ DECLARE r RECORD; BEGIN
  FOR r IN SELECT policyname FROM pg_policies WHERE tablename = 'leaves' AND schemaname = 'public' LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.leaves', r.policyname);
  END LOOP;
END $$;

-- Staff see own; admins see all in org
CREATE POLICY "leaves_select" ON public.leaves
  FOR SELECT USING (
    (org_id = public.get_my_org_id() AND (user_id = auth.uid() OR public.is_org_admin()))
    OR public.is_platform_admin()
  );

-- Staff submit their own leave requests
CREATE POLICY "leaves_insert" ON public.leaves
  FOR INSERT WITH CHECK (
    user_id = auth.uid() AND org_id = public.get_my_org_id()
  );

-- Staff can withdraw pending leaves; admins approve/reject
CREATE POLICY "leaves_update" ON public.leaves
  FOR UPDATE USING (
    org_id = public.get_my_org_id()
    AND (user_id = auth.uid() OR public.is_org_admin())
  );

CREATE POLICY "leaves_delete" ON public.leaves
  FOR DELETE USING (org_id = public.get_my_org_id() AND public.is_org_admin());

-- ============================================================
-- 13. TASK HISTORY (access scoped through parent work order)
-- ============================================================

ALTER TABLE public.task_history ENABLE ROW LEVEL SECURITY;

DO $$ DECLARE r RECORD; BEGIN
  FOR r IN SELECT policyname FROM pg_policies WHERE tablename = 'task_history' AND schemaname = 'public' LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.task_history', r.policyname);
  END LOOP;
END $$;

CREATE POLICY "task_history_select" ON public.task_history
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.work_orders w
      WHERE w.id = work_order_id
        AND w.org_id = public.get_my_org_id()
        AND (public.is_org_admin() OR w.assigned_staff_id = auth.uid())
    )
    OR public.is_platform_admin()
  );

CREATE POLICY "task_history_insert" ON public.task_history
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.work_orders w
      WHERE w.id = work_order_id
        AND w.org_id = public.get_my_org_id()
        AND (public.is_org_admin() OR w.assigned_staff_id = auth.uid())
    )
  );

CREATE POLICY "task_history_delete" ON public.task_history
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM public.work_orders w
      WHERE w.id = work_order_id AND w.org_id = public.get_my_org_id()
    )
    AND public.is_org_admin()
    OR public.is_platform_admin()
  );

-- ============================================================
-- 14. TASK DOCUMENTS (access scoped through parent work order)
-- ============================================================

ALTER TABLE public.task_documents ENABLE ROW LEVEL SECURITY;

DO $$ DECLARE r RECORD; BEGIN
  FOR r IN SELECT policyname FROM pg_policies WHERE tablename = 'task_documents' AND schemaname = 'public' LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.task_documents', r.policyname);
  END LOOP;
END $$;

CREATE POLICY "task_documents_select" ON public.task_documents
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.work_orders w
      WHERE w.id = work_order_id
        AND w.org_id = public.get_my_org_id()
        AND (public.is_org_admin() OR w.assigned_staff_id = auth.uid())
    )
    OR public.is_platform_admin()
  );

CREATE POLICY "task_documents_insert" ON public.task_documents
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.work_orders w
      WHERE w.id = work_order_id
        AND w.org_id = public.get_my_org_id()
        AND (public.is_org_admin() OR w.assigned_staff_id = auth.uid())
    )
  );

CREATE POLICY "task_documents_update" ON public.task_documents
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.work_orders w
      WHERE w.id = work_order_id AND w.org_id = public.get_my_org_id()
    )
    AND public.is_org_admin()
  );

CREATE POLICY "task_documents_delete" ON public.task_documents
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM public.work_orders w
      WHERE w.id = work_order_id AND w.org_id = public.get_my_org_id()
    )
    AND public.is_org_admin()
    OR public.is_platform_admin()
  );
