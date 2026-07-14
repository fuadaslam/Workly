-- ============================================================
-- CLIENT IQAMA NUMBER + WORK ORDER DETAILS/CHARGE + NEW ENQUIRY NATURES
-- Adds:
--   - iqama_number on enquiries & work_orders (client's Iqama/ID number)
--   - details_of_works, default_charging_amount on work_orders
--   - 'Spl' and 'Ticket' as Nature of Enquiry options
-- Applied to project wwnjrarqeunhqwsgpgem. Idempotent.
-- ============================================================

ALTER TABLE public.enquiries
  ADD COLUMN IF NOT EXISTS iqama_number text;

ALTER TABLE public.work_orders
  ADD COLUMN IF NOT EXISTS iqama_number text,
  ADD COLUMN IF NOT EXISTS details_of_works text,
  ADD COLUMN IF NOT EXISTS default_charging_amount numeric(10,2);

-- Seed existing orgs with the two new nature-of-enquiry options (no-op on re-run).
INSERT INTO public.enquiry_options (org_id, category, value, sort_order)
SELECT o.id, 'nature', v.value,
       (SELECT COALESCE(MAX(eo.sort_order), 0) FROM public.enquiry_options eo
         WHERE eo.org_id = o.id AND eo.category = 'nature') + v.ord
FROM public.organizations o
CROSS JOIN unnest(ARRAY['Spl','Ticket']) WITH ORDINALITY AS v(value, ord)
ON CONFLICT (org_id, category, value) DO NOTHING;

-- Carry the client's Iqama number over when an enquiry is converted to a work order.
CREATE OR REPLACE FUNCTION public.convert_enquiry_to_work_order(p_enquiry_id uuid)
RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_caller_org  uuid;
  v_caller_role text;
  v_is_platform boolean;
  e public.enquiries%ROWTYPE;
  v_wo uuid;
  v_total numeric;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required.';
  END IF;

  SELECT org_id, role::text, COALESCE(is_platform_admin, false)
    INTO v_caller_org, v_caller_role, v_is_platform
  FROM profiles WHERE id = auth.uid();

  SELECT * INTO e FROM enquiries WHERE id = p_enquiry_id;
  IF e.id IS NULL THEN
    RAISE EXCEPTION 'Enquiry not found.';
  END IF;

  IF NOT COALESCE(
        v_is_platform
        OR (e.org_id = v_caller_org AND v_caller_role IN ('super_admin','admin'))
        OR (e.responsible_staff_id = auth.uid()),
      false) THEN
    RAISE EXCEPTION 'You are not allowed to convert this enquiry.';
  END IF;

  IF e.client_status <> 'accepted' THEN
    RAISE EXCEPTION 'Only accepted enquiries can be converted to a work order.';
  END IF;
  IF e.work_order_id IS NOT NULL THEN
    RAISE EXCEPTION 'This enquiry has already been converted.';
  END IF;

  INSERT INTO work_orders
    (client_name, client_phone_number, service_type, nationality, iqama_number, priority, status,
     assigned_staff_id, assigned_office_id, org_id, enquiry_id)
  VALUES
    (e.client_name, e.contact_number, e.nature_of_enquiry, e.nationality, e.iqama_number, 'Medium', 'Pending',
     e.responsible_staff_id, e.assigned_office_id, e.org_id, e.id)
  RETURNING id INTO v_wo;

  UPDATE enquiries SET work_order_id = v_wo WHERE id = e.id;

  v_total := COALESCE(e.final_agreed_service_charge,
                      COALESCE(e.official_fee, 0) + COALESCE(e.service_charge_offered, 0));
  IF v_total > 0 THEN
    INSERT INTO payments (work_order_id, total_amount, paid_amount, status)
    VALUES (v_wo, v_total, 0, 'Pending');
  END IF;

  INSERT INTO task_history (work_order_id, title, description, status_at_time, created_by)
  VALUES (v_wo,
          'Created from Enquiry ' || COALESCE(e.enquiry_code, ''),
          'Converted from enquiry', 'Pending', auth.uid());

  RETURN v_wo;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.convert_enquiry_to_work_order(uuid) FROM public, anon;
GRANT  EXECUTE ON FUNCTION public.convert_enquiry_to_work_order(uuid) TO authenticated;
