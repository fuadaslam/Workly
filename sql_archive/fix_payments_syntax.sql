-- Run this SQL in your Supabase SQL Editor to fix the syntax error

DROP POLICY IF EXISTS "Staff update payments for their orders" ON public.payments;

CREATE POLICY "Staff update payments for their orders" ON public.payments
    FOR UPDATE USING (
        work_order_id IN (SELECT id FROM public.work_orders WHERE assigned_staff_id = auth.uid())
    );
