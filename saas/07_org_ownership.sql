-- ============================================================
-- ORG OWNERSHIP MODEL  (applied to project wwnjrarqeunhqwsgpgem)
--
--   platform super-admin (is_platform_admin) : operates the SaaS; manages ALL orgs
--   org owner (super_admin, EXACTLY 1 / org)  : full control of its org
--                                               (incl. delete offices/users)
--   org admins (many per org)                 : manage branches & staff,
--                                               cannot delete offices/users
--   staff                                     : exactly one office (office_id);
--                                               an admin can transfer them
--                                               between branches.
--
-- Idempotent.
-- ============================================================

-- 1. Platform admin can manage members in ANY org (define owners, fix members).
DROP POLICY IF EXISTS "profiles_update_admin" ON public.profiles;
CREATE POLICY "profiles_update_admin" ON public.profiles
  FOR UPDATE
  USING (
    ((org_id = public.get_my_org_id()) AND public.is_org_admin())
    OR public.is_platform_admin()
  )
  WITH CHECK (
    public.is_platform_admin()
    OR (
      (org_id = public.get_my_org_id())
      AND public.is_org_admin()
      AND ((role <> 'super_admin') OR (public.get_my_role() = 'super_admin'))
      AND (is_platform_admin = false)
    )
  );

-- 2. Platform admin can update ANY organization (e.g. owner_id); owners their own.
DROP POLICY IF EXISTS "org_update" ON public.organizations;
CREATE POLICY "org_update" ON public.organizations
  FOR UPDATE
  USING (
    (id = public.get_my_org_id() AND public.get_my_role() = 'super_admin')
    OR public.is_platform_admin()
  );

-- 3. Exactly one owner per org (at most one super_admin per org).
CREATE UNIQUE INDEX IF NOT EXISTS uniq_org_one_owner
  ON public.profiles (org_id)
  WHERE role = 'super_admin' AND org_id IS NOT NULL;

-- 4. Ownership transfer. Only the platform admin or current owner may call it.
--    NOTE the NULL-safe guard: a NULL auth.uid() (service role / no JWT) or any
--    NULL comparison must DENY — COALESCE(...,false) collapses NULL so NOT()
--    raises. (An earlier version without this could be bypassed by a null caller.)
CREATE OR REPLACE FUNCTION public.set_org_owner(p_org_id uuid, p_new_owner uuid)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_caller_role text;
  v_caller_org  uuid;
  v_is_platform boolean;
  v_target_org  uuid;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required.';
  END IF;

  SELECT role::text, org_id, COALESCE(is_platform_admin, false)
    INTO v_caller_role, v_caller_org, v_is_platform
  FROM profiles WHERE id = auth.uid();

  IF NOT COALESCE(
        v_is_platform
        OR (v_caller_org = p_org_id AND v_caller_role = 'super_admin'),
        false
      ) THEN
    RAISE EXCEPTION 'Only the platform admin or the current org owner can set the owner.';
  END IF;

  SELECT org_id INTO v_target_org FROM profiles WHERE id = p_new_owner;
  IF v_target_org IS DISTINCT FROM p_org_id THEN
    RAISE EXCEPTION 'The new owner must be a member of this organization.';
  END IF;

  UPDATE profiles SET role = 'admin'
    WHERE org_id = p_org_id AND role = 'super_admin' AND id <> p_new_owner;
  UPDATE profiles SET role = 'super_admin' WHERE id = p_new_owner;
  UPDATE organizations SET owner_id = p_new_owner WHERE id = p_org_id;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.set_org_owner(uuid, uuid) FROM public, anon;
GRANT  EXECUTE ON FUNCTION public.set_org_owner(uuid, uuid) TO authenticated;
