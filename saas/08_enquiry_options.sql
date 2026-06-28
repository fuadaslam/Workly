-- ============================================================
-- ENQUIRY OPTIONS (Phase 1 of org-configurable enquiry setup)
-- Org admins manage the dropdown choices shown when creating an enquiry.
-- The app falls back to built-in defaults for any category an org leaves empty.
-- Applied to project wwnjrarqeunhqwsgpgem. Idempotent.
-- ============================================================

CREATE TABLE IF NOT EXISTS public.enquiry_options (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id     uuid NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  category   text NOT NULL CHECK (category IN ('nature','nationality','rejection_reason')),
  value      text NOT NULL,
  sort_order int  NOT NULL DEFAULT 0,
  is_active  boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (org_id, category, value)
);
CREATE INDEX IF NOT EXISTS idx_enquiry_options_org_cat
  ON public.enquiry_options(org_id, category, sort_order);

ALTER TABLE public.enquiry_options ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS enquiry_options_select ON public.enquiry_options;
CREATE POLICY enquiry_options_select ON public.enquiry_options
  FOR SELECT USING (org_id = public.get_my_org_id() OR public.is_platform_admin());

DROP POLICY IF EXISTS enquiry_options_write ON public.enquiry_options;
CREATE POLICY enquiry_options_write ON public.enquiry_options
  FOR ALL
  USING ((org_id = public.get_my_org_id() AND public.is_org_admin()) OR public.is_platform_admin())
  WITH CHECK ((org_id = public.get_my_org_id() AND public.is_org_admin()) OR public.is_platform_admin());

-- Seed existing orgs with the built-in defaults (no-op on re-run).
INSERT INTO public.enquiry_options (org_id, category, value, sort_order)
SELECT o.id, 'nature', v.value, v.ord
FROM public.organizations o
CROSS JOIN unnest(ARRAY[
  'Sijil Opening','Qiwa Services','Mudad Service','Gosi','Absher','Business Startup',
  'Baladiya Service','Muqeem Service (Sharika)','Medical Insurance','Vehicle Insurance',
  'Iqama Services','Lawyer Service','Company Related Fine Cutting','Musaned Services',
  'Financial Consultants','Budget Preparation','Cash Flow','Cost Control'
]) WITH ORDINALITY AS v(value, ord)
ON CONFLICT (org_id, category, value) DO NOTHING;

INSERT INTO public.enquiry_options (org_id, category, value, sort_order)
SELECT o.id, 'nationality', v.value, v.ord
FROM public.organizations o
CROSS JOIN unnest(ARRAY[
  'Indian','Pakistani','Bangladeshi','Burma','Saudi Arabia','United Arab Emirates',
  'Indonesia','Philippine','Other','Company'
]) WITH ORDINALITY AS v(value, ord)
ON CONFLICT (org_id, category, value) DO NOTHING;

INSERT INTO public.enquiry_options (org_id, category, value, sort_order)
SELECT o.id, 'rejection_reason', v.value, v.ord
FROM public.organizations o
CROSS JOIN unnest(ARRAY[
  'Pricing Too High','Competitor Chosen','No Response','Project Delayed',
  'Not a Good Fit','Attitude issue','Other'
]) WITH ORDINALITY AS v(value, ord)
ON CONFLICT (org_id, category, value) DO NOTHING;

-- TODO (Phase 2): custom enquiry fields / form builder
--   enquiries.custom_data JSONB + an enquiry_fields definition table.
