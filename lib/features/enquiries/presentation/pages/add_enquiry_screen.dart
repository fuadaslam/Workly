import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/notification_service.dart';
import '../../domain/models/enquiry.dart';
import '../providers/enquiry_provider.dart';
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
        'client_status': 'pending',
        'final_status': 'In Progress',
      };
      final created = await ref.read(enquiryRepositoryProvider).createEnquiry(data);
      // Schedule follow-up notification if date was set
      if (_followUpDate != null) {
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

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
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
                _dropdown('Nature of Enquiry *', _natureOfEnquiry, kNatureOfEnquiry, (v) => setState(() => _natureOfEnquiry = v), required: true),
                _dropdown('Nationality', _nationality, kNationalities, (v) => setState(() => _nationality = v)),
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
              ]),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.emeraldGreen, letterSpacing: 0.5)),
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(children: children),
    );
  }

  InputDecoration _inputDec(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: AppTheme.backgroundLight,
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.backgroundLight,
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
