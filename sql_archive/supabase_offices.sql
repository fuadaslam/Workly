-- Create Offices Table
CREATE TABLE public.offices (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name TEXT NOT NULL,
    location TEXT NOT NULL,
    manager_name TEXT,
    workload_percentage INTEGER DEFAULT 0,
    staff_count INTEGER DEFAULT 0,
    revenue NUMERIC(15, 2) DEFAULT 0.00,
    color_hex TEXT DEFAULT '#10B981', -- Default emerald green
    manager_phone TEXT,
    phone_numbers JSONB DEFAULT '[]', -- List of {number: string, type: 'mobile'|'landline'}
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS
ALTER TABLE public.offices ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins manage offices" ON public.offices
    FOR ALL USING (get_my_role() IN ('super_admin', 'admin'));

CREATE POLICY "Everyone view offices" ON public.offices
    FOR SELECT USING (auth.role() = 'authenticated');
