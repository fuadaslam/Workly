-- Run this SQL in your Supabase SQL Editor to support soft deletes and cross-schema user creation

-- 1. Add is_active column to profiles
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;

-- 2. Create an RPC to safely create an auth user from the admin dashboard
-- This requires the 'service_role' or high privileges, so we use 'SECURITY DEFINER'.
-- WARNING: Only expose this if you have proper RLS/checks!

-- First, drop any potentially conflicting overloaded versions (e.g. if office was previously TEXT)
DROP FUNCTION IF EXISTS public.create_user_admin(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT);

CREATE OR REPLACE FUNCTION public.create_user_admin(
    new_email TEXT,
    new_password TEXT,
    full_name TEXT,
    user_role TEXT,
    phone TEXT DEFAULT NULL,
    office UUID DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER -- Runs with privileges of the creator
AS $$
DECLARE
    new_user_id UUID;
BEGIN
    -- Check if the caller is a super_admin
    IF (SELECT role FROM public.profiles WHERE id = auth.uid()) != 'super_admin' THEN
        RAISE EXCEPTION 'Only super_admins can create users manually.';
    END IF;

    -- Create user in auth.users
    INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token)
    VALUES (
        '00000000-0000-0000-0000-000000000000',
        gen_random_uuid(),
        'authenticated',
        'authenticated',
        new_email,
        crypt(new_password, gen_salt('bf')),
        now(),
        '{"provider":"email","providers":["email"]}',
        jsonb_build_object('full_name', full_name),
        now(),
        now(),
        '',
        '',
        '',
        ''
    )
    RETURNING id INTO new_user_id;

    -- The trigger 'on_auth_user_created' in supabase_schema.sql will automatically 
    -- create the profile, but we need to update it with the specific role/office
    -- because the trigger defaults to 'staff'.
    
    UPDATE public.profiles
    SET 
        role = user_role::public.app_role,
        phone_number = phone,
        office_id = office,
        name = full_name
    WHERE id = new_user_id;

    RETURN new_user_id;
END;
$$;
