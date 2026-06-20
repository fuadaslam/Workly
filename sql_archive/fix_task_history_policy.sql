-- Allow staff to insert task history for their own assigned work orders
DROP POLICY IF EXISTS "Staff insert task history" ON public.task_history;
CREATE POLICY "Staff insert task history" ON public.task_history 
FOR INSERT WITH CHECK (
    work_order_id IN (SELECT id FROM public.work_orders WHERE assigned_staff_id = auth.uid())
);
