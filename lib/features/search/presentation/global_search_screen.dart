import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/dashboard/presentation/providers/dashboard_provider.dart';
import '../../../features/enquiries/presentation/providers/enquiry_provider.dart';
import '../../../features/enquiries/presentation/pages/enquiry_detail_screen.dart';
import '../../../features/dashboard/presentation/pages/task_detail_screen.dart';

class GlobalSearchScreen extends ConsumerStatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  ConsumerState<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends ConsumerState<GlobalSearchScreen> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceWhite,
        foregroundColor: AppTheme.emeraldGreen,
        elevation: 0,
        titleSpacing: 0,
        title: TextField(
          controller: _ctrl,
          focusNode: _focus,
          decoration: InputDecoration(
            hintText: 'Search clients, services, enquiries...',
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () { _ctrl.clear(); setState(() => _query = ''); },
                  )
                : null,
          ),
          onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
        ),
      ),
      body: _query.length < 2
          ? _placeholder()
          : _results(),
    );
  }

  Widget _placeholder() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.search_rounded, size: 64, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text('Type at least 2 characters to search',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
      ]),
    );
  }

  Widget _results() {
    final workOrdersAsync = ref.watch(allWorkOrdersProvider);
    final enquiriesAsync = ref.watch(allEnquiriesProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Work Orders
        workOrdersAsync.when(
          loading: () => const LinearProgressIndicator(color: AppTheme.emeraldGreen),
          error: (_, __) => const SizedBox(),
          data: (orders) {
            final filtered = orders.where((o) {
              final name = (o.clientName ?? '').toLowerCase();
              final service = (o.serviceType ?? '').toLowerCase();
              final phone = (o.clientPhoneNumber ?? '').toLowerCase();
              return name.contains(_query) || service.contains(_query) || phone.contains(_query);
            }).take(10).toList();
            if (filtered.isEmpty) return const SizedBox();
            return _section('Work Orders', filtered.map((o) => _workOrderTile(o)).toList());
          },
        ),
        const SizedBox(height: 8),
        // Enquiries
        enquiriesAsync.when(
          loading: () => const SizedBox(),
          error: (_, __) => const SizedBox(),
          data: (enquiries) {
            final filtered = enquiries.where((e) {
              final name = (e.clientName ?? '').toLowerCase();
              final code = e.enquiryCode.toLowerCase();
              final service = (e.natureOfEnquiry ?? '').toLowerCase();
              final phone = (e.contactNumber ?? '').toLowerCase();
              return name.contains(_query) || code.contains(_query) ||
                  service.contains(_query) || phone.contains(_query);
            }).take(10).toList();
            if (filtered.isEmpty) return const SizedBox();
            return _section('Enquiries', filtered.map((e) => _enquiryTile(e)).toList());
          },
        ),
      ],
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(title.toUpperCase(),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                  color: Colors.grey, letterSpacing: 1)),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceWhite,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
          ),
          child: Column(children: children),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _workOrderTile(dynamic o) {
    final statusColor = o.status.name == 'completed' ? Colors.green
        : o.status.name == 'inProgress' ? Colors.orange
        : Colors.grey;
    return ListTile(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => TaskDetailScreen(
          taskId: o.id,
          clientName: o.clientName ?? '—',
          clientPhone: o.clientPhoneNumber,
          priority: o.priority.name,
          initialStatus: o.status.name,
        ),
      )),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(color: AppTheme.backgroundLight, shape: BoxShape.circle),
        child: const Icon(Icons.assignment_outlined, size: 18, color: AppTheme.emeraldGreen),
      ),
      title: Text(o.clientName ?? '—', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(o.serviceType ?? '—', style: const TextStyle(fontSize: 12)),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(o.status.name, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _enquiryTile(dynamic e) {
    return ListTile(
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(
          builder: (_) => EnquiryDetailScreen(enquiry: e),
        ));
        ref.invalidate(allEnquiriesProvider);
      },
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(color: AppTheme.backgroundLight, shape: BoxShape.circle),
        child: const Icon(Icons.track_changes_outlined, size: 18, color: AppTheme.emeraldGreen),
      ),
      title: Text(e.clientName ?? '—', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text('${e.enquiryCode} · ${e.natureOfEnquiry ?? '—'}',
          style: const TextStyle(fontSize: 12)),
      trailing: e.contactNumber != null
          ? Text(e.contactNumber!, style: const TextStyle(fontSize: 11, color: Colors.grey))
          : null,
    );
  }
}
