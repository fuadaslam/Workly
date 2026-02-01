-- ==========================================
-- SEED DATA FOR SAUDI SERVICE MANAGER APP
-- ==========================================

-- 0. CLEANUP OLD SEED USERS
DELETE FROM auth.users WHERE email IN ('superadmin@example.com', 'admin@example.com', 'staff@example.com', 'staff.riyadh2@example.com', 'staff.jeddah@example.com', 'staff.dammam@example.com');

-- 0. SEED TEST USERS (Supabase Auth)
-- Password for all: 123456
INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, recovery_token, email_change_token_new, email_change)
VALUES 
('00000000-0000-0000-0000-000000000000', 'a1111111-1111-1111-1111-111111111111', 'authenticated', 'authenticated', 'superadmin@example.com', crypt('123456', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"full_name": "Main Super Admin"}', now(), now(), '', '', '', ''),
('00000000-0000-0000-0000-000000000000', 'b2222222-2222-2222-2222-222222222222', 'authenticated', 'authenticated', 'admin@example.com', crypt('123456', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"full_name": "Regional Admin"}', now(), now(), '', '', '', ''),
('00000000-0000-0000-0000-000000000000', 'c3333333-3333-3333-3333-333333333333', 'authenticated', 'authenticated', 'staff@example.com', crypt('123456', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"full_name": "Ahmed (Staff)"}', now(), now(), '', '', '', ''),
('00000000-0000-0000-0000-000000000000', 'c4444444-4444-4444-4444-444444444444', 'authenticated', 'authenticated', 'staff.riyadh2@example.com', crypt('123456', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"full_name": "Sara (Riyadh)"}', now(), now(), '', '', '', ''),
('00000000-0000-0000-0000-000000000000', 'd5555555-5555-5555-5555-555555555555', 'authenticated', 'authenticated', 'staff.jeddah@example.com', crypt('123456', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"full_name": "Faisal (Jeddah)"}', now(), now(), '', '', '', ''),
('00000000-0000-0000-0000-000000000000', 'e6666666-6666-6666-6666-666666666666', 'authenticated', 'authenticated', 'staff.dammam@example.com', crypt('123456', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"full_name": "Omar (Dammam)"}', now(), now(), '', '', '', '')
ON CONFLICT (id) DO NOTHING;

-- ==========================================
-- MASTER SYNC: Ensure ALL Auth users have Profiles
-- ==========================================
INSERT INTO public.profiles (id, email, name, role)
SELECT 
    id, 
    email, 
    COALESCE(raw_user_meta_data->>'full_name', raw_user_meta_data->>'name', 'Staff Member'), 
    'staff' -- Default role
FROM auth.users
ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    name = COALESCE(EXCLUDED.name, public.profiles.name);

-- Update the specific roles based on the email (Seed Specific)
UPDATE public.profiles SET role = 'super_admin' WHERE email = 'superadmin@example.com';
UPDATE public.profiles SET role = 'admin' WHERE email = 'admin@example.com';
UPDATE public.profiles SET role = 'staff' WHERE email LIKE 'staff.%';

-- 1. SEED OFFICES
INSERT INTO public.offices (id, name, location, manager_name, workload_percentage, staff_count, revenue, color_hex) VALUES
('f1111111-1111-1111-1111-111111111111', 'Riyadh Main Office', 'Olaya District, Riyadh', 'Abdullah Mansour', 85, 12, 150000.00, '#10B981'),
('f2222222-2222-2222-2222-222222222222', 'Jeddah Branch', 'Prince Sultan St, Jeddah', 'Faisal Khalid', 65, 8, 95000.00, '#3B82F6'),
('f3333333-3333-3333-3333-333333333333', 'Dammam Hub', 'King Fahd Rd, Dammam', 'Omar Ibrahim', 45, 5, 45000.00, '#F59E0B')
ON CONFLICT (id) DO NOTHING;

-- Assign staff to their respective offices
UPDATE public.profiles SET office_id = 'f1111111-1111-1111-1111-111111111111' WHERE email LIKE 'staff.riyadh%';
UPDATE public.profiles SET office_id = 'f2222222-2222-2222-2222-222222222222' WHERE email = 'staff.jeddah@example.com';
UPDATE public.profiles SET office_id = 'f3333333-3333-3333-3333-333333333333' WHERE email = 'staff.dammam@example.com';
UPDATE public.profiles SET office_id = 'f1111111-1111-1111-1111-111111111111' WHERE email = 'admin@example.com';

-- 2. SEED SERVICES
INSERT INTO public.services (name, description, base_fee) VALUES
('Iqama Renewal', 'Annual residence permit renewal for expatriates.', 650.00),
('New Work Visa', 'Processing new employment visa issuance.', 2000.00),
('Medical Insurance', 'Health insurance policy issuance (Class C/B/A).', 850.00),
('Exit Re-Entry Visa', 'Single or multiple exit re-entry visa processing.', 200.00),
('Family Visit Visa', 'Application for family visitation requests.', 350.00),
('Profession Change', 'Official profession modification in Qiwa/Absher.', 1000.00),
('Driving License', 'Assistance with driving license issuance procedures.', 1500.00),
('Muqeem Service', 'General Muqeem portal updates and management.', 400.00),
('GOSI Registration', 'Employee registration in the Social Insurance portal.', 500.00),
('Qiwa Contract', 'Electronic contract documentation on Qiwa.', 300.00),
('Commercial License', 'Business registration and municipal licensing.', 2500.00)
ON CONFLICT DO NOTHING;

-- 3. SEED CLIENTS
INSERT INTO public.clients (full_name, phone_number, email, address) VALUES
('Al-Futtaim Construction', '+966501234567', 'contact@alfuttaim.sa', 'Riyadh, Olaya St.'),
('Saudi Tech Solutions', '+966509876543', 'hr@sauditech.com', 'Jeddah, Prince Sultan Rd.'),
('Mohammed Al-Harbi', '+966551122334', 'm.alharbi@gmail.com', 'Dammam, Corniche'),
('Green Leaf Restaurant', '+966540001111', 'manager@greenleaf.sa', 'Khobar, King Fahd Rd.'),
('Dr. Sarah Ahmed', '+966567778888', 'contact@drsarahclinics.com', 'Riyadh, As Sulimaniyah'),
('Blue Sky Logistics', '+966599900001', 'info@bluesky.com', 'Riyadh, Exit 10'),
('Ahmad Al-Ghamdi', '+966555444333', 'ahmad.g@outlook.com', 'Riyadh, Al Malqa')
ON CONFLICT DO NOTHING;

-- 4. SEED WORK ORDERS & PAYMENTS (Complex multi-staff/different office distribution)
DO $$
DECLARE
    -- Client IDs
    c_futtaim UUID; c_tech UUID; c_harbi UUID; c_leaf UUID; c_sarah UUID; c_sky UUID; c_ghamdi UUID;
    
    -- Staff IDs
    s_riyadh1 UUID := 'c3333333-3333-3333-3333-333333333333';
    s_riyadh2 UUID := 'c4444444-4444-4444-4444-444444444444';
    s_jeddah UUID  := 'd5555555-5555-5555-5555-555555555555';
    s_dammam UUID  := 'e6666666-6666-6666-6666-666666666666';
    
    -- Service IDs
    s_iqama UUID; s_visa UUID; s_ins UUID; s_muq UUID; s_qiwa UUID; s_prof UUID; s_comm_license UUID;
    
    -- Temp IDs for seeding payments
    w_id UUID;
BEGIN
    -- Fetch IDs
    SELECT id INTO c_futtaim FROM public.clients WHERE full_name = 'Al-Futtaim Construction' LIMIT 1;
    SELECT id INTO c_tech FROM public.clients WHERE full_name = 'Saudi Tech Solutions' LIMIT 1;
    SELECT id INTO c_harbi FROM public.clients WHERE full_name = 'Mohammed Al-Harbi' LIMIT 1;
    SELECT id INTO c_leaf FROM public.clients WHERE full_name = 'Green Leaf Restaurant' LIMIT 1;
    SELECT id INTO c_sarah FROM public.clients WHERE full_name = 'Dr. Sarah Ahmed' LIMIT 1;
    SELECT id INTO c_sky FROM public.clients WHERE full_name = 'Blue Sky Logistics' LIMIT 1;
    SELECT id INTO c_ghamdi FROM public.clients WHERE full_name = 'Ahmad Al-Ghamdi' LIMIT 1;
    
    SELECT id INTO s_iqama FROM public.services WHERE name = 'Iqama Renewal' LIMIT 1;
    SELECT id INTO s_visa FROM public.services WHERE name = 'New Work Visa' LIMIT 1;
    SELECT id INTO s_ins FROM public.services WHERE name = 'Medical Insurance' LIMIT 1;
    SELECT id INTO s_muq FROM public.services WHERE name = 'Muqeem Service' LIMIT 1;
    SELECT id INTO s_qiwa FROM public.services WHERE name = 'Qiwa Contract' LIMIT 1;
    SELECT id INTO s_prof FROM public.services WHERE name = 'Profession Change' LIMIT 1;
    SELECT id INTO s_comm_license FROM public.services WHERE name = 'Commercial License' LIMIT 1;

    -- --- RIYADH 1 TASKS ---
    INSERT INTO public.work_orders (client_id, client_name, client_phone_number, service_id, service_type, assigned_staff_id, assigned_office_id, priority, status)
    VALUES (c_futtaim, 'Al-Futtaim Construction', '+966501234567', s_visa, 'New Work Visa', s_riyadh1, 'f1111111-1111-1111-1111-111111111111', 'High', 'Pending') RETURNING id INTO w_id;
    INSERT INTO public.payments (work_order_id, total_amount, paid_amount, status) VALUES (w_id, 2000.00, 500.00, 'Advance');

    INSERT INTO public.work_orders (client_id, client_name, client_phone_number, service_id, service_type, assigned_staff_id, assigned_office_id, priority, status)
    VALUES (c_sarah, 'Dr. Sarah Ahmed', '+966567778888', s_iqama, 'Iqama Renewal', s_riyadh1, 'f1111111-1111-1111-1111-111111111111', 'Medium', 'In-Progress') RETURNING id INTO w_id;
    INSERT INTO public.payments (work_order_id, total_amount, paid_amount, status) VALUES (w_id, 650.00, 650.00, 'Paid');

    -- --- RIYADH 2 TASKS ---
    INSERT INTO public.work_orders (client_id, client_name, client_phone_number, service_id, service_type, assigned_staff_id, assigned_office_id, priority, status)
    VALUES (c_ghamdi, 'Ahmad Al-Ghamdi', '+966555444333', s_qiwa, 'Qiwa Contract', s_riyadh2, 'f1111111-1111-1111-1111-111111111111', 'Low', 'Pending') RETURNING id INTO w_id;
    INSERT INTO public.payments (work_order_id, total_amount, paid_amount, status) VALUES (w_id, 300.00, 0.00, 'Pending');

    INSERT INTO public.work_orders (client_id, client_name, client_phone_number, service_id, service_type, assigned_staff_id, assigned_office_id, priority, status)
    VALUES (c_sky, 'Blue Sky Logistics', '+966599900001', s_muq, 'Muqeem Service', s_riyadh2, 'f1111111-1111-1111-1111-111111111111', 'High', 'Completed') RETURNING id INTO w_id;
    INSERT INTO public.payments (work_order_id, total_amount, paid_amount, status) VALUES (w_id, 400.00, 400.00, 'Paid');

    -- --- JEDDAH TASKS ---
    INSERT INTO public.work_orders (client_id, client_name, client_phone_number, service_id, service_type, assigned_staff_id, assigned_office_id, priority, status)
    VALUES (c_tech, 'Saudi Tech Solutions', '+966509876543', s_visa, 'Bulk Visa Processing', s_jeddah, 'f2222222-2222-2222-2222-222222222222', 'High', 'Pending') RETURNING id INTO w_id;
    INSERT INTO public.payments (work_order_id, total_amount, paid_amount, status) VALUES (w_id, 10000.00, 2000.00, 'Advance');

    INSERT INTO public.work_orders (client_id, client_name, client_phone_number, service_id, service_type, assigned_staff_id, assigned_office_id, priority, status)
    VALUES (c_leaf, 'Green Leaf Restaurant', '+966540001111', s_comm_license, 'Commercial License', s_jeddah, 'f2222222-2222-2222-2222-222222222222', 'Medium', 'In-Progress') RETURNING id INTO w_id;
    -- Service ID was fetched earlier, using a literal for variety
    INSERT INTO public.payments (work_order_id, total_amount, paid_amount, status) VALUES (w_id, 2500.00, 0.00, 'Pending');

    -- --- DAMMAM TASKS ---
    INSERT INTO public.work_orders (client_id, client_name, client_phone_number, service_id, service_type, assigned_staff_id, assigned_office_id, priority, status)
    VALUES (c_harbi, 'Mohammed Al-Harbi', '+966551122334', s_ins, 'Medical Insurance', s_dammam, 'f3333333-3333-3333-3333-333333333333', 'Low', 'Completed') RETURNING id INTO w_id;
    INSERT INTO public.payments (work_order_id, total_amount, paid_amount, status) VALUES (w_id, 850.00, 850.00, 'Paid');

    INSERT INTO public.work_orders (client_id, client_name, client_phone_number, service_id, service_type, assigned_staff_id, assigned_office_id, priority, status)
    VALUES (c_futtaim, 'Al-Futtaim (Dammam Branch)', '+966501234567', s_prof, 'Profession Change', s_dammam, 'f3333333-3333-3333-3333-333333333333', 'Medium', 'In-Progress') RETURNING id INTO w_id;
    INSERT INTO public.payments (work_order_id, total_amount, paid_amount, status) VALUES (w_id, 1000.00, 500.00, 'Advance');

END $$;
