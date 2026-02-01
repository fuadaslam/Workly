-- Run this SQL in your Supabase SQL Editor to fix the permission error

CREATE POLICY "Staff insert payments for their orders" ON public.payments
    FOR INSERT WITH CHECK (
        work_order_id IN (SELECT id FROM public.work_orders WHERE assigned_staff_id = auth.uid())
    );
