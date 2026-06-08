-- =====================================
-- DANGER: CLEAR ALL DATA FROM PUBLIC TABLES
-- =====================================
-- This script wipes all data from your public application tables.
-- It does NOT delete your Auth Login (unless you add the DELETE FROM auth.users line).

BEGIN;

-- Disable Row Level Security temporarily to ensure we can truncate everything if running as a specific role
-- (Though SQL Editor usually runs as service_role/postgres which bypasses RLS)

TRUNCATE 
    public.task_history, 
    public.task_documents, 
    public.payments, 
    public.work_orders, 
    public.attendance, 
    public.leaves, 
    public.profiles, 
    public.offices, 
    public.clients, 
    public.services 
CASCADE;

-- Optional: If you also want to remove all users you created (EXCEPT your current admin)
-- DELETE FROM auth.users WHERE email != 'your-admin-email@example.com';

COMMIT;
