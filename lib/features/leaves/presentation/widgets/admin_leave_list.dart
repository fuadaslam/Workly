
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/leave_request.dart';
import '../providers/leave_provider.dart';

class AdminLeaveList extends ConsumerStatefulWidget {
  const AdminLeaveList({super.key});

  @override
  ConsumerState<AdminLeaveList> createState() => _AdminLeaveListState();
}

class _AdminLeaveListState extends ConsumerState<AdminLeaveList> {
  String _statusFilter = 'All';

  @override
  Widget build(BuildContext context) {
    var state = ref.watch(adminLeaveProvider);
    
    final requests = state.requests.where((r) {
      if (_statusFilter == 'All') return true;
      return r.status.name.toLowerCase() == _statusFilter.toLowerCase();
    }).toList();

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _buildFilterChip('All', _statusFilter == 'All'),
              _buildFilterChip('Pending', _statusFilter == 'Pending'),
              _buildFilterChip('Approved', _statusFilter == 'Approved'),
              _buildFilterChip('Rejected', _statusFilter == 'Rejected'),
            ],
          ),
        ),
        Expanded(
          child: state.isLoading 
            ? const Center(child: CircularProgressIndicator())
            : requests.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.event_busy, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text('No matching records found', 
                        style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: const Color(0xFF0D1B2E),
                  onRefresh: () => ref.read(adminLeaveProvider.notifier).loadAllLeaves(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: requests.length,
                    itemBuilder: (context, index) {
                      final request = requests[index];
                      return _LeaveRequestCard(request: request);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.black87)),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _statusFilter = label;
          });
        },
        selectedColor: AppTheme.emeraldGreen,
        backgroundColor: Colors.white,
        checkmarkColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.shade300)),
      ),
    );
  }
}

class _LeaveRequestCard extends ConsumerWidget {
  final LeaveRequest request;

  const _LeaveRequestCard({required this.request});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: AppTheme.emeraldLight,
                  child: Icon(Icons.person, color: AppTheme.emeraldGreen),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(request.userName ?? 'Unknown Staff / موظف غير معروف', 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('${request.type.name.toUpperCase()} LEAVE / إجازة ${request.type.name}', 
                        style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                _StatusBadge(status: request.status),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  '${DateFormat('dd MMM yyyy').format(request.startDate)} - ${DateFormat('dd MMM yyyy').format(request.endDate)}',
                  style: const TextStyle(fontSize: 14),
                ),
                const Spacer(),
                const Icon(Icons.timer_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text('${request.durationDays} days / أيام', style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            if (request.reason.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Reason / السبب:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(
                      request.reason,
                      style: TextStyle(color: Colors.grey[800], fontSize: 13, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ],
            if (request.status == LeaveStatus.pending) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _updateStatus(context, ref, LeaveStatus.rejected),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.errorRed,
                        side: const BorderSide(color: AppTheme.errorRed),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Reject / رفض', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateStatus(context, ref, LeaveStatus.approved),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.emeraldGreen,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                      ),
                      child: const Text('Approve / موافقة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _updateStatus(BuildContext context, WidgetRef ref, LeaveStatus status) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(status == LeaveStatus.approved ? 'Approve Leave? / الموافقة على الإجازة؟' : 'Reject Leave? / رفض الإجازة؟'),
        content: Text(status == LeaveStatus.approved 
          ? 'Are you sure you want to approve this leave request? / هل أنت متأكد من الموافقة على طلب الإجازة هذا؟' 
          : 'Are you sure you want to reject this leave request? / هل أنت متأكد من رفض طلب الإجازة هذا؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel / إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: status == LeaveStatus.approved ? AppTheme.emeraldGreen : AppTheme.errorRed),
            child: Text(status == LeaveStatus.approved ? 'Approve / موافقة' : 'Reject / رفض'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(adminLeaveProvider.notifier).updateStatus(request.id, status);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Leave request ${status.name}'),
          backgroundColor: status == LeaveStatus.approved ? AppTheme.emeraldGreen : AppTheme.errorRed,
        ));
      }
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final LeaveStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;

    switch (status) {
      case LeaveStatus.approved:
        color = AppTheme.emeraldGreen;
        text = 'APPROVED';
        break;
      case LeaveStatus.rejected:
        color = AppTheme.errorRed;
        text = 'REJECTED';
        break;
      case LeaveStatus.pending:
        color = AppTheme.accentGold;
        text = 'PENDING';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
