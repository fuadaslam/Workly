
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/premium_card.dart';
import '../../data/models/leave_request.dart';
import '../providers/leave_provider.dart';

class ApplyLeaveForm extends ConsumerStatefulWidget {
  final VoidCallback onSuccess;

  const ApplyLeaveForm({super.key, required this.onSuccess});

  @override
  ConsumerState<ApplyLeaveForm> createState() => _ApplyLeaveFormState();
}

class _ApplyLeaveFormState extends ConsumerState<ApplyLeaveForm> {
  final _formKey = GlobalKey<FormState>();
  LeaveType _selectedType = LeaveType.annual;
  DateTime? _startDate;
  DateTime? _endDate;
  final _reasonController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Apply for Leave / طلب إجازة', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.darkBlue, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            
            // Leave Type
            DropdownButtonFormField<LeaveType>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Leave Type / نوع الإجازة',
                prefixIcon: Icon(Icons.category, color: AppTheme.emeraldGreen),
                border: OutlineInputBorder(),
              ),
              items: LeaveType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.name.toUpperCase()),
                );
              }).toList(),
              onChanged: (v) => setState(() => _selectedType = v!),
            ),
            const SizedBox(height: 16),

            // Date Selection
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _pickDate(true),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Start Date',
                        prefixIcon: Icon(Icons.calendar_today, color: AppTheme.emeraldGreen),
                        border: OutlineInputBorder(),
                      ),
                      child: Text(_startDate == null ? 'Select' : DateFormat('dd/MM/yyyy').format(_startDate!)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => _pickDate(false),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'End Date',
                        prefixIcon: Icon(Icons.event, color: AppTheme.emeraldGreen),
                        border: OutlineInputBorder(),
                      ),
                      child: Text(_endDate == null ? 'Select' : DateFormat('dd/MM/yyyy').format(_endDate!)),
                    ),
                  ),
                ),
              ],
            ),
             const SizedBox(height: 16),

            // Reason
            TextFormField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason / السبب',
                prefixIcon: Icon(Icons.edit_note, color: AppTheme.emeraldGreen),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (val) => val == null || val.isEmpty ? 'Please enter a reason' : null,
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.emeraldGreen,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text('Submit Request', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate(bool isStart) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? (_startDate ?? now) : (_endDate ?? _startDate ?? now),
      firstDate: now,
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(picked)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_startDate == null || _endDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select dates')));
        return;
      }
      
      setState(() => _isLoading = true);

      final newRequest = LeaveRequest(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: 'current_user',
        type: _selectedType,
        startDate: _startDate!,
        endDate: _endDate!,
        reason: _reasonController.text,
        status: LeaveStatus.pending,
        requestedAt: DateTime.now(),
      );

      await ref.read(leaveProvider.notifier).submitLeaveRequest(newRequest);
      
      if (mounted) {
        setState(() => _isLoading = false);
        widget.onSuccess();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Leave Request Submitted Successfully'),
          backgroundColor: AppTheme.emeraldGreen,
        ));
      }
    }
  }
}

class UpcomingHolidaysList extends ConsumerWidget {
  const UpcomingHolidaysList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final holidays = ref.watch(upcomingHolidaysProvider);

    return PremiumCard(
      padding: const EdgeInsets.all(16.0),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             const Row(
               children: [
                 Icon(Icons.celebration, color: AppTheme.accentGold),
                 SizedBox(width: 8),
                 Text('Upcoming Holidays / العطلات القادمة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.darkBlue)),
               ],
             ),
             const SizedBox(height: 16),
             ...holidays.map((h) => Padding(
               padding: const EdgeInsets.only(bottom: 12.0),
               child: Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   Text(h.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                   Container(
                     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                     decoration: BoxDecoration(
                       color: AppTheme.accentGold.withValues(alpha: 0.1),
                       borderRadius: BorderRadius.circular(8),
                     ),
                     child: Text(DateFormat('d MMM y').format(h.date), style: const TextStyle(color: AppTheme.accentGold, fontSize: 12, fontWeight: FontWeight.bold)),
                   ),
                 ],
               ),
             )),
          ],
        ),
    );
  }
}

class LeaveHistoryList extends ConsumerWidget {
  const LeaveHistoryList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(leaveProvider);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.requests.isEmpty) {
      return Center(
        child: Column(
          children: [
            const Icon(Icons.event_busy, size: 48, color: Colors.grey),
            const SizedBox(height: 8),
            Text('No leave history', style: TextStyle(color: Colors.grey[400])),
          ],
        ),
      ); 
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: state.requests.map((request) {
        return PremiumCard(
          margin: const EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.zero,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getStatusColor(request.status).withValues(alpha: 0.1),
              child: Icon(_getTypeIcon(request.type), color: _getStatusColor(request.status), size: 20),
            ),
            title: Text('${request.type.name.toUpperCase()} LEAVE', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text('${DateFormat('d MMM').format(request.startDate)} - ${DateFormat('d MMM').format(request.endDate)} (${request.durationDays} days)', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(request.status).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                request.status.name.toUpperCase(),
                style: TextStyle(color: _getStatusColor(request.status), fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _getStatusColor(LeaveStatus status) {
    switch (status) {
      case LeaveStatus.approved: return AppTheme.emeraldGreen;
      case LeaveStatus.rejected: return AppTheme.errorRed;
      case LeaveStatus.pending: return AppTheme.accentGold;
    }
  }

  IconData _getTypeIcon(LeaveType type) {
    switch (type) {
      case LeaveType.sick: return Icons.local_hospital;
      case LeaveType.annual: return Icons.beach_access;
      default: return Icons.event;
    }
  }
}
