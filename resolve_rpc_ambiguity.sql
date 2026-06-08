-- Resolve PGRST203 ambiguity error by dropping the overloaded version of create_user_admin
-- that uses TEXT for the office parameter.

-- 1. Drop the version with TEXT for office
-- The signature has 6 text parameters (since Postgres treats UUID vs TEXT differently for overloading)
DROP FUNCTION IF EXISTS public.create_user_admin(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT);

-- 2. Ensure the correct version with UUID for office is properly defined
-- We use CREATE OR REPLACE to ensure it's up to date.
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
SECURITY DEFINER
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

    -- Update the profile with the specific role/office
    -- This works because on_auth_user_created trigger already created the profile row
    UPDATE public.profiles
    SET 
        role = user_role::public.app_role, -- Cast to the custom enum type
        phone_number = phone,
        office_id = office,
        name = full_name
    WHERE id = new_user_id;

    RETURN new_user_id;
END;
$$;
