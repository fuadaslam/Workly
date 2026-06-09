import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/contact_utils.dart';
import '../../../../core/widgets/app_bar.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../providers/dashboard_provider.dart';
import '../../domain/models/work_order.dart';
import 'task_detail_screen.dart';

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

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
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
                        Icon(Icons.assignment_outlined, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(
                          _searchQuery.isNotEmpty ? 'No results for "$_searchQuery"' : 'No active cases',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
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
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: ResponsiveLayout(
        maxWidth: 900,
        child: Column(
          children: [
            TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search client, service, staff…',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
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
                fillColor: AppTheme.backgroundLight,
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
                      selectedColor: AppTheme.emeraldGreen.withValues(alpha: 0.15),
                      checkmarkColor: AppTheme.emeraldGreen,
                      labelStyle: TextStyle(
                        color: isSelected ? AppTheme.emeraldGreen : Colors.grey.shade700,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                      side: BorderSide(color: isSelected ? AppTheme.emeraldGreen : Colors.grey.shade300),
                      backgroundColor: Colors.white,
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
    final isInProgress = order.status == WorkStatus.inProgress;
    final isHighPriority = order.priority == PriorityLevel.high;
    final statusColor = isInProgress ? Colors.blue : AppTheme.accentGold;
    final df = DateFormat('dd MMM yyyy');

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isHighPriority ? AppTheme.errorRed.withValues(alpha: 0.3) : Colors.grey.shade200,
          width: isHighPriority ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TaskDetailScreen(
              taskId: order.id,
              clientName: order.clientName ?? 'Unknown',
              clientPhone: order.clientPhoneNumber,
              priority: order.priority.name,
              initialStatus: order.status == WorkStatus.inProgress ? 'In-Progress' : 'Pending',
            ),
          ),
        ).then((_) => ref.invalidate(activeWorkOrdersProvider)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order.serviceType ?? 'General Service',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.darkBlue),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isInProgress ? 'IN PROGRESS' : 'PENDING',
                      style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (isHighPriority) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.flash_on, size: 16, color: AppTheme.errorRed),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      order.clientName ?? 'N/A',
                      style: const TextStyle(fontSize: 13, color: AppTheme.darkBlue),
                    ),
                  ),
                  if (order.clientPhoneNumber != null) ...[
                    IconButton(
                      icon: const Icon(Icons.phone_outlined, size: 16, color: AppTheme.emeraldGreen),
                      onPressed: () => ContactUtils.callNumber(order.clientPhoneNumber),
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(Icons.message, size: 16, color: Colors.green),
                      onPressed: () => ContactUtils.openWhatsApp(order.clientPhoneNumber),
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ],
              ),
              if (order.nationality != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.flag_outlined, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(order.nationality!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ],
              const Divider(height: 16),
              Row(
                children: [
                  const Icon(Icons.assignment_ind_outlined, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      order.assignedStaffName != null
                          ? '${order.assignedStaffName}${order.assignedOfficeName != null ? ' · ${order.assignedOfficeName}' : ''}'
                          : 'Unassigned',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (order.createdAt != null)
                    Text(
                      df.format(order.createdAt!),
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
