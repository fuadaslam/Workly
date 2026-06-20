-- Enquiries table for SPOT Business Enquiry Settle Tracker
CREATE SEQUENCE IF NOT EXISTS enquiry_seq START 1;

CREATE TABLE IF NOT EXISTS enquiries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  enquiry_code TEXT NOT NULL DEFAULT 'R ' || LPAD(CAST(nextval('enquiry_seq') AS TEXT), 3, '0'),

  -- Section 1: Enquiry Main Details
  client_name TEXT,
  contact_number TEXT,
  nature_of_enquiry TEXT,
  date_of_enquiry DATE,
  nationality TEXT,
  official_fee NUMERIC(10,2) DEFAULT 0,
  service_charge_offered NUMERIC(10,2) DEFAULT 0,

  -- Section 2: Follow Up / Action
  action_notes TEXT,
  follow_up_date DATE,
  final_agreed_service_charge NUMERIC(10,2),
  responsible_staff_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  client_status TEXT DEFAULT 'pending' CHECK (client_status IN ('pending', 'accepted', 'rejected')),
  rejection_reason TEXT,

  -- Section 3: Settlement & Metrics
  final_status TEXT DEFAULT 'In Progress' CHECK (final_status IN (
    'In Progress', 'Executed', 'Settled', 'Postponed by client', 'Rejected by client', 'Cancelled'
  )),
  settlement_date DATE,
  final_notes TEXT,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Auto-update updated_at on changes
CREATE OR REPLACE FUNCTION update_enquiries_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER enquiries_updated_at
  BEFORE UPDATE ON enquiries
  FOR EACH ROW EXECUTE FUNCTION update_enquiries_updated_at();

-- Computed columns as views for reporting
CREATE OR REPLACE VIEW enquiries_with_metrics AS
SELECT
  e.*,
  p.name AS responsible_staff_name,
  COALESCE(e.official_fee, 0) + COALESCE(e.service_charge_offered, 0) AS total_offered,
  CASE
    WHEN e.date_of_enquiry IS NULL THEN 0
    WHEN e.final_status IN ('Settled', 'Executed') THEN
      COALESCE(e.settlement_date, CURRENT_DATE) - e.date_of_enquiry
    ELSE CURRENT_DATE - e.date_of_enquiry
  END AS days_open,
  CASE
    WHEN e.client_status = 'rejected' OR e.final_status IN ('Rejected by client', 'Cancelled') THEN 'Needs Review'
    WHEN (CASE
      WHEN e.date_of_enquiry IS NULL THEN 0
      WHEN e.final_status IN ('Settled', 'Executed') THEN COALESCE(e.settlement_date, CURRENT_DATE) - e.date_of_enquiry
      ELSE CURRENT_DATE - e.date_of_enquiry END) <= 7 THEN 'Excellent'
    WHEN (CASE
      WHEN e.date_of_enquiry IS NULL THEN 0
      WHEN e.final_status IN ('Settled', 'Executed') THEN COALESCE(e.settlement_date, CURRENT_DATE) - e.date_of_enquiry
      ELSE CURRENT_DATE - e.date_of_enquiry END) <= 14 THEN 'Good'
    WHEN (CASE
      WHEN e.date_of_enquiry IS NULL THEN 0
      WHEN e.final_status IN ('Settled', 'Executed') THEN COALESCE(e.settlement_date, CURRENT_DATE) - e.date_of_enquiry
      ELSE CURRENT_DATE - e.date_of_enquiry END) <= 30 THEN 'Average'
    ELSE 'Needs Review'
  END AS performance_rating
FROM enquiries e
LEFT JOIN profiles p ON p.id = e.responsible_staff_id;

-- RLS Policies
ALTER TABLE enquiries ENABLE ROW LEVEL SECURITY;

-- Super admins and admins can see all enquiries
CREATE POLICY "Admins can view all enquiries"
  ON enquiries FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('super_admin', 'admin')
    )
  );

-- Staff can view their own assigned enquiries
CREATE POLICY "Staff can view their enquiries"
  ON enquiries FOR SELECT
  USING (responsible_staff_id = auth.uid());

-- Admins and staff can insert enquiries
CREATE POLICY "Authenticated users can create enquiries"
  ON enquiries FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

-- Admins can update any, staff can update their own
CREATE POLICY "Admins can update all enquiries"
  ON enquiries FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('super_admin', 'admin')
    )
  );

CREATE POLICY "Staff can update their own enquiries"
  ON enquiries FOR UPDATE
  USING (responsible_staff_id = auth.uid());

-- Only admins can delete
CREATE POLICY "Admins can delete enquiries"
  ON enquiries FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('super_admin', 'admin')
    )
  );

-- Index for performance
CREATE INDEX IF NOT EXISTS idx_enquiries_staff ON enquiries(responsible_staff_id);
CREATE INDEX IF NOT EXISTS idx_enquiries_status ON enquiries(final_status);
CREATE INDEX IF NOT EXISTS idx_enquiries_created ON enquiries(created_at DESC);
