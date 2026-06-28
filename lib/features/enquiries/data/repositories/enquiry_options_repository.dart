import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/supabase_org_utils.dart';

/// Categories of configurable enquiry dropdowns.
class EnquiryOptionCategory {
  static const nature = 'nature';
  static const nationality = 'nationality';
  static const rejectionReason = 'rejection_reason';
}

class EnquiryOption {
  final String id;
  final String value;
  final String? subtitle;
  final bool isActive;
  final int sortOrder;

  EnquiryOption({
    required this.id,
    required this.value,
    this.subtitle,
    required this.isActive,
    required this.sortOrder,
  });

  factory EnquiryOption.fromJson(Map<String, dynamic> j) => EnquiryOption(
        id: j['id'] as String,
        value: j['value'] as String,
        subtitle: j['subtitle'] as String?,
        isActive: j['is_active'] as bool? ?? true,
        sortOrder: j['sort_order'] as int? ?? 0,
      );
}

class EnquiryOptionsRepository {
  final SupabaseClient _client;
  EnquiryOptionsRepository(this._client);

  Future<List<EnquiryOption>> getOptions(String category) async {
    final res = await _client
        .from('enquiry_options')
        .select()
        .eq('category', category)
        .order('sort_order')
        .order('value');
    return (res as List)
        .map((j) => EnquiryOption.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<void> addOption(String category, String value, {String? subtitle}) async {
    final orgId = await fetchCallerOrgId(_client);
    final last = await _client
        .from('enquiry_options')
        .select('sort_order')
        .eq('category', category)
        .order('sort_order', ascending: false)
        .limit(1);
    final nextOrder =
        last.isNotEmpty ? ((last.first['sort_order'] as int? ?? 0) + 1) : 0;
    await _client.from('enquiry_options').insert({
      'org_id': orgId,
      'category': category,
      'value': value.trim(),
      'subtitle': (subtitle == null || subtitle.trim().isEmpty) ? null : subtitle.trim(),
      'sort_order': nextOrder,
      'is_active': true,
    });
  }

  Future<void> updateOption(String id, {required String value, String? subtitle}) async {
    await _client.from('enquiry_options').update({
      'value': value.trim(),
      'subtitle': (subtitle == null || subtitle.trim().isEmpty) ? null : subtitle.trim(),
    }).eq('id', id);
  }

  Future<void> setActive(String id, bool active) async {
    await _client.from('enquiry_options').update({'is_active': active}).eq('id', id);
  }

  Future<void> deleteOption(String id) async {
    await _client.from('enquiry_options').delete().eq('id', id);
  }

  // ── Per-field "required in form" config ──────────────────────────────────
  Future<bool> getFieldRequired(String category) async {
    final res = await _client
        .from('enquiry_field_config')
        .select('required')
        .eq('category', category)
        .maybeSingle();
    if (res != null) return res['required'] as bool? ?? false;
    return category == EnquiryOptionCategory.nature; // sensible default
  }

  Future<void> setFieldRequired(String category, bool required) async {
    final orgId = await fetchCallerOrgId(_client);
    await _client.from('enquiry_field_config').upsert({
      'org_id': orgId,
      'category': category,
      'required': required,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'org_id,category');
  }
}
