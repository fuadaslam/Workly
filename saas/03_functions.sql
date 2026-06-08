-- ============================================================
-- SAAS MIGRATION — Step 3: Helper Functions & RPCs
-- Run AFTER 02_add_org_id.sql.
-- These functions are used by RLS policies (Step 4) and the Flutter app.
-- ============================================================

-- ============================================================
-- SECTION A: RLS Helper Functions
-- All are SECURITY DEFINER so they bypass RLS when reading profiles,
-- preventing infinite recursion in policies.
-- ============================================================

-- Returns the org_id of the currently authenticated user
CREATE OR REPLACE FUNCTION public.get_my_org_id()
RETURNS UUID
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public AS $$
  SELECT org_id FROM public.profiles WHERE id = auth.uid();
$$;

-- Returns the role string of the currently authenticated user
CREATE OR REPLACE FUNCTION public.get_my_role()
RETURNS TEXT
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public AS $$
  SELECT role::TEXT FROM public.profiles WHERE id = auth.uid();
$$;

-- Returns true if the caller is the SaaS platform operator
CREATE OR REPLACE FUNCTION public.is_platform_admin()
RETURNS BOOLEAN
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public AS $$
  SELECT COALESCE(is_platform_admin, FALSE) FROM public.profiles WHERE id = auth.uid();
$$;

-- Returns true if the caller is an org-level admin (super_admin or admin)
CREATE OR REPLACE FUNCTION public.is_org_admin()
RETURNS BOOLEAN
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public AS $$
  SELECT role::TEXT IN ('super_admin', 'admin') FROM public.profiles WHERE id = auth.uid();
$$;

-- ============================================================
-- SECTION B: Updated Auth Trigger (org-aware)
-- When a user signs up:
--   - With invitation_token in metadata  → auto-join the org
--   - Without                            → create a bare profile (must create/join org later)
-- ============================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public AS $$
DECLARE
  v_token       TEXT;
  v_invitation  RECORD;
BEGIN
  v_token := NEW.raw_user_meta_data->>'invitation_token';

  IF v_token IS NOT NULL THEN
    -- Find a valid, unused invitation matching token + email
    SELECT * INTO v_invitation
    FROM public.org_invitations
    WHERE token       = v_token
      AND LOWER(email) = LOWER(NEW.email)
      AND accepted_at IS NULL
      AND expires_at  > NOW();

    IF FOUND THEN
      -- Create profile linked to the org
      INSERT INTO public.profiles (id, email, name, role, org_id)
      VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
        v_invitation.role::public.app_role,
        v_invitation.org_id
      )
      ON CONFLICT (id) DO NOTHING;

      -- Consume the invitation
      UPDATE public.org_invitations SET accepted_at = NOW() WHERE id = v_invitation.id;

      RETURN NEW;
    END IF;
  END IF;

  -- Default: bare profile, no org yet
  INSERT INTO public.profiles (id, email, name, role)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
    'staff'
  )
  ON CONFLICT (id) DO NOTHING;

  RETURN NEW;
END;
$$;

-- Recreate the trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================================
-- SECTION C: create_organization
-- Called by a logged-in user to create their own workspace.
-- The caller becomes the super_admin of the new org.
-- ============================================================

CREATE OR REPLACE FUNCTION public.create_organization(
  org_name TEXT,
  org_slug TEXT
)
RETURNS UUID
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public AS $$
DECLARE
  v_new_org_id    UUID;
  v_free_plan_id  UUID;
BEGIN
  -- Validate slug: 3-63 chars, lowercase, alphanumeric + hyphens, no leading/trailing hyphens
  IF org_slug !~ '^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$' THEN
    RAISE EXCEPTION 'Invalid workspace URL. Use 3-63 characters: lowercase letters, numbers, and hyphens only.';
  END IF;

  IF EXISTS (SELECT 1 FROM public.organizations WHERE slug = org_slug) THEN
    RAISE EXCEPTION 'Workspace URL "%" is already taken. Please choose another.', org_slug;
  END IF;

  IF (SELECT org_id FROM public.profiles WHERE id = auth.uid()) IS NOT NULL THEN
    RAISE EXCEPTION 'You already belong to an organization. Leave it before creating a new one.';
  END IF;

  -- Create the org
  INSERT INTO public.organizations (name, slug, owner_id)
  VALUES (org_name, org_slug, auth.uid())
  RETURNING id INTO v_new_org_id;

  -- Start a 14-day free trial
  SELECT id INTO v_free_plan_id FROM public.plans WHERE name = 'free' LIMIT 1;
  INSERT INTO public.subscriptions (org_id, plan_id, status, trial_ends_at, current_period_start, current_period_end)
  VALUES (
    v_new_org_id,
    v_free_plan_id,
    'trialing',
    NOW() + INTERVAL '14 days',
    NOW(),
    NOW() + INTERVAL '14 days'
  );

  -- Make the creator the org owner
  UPDATE public.profiles
  SET org_id = v_new_org_id, role = 'super_admin'
  WHERE id = auth.uid();

  RETURN v_new_org_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.create_organization(TEXT, TEXT) TO authenticated;

-- ============================================================
-- SECTION D: invite_user_to_org
-- Creates (or re-sends) an invitation for an email address.
-- Returns the invitation ID — your backend should email the token.
-- ============================================================

CREATE OR REPLACE FUNCTION public.invite_user_to_org(
  invite_email TEXT,
  invite_role  TEXT DEFAULT 'staff'
)
RETURNS UUID
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public AS $$
DECLARE
  v_caller_org_id     UUID;
  v_caller_role       TEXT;
  v_plan_max_users    INT;
  v_current_users     INT;
  v_invitation_id     UUID;
BEGIN
  SELECT org_id, role::TEXT INTO v_caller_org_id, v_caller_role
  FROM public.profiles WHERE id = auth.uid();

  IF v_caller_org_id IS NULL THEN
    RAISE EXCEPTION 'You do not belong to any organization.';
  END IF;

  IF v_caller_role NOT IN ('super_admin', 'admin') THEN
    RAISE EXCEPTION 'Only admins can invite users.';
  END IF;

  -- Prevent non-owners from inviting another super_admin
  IF invite_role = 'super_admin' AND v_caller_role != 'super_admin' THEN
    RAISE EXCEPTION 'Only the organization owner can invite another owner.';
  END IF;

  -- Enforce plan seat limit (-1 = unlimited)
  SELECT p.max_users INTO v_plan_max_users
  FROM public.subscriptions s
  JOIN public.plans p ON p.id = s.plan_id
  WHERE s.org_id = v_caller_org_id AND s.status IN ('active', 'trialing')
  LIMIT 1;

  SELECT COUNT(*) INTO v_current_users
  FROM public.profiles WHERE org_id = v_caller_org_id;

  IF v_plan_max_users <> -1 AND v_current_users >= v_plan_max_users THEN
    RAISE EXCEPTION 'User seat limit reached for your current plan. Please upgrade to invite more members.';
  END IF;

  -- Upsert invitation (refreshes token + expiry if already sent)
  INSERT INTO public.org_invitations (org_id, email, role, invited_by, expires_at)
  VALUES (v_caller_org_id, LOWER(invite_email), invite_role, auth.uid(), NOW() + INTERVAL '7 days')
  ON CONFLICT (org_id, email) DO UPDATE SET
    role        = EXCLUDED.role,
    invited_by  = EXCLUDED.invited_by,
    token       = encode(gen_random_bytes(32), 'hex'),
    expires_at  = EXCLUDED.expires_at,
    accepted_at = NULL
  RETURNING id INTO v_invitation_id;

  RETURN v_invitation_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.invite_user_to_org(TEXT, TEXT) TO authenticated;

-- ============================================================
-- SECTION E: accept_invitation
-- Called after a user is already signed in but joined without a token
-- (e.g. they registered first, then clicked the invite link).
-- Returns { org_id, role } on success.
-- ============================================================

CREATE OR REPLACE FUNCTION public.accept_invitation(
  invitation_token TEXT
)
RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public AS $$
DECLARE
  v_invitation RECORD;
  v_my_email   TEXT;
BEGIN
  SELECT email INTO v_my_email FROM public.profiles WHERE id = auth.uid();

  SELECT * INTO v_invitation
  FROM public.org_invitations
  WHERE token        = invitation_token
    AND LOWER(email) = LOWER(v_my_email)
    AND accepted_at IS NULL
    AND expires_at  > NOW();

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Invalid or expired invitation link.';
  END IF;

  IF (SELECT org_id FROM public.profiles WHERE id = auth.uid()) IS NOT NULL THEN
    RAISE EXCEPTION 'You already belong to an organization. Leave it before accepting a new invitation.';
  END IF;

  UPDATE public.profiles
  SET org_id = v_invitation.org_id, role = v_invitation.role::public.app_role
  WHERE id = auth.uid();

  UPDATE public.org_invitations SET accepted_at = NOW() WHERE id = v_invitation.id;

  RETURN jsonb_build_object('org_id', v_invitation.org_id, 'role', v_invitation.role);
END;
$$;

GRANT EXECUTE ON FUNCTION public.accept_invitation(TEXT) TO authenticated;

-- ============================================================
-- SECTION F: create_user_admin (org-scoped replacement)
-- Replaces the old single-tenant version.
-- Now enforces: same org as caller, and plan seat limits.
-- ============================================================

DROP FUNCTION IF EXISTS public.create_user_admin(TEXT, TEXT, TEXT, TEXT, TEXT, UUID);
DROP FUNCTION IF EXISTS public.create_user_admin(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT);

CREATE OR REPLACE FUNCTION public.create_user_admin(
  new_email    TEXT,
  new_password TEXT,
  full_name    TEXT,
  user_role    TEXT,
  phone        TEXT DEFAULT NULL,
  office       UUID DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public AS $$
DECLARE
  v_new_user_id    UUID;
  v_caller_org_id  UUID;
  v_caller_role    TEXT;
  v_plan_max_users INT;
  v_current_users  INT;
BEGIN
  SELECT org_id, role::TEXT INTO v_caller_org_id, v_caller_role
  FROM public.profiles WHERE id = auth.uid();

  IF v_caller_role NOT IN ('super_admin', 'admin') THEN
    RAISE EXCEPTION 'Only admins can create users.';
  END IF;

  IF v_caller_org_id IS NULL THEN
    RAISE EXCEPTION 'You do not belong to an organization.';
  END IF;

  -- Enforce plan seat limit
  SELECT p.max_users INTO v_plan_max_users
  FROM public.subscriptions s
  JOIN public.plans p ON p.id = s.plan_id
  WHERE s.org_id = v_caller_org_id AND s.status IN ('active', 'trialing')
  LIMIT 1;

  SELECT COUNT(*) INTO v_current_users FROM public.profiles WHERE org_id = v_caller_org_id;

  IF v_plan_max_users <> -1 AND v_current_users >= v_plan_max_users THEN
    RAISE EXCEPTION 'User seat limit reached for your current plan. Please upgrade.';
  END IF;

  -- Create the auth user
  INSERT INTO auth.users (
    instance_id, id, aud, role, email, encrypted_password,
    email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
    created_at, updated_at, confirmation_token, email_change,
    email_change_token_new, recovery_token
  ) VALUES (
    '00000000-0000-0000-0000-000000000000',
    gen_random_uuid(), 'authenticated', 'authenticated',
    new_email, crypt(new_password, gen_salt('bf')), NOW(),
    '{"provider":"email","providers":["email"]}',
    jsonb_build_object('full_name', full_name),
    NOW(), NOW(), '', '', '', ''
  )
  RETURNING id INTO v_new_user_id;

  -- Assign to caller's org (trigger creates bare profile; we update it)
  UPDATE public.profiles
  SET
    role         = user_role::public.app_role,
    phone_number = phone,
    office_id    = office,
    name         = full_name,
    org_id       = v_caller_org_id
  WHERE id = v_new_user_id;

  RETURN v_new_user_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.create_user_admin(TEXT, TEXT, TEXT, TEXT, TEXT, UUID) TO authenticated;

-- ============================================================
-- SECTION G: get_org_usage
-- Returns current usage vs plan limits for the caller's org.
-- Use this in the Flutter app to show upgrade prompts.
-- ============================================================

CREATE OR REPLACE FUNCTION public.get_org_usage()
RETURNS JSONB
LANGUAGE plpgsql STABLE SECURITY DEFINER
SET search_path = public AS $$
DECLARE
  v_org_id UUID;
  v_result JSONB;
BEGIN
  v_org_id := public.get_my_org_id();

  IF v_org_id IS NULL THEN
    RETURN '{"error":"not_in_org"}'::JSONB;
  END IF;

  SELECT jsonb_build_object(
    'user_count',                (SELECT COUNT(*) FROM public.profiles    WHERE org_id = v_org_id),
    'office_count',              (SELECT COUNT(*) FROM public.offices     WHERE org_id = v_org_id),
    'work_orders_this_month',    (
      SELECT COUNT(*) FROM public.work_orders
      WHERE org_id = v_org_id AND created_at >= date_trunc('month', NOW())
    ),
    'plan', (
      SELECT jsonb_build_object(
        'name',                       p.name,
        'display_name',               p.display_name,
        'max_users',                  p.max_users,
        'max_offices',                p.max_offices,
        'max_work_orders_per_month',  p.max_work_orders_per_month,
        'status',                     s.status,
        'trial_ends_at',              s.trial_ends_at,
        'current_period_end',         s.current_period_end
      )
      FROM public.subscriptions s
      JOIN public.plans p ON p.id = s.plan_id
      WHERE s.org_id = v_org_id
      LIMIT 1
    )
  ) INTO v_result;

  RETURN v_result;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_org_usage() TO authenticated;
