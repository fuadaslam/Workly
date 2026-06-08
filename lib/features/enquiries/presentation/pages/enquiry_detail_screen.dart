import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/enquiry.dart';
import '../providers/enquiry_provider.dart';

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
  late TextEditingController _officialFeeCtrl;
  late TextEditingController _serviceChargeCtrl;
  late TextEditingController _actionNotesCtrl;
  late TextEditingController _agreedChargeCtrl;
  late TextEditingController _finalNotesCtrl;

  @override
  void initState() {
    super.initState();
    _enquiry = widget.enquiry;
    _initControllers();
  }

  void _initControllers() {
    _clientNameCtrl = TextEditingController(text: _enquiry.clientName ?? '');
    _contactCtrl = TextEditingController(text: _enquiry.contactNumber ?? '');
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
    _officialFeeCtrl.dispose();
    _serviceChargeCtrl.dispose();
    _actionNotesCtrl.dispose();
    _agreedChargeCtrl.dispose();
    _finalNotesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final data = _enquiry.toJson()
        ..['client_name'] = _clientNameCtrl.text.trim()
        ..['contact_number'] = _contactCtrl.text.trim()
        ..['official_fee'] = double.tryParse(_officialFeeCtrl.text)
        ..['service_charge_offered'] = double.tryParse(_serviceChargeCtrl.text)
        ..['action_notes'] = _actionNotesCtrl.text.trim()
        ..['final_agreed_service_charge'] = double.tryParse(_agreedChargeCtrl.text)
        ..['final_notes'] = _finalNotesCtrl.text.trim();

      final updated = await ref.read(enquiryRepositoryProvider).updateEnquiry(_enquiry.id, data);
      setState(() {
        _enquiry = updated;
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
      case EnquiryFinalStatus.settled: return Colors.green;
      case EnquiryFinalStatus.inProgress: return AppTheme.accentGold;
      case EnquiryFinalStatus.postponedByClient: return Colors.orange;
      case EnquiryFinalStatus.rejectedByClient:
      case EnquiryFinalStatus.cancelled: return AppTheme.errorRed;
    }
  }

  Color _perfColor(PerformanceRating r) {
    switch (r) {
      case PerformanceRating.excellent: return Colors.green;
      case PerformanceRating.good: return Colors.teal;
      case PerformanceRating.average: return Colors.orange;
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
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(_enquiry.enquiryCode, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.surfaceWhite,
        foregroundColor: AppTheme.emeraldGreen,
        elevation: 0,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status + Metrics header
            _metricsBar(statusColor, perfColor, df),
            const SizedBox(height: 16),

            // Section 1: Client Info
            _sectionTitle('1. Enquiry Details'),
            _card([
              _detailRow('Client Name', _editing
                  ? _editField(_clientNameCtrl)
                  : Text(_enquiry.clientName ?? '—', style: const TextStyle(fontWeight: FontWeight.w600))),
              _detailRow('Contact', _editing
                  ? _editField(_contactCtrl, keyboardType: TextInputType.phone)
                  : Text(_enquiry.contactNumber ?? '—')),
              _detailRow('Service Type', Text(_enquiry.natureOfEnquiry ?? '—')),
              _detailRow('Nationality', Text(_enquiry.nationality ?? '—')),
              _detailRow('Date of Enquiry', _dateTapRow(
                  _enquiry.dateOfEnquiry != null ? df.format(_enquiry.dateOfEnquiry!) : 'Tap to set',
                  () => _pickDate(false))),
            ]),
            const SizedBox(height: 16),

            // Section 2: Pricing
            _sectionTitle('2. Pricing'),
            _card([
              _detailRow('Official Fee (SAR)', _editing
                  ? _editField(_officialFeeCtrl, keyboardType: TextInputType.number)
                  : Text('SAR ${_enquiry.officialFee?.toStringAsFixed(0) ?? "0"}')),
              _detailRow('Service Charge Offered', _editing
                  ? _editField(_serviceChargeCtrl, keyboardType: TextInputType.number)
                  : Text('SAR ${_enquiry.serviceChargeOffered?.toStringAsFixed(0) ?? "0"}')),
              const Divider(height: 20),
              _detailRow('Total Offered',
                  Text('SAR ${_enquiry.totalOffered.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.emeraldGreen))),
            ]),
            const SizedBox(height: 16),

            // Section 3: Follow Up
            _sectionTitle('2. Follow Up / Action'),
            _card([
              _detailRow('Action Notes', _editing
                  ? _editField(_actionNotesCtrl, maxLines: 3)
                  : Text(_enquiry.actionNotes ?? '—', style: const TextStyle(height: 1.5))),
              _detailRow('Follow-up Date', _dateTapRow(
                  _enquiry.followUpDate != null ? df.format(_enquiry.followUpDate!) : 'Tap to set',
                  () => _pickDate(true))),
              _detailRow('Responsible', Text(_enquiry.responsibleStaffName ?? '—')),
              // Client Accept/Reject
              _detailRow('Client Decision', _clientStatusWidget()),
              if (_enquiry.clientStatus == ClientStatus.rejected && _enquiry.rejectionReason != null)
                _detailRow('Rejection Reason', Text(_enquiry.rejectionReason!,
                    style: const TextStyle(color: AppTheme.errorRed))),
            ]),
            const SizedBox(height: 16),

            // Section 4: Settlement
            _sectionTitle('3. Settlement & Metrics'),
            _card([
              _detailRow('Final Status', _finalStatusDropdown()),
              if (_enquiry.settlementDate != null)
                _detailRow('Settlement Date', Text(df.format(_enquiry.settlementDate!))),
              _detailRow('Final Agreed Charge', _editing
                  ? _editField(_agreedChargeCtrl, keyboardType: TextInputType.number)
                  : Text(_enquiry.finalAgreedServiceCharge != null
                      ? 'SAR ${_enquiry.finalAgreedServiceCharge!.toStringAsFixed(0)}'
                      : '—',
                      style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.teal))),
              _detailRow('Final Notes', _editing
                  ? _editField(_finalNotesCtrl, maxLines: 3)
                  : Text(_enquiry.finalNotes ?? '—')),
              const Divider(height: 20),
              _detailRow('Days Open / Ageing',
                  Text('${_enquiry.daysOpen} days',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
              _detailRow('Performance',
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: perfColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.star_rounded, size: 14, color: perfColor),
                      const SizedBox(width: 4),
                      Text(_perfLabel(_enquiry.performanceRating),
                          style: TextStyle(color: perfColor, fontWeight: FontWeight.bold)),
                    ]),
                  )),
            ]),
            const SizedBox(height: 32),

            // Delete button
            Center(
              child: TextButton.icon(
                onPressed: _confirmDelete,
                icon: const Icon(Icons.delete_outline, color: AppTheme.errorRed),
                label: const Text('Delete Enquiry', style: TextStyle(color: AppTheme.errorRed)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _metricsBar(Color statusColor, Color perfColor, DateFormat df) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.emeraldGreen, AppTheme.emeraldGreen.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(_enquiry.clientName ?? '—',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor.withValues(alpha: 0.5)),
              ),
              child: Text(_statusToString(_enquiry.finalStatus),
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ]),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _metricTile('Days Open', '${_enquiry.daysOpen}', Colors.white),
              _metricTile('Total Offered', 'SAR ${_enquiry.totalOffered.toStringAsFixed(0)}', Colors.white),
              _metricTile('Performance', _perfLabel(_enquiry.performanceRating), perfColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricTile(String label, String value, Color valueColor) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
      const SizedBox(height: 2),
      Text(value, style: TextStyle(color: valueColor, fontWeight: FontWeight.bold, fontSize: 14)),
    ]);
  }

  Widget _sectionTitle(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(t, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13,
        color: AppTheme.emeraldGreen, letterSpacing: 0.5)),
  );

  Widget _card(List<Widget> children) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.surfaceWhite,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
  );

  Widget _detailRow(String label, Widget value) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 140, child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13))),
        Expanded(child: value),
      ],
    ),
  );

  Widget _dateTapRow(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.backgroundLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(children: [
          const Icon(Icons.calendar_today_outlined, size: 14, color: AppTheme.emeraldGreen),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(color: AppTheme.emeraldGreen, fontSize: 14))),
          const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
        ]),
      ),
    );
  }

  Widget _editField(TextEditingController ctrl, {TextInputType? keyboardType, int maxLines = 1}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: AppTheme.backgroundLight,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.emeraldGreen),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
    );
  }

  Widget _clientStatusWidget() {
    return Row(children: [
      _statusBtn('Accepted', _enquiry.clientStatus == ClientStatus.accepted, Colors.green,
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reason for Rejection'),
        content: DropdownButtonFormField<String>(
          decoration: const InputDecoration(hintText: 'Select reason'),
          items: kRejectionReasons.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
          onChanged: (v) => reason = v,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emeraldGreen),
            onPressed: () {
              Navigator.pop(ctx);
              _updateClientStatus(ClientStatus.rejected, rejectionReason: reason);
            },
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
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
