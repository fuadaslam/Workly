-- ============================================================
-- SAAS MIGRATION — Step 1: Core SaaS Tables
-- Run this FIRST in the Supabase SQL Editor.
-- Safe to run multiple times (idempotent).
-- ============================================================

-- --------------------------------
-- 1. SET_UPDATED_AT helper trigger function
-- (used by organizations and subscriptions)
-- --------------------------------

CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

-- --------------------------------
-- 2. ORGANIZATIONS
-- Each row = one customer's isolated workspace (the tenant).
-- --------------------------------

CREATE TABLE IF NOT EXISTS public.organizations (
  id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  name         TEXT        NOT NULL,
  slug         TEXT        UNIQUE NOT NULL,            -- URL-safe workspace identifier
  owner_id     UUID        REFERENCES auth.users(id) ON DELETE SET NULL,
  logo_url     TEXT,
  website      TEXT,
  phone        TEXT,
  address      TEXT,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_organizations_slug     ON public.organizations(slug);
CREATE INDEX IF NOT EXISTS idx_organizations_owner_id ON public.organizations(owner_id);

DROP TRIGGER IF EXISTS organizations_set_updated_at ON public.organizations;
CREATE TRIGGER organizations_set_updated_at
  BEFORE UPDATE ON public.organizations
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- --------------------------------
-- 3. PLANS
-- Defines the feature tiers available for purchase.
-- max_users / max_offices / max_work_orders_per_month = -1 means unlimited.
-- --------------------------------

CREATE TABLE IF NOT EXISTS public.plans (
  id                            UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  name                          TEXT         UNIQUE NOT NULL,   -- 'free' | 'pro' | 'enterprise'
  display_name                  TEXT         NOT NULL,
  max_users                     INT          NOT NULL DEFAULT 5,
  max_offices                   INT          NOT NULL DEFAULT 1,
  max_work_orders_per_month     INT          NOT NULL DEFAULT 50,
  price_monthly                 NUMERIC(10,2) NOT NULL DEFAULT 0,
  price_yearly                  NUMERIC(10,2) NOT NULL DEFAULT 0,
  features                      JSONB        NOT NULL DEFAULT '{}',
  is_active                     BOOLEAN      NOT NULL DEFAULT TRUE,
  created_at                    TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- Seed the default tier catalogue
INSERT INTO public.plans
  (name, display_name, max_users, max_offices, max_work_orders_per_month, price_monthly, price_yearly, features)
VALUES
  ('free',
   'Free',
   5, 1, 50,
   0, 0,
   '{"attendance":true,"leaves":true,"reports":false,"api_access":false,"white_label":false}'
  ),
  ('pro',
   'Pro',
   25, 5, 500,
   99, 990,
   '{"attendance":true,"leaves":true,"reports":true,"api_access":false,"white_label":false}'
  ),
  ('enterprise',
   'Enterprise',
   -1, -1, -1,
   299, 2990,
   '{"attendance":true,"leaves":true,"reports":true,"api_access":true,"white_label":true}'
  )
ON CONFLICT (name) DO NOTHING;

-- --------------------------------
-- 4. SUBSCRIPTIONS
-- Links each organization to a plan, tracks billing state.
-- One active subscription per org (UNIQUE on org_id).
-- --------------------------------

CREATE TABLE IF NOT EXISTS public.subscriptions (
  id                       UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id                   UUID        NOT NULL UNIQUE REFERENCES public.organizations(id) ON DELETE CASCADE,
  plan_id                  UUID        NOT NULL REFERENCES public.plans(id),
  status                   TEXT        NOT NULL DEFAULT 'trialing'
                                         CHECK (status IN ('trialing','active','past_due','cancelled','paused')),
  trial_ends_at            TIMESTAMPTZ,
  current_period_start     TIMESTAMPTZ,
  current_period_end       TIMESTAMPTZ,
  stripe_subscription_id   TEXT,
  stripe_customer_id       TEXT,
  cancelled_at             TIMESTAMPTZ,
  created_at               TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at               TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_subscriptions_org_id ON public.subscriptions(org_id);

DROP TRIGGER IF EXISTS subscriptions_set_updated_at ON public.subscriptions;
CREATE TRIGGER subscriptions_set_updated_at
  BEFORE UPDATE ON public.subscriptions
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- --------------------------------
-- 5. ORG INVITATIONS
-- Tracks email invites sent to future members.
-- Token is emailed to the invitee; they sign up with it to join the org.
-- --------------------------------

CREATE TABLE IF NOT EXISTS public.org_invitations (
  id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id       UUID        NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  email        TEXT        NOT NULL,
  role         TEXT        NOT NULL DEFAULT 'staff'
                             CHECK (role IN ('super_admin','admin','staff','agent')),
  invited_by   UUID        REFERENCES auth.users(id) ON DELETE SET NULL,
  token        TEXT        UNIQUE NOT NULL DEFAULT encode(gen_random_bytes(32), 'hex'),
  accepted_at  TIMESTAMPTZ,
  expires_at   TIMESTAMPTZ NOT NULL DEFAULT NOW() + INTERVAL '7 days',
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(org_id, email)   -- one pending invite per email per org (re-invite updates the row)
);

CREATE INDEX IF NOT EXISTS idx_org_invitations_token  ON public.org_invitations(token);
CREATE INDEX IF NOT EXISTS idx_org_invitations_email  ON public.org_invitations(email);
CREATE INDEX IF NOT EXISTS idx_org_invitations_org_id ON public.org_invitations(org_id);
