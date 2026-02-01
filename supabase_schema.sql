-- Enable Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- RESET (Caution: Deletes all data)
DROP TABLE IF EXISTS public.payments CASCADE;
DROP TABLE IF EXISTS public.task_history CASCADE;
DROP TABLE IF EXISTS public.task_documents CASCADE;
DROP TABLE IF EXISTS public.work_orders CASCADE;
DROP TABLE IF EXISTS public.attendance CASCADE;
DROP TABLE IF EXISTS public.leaves CASCADE;
DROP TABLE IF EXISTS public.profiles CASCADE;
DROP TABLE IF EXISTS public.offices CASCADE;
DROP TABLE IF EXISTS public.clients CASCADE;
DROP TABLE IF EXISTS public.services CASCADE;

DROP TYPE IF EXISTS public.app_role CASCADE;
DROP TYPE IF EXISTS public.priority_level CASCADE;
DROP TYPE IF EXISTS public.work_status CASCADE;
DROP TYPE IF EXISTS public.payment_status CASCADE;

-- 1. ENUMS
CREATE TYPE app_role AS ENUM ('super_admin', 'admin', 'staff');
CREATE TYPE priority_level AS ENUM ('High', 'Medium', 'Low');
CREATE TYPE work_status AS ENUM ('Pending', 'In-Progress', 'Completed');
CREATE TYPE payment_status AS ENUM ('Paid', 'Advance', 'Pending');

-- 2. TABLES

-- Offices
CREATE TABLE public.offices (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name TEXT NOT NULL,
    location TEXT NOT NULL,
    manager_name TEXT,
    workload_percentage INTEGER DEFAULT 0,
    staff_count INTEGER DEFAULT 0,
    revenue NUMERIC(15, 2) DEFAULT 0.00,
    color_hex TEXT DEFAULT '#10B981',
    manager_phone TEXT,
    phone_numbers JSONB DEFAULT '[]', -- List of {number: string, type: 'mobile'|'landline'}
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Profiles (Linked to Auth)
CREATE TABLE public.profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    email TEXT,
    name TEXT,
    role app_role DEFAULT 'staff',
    whatsapp_no TEXT,
    phone_number TEXT,
    office_id UUID REFERENCES public.offices(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Clients
CREATE TABLE public.clients (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    full_name TEXT NOT NULL,
    phone_number TEXT NOT NULL,
    email TEXT,
    address TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Services
CREATE TABLE public.services (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    base_fee NUMERIC(10, 2) DEFAULT 0.00,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Attendance
CREATE TABLE public.attendance (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    check_in_time TIMESTAMP WITH TIME ZONE,
    check_out_time TIMESTAMP WITH TIME ZONE,
    location_gps TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Leaves
CREATE TABLE public.leaves (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    leave_type TEXT NOT NULL, -- Annual, Sick, Emergency
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    reason TEXT,
    status TEXT DEFAULT 'Pending', -- Pending, Approved, Rejected
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Work Orders
CREATE TABLE public.work_orders (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    client_id UUID REFERENCES public.clients(id) ON DELETE SET NULL,
    client_name TEXT,
    client_phone_number TEXT,
    service_id UUID REFERENCES public.services(id) ON DELETE SET NULL,
    service_type TEXT,
    assigned_staff_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    assigned_office_id UUID REFERENCES public.offices(id) ON DELETE SET NULL,
    priority priority_level DEFAULT 'Medium',
    status work_status DEFAULT 'Pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Task Documents
CREATE TABLE public.task_documents (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    work_order_id UUID REFERENCES public.work_orders(id) ON DELETE CASCADE NOT NULL,
    title TEXT NOT NULL,
    file_url TEXT,
    icon_name TEXT, -- title, icon mapping
    is_verified BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Task History / Timeline
CREATE TABLE public.task_history (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    work_order_id UUID REFERENCES public.work_orders(id) ON DELETE CASCADE NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    status_at_time work_status,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Payments
CREATE TABLE public.payments (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    work_order_id UUID REFERENCES public.work_orders(id) ON DELETE CASCADE NOT NULL,
    total_amount NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    paid_amount NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    balance NUMERIC(10, 2) GENERATED ALWAYS AS (total_amount - paid_amount) STORED,
    status payment_status DEFAULT 'Pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. RLS POLICIES
ALTER TABLE public.offices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.services ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.leaves ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.work_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.task_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.task_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;

-- Helper function to get current user role
CREATE OR REPLACE FUNCTION public.get_my_role()
RETURNS app_role AS $$
DECLARE
  v_role app_role;
BEGIN
  SELECT role INTO v_role FROM public.profiles WHERE id = auth.uid();
  RETURN COALESCE(v_role, 'staff');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- POLICIES

-- Offices:
CREATE POLICY "Everyone view offices" ON public.offices FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Admins manage offices" ON public.offices FOR ALL USING (get_my_role() IN ('super_admin', 'admin'));

-- Profiles:
CREATE POLICY "Users can view own profile" ON public.profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Admins view all profiles" ON public.profiles FOR SELECT USING (get_my_role() IN ('admin', 'super_admin'));
CREATE POLICY "Super Admins manage profiles" ON public.profiles FOR ALL USING (get_my_role() = 'super_admin');

-- Clients:
CREATE POLICY "Admins manage clients" ON public.clients FOR ALL USING (get_my_role() IN ('super_admin', 'admin'));
CREATE POLICY "Staff view clients" ON public.clients FOR SELECT USING (get_my_role() = 'staff');

-- Services:
CREATE POLICY "Everyone view services" ON public.services FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Admins manage services" ON public.services FOR ALL USING (get_my_role() IN ('super_admin', 'admin'));

-- Attendance:
CREATE POLICY "Users manage own attendance" ON public.attendance FOR ALL USING (user_id = auth.uid());
CREATE POLICY "Admins view all attendance" ON public.attendance FOR SELECT USING (get_my_role() IN ('super_admin', 'admin'));

-- Leaves:
CREATE POLICY "Users manage own leaves" ON public.leaves FOR ALL USING (user_id = auth.uid());
CREATE POLICY "Admins manage all leaves" ON public.leaves FOR ALL USING (get_my_role() IN ('super_admin', 'admin'));

-- Work Orders:
CREATE POLICY "Admins manage all work orders" ON public.work_orders FOR ALL USING (get_my_role() IN ('super_admin', 'admin'));
CREATE POLICY "Staff view assigned work orders" ON public.work_orders FOR SELECT USING (assigned_staff_id = auth.uid());
CREATE POLICY "Staff update assigned work orders" ON public.work_orders FOR UPDATE USING (assigned_staff_id = auth.uid());
CREATE POLICY "Staff can create work orders" ON public.work_orders FOR INSERT WITH CHECK (true);

-- Task Documents:
CREATE POLICY "Users view task documents" ON public.task_documents FOR SELECT USING (
    work_order_id IN (SELECT id FROM public.work_orders WHERE assigned_staff_id = auth.uid() OR get_my_role() IN ('super_admin', 'admin'))
);
CREATE POLICY "Users manage task documents" ON public.task_documents FOR ALL USING (
    work_order_id IN (SELECT id FROM public.work_orders WHERE assigned_staff_id = auth.uid() OR get_my_role() IN ('super_admin', 'admin'))
);

-- Task History:
CREATE POLICY "Users view task history" ON public.task_history FOR SELECT USING (
    work_order_id IN (SELECT id FROM public.work_orders WHERE assigned_staff_id = auth.uid() OR get_my_role() IN ('super_admin', 'admin'))
);
CREATE POLICY "Staff insert task history" ON public.task_history FOR INSERT WITH CHECK (
    work_order_id IN (SELECT id FROM public.work_orders WHERE assigned_staff_id = auth.uid())
);
CREATE POLICY "Admins manage task history" ON public.task_history FOR ALL USING (get_my_role() IN ('super_admin', 'admin'));

-- Payments:
CREATE POLICY "Super Admin manage all payments" ON public.payments FOR ALL USING (get_my_role() = 'super_admin');
CREATE POLICY "Admin view all payments" ON public.payments FOR SELECT USING (get_my_role() = 'admin');
CREATE POLICY "Staff view own payments" ON public.payments FOR SELECT USING (
    work_order_id IN (SELECT id FROM public.work_orders WHERE assigned_staff_id = auth.uid())
);
CREATE POLICY "Staff update own payments" ON public.payments FOR UPDATE USING (
    work_order_id IN (SELECT id FROM public.work_orders WHERE assigned_staff_id = auth.uid())
);
CREATE POLICY "Staff insert own payments" ON public.payments FOR INSERT WITH CHECK (
    work_order_id IN (SELECT id FROM public.work_orders WHERE assigned_staff_id = auth.uid())
);

-- Trigger for new user profile creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, email, name, role)
  VALUES (
    new.id, 
    new.email, 
    COALESCE(
      new.raw_user_meta_data->>'full_name', 
      new.raw_user_meta_data->>'name', 
      'Staff Member'
    ), 
    'staff'
  )
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    name = COALESCE(EXCLUDED.name, public.profiles.name);
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Re-create the trigger to ensure it's fresh
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();
