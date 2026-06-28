import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/router/app_router.dart' show TaskRouteArgs;
import '../../../../core/widgets/workly_primitives.dart';
import '../../domain/models/work_order.dart';
import '../providers/dashboard_provider.dart';

/// Admin "Works" tab — lists all work orders with assigned staff, office,
/// status and price. Tapping opens the work detail screen.
class WorksManagementTab extends ConsumerStatefulWidget {
  const WorksManagementTab({super.key});

  @override
  ConsumerState<WorksManagementTab> createState() => _WorksManagementTabState();
}

class _WorksManagementTabState extends ConsumerState<WorksManagementTab> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String? _status; // null = all

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<WorkOrder> _filter(List<WorkOrder> orders) {
    return orders.where((o) {
      if (_status != null) {
        final s = switch (o.status) {
          WorkStatus.pending => 'Pending',
          WorkStatus.inProgress => 'In-Progress',
          WorkStatus.completed => 'Completed',
        };
        if (s != _status) return false;
      }
      if (_query.isNotEmpty) {
        final hay = '${o.clientName ?? ''} ${o.serviceType ?? ''} '
                '${o.assignedStaffName ?? ''} ${o.assignedOfficeName ?? ''}'
            .toLowerCase();
        if (!hay.contains(_query.toLowerCase())) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final async = ref.watch(allWorkOrdersProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Work Orders',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppTheme.darkBlue)),
                    const Text('ALL JOBS',
                        style: TextStyle(fontSize: 11, color: Colors.grey, letterSpacing: 1)),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Refresh',
                onPressed: () => ref.invalidate(allWorkOrdersProvider),
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Search client, service, staff…',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: isDark ? AppTheme.darkCard : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _chip('All', null),
              _chip('Pending', 'Pending'),
              _chip('In-Progress', 'In-Progress'),
              _chip('Completed', 'Completed'),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (orders) {
              final list = _filter(orders);
              if (list.isEmpty) {
                return const Center(
                  child: Text('No work orders found', style: TextStyle(color: Colors.grey)),
                );
              }
              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(allWorkOrdersProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: list.length,
                  itemBuilder: (_, i) => _card(list[i]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _chip(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: _status == value,
        onSelected: (_) => setState(() => _status = value),
      ),
    );
  }

  Widget _card(WorkOrder o) {
    final status = switch (o.status) {
      WorkStatus.inProgress => WorqlyOrderStatus.progress,
      WorkStatus.completed => WorqlyOrderStatus.completed,
      WorkStatus.pending => WorqlyOrderStatus.pending,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: WorqlyWorkOrderCard(
        serviceType: o.serviceType ?? 'General Service',
        orderId: o.id.length > 8 ? 'WO-${o.id.substring(0, 6).toUpperCase()}' : o.id,
        clientName: o.clientName,
        staffName: o.assignedStaffName,
        officeName: o.assignedOfficeName,
        status: status,
        highPriority: o.priority == PriorityLevel.high,
        contactable: (o.clientPhoneNumber ?? '').isNotEmpty,
        actionButton: o.totalAmount != null ? _priceChip(o) : null,
        onTap: () {
          context.push(
            '/dashboard/task/${o.id}',
            extra: TaskRouteArgs(
              clientName: o.clientName ?? 'Unknown',
              clientPhone: o.clientPhoneNumber,
              priority: o.priority.name,
              initialStatus: switch (o.status) {
                WorkStatus.inProgress => 'In-Progress',
                WorkStatus.completed => 'Completed',
                WorkStatus.pending => 'Pending',
              },
            ),
          ).then((_) => ref.invalidate(allWorkOrdersProvider));
        },
      ),
    );
  }

  Widget _priceChip(WorkOrder o) {
    final total = o.totalAmount ?? 0;
    final paid = o.paidAmount ?? 0;
    final color = o.paymentStatus == 'Paid'
        ? AppTheme.mintGreen
        : (paid > 0 ? AppTheme.mutedAmber : Colors.grey);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('SAR ${total.toStringAsFixed(0)}',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: color)),
          Text(o.paymentStatus ?? (paid > 0 ? 'Advance' : 'Pending'),
              style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
