import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/models/organization.dart';

class SaasRepository {
  final SupabaseClient _client;
  SaasRepository(this._client);

  // ─── Organizations ────────────────────────────────────────────────────────

  Future<List<Organization>> getAllOrganizations() async {
    final rows = await _client.from('organizations').select('''
      id, name, slug, owner_id, logo_url, website, phone, address, created_at,
      subscriptions ( status, trial_ends_at, current_period_end,
        plans ( name, display_name, price_monthly, max_users, max_offices ) )
    ''').order('created_at', ascending: false);

    final List<Map<String, dynamic>> orgs = List<Map<String, dynamic>>.from(rows as List);

    // One batched query for member counts instead of one query per org.
    final orgIds = orgs.map((o) => o['id'] as String).toList();
    final memberCounts = <String, int>{};
    if (orgIds.isNotEmpty) {
      final profileRows = await _client.from('profiles').select('org_id').inFilter('org_id', orgIds);
      for (final p in (profileRows as List)) {
        final orgId = p['org_id'] as String?;
        if (orgId != null) memberCounts[orgId] = (memberCounts[orgId] ?? 0) + 1;
      }
    }

    final result = <Organization>[];
    for (final o in orgs) {
      final subRaw = o['subscriptions'];
      final sub = subRaw is List ? subRaw.firstOrNull as Map<String, dynamic>? : subRaw as Map<String, dynamic>?;
      final planRaw = sub?['plans'];
      final plan = planRaw is List ? planRaw.firstOrNull as Map<String, dynamic>? : planRaw as Map<String, dynamic>?;
      result.add(Organization(
        id: o['id'],
        name: o['name'] ?? '',
        slug: o['slug'] ?? '',
        ownerId: o['owner_id'],
        ownerName: (o['owner'] as Map?)?.containsKey('name') == true ? o['owner']['name'] : null,
        logoUrl: o['logo_url'],
        website: o['website'],
        phone: o['phone'],
        address: o['address'],
        createdAt: DateTime.parse(o['created_at']),
        planName: plan?['name'],
        planDisplayName: plan?['display_name'],
        subStatus: sub?['status'],
        priceMonthly: plan?['price_monthly'] != null ? (plan!['price_monthly'] as num).toDouble() : null,
        maxUsers: plan?['max_users'],
        maxOffices: plan?['max_offices'],
        periodEnd: sub?['current_period_end'] != null ? DateTime.parse(sub!['current_period_end']) : null,
        trialEndsAt: sub?['trial_ends_at'] != null ? DateTime.parse(sub!['trial_ends_at']) : null,
        memberCount: memberCounts[o['id']] ?? 0,
      ));
    }
    return result;
  }

  Future<Organization> getOrganization(String orgId) async {
    final orgs = await getAllOrganizations();
    return orgs.firstWhere((o) => o.id == orgId);
  }

  Future<Organization> createOrganization({
    required String name,
    required String slug,
    required String planId,
    String? website,
    String? phone,
    String? address,
  }) async {
    final result = await _client.rpc('create_organization', params: {
      'p_name': name,
      'p_slug': slug,
      'p_plan_id': planId,
      'p_website': website,
      'p_phone': phone,
      'p_address': address,
    });
    final orgId = result as String;
    return getOrganization(orgId);
  }

  Future<void> updateOrganization(String orgId, {
    String? name,
    String? website,
    String? phone,
    String? address,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (website != null) data['website'] = website;
    if (phone != null) data['phone'] = phone;
    if (address != null) data['address'] = address;
    await _client.from('organizations').update(data).eq('id', orgId);
  }

  Future<void> updateSubscriptionPlan(String orgId, String planId, String status) async {
    await _client.from('subscriptions')
        .update({
          'plan_id': planId,
          'status': status,
          'current_period_start': DateTime.now().toIso8601String(),
          'current_period_end': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
        })
        .eq('org_id', orgId);
  }

  Future<void> suspendOrganization(String orgId) async {
    await _client.from('subscriptions').update({'status': 'paused'}).eq('org_id', orgId);
  }

  Future<void> reactivateOrganization(String orgId) async {
    await _client.from('subscriptions').update({'status': 'active'}).eq('org_id', orgId);
  }

  // ─── Plans ────────────────────────────────────────────────────────────────

  Future<List<OrgPlan>> getPlans() async {
    final rows = await _client.from('plans').select().eq('is_active', true).order('price_monthly');
    return (rows as List).map((j) => OrgPlan.fromJson(j as Map<String, dynamic>)).toList();
  }

  // ─── Members ──────────────────────────────────────────────────────────────

  Future<List<OrgMember>> getOrgMembers(String orgId) async {
    final rows = await _client
        .from('profiles')
        .select('id, name, email, role, is_active, created_at, offices(name)')
        .eq('org_id', orgId)
        .order('created_at');
    return (rows as List).map((j) => OrgMember.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<void> removeMember(String profileId) async {
    await _client.from('profiles').update({'org_id': null, 'is_active': false}).eq('id', profileId);
  }

  Future<void> updateMemberRole(String profileId, String role) async {
    await _client.from('profiles').update({'role': role}).eq('id', profileId);
  }

  // ─── Invitations ──────────────────────────────────────────────────────────

  Future<List<OrgInvitation>> getInvitations(String orgId) async {
    final rows = await _client
        .from('org_invitations')
        .select('*, invited_by_profile:invited_by(name)')
        .eq('org_id', orgId)
        .order('created_at', ascending: false);
    return (rows as List).map((j) => OrgInvitation.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<void> sendInvitation(String orgId, String email, String role) async {
    await _client.from('org_invitations').upsert({
      'org_id': orgId,
      'email': email.toLowerCase().trim(),
      'role': role,
      'invited_by': _client.auth.currentUser?.id,
      'accepted_at': null,
      'expires_at': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
    }, onConflict: 'org_id,email');
  }

  Future<void> cancelInvitation(String invitationId) async {
    await _client.from('org_invitations').delete().eq('id', invitationId);
  }

  // ─── Platform stats ───────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getPlatformStats() async {
    final results = await Future.wait([
      _client.from('organizations').select('id').count(CountOption.exact),
      _client.from('profiles').select('id').count(CountOption.exact),
      _client.from('work_orders').select('id').count(CountOption.exact),
      _client.from('subscriptions').select('id').eq('status', 'active').count(CountOption.exact),
    ]);

    double mrr = 0;
    final subs = await _client.from('subscriptions').select('status, plans(price_monthly)').eq('status', 'active');
    for (final s in (subs as List)) {
      mrr += (s['plans']?['price_monthly'] as num? ?? 0).toDouble();
    }

    return {
      'totalOrgs': results[0].count,
      'totalUsers': results[1].count,
      'totalWorkOrders': results[2].count,
      'activeSubscriptions': results[3].count,
      'mrr': mrr,
    };
  }
}
