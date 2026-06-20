import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/dashboard_provider.dart';
import '../../domain/models/work_order.dart';
import 'profile_view.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/providers/locale_provider.dart';
import 'assignment_sheet.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../../attendance/presentation/widgets/attendance_monitor.dart';
import 'package:service_manager_app/core/widgets/app_bar.dart';
import '../../../../core/widgets/workly_primitives.dart';
class AdminView extends ConsumerStatefulWidget {
  const AdminView({super.key});

  @override
  ConsumerState<AdminView> createState() => _AdminViewState();
}

class _AdminViewState extends ConsumerState<AdminView> {
  String _statusFilter = 'All';
  String? _staffFilter;
  final GlobalKey<NavigatorState> _adminNavKey = GlobalKey<NavigatorState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.backgroundLight,
      endDrawer: const Drawer(width: 400, child: ProfileView()),
      body: Navigator(
        key: _adminNavKey,
        onGenerateRoute: (settings) {
          return MaterialPageRoute(
            builder: (innerContext) => _buildMainBody(innerContext, workOrdersAsync, staffAsync),
          );
        },
      ),
    );
  }

  Widget _buildMainBody(BuildContext context, AsyncValue<List<WorkOrder>> workOrdersAsync, AsyncValue<List<dynamic>> staffAsync) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: WorkqlyAppBar(
        title: 'Operations Tracking',
        automaticallyImplyLeading: false,
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
                  appBar: WorkqlyAppBar(
                    title: 'Staff Attendance',
                    leading: IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      color: AppTheme.darkBlue,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  body: const AttendanceMonitor(),
                ),
              );
            },
            icon: const Icon(Icons.how_to_reg_outlined),
          ),
          Builder(
            builder: (innerCtx) => IconButton(
              onPressed: () {
                _scaffoldKey.currentState?.openEndDrawer();
              },
              icon: const CircleAvatar(
                radius: 14,
                backgroundColor: AppTheme.emeraldLight,
                child: Icon(Icons.person, size: 18, color: AppTheme.emeraldGreen),
              ),
            ),
          ),
          IconButton(
            onPressed: () => ref.invalidate(allWorkOrdersProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ResponsiveLayout(
        maxWidth: double.infinity,
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
                         ...staff.map((s) => DropdownMenuItem(value: s['id'] as String, child: Text((s['name'] as String?) ?? 'Unknown'))),
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
                      Consumer(
                        builder: (ctx, cRef, _) {
                          return cRef.watch(recentActivityProvider).when(
                            loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.emeraldGreen)),
                            error: (_, __) => const SizedBox.shrink(),
                            data: (activities) {
                              if (activities.isEmpty) {
                                return const Text('No recent activity', style: TextStyle(color: Colors.grey, fontSize: 13));
                              }
                              return Column(
                                children: activities.map((a) {
                                  return _buildStaffActivityLog(
                                    '${a['name']} ${a['action']}',
                                    _formatActivityTime(a['time'] as String?),
                                    _getActivityColor(a['action'] as String? ?? ''),
                                  );
                                }).toList(),
                              );
                            },
                          );
                        },
                      ),
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
        backgroundColor: isDark ? AppTheme.primaryAccent(isDark) : AppTheme.emeraldGreen,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Icon(Icons.assignment_add, color: isDark ? AppTheme.ink900 : Colors.white, size: 24),
        label: Text(
          'Assign Work',
          style: TextStyle(color: isDark ? AppTheme.ink900 : Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, Function(bool) onSelected) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AppTheme.primaryAccent(isDark);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label, style: TextStyle(fontSize: 12, color: isSelected ? (isDark ? AppTheme.ink900 : Colors.white) : (isDark ? AppTheme.darkSubtext : Colors.black87))),
        selected: isSelected,
        onSelected: onSelected,
        selectedColor: accent,
        backgroundColor: isDark ? AppTheme.darkCardAlt : Colors.white,
        checkmarkColor: isDark ? AppTheme.ink900 : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isDark ? AppTheme.darkBorder : Colors.grey.shade300)),
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
    final status = switch (order.status) {
      WorkStatus.inProgress => WorqlyOrderStatus.progress,
      WorkStatus.completed => WorqlyOrderStatus.completed,
      WorkStatus.pending => WorqlyOrderStatus.pending,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: WorqlyWorkOrderCard(
        serviceType: order.serviceType ?? 'General Service',
        orderId: order.id.length > 8 ? 'WO-${order.id.substring(0, 6).toUpperCase()}' : order.id,
        clientName: order.clientName,
        staffName: order.assignedStaffName,
        officeName: order.assignedOfficeName,
        status: status,
        highPriority: order.priority == PriorityLevel.high,
        contactable: (order.clientPhoneNumber ?? '').isNotEmpty,
        onTap: () {
          context.push(
            '/dashboard/task/${order.id}',
            extra: TaskRouteArgs(
              clientName: order.clientName ?? 'Unknown',
              clientPhone: order.clientPhoneNumber,
              priority: order.priority.name,
              initialStatus: order.status.name,
            ),
          );
        },
      ),
    );
  }

  String _formatActivityTime(String? isoTime) {
    if (isoTime == null) return '';
    final dt = DateTime.tryParse(isoTime);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt.toLocal());
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mins ago';
    if (diff.inHours < 24) return '${diff.inHours} hr${diff.inHours == 1 ? '' : 's'} ago';
    return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
  }

  Color _getActivityColor(String action) {
    final lower = action.toLowerCase();
    if (lower.contains('completed')) return AppTheme.emeraldGreen;
    if (lower.contains('pending')) return AppTheme.statAmber;
    if (lower.contains('cancelled')) return AppTheme.errorRed;
    return AppTheme.statBlue;
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
