-- ==========================================
-- MASTER SEED DATA FOR SAUDI SERVICE MANAGER APP
-- ==========================================
-- This script clears existing data and populates it with fresh, realistic data.

-- 1. CLEANUP EVERYTHING
-- Order matters due to foreign keys if not using CASCADE, but schema has many CASCADE.
BEGIN;

-- Clear public tables
TRUNCATE public.task_history, public.task_documents, public.payments, public.work_orders, 
         public.attendance, public.leaves, public.profiles, public.offices, 
         public.clients, public.services CASCADE;

-- Clear seed users from auth.users (if they exist)
DELETE FROM auth.users WHERE email LIKE '%@smanager.com' OR email IN (
    'superadmin@example.com', 'admin@example.com', 'staff@example.com', 
    'staff.riyadh2@example.com', 'staff.jeddah@example.com', 'staff.dammam@example.com'
);

-- 2. SEED OFFICES
-- Using fixed UUIDs to make it easy to reference later
INSERT INTO public.offices (id, name, location, manager_name, workload_percentage, staff_count, revenue, color_hex, manager_phone) VALUES
('f1111111-1111-1111-1111-111111111111', 'Riyadh HQ (Olaya)', 'Olaya Tower, King Fahd Rd, Riyadh', 'Abdullah bin Salman', 75, 15, 1250000.00, '#1E40AF', '+966501112222'),
('f2222222-2222-2222-2222-222222222222', 'Jeddah Branch', 'Prince Sultan St, Jeddah', 'Fatima Al-Zahrani', 45, 8, 850000.00, '#047857', '+966501113333'),
('f3333333-3333-3333-3333-333333333333', 'Dammam Industrial', 'King Abdulaziz Rd, Dammam', 'Ibrahim Al-Hussain', 30, 5, 450000.00, '#B45309', '+966501114444')
ON CONFLICT (id) DO NOTHING;

-- 3. SEED TEST USERS (Supabase Auth)
-- Password for all: 123456
-- We insert them directly into auth.users for testing. 
-- In production, users would sign up via the app or be invited.
INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, recovery_token, email_change_token_new, email_change)
VALUES 
('00000000-0000-0000-0000-000000000000', 'a1111111-1111-1111-1111-111111111111', 'authenticated', 'authenticated', 'superadmin@smanager.com', crypt('123456', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"full_name": "Sultan Al-Sudairi"}', now(), now(), '', '', '', ''),
('00000000-0000-0000-0000-000000000000', 'b2222222-2222-2222-2222-222222222222', 'authenticated', 'authenticated', 'admin.riyadh@smanager.com', crypt('123456', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"full_name": "Nasser Al-Qahtani"}', now(), now(), '', '', '', ''),
('00000000-0000-0000-0000-000000000000', 'b3333333-3333-3333-3333-333333333333', 'authenticated', 'authenticated', 'admin.jeddah@smanager.com', crypt('123456', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"full_name": "Hana Al-Amri"}', now(), now(), '', '', '', ''),
('00000000-0000-0000-0000-000000000000', 'c1111111-1111-1111-1111-111111111111', 'authenticated', 'authenticated', 'staff.ali@smanager.com', crypt('123456', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"full_name": "Ali Hassan"}', now(), now(), '', '', '', ''),
('00000000-0000-0000-0000-000000000000', 'c2222222-2222-2222-2222-222222222222', 'authenticated', 'authenticated', 'staff.noura@smanager.com', crypt('123456', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"full_name": "Noura Al-Shehri"}', now(), now(), '', '', '', ''),
('00000000-0000-0000-0000-000000000000', 'c3333333-3333-3333-3333-333333333333', 'authenticated', 'authenticated', 'staff.omar@smanager.com', crypt('123456', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"full_name": "Omar Bakr"}', now(), now(), '', '', '', '')
ON CONFLICT (id) DO NOTHING;

-- Ensure Profiles are synced and roles are set
-- (Trigger might handle it, but this is safer for seed data)
INSERT INTO public.profiles (id, email, name, role, office_id)
VALUES
('a1111111-1111-1111-1111-111111111111', 'superadmin@smanager.com', 'Sultan Al-Sudairi', 'super_admin', 'f1111111-1111-1111-1111-111111111111'),
('b2222222-2222-2222-2222-222222222222', 'admin.riyadh@smanager.com', 'Nasser Al-Qahtani', 'admin', 'f1111111-1111-1111-1111-111111111111'),
('b3333333-3333-3333-3333-333333333333', 'admin.jeddah@smanager.com', 'Hana Al-Amri', 'admin', 'f2222222-2222-2222-2222-222222222222'),
('c1111111-1111-1111-1111-111111111111', 'staff.ali@smanager.com', 'Ali Hassan', 'staff', 'f1111111-1111-1111-1111-111111111111'),
('c2222222-2222-2222-2222-222222222222', 'staff.noura@smanager.com', 'Noura Al-Shehri', 'staff', 'f1111111-1111-1111-1111-111111111111'),
('c3333333-3333-3333-3333-333333333333', 'staff.omar@smanager.com', 'Omar Bakr', 'staff', 'f2222222-2222-2222-2222-222222222222')
ON CONFLICT (id) DO UPDATE SET 
    role = EXCLUDED.role, 
    office_id = EXCLUDED.office_id,
    name = EXCLUDED.name,
    email = EXCLUDED.email;

-- 4. SEED SERVICES
INSERT INTO public.services (id, name, description, base_fee) VALUES
('e1111111-1111-1111-1111-111111111111', 'Business CR Issuance', 'Complete registration of a new commercial entity.', 2500.00),
('e2222222-2222-2222-2222-222222222222', 'Muqeem Portal Management', 'Annual subscription and renewal services for Muqeem.', 500.00),
('e3333333-3333-3333-3333-333333333333', 'GOSI Compliance', 'Handling social insurance registrations and updates.', 300.00),
('e4444444-4444-4444-4444-444444444444', 'MOL File Opening', 'Opening records with the Ministry of Labor.', 1500.00),
('e5555555-5555-5555-5555-555555555555', 'Qiwa Contract Hub', 'Electronic documentation of labor contracts on Qiwa.', 200.00),
('e6666666-6666-6666-6666-666666666666', 'Zakat & VAT Filing', 'Assistance with periodic tax and Zakat declarations.', 5000.00)
ON CONFLICT (id) DO NOTHING;

-- 5. SEED CLIENTS
INSERT INTO public.clients (id, full_name, phone_number, email, address) VALUES
('d1111111-1111-1111-1111-111111111111', 'Saudi Aramco', '+966138720111', 'hr-support@aramco.com', 'Dhahran HQ, Eastern Province'),
('d2222222-2222-2222-2222-222222222222', 'NEOM Construction Ltd', '+966144881111', 'procurement@neom.com', 'Neom City Office'),
('d3333333-3333-3333-3333-333333333333', 'Al-Rajhi Group', '+966112113333', 'contact@alrajhi.com', 'King Fahd Rd, Riyadh'),
('d4444444-4444-4444-4444-444444444444', 'Jeddah Coffee Roasters', '+966505556667', 'hello@jeddahcoffee.sa', 'Al-Balad, Jeddah'),
('d5555555-5555-5555-5555-555555555555', 'Mohammed Al-Otaibi', '+966551122334', 'm.otaibi@outlook.com', 'Al-Nakheel, Riyadh')
ON CONFLICT (id) DO NOTHING;

-- 6. SEED WORK ORDERS & PAYMENTS & HISTORY
DO $$
DECLARE
    w1 UUID; w2 UUID; w3 UUID; w4 UUID;
BEGIN
    -- Work Order 1: Saudi Aramco - GOSI Compliance (Staff: Ali)
    INSERT INTO public.work_orders (client_id, client_name, client_phone_number, service_id, service_type, assigned_staff_id, assigned_office_id, priority, status)
    VALUES ('d1111111-1111-1111-1111-111111111111', 'Saudi Aramco', '+966138720111', 'e3333333-3333-3333-3333-333333333333', 'GOSI Compliance', 'c1111111-1111-1111-1111-111111111111', 'f1111111-1111-1111-1111-111111111111', 'High', 'In-Progress')
    RETURNING id INTO w1;

    INSERT INTO public.payments (work_order_id, total_amount, paid_amount, status)
    VALUES (w1, 5000.00, 2500.00, 'Advance');

    INSERT INTO public.task_history (work_order_id, title, description, status_at_time)
    VALUES 
    (w1, 'Project Kick-off', 'Met with Aramco HR to discuss bulk registration.', 'Pending'),
    (w1, 'Docs Uploaded', 'Uploaded 50 employee profiles to GOSI portal.', 'In-Progress');

    -- Work Order 2: NEOM - Business CR Issuance (Staff: Noura)
    INSERT INTO public.work_orders (client_id, client_name, client_phone_number, service_id, service_type, assigned_staff_id, assigned_office_id, priority, status)
    VALUES ('d2222222-2222-2222-2222-222222222222', 'NEOM Construction Ltd', '+966144881111', 'e1111111-1111-1111-1111-111111111111', 'Business CR Issuance', 'c2222222-2222-2222-2222-222222222222', 'f1111111-1111-1111-1111-111111111111', 'High', 'Pending')
    RETURNING id INTO w2;

    INSERT INTO public.payments (work_order_id, total_amount, paid_amount, status)
    VALUES (w2, 10000.00, 0.00, 'Pending');

    -- Work Order 3: Jeddah Coffee Roasters - Muqeem Renewal (Staff: Omar)
    INSERT INTO public.work_orders (client_id, client_name, client_phone_number, service_id, service_type, assigned_staff_id, assigned_office_id, priority, status)
    VALUES ('d4444444-4444-4444-4444-444444444444', 'Jeddah Coffee Roasters', '+966505556667', 'e2222222-2222-2222-2222-222222222222', 'Muqeem Portal Management', 'c3333333-3333-3333-3333-333333333333', 'f2222222-2222-2222-2222-222222222222', 'Medium', 'Completed')
    RETURNING id INTO w3;

    INSERT INTO public.payments (work_order_id, total_amount, paid_amount, status)
    VALUES (w3, 1500.00, 1500.00, 'Paid');

    INSERT INTO public.task_history (work_order_id, title, description, status_at_time)
    VALUES 
    (w3, 'System Login', 'Successfully accessed Jeddah Coffee Roasters Muqeem account.', 'In-Progress'),
    (w3, 'Complete', 'All 12 staff members renewed. Invoice issued.', 'Completed');

    -- Work Order 4: Mohammed Al-Otaibi - Muqeem Renewal (Staff: Ali)
    INSERT INTO public.work_orders (client_id, client_name, client_phone_number, service_id, service_type, assigned_staff_id, assigned_office_id, priority, status)
    VALUES ('d5555555-5555-5555-5555-555555555555', 'Mohammed Al-Otaibi', '+966551122334', 'e2222222-2222-2222-2222-222222222222', 'Iqama Renewal', 'c1111111-1111-1111-1111-111111111111', 'f1111111-1111-1111-1111-111111111111', 'Low', 'In-Progress')
    RETURNING id INTO w4;

    INSERT INTO public.payments (work_order_id, total_amount, paid_amount, status)
    VALUES (w4, 650.00, 650.00, 'Paid');

    -- 7. SEED ATTENDANCE
    INSERT INTO public.attendance (user_id, check_in_time, check_out_time, location_gps) VALUES
    ('c1111111-1111-1111-1111-111111111111', NOW() - INTERVAL '1 day 8 hours', NOW() - INTERVAL '1 day', '24.7136, 46.6753'), -- Ali (Riyadh)
    ('c2222222-2222-2222-2222-222222222222', NOW() - INTERVAL '1 day 7 hours', NOW() - INTERVAL '1 day', '24.7136, 46.6753'), -- Noura (Riyadh)
    ('c3333333-3333-3333-3333-333333333333', NOW() - INTERVAL '1 day 9 hours', NOW() - INTERVAL '1 day 1 hour', '21.5433, 39.1728'); -- Omar (Jeddah)

    -- 8. SEED LEAVES
    INSERT INTO public.leaves (user_id, leave_type, start_date, end_date, reason, status) VALUES
    ('c1111111-1111-1111-1111-111111111111', 'Annual', CURRENT_DATE + INTERVAL '10 days', CURRENT_DATE + INTERVAL '14 days', 'Family vacation to Abha', 'Approved'),
    ('c3333333-3333-3333-3333-333333333333', 'Sick', CURRENT_DATE - INTERVAL '2 days', CURRENT_DATE - INTERVAL '1 day', 'Flu', 'Approved');

    -- 9. SEED TASK DOCUMENTS
    INSERT INTO public.task_documents (work_order_id, title, file_url, icon_name, is_verified) VALUES
    (w1, 'Aramco GOSI Portal Screenshot', 'https://example.com/docs/gosi1.png', 'image', true),
    (w2, 'NEOM CR Copy', 'https://example.com/docs/neom_cr.pdf', 'description', false),
    (w4, 'Passport Copy - Al-Otaibi', 'https://example.com/docs/pass1.jpg', 'person', true);

END $$;

COMMIT;
