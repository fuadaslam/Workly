-- ============================================================
-- ENQUIRY CUSTOM FIELDS (Phase 2 of org-configurable enquiry setup)
-- Admins define which extra fields an enquiry collects (per org).
-- Definitions: enquiry_fields. Values: enquiries.custom_data (JSONB) keyed by field_key.
-- Applied to project wwnjrarqeunhqwsgpgem. Idempotent.
-- ============================================================

CREATE TABLE IF NOT EXISTS public.enquiry_fields (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id     uuid NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  field_key  text NOT NULL,
  label      text NOT NULL,
  field_type text NOT NULL CHECK (field_type IN ('text','number','date','dropdown','textarea')),
  required   boolean NOT NULL DEFAULT false,
  options    jsonb   NOT NULL DEFAULT '[]',   -- choices for dropdown type
  sort_order int     NOT NULL DEFAULT 0,
  is_active  boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (org_id, field_key)
);
CREATE INDEX IF NOT EXISTS idx_enquiry_fields_org ON public.enquiry_fields(org_id, sort_order);

ALTER TABLE public.enquiry_fields ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS enquiry_fields_select ON public.enquiry_fields;
CREATE POLICY enquiry_fields_select ON public.enquiry_fields
  FOR SELECT USING (org_id = public.get_my_org_id() OR public.is_platform_admin());

DROP POLICY IF EXISTS enquiry_fields_write ON public.enquiry_fields;
CREATE POLICY enquiry_fields_write ON public.enquiry_fields
  FOR ALL
  USING ((org_id = public.get_my_org_id() AND public.is_org_admin()) OR public.is_platform_admin())
  WITH CHECK ((org_id = public.get_my_org_id() AND public.is_org_admin()) OR public.is_platform_admin());

-- Per-enquiry custom field values, keyed by enquiry_fields.field_key.
ALTER TABLE public.enquiries
  ADD COLUMN IF NOT EXISTS custom_data jsonb NOT NULL DEFAULT '{}'::jsonb;
