-- ==========================================
-- SEED DATA FOR TASK HISTORY (DAILY NOTES)
-- ==========================================

DO $$
DECLARE
    order_id UUID;
    staff_id UUID;
BEGIN
    -- 1. Progress for Al-Futtaim Construction Visa (assigned to staff@example.com)
    SELECT id, assigned_staff_id INTO order_id, staff_id FROM public.work_orders WHERE client_name = 'Al-Futtaim Construction' LIMIT 1;
    
    IF order_id IS NOT NULL THEN
        INSERT INTO public.task_history (work_order_id, title, description, status_at_time, created_at)
        VALUES 
        (order_id, 'Docs Received / استلام الأوراق', 'Passport copies and CR received from client.', 'Pending', NOW() - INTERVAL '3 days'),
        (order_id, 'Initial Submission / التقديم الأولي', 'Application submitted via Qiwa portal.', 'Pending', NOW() - INTERVAL '2 days'),
        (order_id, 'Payment Pending / انتطار الدفع', 'Awaiting government fee payment from finance.', 'Pending', NOW() - INTERVAL '1 day');
    END IF;

    -- 2. Progress for Dr. Sarah Ahmed Iqama (assigned to staff@example.com)
    SELECT id, assigned_staff_id INTO order_id, staff_id FROM public.work_orders WHERE client_name = 'Dr. Sarah Ahmed' LIMIT 1;
    
    IF order_id IS NOT NULL THEN
        INSERT INTO public.task_history (work_order_id, title, description, status_at_time, created_at)
        VALUES 
        (order_id, 'Medical Done / الفحص الطبي', 'Client completed medical checkup at Riyadh Clinic.', 'In-Progress', NOW() - INTERVAL '4 days'),
        (order_id, 'Insurance Updated / تحديث التأمين', 'Health insurance policy linked to Absher.', 'In-Progress', NOW() - INTERVAL '2 days'),
        (order_id, 'Processing / قيد المعالجة', 'Final approval pending from Jawazat.', 'In-Progress', NOW() - INTERVAL '5 hours');
    END IF;

    -- 3. Completed Task: Blue Sky Logistics (assigned to staff.riyadh2@example.com)
    SELECT id, assigned_staff_id INTO order_id, staff_id FROM public.work_orders WHERE client_name = 'Blue Sky Logistics' LIMIT 1;
    
    IF order_id IS NOT NULL THEN
        INSERT INTO public.task_history (work_order_id, title, description, status_at_time, created_at)
        VALUES 
        (order_id, 'Request Setup / إعداد الطلب', 'Muqeem portal access verified.', 'Pending', NOW() - INTERVAL '7 days'),
        (order_id, 'Data Entry / إدخال البيانات', 'Employee list uploaded to Muqeem.', 'In-Progress', NOW() - INTERVAL '5 days'),
        (order_id, 'Task Completed / تم الانتهاء', 'All updates reflected in Muqeem system.', 'Completed', NOW() - INTERVAL '2 days');
    END IF;

    -- 4. Jeddah Branch: Saudi Tech Solutions
    SELECT id, assigned_staff_id INTO order_id, staff_id FROM public.work_orders WHERE client_name = 'Saudi Tech Solutions' LIMIT 1;
    
    IF order_id IS NOT NULL THEN
        INSERT INTO public.task_history (work_order_id, title, description, status_at_time, created_at)
        VALUES 
        (order_id, 'Bulk Upload / رفع جماعي', 'Started processing 50 work visas.', 'Pending', NOW() - INTERVAL '1 day'),
        (order_id, 'Note / ملاحظة', 'Waiting for HR manager signature on contracts.', 'Pending', NOW());
    END IF;

END $$;
