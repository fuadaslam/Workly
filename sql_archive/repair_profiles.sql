-- ===================================================
-- REPAIR SCRIPT: Fix Missing Profiles
-- Run this if you are seeing "Profile not found" 
-- but you are already signed up.
-- ===================================================

INSERT INTO public.profiles (id, email, name, role)
SELECT 
    id, 
    email, 
    COALESCE(raw_user_meta_data->>'full_name', 'Unknown User'), 
    'staff'
FROM auth.users
WHERE id NOT IN (SELECT id FROM public.profiles);

-- Verify it worked
SELECT * FROM public.profiles;
