import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/supabase_org_utils.dart';

/// Supported custom field input types.
class EnquiryFieldType {
  static const text = 'text';
  static const number = 'number';
  static const date = 'date';
  static const dropdown = 'dropdown';
  static const textarea = 'textarea';

  static const all = [text, number, date, dropdown, textarea];
  static String label(String t) {
    switch (t) {
      case text: return 'Text';
      case number: return 'Number';
      case date: return 'Date';
      case dropdown: return 'Dropdown';
      case textarea: return 'Paragraph';
      default: return t;
    }
  }
}

class EnquiryField {
  final String id;
  final String fieldKey;
  final String label;
  final String fieldType;
  final bool required;
  final List<String> options;
  final int sortOrder;
  final bool isActive;

  EnquiryField({
    required this.id,
    required this.fieldKey,
    required this.label,
    required this.fieldType,
    required this.required,
    required this.options,
    required this.sortOrder,
    required this.isActive,
  });

  factory EnquiryField.fromJson(Map<String, dynamic> j) => EnquiryField(
        id: j['id'] as String,
        fieldKey: j['field_key'] as String,
        label: j['label'] as String,
        fieldType: j['field_type'] as String,
        required: j['required'] as bool? ?? false,
        options: (j['options'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        sortOrder: j['sort_order'] as int? ?? 0,
        isActive: j['is_active'] as bool? ?? true,
      );
}

class EnquiryFieldsRepository {
  final SupabaseClient _client;
  EnquiryFieldsRepository(this._client);

  Future<List<EnquiryField>> getFields() async {
    final res = await _client
        .from('enquiry_fields')
        .select()
        .order('sort_order')
        .order('created_at');
    return (res as List)
        .map((j) => EnquiryField.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  /// Derives a unique snake_case key from [label] within the org.
  Future<String> _uniqueKey(String label, List<EnquiryField> existing) async {
    var base = label
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    if (base.isEmpty) base = 'field';
    final keys = existing.map((f) => f.fieldKey).toSet();
    if (!keys.contains(base)) return base;
    var i = 2;
    while (keys.contains('${base}_$i')) {
      i++;
    }
    return '${base}_$i';
  }

  Future<void> addField({
    required String label,
    required String fieldType,
    required bool required,
    List<String> options = const [],
  }) async {
    final orgId = await fetchCallerOrgId(_client);
    final existing = await getFields();
    final key = await _uniqueKey(label, existing);
    final nextOrder = existing.isEmpty ? 0 : existing.map((f) => f.sortOrder).reduce((a, b) => a > b ? a : b) + 1;
    await _client.from('enquiry_fields').insert({
      'org_id': orgId,
      'field_key': key,
      'label': label.trim(),
      'field_type': fieldType,
      'required': required,
      'options': options,
      'sort_order': nextOrder,
      'is_active': true,
    });
  }

  Future<void> updateField(
    String id, {
    String? label,
    String? fieldType,
    bool? required,
    List<String>? options,
    bool? isActive,
  }) async {
    final data = <String, dynamic>{};
    if (label != null) data['label'] = label.trim();
    if (fieldType != null) data['field_type'] = fieldType;
    if (required != null) data['required'] = required;
    if (options != null) data['options'] = options;
    if (isActive != null) data['is_active'] = isActive;
    if (data.isEmpty) return;
    await _client.from('enquiry_fields').update(data).eq('id', id);
  }

  Future<void> deleteField(String id) async {
    await _client.from('enquiry_fields').delete().eq('id', id);
  }
}
