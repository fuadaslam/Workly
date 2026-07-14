import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/router/app_router.dart' show TaskRouteArgs;
import '../../domain/models/enquiry.dart';
import '../providers/enquiry_provider.dart';
import '../providers/enquiry_options_provider.dart';
import '../providers/enquiry_fields_provider.dart';
import '../../data/repositories/enquiry_options_repository.dart';
import '../../data/repositories/enquiry_fields_repository.dart';
import '../../../../features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:service_manager_app/core/widgets/app_bar.dart';
import 'package:service_manager_app/core/widgets/responsive_layout.dart';

class EnquiryDetailScreen extends ConsumerStatefulWidget {
  final Enquiry enquiry;
  const EnquiryDetailScreen({super.key, required this.enquiry});

  @override
  ConsumerState<EnquiryDetailScreen> createState() => _EnquiryDetailScreenState();
}

class _EnquiryDetailScreenState extends ConsumerState<EnquiryDetailScreen> {
  late Enquiry _enquiry;
  bool _editing = false;
  bool _saving = false;

  // Edit controllers
  late TextEditingController _clientNameCtrl;
  late TextEditingController _contactCtrl;
  late TextEditingController _iqamaCtrl;
  late TextEditingController _officialFeeCtrl;
  late TextEditingController _serviceChargeCtrl;
  late TextEditingController _actionNotesCtrl;
  late TextEditingController _agreedChargeCtrl;
  late TextEditingController _finalNotesCtrl;

  // Working copy of custom field values, edited in-place while editing.
  late Map<String, dynamic> _customValues;

  @override
  void initState() {
    super.initState();
    _enquiry = widget.enquiry;
    _customValues = Map<String, dynamic>.from(_enquiry.customData);
    _initControllers();
  }

  void _initControllers() {
    _clientNameCtrl = TextEditingController(text: _enquiry.clientName ?? '');
    _contactCtrl = TextEditingController(text: _enquiry.contactNumber ?? '');
    _iqamaCtrl = TextEditingController(text: _enquiry.iqamaNumber ?? '');
    _officialFeeCtrl = TextEditingController(text: _enquiry.officialFee?.toStringAsFixed(0) ?? '');
    _serviceChargeCtrl = TextEditingController(text: _enquiry.serviceChargeOffered?.toStringAsFixed(0) ?? '');
    _actionNotesCtrl = TextEditingController(text: _enquiry.actionNotes ?? '');
    _agreedChargeCtrl = TextEditingController(text: _enquiry.finalAgreedServiceCharge?.toStringAsFixed(0) ?? '');
    _finalNotesCtrl = TextEditingController(text: _enquiry.finalNotes ?? '');
  }

  @override
  void dispose() {
    _clientNameCtrl.dispose();
    _contactCtrl.dispose();
    _iqamaCtrl.dispose();
    _officialFeeCtrl.dispose();
    _serviceChargeCtrl.dispose();
    _actionNotesCtrl.dispose();
    _agreedChargeCtrl.dispose();
    _finalNotesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    // Validate + collect custom fields.
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
    // Preserve values stored for fields that are no longer active.
    final activeKeys = activeFields.map((f) => f.fieldKey).toSet();
    _customValues.forEach((k, v) {
      final isEmpty = v == null || (v is String && v.trim().isEmpty);
      if (!activeKeys.contains(k) && !isEmpty) cleanCustom[k] = v;
    });

    setState(() => _saving = true);
    try {
      final data = _enquiry.toJson()
        ..['client_name'] = _clientNameCtrl.text.trim()
        ..['contact_number'] = _contactCtrl.text.trim()
        ..['iqama_number'] = _iqamaCtrl.text.trim().isEmpty ? null : _iqamaCtrl.text.trim()
        ..['official_fee'] = double.tryParse(_officialFeeCtrl.text)
        ..['service_charge_offered'] = double.tryParse(_serviceChargeCtrl.text)
        ..['action_notes'] = _actionNotesCtrl.text.trim()
        ..['final_agreed_service_charge'] = double.tryParse(_agreedChargeCtrl.text)
        ..['final_notes'] = _finalNotesCtrl.text.trim()
        ..['custom_data'] = cleanCustom;

      final updated = await ref.read(enquiryRepositoryProvider).updateEnquiry(_enquiry.id, data);
      setState(() {
        _enquiry = updated;
        _customValues = Map<String, dynamic>.from(updated.customData);
        _editing = false;
      });
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

  Future<void> _convertToWorkOrder() async {
    setState(() => _saving = true);
    try {
      final woId = await ref.read(enquiryRepositoryProvider).convertToWorkOrder(_enquiry.id);
      if (mounted) setState(() => _enquiry = _enquiry.copyWith(workOrderId: woId));
      ref.read(paginatedEnquiriesProvider.notifier).refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Work order created from enquiry'), backgroundColor: AppTheme.statusCompleted),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AppTheme.errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _openWorkOrder() {
    final id = _enquiry.workOrderId;
    if (id == null) return;
    context.push('/dashboard/task/$id', extra: TaskRouteArgs(
      clientName: _enquiry.clientName ?? '—',
      clientPhone: _enquiry.contactNumber,
      priority: 'Medium',
      initialStatus: 'Pending',
    ));
  }

  /// Call-to-action shown under the metrics header: convert an accepted
  /// enquiry to a work order, or open the already-created one.
  Widget _buildConversionCta() {
    if (_enquiry.workOrderId != null) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.statusCompleted.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.statusCompleted.withValues(alpha: 0.3)),
        ),
        child: Row(children: [
          const Icon(Icons.check_circle, color: AppTheme.statusCompleted, size: 20),
          const SizedBox(width: 10),
          const Expanded(child: Text('Converted to a work order', style: TextStyle(fontWeight: FontWeight.w600))),
          TextButton(onPressed: _openWorkOrder, child: const Text('Open')),
        ]),
      );
    }
    if (_enquiry.clientStatus == ClientStatus.accepted) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _saving ? null : _convertToWorkOrder,
          icon: const Icon(Icons.assignment_turned_in_outlined),
          label: const Text('Convert to Work Order'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.emeraldGreen,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      );
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.mutedAmber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(children: [
        Icon(Icons.info_outline, size: 18, color: AppTheme.mutedAmber),
        SizedBox(width: 8),
        Expanded(
          child: Text('Mark the client decision as Accepted to convert this enquiry into a work order.',
              style: TextStyle(fontSize: 12)),
        ),
      ]),
    );
  }

  Future<void> _updateStatus(EnquiryFinalStatus status) async {
    setState(() => _saving = true);
    try {
      final data = {
        'final_status': _statusToString(status),
        if (status == EnquiryFinalStatus.settled || status == EnquiryFinalStatus.executed)
          'settlement_date': DateTime.now().toIso8601String(),
      };
      final updated = await ref.read(enquiryRepositoryProvider).updateEnquiry(_enquiry.id, data);
      setState(() => _enquiry = updated);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _updateClientStatus(ClientStatus status, {String? rejectionReason}) async {
    setState(() => _saving = true);
    try {
      final data = {
        'client_status': status.name,
        if (rejectionReason != null) 'rejection_reason': rejectionReason,
      };
      final updated = await ref.read(enquiryRepositoryProvider).updateEnquiry(_enquiry.id, data);
      setState(() => _enquiry = updated);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<String?> _showPicker(
    String title,
    List<MapEntry<String, String>> options,
    String? currentId,
  ) {
    return showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              if (options.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No options available', style: TextStyle(color: Colors.grey)),
                ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: options.map((o) {
                    final selected = o.key == currentId;
                    return ListTile(
                      title: Text(o.value),
                      trailing: selected
                          ? const Icon(Icons.check, color: AppTheme.emeraldGreen)
                          : null,
                      onTap: () => Navigator.pop(ctx, o.key),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  /// Applies an assignment/transfer without reading the row back (see
  /// [EnquiryRepository.assignEnquiry]), updating local state optimistically
  /// and refreshing the list so the change is reflected on return.
  Future<void> _applyAssignment(Map<String, dynamic> data, Enquiry optimistic) async {
    setState(() => _saving = true);
    try {
      await ref.read(enquiryRepositoryProvider).assignEnquiry(_enquiry.id, data);
      if (mounted) setState(() => _enquiry = optimistic);
      ref.read(paginatedEnquiriesProvider.notifier).refresh();
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

  Future<void> _assignResponsibleStaff() async {
    final staff = await ref.read(staffProfilesProvider.future);
    if (!mounted) return;
    final options = staff
        .map((p) => MapEntry(p['id'] as String, (p['name'] ?? p['id']) as String))
        .toList();
    final selected = await _showPicker(
      'Assign / Transfer to Staff',
      options,
      _enquiry.responsibleStaffId,
    );
    if (selected == null || selected == _enquiry.responsibleStaffId) return;
    final name = options.firstWhere((o) => o.key == selected).value;
    await _applyAssignment(
      {'responsible_staff_id': selected},
      _enquiry.copyWith(responsibleStaffId: selected, responsibleStaffName: name),
    );
  }

  Future<void> _assignOffice() async {
    final offices = await ref.read(officesProvider.future);
    if (!mounted) return;
    final options = offices
        .map((o) => MapEntry(o['id'] as String, (o['name'] ?? o['id']) as String))
        .toList();
    final selected = await _showPicker(
      'Assign to Office / Location',
      options,
      _enquiry.assignedOfficeId,
    );
    if (selected == null || selected == _enquiry.assignedOfficeId) return;
    final name = options.firstWhere((o) => o.key == selected).value;
    await _applyAssignment(
      {'assigned_office_id': selected},
      _enquiry.copyWith(assignedOfficeId: selected, assignedOfficeName: name),
    );
  }

  Widget _assignRow(String text, bool isSet, VoidCallback onTap) {
    return InkWell(
      onTap: _saving ? null : onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 15,
                color: isSet ? null : Colors.grey,
                fontStyle: isSet ? FontStyle.normal : FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.swap_horiz_rounded, size: 18, color: AppTheme.electricBlue),
        ],
      ),
    );
  }

  Future<void> _pickDate(bool isFollowUp) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: AppTheme.emeraldGreen)),
        child: child!,
      ),
    );
    if (picked != null) {
      final data = isFollowUp
          ? {'follow_up_date': picked.toIso8601String()}
          : {'date_of_enquiry': picked.toIso8601String()};
      final updated = await ref.read(enquiryRepositoryProvider).updateEnquiry(_enquiry.id, data);
      setState(() => _enquiry = updated);
    }
  }

  String _statusToString(EnquiryFinalStatus s) {
    switch (s) {
      case EnquiryFinalStatus.executed: return 'Executed';
      case EnquiryFinalStatus.settled: return 'Settled';
      case EnquiryFinalStatus.postponedByClient: return 'Postponed by client';
      case EnquiryFinalStatus.rejectedByClient: return 'Rejected by client';
      case EnquiryFinalStatus.cancelled: return 'Cancelled';
      case EnquiryFinalStatus.inProgress: return 'In Progress';
    }
  }

  Color _statusColor(EnquiryFinalStatus s) {
    switch (s) {
      case EnquiryFinalStatus.executed:
      case EnquiryFinalStatus.settled: return AppTheme.statusCompleted;
      case EnquiryFinalStatus.inProgress: return AppTheme.accentGold;
      case EnquiryFinalStatus.postponedByClient: return AppTheme.statusPending;
      case EnquiryFinalStatus.rejectedByClient:
      case EnquiryFinalStatus.cancelled: return AppTheme.errorRed;
    }
  }

  Color _perfColor(PerformanceRating r) {
    switch (r) {
      case PerformanceRating.excellent: return AppTheme.statusCompleted;
      case PerformanceRating.good: return AppTheme.statusCompleted;
      case PerformanceRating.average: return AppTheme.statusPending;
      case PerformanceRating.needsReview: return AppTheme.errorRed;
    }
  }

  String _perfLabel(PerformanceRating r) {
    switch (r) {
      case PerformanceRating.excellent: return 'Excellent';
      case PerformanceRating.good: return 'Good';
      case PerformanceRating.average: return 'Average';
      case PerformanceRating.needsReview: return 'Needs Review';
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd MMM yyyy');
    final statusColor = _statusColor(_enquiry.finalStatus);
    final perfColor = _perfColor(_enquiry.performanceRating);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Slate 50
      appBar: WorkqlyAppBar(
        title: 'Enquiry Details',
        actions: [
          if (_editing) ...[
            TextButton(
              onPressed: () => setState(() {
                _editing = false;
                _initControllers();
              }),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save', style: TextStyle(color: AppTheme.emeraldGreen, fontWeight: FontWeight.bold)),
            ),
          ] else
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => setState(() => _editing = true),
            ),
        ],
      ),
      body: ResponsiveLayout(
        maxWidth: double.infinity,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status + Metrics header
              _metricsBar(statusColor, perfColor, df),
              const SizedBox(height: 16),

              // Convert-to-work-order call to action
              _buildConversionCta(),
              const SizedBox(height: 16),

              // Section 1: Client Info
              _sectionTitle('Enquiry Details'),
              _card([
                _detailRow('Client Name', _editing
                    ? _editField(_clientNameCtrl)
                    : Text(_enquiry.clientName ?? '—', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15))),
                _detailRow('Contact', _editing
                    ? _editField(_contactCtrl, keyboardType: TextInputType.phone)
                    : Text(_enquiry.contactNumber ?? '—', style: const TextStyle(fontSize: 15))),
                _detailRow('Iqama Number', _editing
                    ? _editField(_iqamaCtrl)
                    : Text(_enquiry.iqamaNumber ?? '—', style: const TextStyle(fontSize: 15))),
                _detailRow('Service Type', Text(_enquiry.natureOfEnquiry ?? '—', style: const TextStyle(fontSize: 15))),
                _detailRow('Nationality', Text(_enquiry.nationality ?? '—', style: const TextStyle(fontSize: 15))),
                _detailRow('Date of Enquiry', _dateTapRow(
                    _enquiry.dateOfEnquiry != null ? df.format(_enquiry.dateOfEnquiry!) : 'Tap to set',
                    () => _pickDate(false))),
              ]),
              const SizedBox(height: 24),

              // Section 2: Pricing
              _sectionTitle('Pricing'),
              _card([
                _detailRow('Official Fee (SAR)', _editing
                    ? _editField(_officialFeeCtrl, keyboardType: TextInputType.number)
                    : Text('SAR ${_enquiry.officialFee?.toStringAsFixed(0) ?? "0"}', style: const TextStyle(fontSize: 15))),
                _detailRow('Service Charge Offered', _editing
                    ? _editField(_serviceChargeCtrl, keyboardType: TextInputType.number)
                    : Text('SAR ${_enquiry.serviceChargeOffered?.toStringAsFixed(0) ?? "0"}', style: const TextStyle(fontSize: 15))),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Divider(color: Colors.grey.shade200, height: 1),
                ),
                _detailRow('Total Offered',
                    Text('SAR ${_enquiry.totalOffered.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.emeraldGreen))),
              ]),
              const SizedBox(height: 24),

              // Section 3: Follow Up
              _sectionTitle('Follow Up / Action'),
              _card([
                _detailRow('Action Notes', _editing
                    ? _editField(_actionNotesCtrl, maxLines: 3)
                    : Text(_enquiry.actionNotes ?? '—', style: const TextStyle(height: 1.5, fontSize: 15))),
                _detailRow('Follow-up Date', _dateTapRow(
                    _enquiry.followUpDate != null ? df.format(_enquiry.followUpDate!) : 'Tap to set',
                    () => _pickDate(true))),
                _detailRow('Responsible', _assignRow(
                  _enquiry.responsibleStaffName ?? 'Tap to assign / transfer',
                  _enquiry.responsibleStaffName != null,
                  _assignResponsibleStaff,
                )),
                _detailRow('Office / Location', _assignRow(
                  _enquiry.assignedOfficeName ?? 'Tap to assign',
                  _enquiry.assignedOfficeName != null,
                  _assignOffice,
                )),
                // Client Accept/Reject
                _detailRow('Client Decision', _clientStatusWidget()),
                if (_enquiry.clientStatus == ClientStatus.rejected && _enquiry.rejectionReason != null)
                  _detailRow('Rejection Reason', Text(_enquiry.rejectionReason!,
                      style: const TextStyle(color: AppTheme.errorRed, fontSize: 15))),
              ]),
              const SizedBox(height: 24),

              // Custom fields (admin-configured)
              ..._buildCustomDetails(),

              // Section 4: Settlement
              _sectionTitle('Settlement & Metrics'),
              _card([
                _detailRow('Final Status', _finalStatusDropdown()),
                if (_enquiry.settlementDate != null)
                  _detailRow('Settlement Date', Text(df.format(_enquiry.settlementDate!), style: const TextStyle(fontSize: 15))),
                _detailRow('Final Agreed Charge', _editing
                    ? _editField(_agreedChargeCtrl, keyboardType: TextInputType.number)
                    : Text(_enquiry.finalAgreedServiceCharge != null
                        ? 'SAR ${_enquiry.finalAgreedServiceCharge!.toStringAsFixed(0)}'
                        : '—',
                        style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.statusCompleted, fontSize: 16))),
                _detailRow('Final Notes', _editing
                    ? _editField(_finalNotesCtrl, maxLines: 3)
                    : Text(_enquiry.finalNotes ?? '—', style: const TextStyle(fontSize: 15))),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Divider(color: Colors.grey.shade200, height: 1),
                ),
                _detailRow('Days Open / Ageing',
                    Text('${_enquiry.daysOpen} days',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                _detailRow('Performance',
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: perfColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.star_rounded, size: 16, color: perfColor),
                        const SizedBox(width: 6),
                        Text(_perfLabel(_enquiry.performanceRating),
                            style: TextStyle(color: perfColor, fontWeight: FontWeight.bold, fontSize: 13)),
                      ]),
                    )),
              ]),
              const SizedBox(height: 48),

              // Delete button
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.errorRed.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextButton.icon(
                    onPressed: _confirmDelete,
                    icon: const Icon(Icons.delete_outline, color: AppTheme.errorRed),
                    label: const Text('Delete Enquiry', style: TextStyle(color: AppTheme.errorRed, fontWeight: FontWeight.w600)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  /// Renders the admin-configured custom fields. Editable in edit mode
  /// (shows all active fields), read-only otherwise (shows stored values).
  List<Widget> _buildCustomDetails() {
    final allFields = ref.watch(enquiryFieldRowsProvider).valueOrNull ?? const [];
    final activeFields = allFields.where((f) => f.isActive).toList();

    if (_editing) {
      if (activeFields.isEmpty) return const [];
      return [
        _sectionTitle('Additional Details'),
        _card(activeFields.map(_buildCustomFieldEditor).toList()),
        const SizedBox(height: 24),
      ];
    }

    final labelByKey = {for (final f in allFields) f.fieldKey: f.label};
    final typeByKey = {for (final f in allFields) f.fieldKey: f.fieldType};
    final entries = _customValues.entries
        .where((e) => e.value != null && e.value.toString().trim().isNotEmpty)
        .toList();
    if (entries.isEmpty) return const [];
    return [
      _sectionTitle('Additional Details'),
      _card(entries.map((e) {
        final label = labelByKey[e.key] ?? e.key.replaceAll('_', ' ');
        return _detailRow(label, Text(_formatCustomValue(typeByKey[e.key], e.value),
            style: const TextStyle(fontSize: 15)));
      }).toList()),
      const SizedBox(height: 24),
    ];
  }

  Widget _buildCustomFieldEditor(EnquiryField f) {
    final dec = InputDecoration(
      labelText: f.required ? '${f.label} *' : f.label,
      helperText: (f.helpText != null && f.helpText!.isNotEmpty) ? f.helpText : null,
      isDense: true,
    );
    switch (f.fieldType) {
      case EnquiryFieldType.dropdown:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: DropdownButtonFormField<String>(
            initialValue: _customValues[f.fieldKey] as String?,
            decoration: dec,
            isExpanded: true,
            items: f.options
                .map((o) => DropdownMenuItem(value: o, child: Text(o, overflow: TextOverflow.ellipsis)))
                .toList(),
            onChanged: (v) => setState(() => _customValues[f.fieldKey] = v),
          ),
        );
      case EnquiryFieldType.date:
        final raw = _customValues[f.fieldKey] as String?;
        final shown = raw != null ? DateFormat('dd MMM yyyy').format(DateTime.parse(raw)) : 'Tap to set';
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
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
            child: InputDecorator(decoration: dec, child: Text(shown)),
          ),
        );
      case EnquiryFieldType.number:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: TextFormField(
            initialValue: _customValues[f.fieldKey]?.toString(),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: dec,
            onChanged: (v) => _customValues[f.fieldKey] = num.tryParse(v.trim()) ?? v.trim(),
          ),
        );
      case EnquiryFieldType.textarea:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: TextFormField(
            initialValue: _customValues[f.fieldKey] as String?,
            maxLines: 3,
            decoration: dec,
            onChanged: (v) => _customValues[f.fieldKey] = v,
          ),
        );
      default:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: TextFormField(
            initialValue: _customValues[f.fieldKey] as String?,
            decoration: dec,
            onChanged: (v) => _customValues[f.fieldKey] = v,
          ),
        );
    }
  }

  String _formatCustomValue(String? type, dynamic value) {
    if (type == 'date' && value is String) {
      final d = DateTime.tryParse(value);
      if (d != null) return DateFormat('dd MMM yyyy').format(d);
    }
    return value.toString();
  }

  Widget _metricsBar(Color statusColor, Color perfColor, DateFormat df) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppTheme.ink800, // Slate 800
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.emeraldGreen.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _enquiry.clientName ?? '—',
                      style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.tag, size: 14, color: Colors.white54),
                        const SizedBox(width: 4),
                        Text(
                          _enquiry.enquiryCode,
                          style: const TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _statusToString(_enquiry.finalStatus),
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(child: _metricTile('Days Open', '${_enquiry.daysOpen}', Colors.white)),
              Container(width: 1, height: 40, color: Colors.white12),
              Expanded(child: Center(child: _metricTile('Total Offered', 'SAR ${_enquiry.totalOffered.toStringAsFixed(0)}', Colors.white))),
              Container(width: 1, height: 40, color: Colors.white12),
              Expanded(child: Align(alignment: Alignment.centerRight, child: _metricTile('Performance', _perfLabel(_enquiry.performanceRating), perfColor, icon: Icons.star_rounded))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricTile(String label, String value, Color valueColor, {IconData? icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: valueColor),
              const SizedBox(width: 6),
            ],
            Text(
              value,
              style: TextStyle(color: valueColor, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
      ],
    );
  }

  Widget _sectionTitle(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 12, top: 8),
    child: Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppTheme.emeraldGreen,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(t.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14,
            color: Colors.black87, letterSpacing: 1.0)),
      ],
    ),
  );

  Widget _card(List<Widget> children) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.surfaceWhite,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey.shade200),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
  );
  }

  Widget _detailRow(String label, Widget value) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 160, 
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(label.toUpperCase(), style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
          ),
        ),
        Expanded(child: value),
      ],
    ),
  );

  Widget _dateTapRow(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(children: [
          const Icon(Icons.calendar_today_outlined, size: 16, color: AppTheme.emeraldGreen),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(color: Colors.black87, fontSize: 15))),
          const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
        ]),
      ),
    );
  }

  Widget _editField(TextEditingController ctrl, {TextInputType? keyboardType, int maxLines = 1}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: isDark ? AppTheme.darkCard : Colors.grey.shade50,
        hoverColor: Colors.grey.shade100,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.emeraldGreen, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Widget _clientStatusWidget() {
    return Row(children: [
      _statusBtn('Accepted', _enquiry.clientStatus == ClientStatus.accepted, AppTheme.statusCompleted,
          () => _updateClientStatus(ClientStatus.accepted)),
      const SizedBox(width: 8),
      _statusBtn('Rejected', _enquiry.clientStatus == ClientStatus.rejected, AppTheme.errorRed,
          () => _showRejectionDialog()),
      const SizedBox(width: 8),
      if (_enquiry.clientStatus != ClientStatus.pending)
        _statusBtn('Pending', false, Colors.grey,
            () => _updateClientStatus(ClientStatus.pending)),
    ]);
  }

  Widget _statusBtn(String label, bool active, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.12) : AppTheme.backgroundLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: active ? color : Colors.grey.shade200),
        ),
        child: Text(label,
            style: TextStyle(
                color: active ? color : Colors.grey,
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
                fontSize: 12)),
      ),
    );
  }

  Widget _finalStatusDropdown() {
    return DropdownButton<EnquiryFinalStatus>(
      value: _enquiry.finalStatus,
      underline: const SizedBox(),
      isDense: true,
      items: EnquiryFinalStatus.values.map((s) => DropdownMenuItem(
        value: s,
        child: Text(_statusToString(s), style: const TextStyle(fontSize: 14)),
      )).toList(),
      onChanged: (s) {
        if (s != null) _updateStatus(s);
      },
    );
  }

  void _showRejectionDialog() {
    String? reason;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reasons = ref.read(enquiryOptionValuesProvider(EnquiryOptionCategory.rejectionReason)).valueOrNull
        ?? kRejectionReasons;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reason for Rejection'),
        content: DropdownButtonFormField<String>(
          decoration: const InputDecoration(hintText: 'Select reason'),
          items: reasons.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
          onChanged: (v) => reason = v,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? AppTheme.primaryAccent(isDark) : AppTheme.emeraldGreen,
              foregroundColor: isDark ? AppTheme.ink900 : Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _updateClientStatus(ClientStatus.rejected, rejectionReason: reason);
            },
            child: Text('Confirm', style: TextStyle(color: isDark ? AppTheme.ink900 : Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Enquiry'),
        content: Text('Delete ${_enquiry.enquiryCode}? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(enquiryRepositoryProvider).deleteEnquiry(_enquiry.id);
              if (mounted) Navigator.pop(context, true);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
