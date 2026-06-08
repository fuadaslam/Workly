-- ============================================================
-- SAAS MIGRATION — Step 2: Add org_id to Existing Tables
-- Run AFTER 01_core_tables.sql.
-- Safe to run multiple times (idempotent).
--
-- What this does:
--   1. Adds org_id FK to all tenant-scoped tables
--   2. Adds is_platform_admin flag to profiles (for the SaaS operator)
--   3. Creates a "Default Organization" from your existing data
--   4. Migrates all existing rows into that default org
--   5. Adds an auto-fill trigger so the Flutter app doesn't break immediately
--      (org_id is auto-populated from the user's profile on INSERT)
-- ============================================================

-- --------------------------------
-- 1. ADD org_id COLUMNS
-- --------------------------------

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS org_id            UUID    REFERENCES public.organizations(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS is_platform_admin BOOLEAN NOT NULL DEFAULT FALSE;

ALTER TABLE public.offices
  ADD COLUMN IF NOT EXISTS org_id UUID REFERENCES public.organizations(id) ON DELETE CASCADE;

ALTER TABLE public.work_orders
  ADD COLUMN IF NOT EXISTS org_id UUID REFERENCES public.organizations(id) ON DELETE CASCADE;

ALTER TABLE public.clients
  ADD COLUMN IF NOT EXISTS org_id UUID REFERENCES public.organizations(id) ON DELETE CASCADE;

ALTER TABLE public.services
  ADD COLUMN IF NOT EXISTS org_id UUID REFERENCES public.organizations(id) ON DELETE CASCADE;

ALTER TABLE public.attendance
  ADD COLUMN IF NOT EXISTS org_id UUID REFERENCES public.organizations(id) ON DELETE CASCADE;

ALTER TABLE public.leaves
  ADD COLUMN IF NOT EXISTS org_id UUID REFERENCES public.organizations(id) ON DELETE CASCADE;

-- --------------------------------
-- 2. INDEXES
-- --------------------------------

CREATE INDEX IF NOT EXISTS idx_profiles_org_id    ON public.profiles(org_id);
CREATE INDEX IF NOT EXISTS idx_offices_org_id     ON public.offices(org_id);
CREATE INDEX IF NOT EXISTS idx_work_orders_org_id ON public.work_orders(org_id);
CREATE INDEX IF NOT EXISTS idx_clients_org_id     ON public.clients(org_id);
CREATE INDEX IF NOT EXISTS idx_services_org_id    ON public.services(org_id);
CREATE INDEX IF NOT EXISTS idx_attendance_org_id  ON public.attendance(org_id);
CREATE INDEX IF NOT EXISTS idx_leaves_org_id      ON public.leaves(org_id);

-- --------------------------------
-- 3. AUTO-FILL org_id TRIGGER
-- Automatically sets org_id from the calling user's profile on INSERT,
-- so existing Flutter code doesn't break before you update the app.
-- --------------------------------

CREATE OR REPLACE FUNCTION public.auto_fill_org_id()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public AS $$
BEGIN
  IF NEW.org_id IS NULL THEN
    NEW.org_id := (SELECT org_id FROM public.profiles WHERE id = auth.uid());
  END IF;
  RETURN NEW;
END;
$$;

-- Apply to tables where rows are created by app users
DROP TRIGGER IF EXISTS auto_fill_org_id ON public.offices;
CREATE TRIGGER auto_fill_org_id BEFORE INSERT ON public.offices
  FOR EACH ROW EXECUTE FUNCTION public.auto_fill_org_id();

DROP TRIGGER IF EXISTS auto_fill_org_id ON public.work_orders;
CREATE TRIGGER auto_fill_org_id BEFORE INSERT ON public.work_orders
  FOR EACH ROW EXECUTE FUNCTION public.auto_fill_org_id();

DROP TRIGGER IF EXISTS auto_fill_org_id ON public.clients;
CREATE TRIGGER auto_fill_org_id BEFORE INSERT ON public.clients
  FOR EACH ROW EXECUTE FUNCTION public.auto_fill_org_id();

DROP TRIGGER IF EXISTS auto_fill_org_id ON public.services;
CREATE TRIGGER auto_fill_org_id BEFORE INSERT ON public.services
  FOR EACH ROW EXECUTE FUNCTION public.auto_fill_org_id();

DROP TRIGGER IF EXISTS auto_fill_org_id ON public.attendance;
CREATE TRIGGER auto_fill_org_id BEFORE INSERT ON public.attendance
  FOR EACH ROW EXECUTE FUNCTION public.auto_fill_org_id();

DROP TRIGGER IF EXISTS auto_fill_org_id ON public.leaves;
CREATE TRIGGER auto_fill_org_id BEFORE INSERT ON public.leaves
  FOR EACH ROW EXECUTE FUNCTION public.auto_fill_org_id();

-- --------------------------------
-- 4. DATA MIGRATION
-- Creates a "Default Organization" and assigns all existing data to it.
-- Existing super_admin becomes the org owner.
-- --------------------------------

DO $$
DECLARE
  v_default_org_id UUID  := '00000000-0000-0000-0000-000000000001';
  v_owner_id       UUID;
  v_free_plan_id   UUID;
BEGIN

  -- Pick the first super_admin as the org owner
  SELECT id INTO v_owner_id
  FROM public.profiles
  WHERE role = 'super_admin'
  ORDER BY created_at
  LIMIT 1;

  -- Create the default org if it doesn't exist yet
  IF NOT EXISTS (SELECT 1 FROM public.organizations WHERE id = v_default_org_id) THEN
    INSERT INTO public.organizations (id, name, slug, owner_id)
    VALUES (v_default_org_id, 'My Organization', 'my-organization', v_owner_id);

    -- Attach a free-plan subscription (no trial expiry for migrated data)
    SELECT id INTO v_free_plan_id FROM public.plans WHERE name = 'free' LIMIT 1;
    INSERT INTO public.subscriptions (org_id, plan_id, status, current_period_start, current_period_end)
    VALUES (v_default_org_id, v_free_plan_id, 'active', NOW(), NOW() + INTERVAL '1 year');

    RAISE NOTICE 'Default organization created: %', v_default_org_id;
  ELSE
    RAISE NOTICE 'Default organization already exists — skipping creation.';
  END IF;

  -- Assign all un-tagged rows to the default org
  UPDATE public.profiles    SET org_id = v_default_org_id WHERE org_id IS NULL;
  UPDATE public.offices     SET org_id = v_default_org_id WHERE org_id IS NULL;
  UPDATE public.work_orders SET org_id = v_default_org_id WHERE org_id IS NULL;
  UPDATE public.clients     SET org_id = v_default_org_id WHERE org_id IS NULL;
  UPDATE public.services    SET org_id = v_default_org_id WHERE org_id IS NULL;
  UPDATE public.attendance  SET org_id = v_default_org_id WHERE org_id IS NULL;
  UPDATE public.leaves      SET org_id = v_default_org_id WHERE org_id IS NULL;

  RAISE NOTICE 'Data migration complete. All existing rows assigned to org: %', v_default_org_id;
END;
$$;
