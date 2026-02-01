import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/contact_utils.dart';
import '../providers/dashboard_provider.dart';
import '../../domain/models/work_order.dart';
import 'profile_view.dart';
import '../../../../core/providers/locale_provider.dart';
import 'assignment_sheet.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../../attendance/presentation/widgets/attendance_monitor.dart';

class AdminView extends ConsumerStatefulWidget {
  const AdminView({super.key});

  @override
  ConsumerState<AdminView> createState() => _AdminViewState();
}

class _AdminViewState extends ConsumerState<AdminView> {
  String _statusFilter = 'All';
  String? _staffFilter;

  void _showLanguagePicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Language / اختر اللغة',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.darkBlue),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.language, color: AppTheme.emeraldGreen),
                title: const Text('English'),
                trailing: ref.watch(localeProvider).languageCode == 'en' ? const Icon(Icons.check, color: AppTheme.emeraldGreen) : null,
                onTap: () {
                  ref.read(localeProvider.notifier).state = const Locale('en');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.language, color: AppTheme.emeraldGreen),
                title: const Text('العربية'),
                trailing: ref.watch(localeProvider).languageCode == 'ar' ? const Icon(Icons.check, color: AppTheme.emeraldGreen) : null,
                onTap: () {
                  ref.read(localeProvider.notifier).state = const Locale('ar');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final workOrdersAsync = ref.watch(allWorkOrdersProvider);
    final staffAsync = ref.watch(staffProfilesProvider);
    final currentLocale = ref.watch(localeProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Operations Tracking'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.darkBlue,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _showLanguagePicker(context, ref),
            icon: const Icon(Icons.translate),
          ),
          IconButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                builder: (context) => Scaffold(
                  appBar: AppBar(
                    title: const Text('Staff Attendance'),
                    leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ),
                  body: const AttendanceMonitor(),
                ),
              );
            },
            icon: const Icon(Icons.how_to_reg_outlined),
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileView()),
              );
            },
            icon: const CircleAvatar(
              radius: 14,
              backgroundColor: AppTheme.emeraldLight,
              child: Icon(Icons.person, size: 18, color: AppTheme.emeraldGreen),
            ),
          ),
          IconButton(
            onPressed: () => ref.invalidate(allWorkOrdersProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ResponsiveLayout(
        maxWidth: 1000,
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            // Filters row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                   _buildFilterChip('All', _statusFilter == 'All', (v) => setState(() => _statusFilter = 'All')),
                   _buildFilterChip('Pending', _statusFilter == 'Pending', (v) => setState(() => _statusFilter = 'Pending')),
                   _buildFilterChip('In-Progress', _statusFilter == 'In-Progress', (v) => setState(() => _statusFilter = 'In-Progress')),
                   _buildFilterChip('Completed', _statusFilter == 'Completed', (v) => setState(() => _statusFilter = 'Completed')),
                   const VerticalDivider(),
                   staffAsync.when(
                     data: (staff) => DropdownButton<String>(
                       hint: const Text('All Staff', style: TextStyle(fontSize: 12)),
                       value: _staffFilter,
                       underline: const SizedBox(),
                       items: [
                         const DropdownMenuItem(value: null, child: Text('Show All Staff')),
                         ...staff.map((s) => DropdownMenuItem(value: s['id'], child: Text(s['name'] ?? 'Unknown'))),
                       ],
                       onChanged: (v) => setState(() => _staffFilter = v),
                     ),
                     loading: () => const SizedBox(),
                     error: (_, __) => const SizedBox(),
                   ),
                ],
              ),
            ),
            Expanded(
              child: workOrdersAsync.when(
                data: (orders) {
                  var filtered = orders;
                  if (_statusFilter != 'All') {
                    filtered = filtered.where((o) => o.status.name.toLowerCase() == _statusFilter.toLowerCase().replaceAll('-', '')).toList();
                  }
                  if (_staffFilter != null) {
                    filtered = filtered.where((o) => o.assignedStaffId == _staffFilter).toList();
                  }
  
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildSectionHeader('Live Operations Feed'),
                      const SizedBox(height: 12),
                      if (filtered.isEmpty)
                        const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('No matching work orders.')))
                      else
                        ...filtered.map((order) => _buildWorkOrderCard(order)),
                      
                      const SizedBox(height: 24),
                      _buildSectionHeader('Recent Staff Activity'),
                      const SizedBox(height: 12),
                      _buildStaffActivityLog('Ahmed updated "Iqama Renewal" status to In-Progress', '2 mins ago', Colors.blue),
                      _buildStaffActivityLog('Saeed uploaded a document for "New Work Visa"', '15 mins ago', AppTheme.emeraldGreen),
                      _buildStaffActivityLog('Khalid checked in at Olaya Office', '1 hour ago', AppTheme.accentGold),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAssignmentModal(context, ref),
        backgroundColor: AppTheme.emeraldGreen,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.assignment_add, color: Colors.white, size: 24),
        label: const Text(
          'Assign Work', 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5)
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, Function(bool) onSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.black87)),
        selected: isSelected,
        onSelected: onSelected,
        selectedColor: AppTheme.emeraldGreen,
        backgroundColor: Colors.white,
        checkmarkColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.shade300)),
      ),
    );
  }

  void _showAssignmentModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => const AssignmentSheet(),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.grey),
    );
  }

  Widget _buildWorkOrderCard(WorkOrder order) {
    Color statusColor;
    switch (order.status) {
      case WorkStatus.completed: statusColor = AppTheme.emeraldGreen; break;
      case WorkStatus.inProgress: statusColor = Colors.blue; break;
      default: statusColor = order.priority == PriorityLevel.high ? AppTheme.errorRed : AppTheme.accentGold;
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(order.serviceType ?? 'General Service', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(order.status.name.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(order.clientName ?? "N/A", style: const TextStyle(fontSize: 13)),
                if (order.clientPhoneNumber != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.phone_outlined, size: 16, color: AppTheme.emeraldGreen),
                    onPressed: () => ContactUtils.callNumber(order.clientPhoneNumber),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.message, size: 16, color: Colors.green),
                    onPressed: () => ContactUtils.openWhatsApp(order.clientPhoneNumber),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                ],
                const Spacer(),
                if (order.priority == PriorityLevel.high)
                  const Icon(Icons.flash_on, size: 14, color: AppTheme.errorRed),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                const Icon(Icons.assignment_ind_outlined, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  order.assignedStaffName != null 
                    ? 'Staff: ${order.assignedStaffName}${order.assignedOfficeName != null ? ' (${order.assignedOfficeName})' : ''}' 
                    : (order.assignedOfficeName != null ? 'Office: ${order.assignedOfficeName}' : 'Unassigned'),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffActivityLog(String text, String time, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(margin: const EdgeInsets.only(top: 4), width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: const TextStyle(fontSize: 13)),
                Text(time, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
