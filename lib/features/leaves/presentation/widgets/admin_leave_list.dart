
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/workly_primitives.dart';
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
                  color: AppTheme.ink900,
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
    return WorklyFilterChip(
      label: label,
      selected: isSelected,
      onTap: () => setState(() => _statusFilter = label),
    );
  }
}

class _LeaveRequestCard extends ConsumerWidget {
  final LeaveRequest request;

  const _LeaveRequestCard({required this.request});

  Color _accentColor() {
    switch (request.status) {
      case LeaveStatus.approved: return AppTheme.mintGreen;
      case LeaveStatus.rejected: return AppTheme.errorRed;
      case LeaveStatus.pending: return AppTheme.mutedAmber;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = _accentColor();
    final cardBg = isDark ? AppTheme.darkCard : Colors.white;
    final cardBorder = isDark ? AppTheme.darkBorder : const Color(0xFFE9EEF5);
    final titleColor = isDark ? AppTheme.darkOnSurface : AppTheme.darkBlue;
    final metaColor = isDark ? AppTheme.darkSubtext : Colors.grey.shade600;
    final dateBg = isDark ? AppTheme.darkCardAlt : AppTheme.backgroundLight;
    final reasonBg = isDark ? AppTheme.darkCardAlt : Colors.grey.shade50;
    final reasonBorder = isDark ? AppTheme.darkBorder : Colors.grey.shade200;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Colored top accent strip
            Container(height: 3, color: accent),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.10),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.person_outline, color: accent, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              request.userName ?? 'Unknown Staff / موظف غير معروف',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: titleColor),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${request.type.name.toUpperCase()} LEAVE',
                              style: TextStyle(color: metaColor, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.4),
                            ),
                          ],
                        ),
                      ),
                      _StatusBadge(status: request.status),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: dateBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_outlined, size: 14, color: metaColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${DateFormat('dd MMM yyyy').format(request.startDate)} – ${DateFormat('dd MMM yyyy').format(request.endDate)}',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: titleColor),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.timelapse_outlined, size: 12, color: accent),
                            const SizedBox(width: 4),
                            Text('${request.durationDays} days / أيام',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: accent)),
                          ]),
                        ),
                      ],
                    ),
                  ),
                  if (request.reason.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: reasonBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: reasonBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('REASON',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: metaColor, letterSpacing: 0.8)),
                          const SizedBox(height: 4),
                          Text(
                            request.reason,
                            style: TextStyle(color: titleColor, fontSize: 13, height: 1.4),
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
                              side: BorderSide(color: AppTheme.errorRed.withValues(alpha: 0.5)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Reject', style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _updateStatus(context, ref, LeaveStatus.approved),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.mintGreen,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: 0,
                            ),
                            child: const Text('Approve',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
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
        color = AppTheme.mintGreen;
        text = 'Approved';
        break;
      case LeaveStatus.rejected:
        color = AppTheme.errorRed;
        text = 'Rejected';
        break;
      case LeaveStatus.pending:
        color = AppTheme.mutedAmber;
        text = 'Pending';
        break;
    }

    return WorklyStatusBadge(label: text, color: color);
  }
}
