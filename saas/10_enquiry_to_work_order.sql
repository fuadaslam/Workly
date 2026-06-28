-- ============================================================
-- CONVERT ENQUIRY -> WORK ORDER
-- Links the sales pipeline (enquiries) to fulfilment (work_orders) and lets an
-- ACCEPTED enquiry be converted into a work order, carrying over the details.
-- Applied to project wwnjrarqeunhqwsgpgem. Idempotent.
-- ============================================================

ALTER TABLE public.work_orders
  ADD COLUMN IF NOT EXISTS enquiry_id uuid REFERENCES public.enquiries(id) ON DELETE SET NULL;
ALTER TABLE public.enquiries
  ADD COLUMN IF NOT EXISTS work_order_id uuid REFERENCES public.work_orders(id) ON DELETE SET NULL;
CREATE INDEX IF NOT EXISTS idx_work_orders_enquiry ON public.work_orders(enquiry_id);

-- Convert an accepted enquiry into a work order. Allowed for the platform admin,
-- an org admin of the enquiry's org, or the enquiry's responsible staff.
-- NULL-safe permission guard (COALESCE(...,false) so a null caller is denied).
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
    (client_name, client_phone_number, service_type, nationality, priority, status,
     assigned_staff_id, assigned_office_id, org_id, enquiry_id)
  VALUES
    (e.client_name, e.contact_number, e.nature_of_enquiry, e.nationality, 'Medium', 'Pending',
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
