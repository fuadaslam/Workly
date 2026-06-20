import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_bar.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../../../core/router/app_router.dart';
import '../providers/dashboard_provider.dart';
import '../../domain/models/work_order.dart';
import '../../../../core/widgets/workly_primitives.dart';

class ActiveCasesScreen extends ConsumerStatefulWidget {
  const ActiveCasesScreen({super.key});

  @override
  ConsumerState<ActiveCasesScreen> createState() => _ActiveCasesScreenState();
}

class _ActiveCasesScreenState extends ConsumerState<ActiveCasesScreen> {
  String _statusFilter = 'All';
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(activeWorkOrdersProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.backgroundLight,
      appBar: WorkqlyAppBar(
        title: 'Active Cases',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(activeWorkOrdersProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(
            child: ordersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.emeraldGreen)),
              error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: AppTheme.errorRed))),
              data: (orders) {
                final filtered = _applyFilters(orders);
                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.assignment_outlined, size: 64, color: isDark ? AppTheme.darkSubtext : Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(
                          _searchQuery.isNotEmpty ? 'No results for "$_searchQuery"' : 'No active cases',
                          style: TextStyle(color: isDark ? AppTheme.darkSubtext : Colors.grey.shade500, fontSize: 15),
                        ),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  color: AppTheme.emeraldGreen,
                  onRefresh: () async => ref.invalidate(activeWorkOrdersProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => _buildCaseCard(filtered[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AppTheme.primaryAccent(isDark);
    return Container(
      color: isDark ? AppTheme.darkSurface : Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: ResponsiveLayout(
        maxWidth: double.infinity,
        child: Column(
          children: [
            TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search client, service, staff…',
                prefixIcon: Icon(Icons.search, color: isDark ? AppTheme.darkSubtext : Colors.grey),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? AppTheme.darkCard : AppTheme.backgroundLight,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'Pending', 'In-Progress', 'High Priority'].map((f) {
                  final isSelected = _statusFilter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(f),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _statusFilter = f),
                      selectedColor: accent.withValues(alpha: isDark ? 0.18 : 0.12),
                      checkmarkColor: accent,
                      labelStyle: TextStyle(
                        color: isSelected ? accent : (isDark ? AppTheme.darkSubtext : Colors.grey.shade700),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                      side: BorderSide(color: isSelected ? accent : (isDark ? AppTheme.darkBorder : Colors.grey.shade300)),
                      backgroundColor: isDark ? AppTheme.darkCardAlt : Colors.white,
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  List<WorkOrder> _applyFilters(List<WorkOrder> orders) {
    var result = orders;

    if (_statusFilter == 'Pending') {
      result = result.where((o) => o.status == WorkStatus.pending).toList();
    } else if (_statusFilter == 'In-Progress') {
      result = result.where((o) => o.status == WorkStatus.inProgress).toList();
    } else if (_statusFilter == 'High Priority') {
      result = result.where((o) => o.priority == PriorityLevel.high).toList();
    }

    if (_searchQuery.isNotEmpty) {
      result = result.where((o) =>
        (o.clientName?.toLowerCase().contains(_searchQuery) ?? false) ||
        (o.serviceType?.toLowerCase().contains(_searchQuery) ?? false) ||
        (o.assignedStaffName?.toLowerCase().contains(_searchQuery) ?? false) ||
        (o.nationality?.toLowerCase().contains(_searchQuery) ?? false),
      ).toList();
    }

    return result;
  }

  Widget _buildCaseCard(WorkOrder order) {
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
              initialStatus: order.status == WorkStatus.inProgress ? 'In-Progress' : 'Pending',
            ),
          ).then((_) => ref.invalidate(activeWorkOrdersProvider));
        },
      ),
    );
  }
}
