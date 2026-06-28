import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/notification_service.dart';
import '../../domain/models/enquiry.dart';
import '../providers/enquiry_provider.dart';
import '../providers/enquiry_options_provider.dart';
import '../providers/enquiry_fields_provider.dart';
import '../../data/repositories/enquiry_options_repository.dart';
import '../../data/repositories/enquiry_fields_repository.dart';
import '../../../../features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:service_manager_app/core/widgets/app_bar.dart';

class AddEnquiryScreen extends ConsumerStatefulWidget {
  const AddEnquiryScreen({super.key});

  @override
  ConsumerState<AddEnquiryScreen> createState() => _AddEnquiryScreenState();
}

class _AddEnquiryScreenState extends ConsumerState<AddEnquiryScreen> {
  final _form = GlobalKey<FormState>();
  bool _saving = false;

  // Fields
  final _clientNameCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _officialFeeCtrl = TextEditingController();
  final _serviceChargeCtrl = TextEditingController();
  final _actionNotesCtrl = TextEditingController();

  String? _natureOfEnquiry;
  String? _nationality;
  DateTime? _dateOfEnquiry;
  DateTime? _followUpDate;
  String? _responsibleStaffId;
  String? _assignedOfficeId;
  // Values for admin-defined custom fields, keyed by field_key.
  final Map<String, dynamic> _customValues = {};

  @override
  void dispose() {
    _clientNameCtrl.dispose();
    _contactCtrl.dispose();
    _officialFeeCtrl.dispose();
    _serviceChargeCtrl.dispose();
    _actionNotesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isFollowUp) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.emeraldGreen),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isFollowUp) {
          _followUpDate = picked;
        } else {
          _dateOfEnquiry = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;

    // Validate required custom fields.
    final activeFields = ref.read(activeEnquiryFieldsProvider).valueOrNull ?? const [];
    final cleanCustom = <String, dynamic>{};
    for (final f in activeFields) {
      final v = _customValues[f.fieldKey];
      final isEmpty = v == null || (v is String && v.trim().isEmpty);
      if (f.required && isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${f.label} is required'), backgroundColor: AppTheme.errorRed),
        );
        return;
      }
      if (!isEmpty) cleanCustom[f.fieldKey] = v;
    }

    setState(() => _saving = true);
    try {
      final data = {
        'client_name': _clientNameCtrl.text.trim(),
        'contact_number': _contactCtrl.text.trim().isEmpty ? null : _contactCtrl.text.trim(),
        'nature_of_enquiry': _natureOfEnquiry,
        'date_of_enquiry': (_dateOfEnquiry ?? DateTime.now()).toIso8601String(),
        'nationality': _nationality,
        'official_fee': double.tryParse(_officialFeeCtrl.text) ?? 0,
        'service_charge_offered': double.tryParse(_serviceChargeCtrl.text) ?? 0,
        'action_notes': _actionNotesCtrl.text.trim().isEmpty ? null : _actionNotesCtrl.text.trim(),
        'follow_up_date': _followUpDate?.toIso8601String(),
        'responsible_staff_id': _responsibleStaffId,
        'assigned_office_id': _assignedOfficeId,
        'client_status': 'pending',
        'final_status': 'In Progress',
        'custom_data': cleanCustom,
      };
      final created = await ref.read(enquiryRepositoryProvider).createEnquiry(data);
      // Schedule follow-up notification if date was set (native only)
      if (!kIsWeb && _followUpDate != null) {
        await NotificationService.scheduleFollowUpReminder(
          id: created.id.hashCode,
          clientName: _clientNameCtrl.text.trim(),
          enquiryCode: created.enquiryCode,
          followUpDate: _followUpDate!,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final staffAsync = ref.watch(staffProfilesProvider);
    final df = DateFormat('dd MMM yyyy');
    // Org-configured dropdown options (fall back to built-in defaults).
    final natureOptions = ref.watch(enquiryOptionValuesProvider(EnquiryOptionCategory.nature)).valueOrNull ?? kNatureOfEnquiry;
    final nationalityOptions = ref.watch(enquiryOptionValuesProvider(EnquiryOptionCategory.nationality)).valueOrNull ?? kNationalities;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.backgroundLight,
      appBar: WorkqlyAppBar(
        title: 'New Enquiry',
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save', style: TextStyle(color: AppTheme.emeraldGreen, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      body: Form(
        key: _form,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('1. Client Information'),
              _card([
                _field('Client Name *', _clientNameCtrl, required: true),
                _field('Contact Number', _contactCtrl, keyboardType: TextInputType.phone),
                _dropdown('Nature of Enquiry *', _natureOfEnquiry, natureOptions, (v) => setState(() => _natureOfEnquiry = v), required: true),
                _dropdown('Nationality', _nationality, nationalityOptions, (v) => setState(() => _nationality = v)),
                _dateTile('Date of Enquiry', _dateOfEnquiry, df, () => _pickDate(false)),
              ]),
              const SizedBox(height: 16),
              _sectionTitle('2. Pricing'),
              _card([
                _field('Official Fee (SAR)', _officialFeeCtrl, keyboardType: TextInputType.number),
                _field('Service Charge Offered (SAR)', _serviceChargeCtrl, keyboardType: TextInputType.number),
                _totalRow(),
              ]),
              const SizedBox(height: 16),
              _sectionTitle('3. Follow Up'),
              _card([
                _multilineField('Action Taken / Notes', _actionNotesCtrl),
                _dateTile('Follow-up Date', _followUpDate, df, () => _pickDate(true)),
                staffAsync.when(
                  loading: () => const Padding(padding: EdgeInsets.all(8), child: LinearProgressIndicator()),
                  error: (_, __) => const SizedBox(),
                  data: (profiles) {
                    final items = profiles.map((p) => DropdownMenuItem<String>(
                      value: p['id'] as String,
                      child: Text(p['name'] ?? p['id']),
                    )).toList();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: DropdownButtonFormField<String>(
                        value: _responsibleStaffId,
                        decoration: _inputDec('Responsible Staff'),
                        items: items,
                        onChanged: (v) {
                          setState(() {
                            _responsibleStaffId = v;
                          });
                        },
                        hint: const Text('Select staff member'),
                        isExpanded: true,
                      ),
                    );
                  },
                ),
                ref.watch(officesProvider).when(
                  loading: () => const Padding(padding: EdgeInsets.all(8), child: LinearProgressIndicator()),
                  error: (_, __) => const SizedBox(),
                  data: (offices) {
                    final items = offices.map((o) => DropdownMenuItem<String>(
                      value: o['id'] as String,
                      child: Text(o['name'] ?? o['id']),
                    )).toList();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: DropdownButtonFormField<String>(
                        value: _assignedOfficeId,
                        decoration: _inputDec('Office / Location'),
                        items: items,
                        onChanged: (v) => setState(() => _assignedOfficeId = v),
                        hint: const Text('Select office'),
                        isExpanded: true,
                      ),
                    );
                  },
                ),
              ]),
              ..._buildCustomFieldsSection(),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCustomFieldsSection() {
    final fields = ref.watch(activeEnquiryFieldsProvider).valueOrNull ?? const [];
    if (fields.isEmpty) return const [];
    return [
      const SizedBox(height: 16),
      _sectionTitle('Additional Details'),
      _card(fields.map(_buildCustomField).toList()),
    ];
  }

  Widget _buildCustomField(EnquiryField f) {
    final label = f.required ? '${f.label} *' : f.label;
    switch (f.fieldType) {
      case EnquiryFieldType.dropdown:
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: DropdownButtonFormField<String>(
            initialValue: _customValues[f.fieldKey] as String?,
            decoration: _inputDec(label),
            isExpanded: true,
            items: f.options
                .map((o) => DropdownMenuItem(value: o, child: Text(o, overflow: TextOverflow.ellipsis)))
                .toList(),
            onChanged: (v) => setState(() => _customValues[f.fieldKey] = v),
            hint: const Text('Select'),
          ),
        );
      case EnquiryFieldType.date:
        final raw = _customValues[f.fieldKey] as String?;
        final shown = raw != null ? DateFormat('dd MMM yyyy').format(DateTime.parse(raw)) : 'Tap to set';
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: raw != null ? DateTime.parse(raw) : DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2035),
              );
              if (picked != null) {
                setState(() => _customValues[f.fieldKey] = picked.toIso8601String());
              }
            },
            child: InputDecorator(
              decoration: _inputDec(label),
              child: Text(shown),
            ),
          ),
        );
      case EnquiryFieldType.number:
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextFormField(
            initialValue: _customValues[f.fieldKey]?.toString(),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: _inputDec(label),
            onChanged: (v) => _customValues[f.fieldKey] = num.tryParse(v.trim()) ?? v.trim(),
          ),
        );
      case EnquiryFieldType.textarea:
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextFormField(
            initialValue: _customValues[f.fieldKey] as String?,
            maxLines: 3,
            decoration: _inputDec(label),
            onChanged: (v) => _customValues[f.fieldKey] = v,
          ),
        );
      default: // text
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextFormField(
            initialValue: _customValues[f.fieldKey] as String?,
            decoration: _inputDec(label),
            onChanged: (v) => _customValues[f.fieldKey] = v,
          ),
        );
    }
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.emeraldGreen, letterSpacing: 0.5)),
    );
  }

  Widget _card(List<Widget> children) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(children: children),
    );
  }

  InputDecoration _inputDec(String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: isDark ? AppTheme.darkCard : AppTheme.backgroundLight,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.emeraldGreen),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  Widget _field(String label, TextEditingController ctrl,
      {TextInputType? keyboardType, bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        decoration: _inputDec(label),
        validator: required ? (v) => (v == null || v.isEmpty) ? 'Required' : null : null,
      ),
    );
  }

  Widget _multilineField(String label, TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        maxLines: 3,
        decoration: _inputDec(label),
      ),
    );
  }

  Widget _dropdown(String label, String? value, List<String> items, ValueChanged<String?> onChanged,
      {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: _inputDec(label),
        items: items.map((i) => DropdownMenuItem(value: i, child: Text(i, overflow: TextOverflow.ellipsis))).toList(),
        onChanged: onChanged,
        isExpanded: true,
        validator: required ? (v) => (v == null || v.isEmpty) ? 'Required' : null : null,
        hint: Text('Select $label'.replaceAll(' *', '')),
      ),
    );
  }

  Widget _dateTile(String label, DateTime? date, DateFormat df, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : AppTheme.backgroundLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(children: [
            const Icon(Icons.calendar_today_outlined, size: 18, color: AppTheme.emeraldGreen),
            const SizedBox(width: 10),
            Text(date != null ? df.format(date) : label,
                style: TextStyle(color: date != null ? AppTheme.darkBlue : Colors.grey.shade500)),
            const Spacer(),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ]),
        ),
      ),
    );
  }

  Widget _totalRow() {
    final official = double.tryParse(_officialFeeCtrl.text) ?? 0;
    final service = double.tryParse(_serviceChargeCtrl.text) ?? 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('Total Offered', style: TextStyle(color: Colors.grey, fontSize: 13)),
        Text('SAR ${(official + service).toStringAsFixed(0)}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.emeraldGreen)),
      ]),
    );
  }
}
