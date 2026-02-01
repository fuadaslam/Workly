import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:service_manager_app/core/constants/supabase_env.dart';
import 'package:service_manager_app/features/dashboard/data/repositories/office_repository.dart';
import 'package:service_manager_app/features/dashboard/data/repositories/profile_repository.dart';
import 'package:service_manager_app/features/dashboard/data/repositories/work_order_repository.dart';

void main() {
  late SupabaseClient client;
  late OfficeRepository officeRepo;
  late ProfileRepository profileRepo;
  late WorkOrderRepository workRepo;

  setUpAll(() async {
    // We use SupabaseClient directly to avoid SharedPreferences dependency in tests
    client = SupabaseClient(
      SupabaseEnv.url,
      SupabaseEnv.anonKey,
    );
    
    // Sign in to bypass RLS for testing
    await client.auth.signInWithPassword(
      email: 'superadmin@example.com',
      password: '123456',
    );
    
    officeRepo = OfficeRepository(client);
    profileRepo = ProfileRepository(client);
    workRepo = WorkOrderRepository(client);
  });

  group('Operation & API Audit', () {
    test('Office Repository CRUD', () async {
      print('Testing Office API...');
      final offices = await officeRepo.getOffices();
      expect(offices, isNotNull);
      print('✓ Successfully fetched ${offices.length} offices');

      final testOfficeName = 'Test Office ${DateTime.now().millisecondsSinceEpoch}';
      await officeRepo.addOffice({
        'name': testOfficeName,
        'location': 'Test Location',
        'manager_name': 'Test Manager',
      });
      print('✓ Successfully created test office');

      final updatedOffices = await officeRepo.getOffices();
      final createdExtra = updatedOffices.where((o) => o['name'] == testOfficeName).toList();
      expect(createdExtra.length, 1);
      
      // Cleanup
      await officeRepo.deleteOffice(createdExtra[0]['id']);
      print('✓ Successfully deleted test office');
    });

    test('Profile Soft Delete Operations', () async {
      print('Testing Profile API (Soft Delete)...');
      final profiles = await profileRepo.getProfiles();
      expect(profiles, isNotEmpty);
      
      final testStaff = profiles.firstWhere((p) => p['role'] == 'staff', orElse: () => {});
      if (testStaff.isNotEmpty) {
        final id = testStaff['id'];
        await profileRepo.deleteProfile(id);
        print('✓ Successfully performed soft delete on staff $id');
        
        final checkProfiles = await profileRepo.getProfiles();
        final deactivated = checkProfiles.firstWhere((p) => p['id'] == id);
        expect(deactivated['is_active'], false);
        
        await profileRepo.reactivateProfile(id);
        print('✓ Successfully reactivated staff $id');
        
        final activeAgain = (await profileRepo.getProfiles()).firstWhere((p) => p['id'] == id);
        expect(activeAgain['is_active'], true);
      } else {
        print('! Skipping profile test: No staff found in seed data');
      }
    });

    test('Work Order & Payment Flow', () async {
      print('Testing Work Order & Payment Logic...');
      
      // 1. Create Work Order
      final profiles = await profileRepo.getProfiles();
      final staffId = profiles.firstWhere((p) => p['role'] == 'staff')['id'];

      await workRepo.createWorkOrder(
        clientName: 'Audit Client',
        clientPhoneNumber: '123456789',
        serviceType: 'Audit Service',
        priority: 'High',
        assignedStaffId: staffId,
      );
      print('✓ Successfully created work order');

      // 2. Fetch and Verify
      final orders = await workRepo.getAllWorkOrders();
      final myOrder = orders.firstWhere((o) => o.clientName == 'Audit Client');
      expect(myOrder.status.name, 'pending');

      // 3. Update Status
      await workRepo.updateWorkOrderStatus(myOrder.id, 'In-Progress');
      print('✓ Successfully updated status to In-Progress');

      // 4. Update Payment
      await workRepo.updatePayment(myOrder.id, 1000.0, 400.0);
      print('✓ Successfully updated payment (1000 total, 400 paid)');
      
      final updatedOrders = await workRepo.getAllWorkOrders();
      final updatedOrder = updatedOrders.firstWhere((o) => o.id == myOrder.id);
      // Logic check: 400 < 1000 and > 0, should be 'Advance'
      // We need to check the DB directly for payment since WorkOrder model might not have all fields in some lists
      final paymentData = await client.from('payments').select().eq('work_order_id', myOrder.id).single();
      expect(paymentData['status'], 'Advance');
      print('✓ Logic verified: Payment status is "Advance"');
    });
  });
}
