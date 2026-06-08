import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:service_manager_app/core/constants/supabase_env.dart';
import 'package:service_manager_app/features/enquiries/data/repositories/enquiry_repository.dart';
import 'package:service_manager_app/features/enquiries/domain/models/enquiry.dart';

void main() {
  late SupabaseClient client;
  late EnquiryRepository repo;
  String? createdId;

  setUpAll(() async {
    client = SupabaseClient(SupabaseEnv.url, SupabaseEnv.anonKey);
    await client.auth.signInWithPassword(
      email: 'superadmin@system.com',
      password: '123456',
    );
    repo = EnquiryRepository(client);
  });

  tearDownAll(() async {
    // Clean up any test enquiry left behind
    if (createdId != null) {
      try {
        await repo.deleteEnquiry(createdId!);
      } catch (_) {}
    }
    await client.auth.signOut();
    client.dispose();
  });

  group('Enquiry Model — Unit Tests', () {
    test('totalOffered = officialFee + serviceChargeOffered', () {
      final e = Enquiry(
        id: 'x', enquiryCode: 'R 001',
        officialFee: 200, serviceChargeOffered: 800,
      );
      expect(e.totalOffered, equals(1000.0));
    });

    test('totalOffered handles nulls as zero', () {
      final e = Enquiry(id: 'x', enquiryCode: 'R 001');
      expect(e.totalOffered, equals(0.0));
    });

    test('daysOpen counts from dateOfEnquiry to today when in progress', () {
      final e = Enquiry(
        id: 'x', enquiryCode: 'R 001',
        dateOfEnquiry: DateTime.now().subtract(const Duration(days: 10)),
        finalStatus: EnquiryFinalStatus.inProgress,
      );
      expect(e.daysOpen, equals(10));
    });

    test('daysOpen stops at settlementDate when settled', () {
      final enquiry = DateTime(2026, 5, 1);
      final settled = DateTime(2026, 5, 6);
      final e = Enquiry(
        id: 'x', enquiryCode: 'R 001',
        dateOfEnquiry: enquiry,
        finalStatus: EnquiryFinalStatus.settled,
        settlementDate: settled,
      );
      expect(e.daysOpen, equals(5));
    });

    test('performanceRating: Excellent when daysOpen <= 7', () {
      final e = Enquiry(
        id: 'x', enquiryCode: 'R 001',
        dateOfEnquiry: DateTime.now().subtract(const Duration(days: 5)),
        finalStatus: EnquiryFinalStatus.inProgress,
        clientStatus: ClientStatus.accepted,
      );
      expect(e.performanceRating, equals(PerformanceRating.excellent));
    });

    test('performanceRating: Good when daysOpen 8–14', () {
      final e = Enquiry(
        id: 'x', enquiryCode: 'R 001',
        dateOfEnquiry: DateTime.now().subtract(const Duration(days: 12)),
        finalStatus: EnquiryFinalStatus.inProgress,
        clientStatus: ClientStatus.accepted,
      );
      expect(e.performanceRating, equals(PerformanceRating.good));
    });

    test('performanceRating: Average when daysOpen 15–30', () {
      final e = Enquiry(
        id: 'x', enquiryCode: 'R 001',
        dateOfEnquiry: DateTime.now().subtract(const Duration(days: 20)),
        finalStatus: EnquiryFinalStatus.inProgress,
        clientStatus: ClientStatus.accepted,
      );
      expect(e.performanceRating, equals(PerformanceRating.average));
    });

    test('performanceRating: Needs Review when daysOpen > 30', () {
      final e = Enquiry(
        id: 'x', enquiryCode: 'R 001',
        dateOfEnquiry: DateTime.now().subtract(const Duration(days: 35)),
        finalStatus: EnquiryFinalStatus.inProgress,
        clientStatus: ClientStatus.accepted,
      );
      expect(e.performanceRating, equals(PerformanceRating.needsReview));
    });

    test('performanceRating: Needs Review when rejected regardless of days', () {
      final e = Enquiry(
        id: 'x', enquiryCode: 'R 001',
        dateOfEnquiry: DateTime.now().subtract(const Duration(days: 3)),
        finalStatus: EnquiryFinalStatus.rejectedByClient,
        clientStatus: ClientStatus.rejected,
      );
      expect(e.performanceRating, equals(PerformanceRating.needsReview));
    });

    test('Enquiry.fromJson parses all fields correctly', () {
      final json = {
        'id': 'abc-123',
        'enquiry_code': 'R 005',
        'client_name': 'Test Client',
        'contact_number': '+966500000000',
        'nature_of_enquiry': 'Gosi',
        'date_of_enquiry': '2026-05-01',
        'nationality': 'Indian',
        'official_fee': 200,
        'service_charge_offered': 300,
        'action_notes': 'Noted',
        'follow_up_date': '2026-05-10',
        'final_agreed_service_charge': 300,
        'responsible_staff_id': 'staff-id',
        'profiles': {'name': 'Ali Hassan'},
        'client_status': 'accepted',
        'rejection_reason': null,
        'final_status': 'Settled',
        'settlement_date': '2026-05-13',
        'final_notes': 'Done',
        'created_at': '2026-05-01T10:00:00Z',
      };
      final e = Enquiry.fromJson(json);
      expect(e.id, 'abc-123');
      expect(e.enquiryCode, 'R 005');
      expect(e.clientName, 'Test Client');
      expect(e.officialFee, 200.0);
      expect(e.serviceChargeOffered, 300.0);
      expect(e.totalOffered, 500.0);
      expect(e.clientStatus, ClientStatus.accepted);
      expect(e.finalStatus, EnquiryFinalStatus.settled);
      expect(e.responsibleStaffName, 'Ali Hassan');
      expect(e.daysOpen, 12); // May 1 → May 13
    });

    test('toJson produces correct keys for Supabase insert', () {
      final e = Enquiry(
        id: 'x', enquiryCode: 'R 001',
        clientName: 'John',
        contactNumber: '+1234',
        natureOfEnquiry: 'Gosi',
        officialFee: 100,
        serviceChargeOffered: 200,
        clientStatus: ClientStatus.accepted,
        finalStatus: EnquiryFinalStatus.settled,
        settlementDate: DateTime(2026, 6, 1),
      );
      final json = e.toJson();
      expect(json['client_name'], 'John');
      expect(json['official_fee'], 100.0);
      expect(json['client_status'], 'accepted');
      expect(json['final_status'], 'Settled');
      expect(json.containsKey('id'), isFalse);
      expect(json.containsKey('enquiry_code'), isFalse);
    });

    test('copyWith preserves unchanged fields', () {
      final e = Enquiry(
        id: 'x', enquiryCode: 'R 001',
        clientName: 'Alice', officialFee: 100,
      );
      final updated = e.copyWith(clientName: 'Bob');
      expect(updated.clientName, 'Bob');
      expect(updated.officialFee, 100.0);
      expect(updated.id, 'x');
    });
  });

  group('Enquiry Repository — Integration Tests (Live Supabase)', () {
    test('CREATE: createEnquiry inserts row and returns auto enquiry_code', () async {
      final enquiry = await repo.createEnquiry({
        'client_name': 'Integration Test Client',
        'contact_number': '+966500000099',
        'nature_of_enquiry': 'Absher',
        'date_of_enquiry': DateTime.now().toIso8601String(),
        'nationality': 'Indian',
        'official_fee': 0,
        'service_charge_offered': 150,
        'client_status': 'pending',
        'final_status': 'In Progress',
      });

      createdId = enquiry.id;

      expect(enquiry.id, isNotEmpty);
      expect(enquiry.enquiryCode, startsWith('R '));
      expect(enquiry.clientName, equals('Integration Test Client'));
      expect(enquiry.natureOfEnquiry, equals('Absher'));
      expect(enquiry.serviceChargeOffered, equals(150.0));
      expect(enquiry.clientStatus, equals(ClientStatus.pending));
      expect(enquiry.finalStatus, equals(EnquiryFinalStatus.inProgress));
      print('✓ CREATE: ${enquiry.enquiryCode} — ${enquiry.clientName}');
    });

    test('READ: getAllEnquiries returns list with profiles joined', () async {
      final enquiries = await repo.getAllEnquiries();
      expect(enquiries, isNotEmpty);
      expect(enquiries.every((e) => e.id.isNotEmpty), isTrue);
      expect(enquiries.every((e) => e.enquiryCode.startsWith('R ')), isTrue);
      // Verify our test row is present
      final found = enquiries.any((e) => e.clientName == 'Integration Test Client');
      expect(found, isTrue);
      print('✓ READ: ${enquiries.length} enquiries fetched');
    });

    test('READ: getEnquiriesByStaff filters correctly', () async {
      // Use Ali Hassan's ID from seed data
      const aliId = 'c1111111-1111-1111-1111-111111111111';
      final enquiries = await repo.getEnquiriesByStaff(aliId);
      expect(enquiries, isNotEmpty);
      expect(enquiries.every((e) => e.responsibleStaffId == aliId), isTrue);
      print('✓ READ BY STAFF: ${enquiries.length} enquiries for Ali Hassan');
    });

    test('UPDATE: updateEnquiry changes status and settlement date', () async {
      expect(createdId, isNotNull, reason: 'CREATE test must run first');
      final updated = await repo.updateEnquiry(createdId!, {
        'client_status': 'accepted',
        'final_agreed_service_charge': 150,
        'final_status': 'Settled',
        'settlement_date': DateTime.now().toIso8601String(),
        'final_notes': 'Test completed successfully.',
      });
      expect(updated.clientStatus, equals(ClientStatus.accepted));
      expect(updated.finalStatus, equals(EnquiryFinalStatus.settled));
      expect(updated.finalAgreedServiceCharge, equals(150.0));
      expect(updated.settlementDate, isNotNull);
      expect(updated.finalNotes, equals('Test completed successfully.'));
      print('✓ UPDATE: ${updated.enquiryCode} → ${updated.finalStatus}');
    });

    test('METRICS: daysOpen and performanceRating computed correctly after update', () async {
      expect(createdId, isNotNull);
      final enquiries = await repo.getAllEnquiries();
      final e = enquiries.firstWhere((e) => e.id == createdId);
      expect(e.finalStatus, equals(EnquiryFinalStatus.settled));
      expect(e.daysOpen, equals(0)); // created and settled same day
      expect(e.performanceRating, equals(PerformanceRating.excellent));
      print('✓ METRICS: days_open=${e.daysOpen}, rating=${e.performanceRating.name}');
    });

    test('SUMMARY: getSummaryStats returns correct structure', () async {
      final stats = await repo.getSummaryStats();
      expect(stats['total'], isA<int>());
      expect(stats['accepted'], isA<int>());
      expect(stats['rejected'], isA<int>());
      expect(stats['settled'], isA<int>());
      expect(stats['inProgress'], isA<int>());
      expect(stats['conversionRate'], isA<double>());
      expect(stats['avgDaysToSettle'], isA<double>());
      expect(stats['totalRevenue'], isA<double>());
      expect(stats['byService'], isA<Map<String, int>>());
      expect(stats['byStaff'], isA<Map<String, Map<String, dynamic>>>());
      expect(stats['total'], greaterThanOrEqualTo(8));
      expect(stats['conversionRate'], inInclusiveRange(0.0, 1.0));
      print('✓ SUMMARY: total=${stats['total']}, conv=${(stats['conversionRate'] * 100).toStringAsFixed(1)}%, revenue=SAR ${stats['totalRevenue']}');
    });

    test('DELETE: deleteEnquiry removes the test row', () async {
      expect(createdId, isNotNull);
      await repo.deleteEnquiry(createdId!);
      final enquiries = await repo.getAllEnquiries();
      final found = enquiries.any((e) => e.id == createdId);
      expect(found, isFalse);
      createdId = null; // prevent tearDownAll from double-deleting
      print('✓ DELETE: test row removed successfully');
    });
  });
}
