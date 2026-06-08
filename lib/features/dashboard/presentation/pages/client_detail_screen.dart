import 'package:flutter/material.dart';
import 'package:service_manager_app/l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/contact_utils.dart';
import '../providers/dashboard_provider.dart';
import '../../domain/models/work_order.dart';
import 'task_detail_screen.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../../../core/widgets/premium_card.dart';
import '../../../../core/widgets/app_section_header.dart';
import 'package:service_manager_app/core/widgets/app_bar.dart';

class ClientDetailScreen extends ConsumerStatefulWidget {
  final String clientName;
  final String? clientPhone;

  const ClientDetailScreen({
    super.key,
    required this.clientName,
    this.clientPhone,
  });

  @override
  ConsumerState<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends ConsumerState<ClientDetailScreen> {
  
  Future<void> _callNumber(String? number) async {
    await ContactUtils.callNumber(number);
  }

  Future<void> _openWhatsApp(String? number) async {
    await ContactUtils.openWhatsApp(number);
  }

  @override
  Widget build(BuildContext context) {
    final workOrdersAsync = ref.watch(allWorkOrdersProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: WorkqlyAppBar(title: l10n.clientDetails),
      body: RefreshIndicator(
        color: const Color(0xFF0D1B2E),
        onRefresh: () async {
          ref.invalidate(allWorkOrdersProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ResponsiveLayout(
          maxWidth: 1000,
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSectionHeader(title: l10n.contactInfo),
                    const SizedBox(height: 8),
                    _buildInfoCard(l10n),
                    const SizedBox(height: 24),
                    
                    AppSectionHeader(title: l10n.projectHistory),
                    const SizedBox(height: 8),
                    _buildPaginatedWorkHistory(context, l10n),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      color: Colors.white,
      child: Column(
        children: [
          Hero(
            tag: 'client_${widget.clientName}',
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.emeraldLight.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, size: 40, color: AppTheme.emeraldGreen),
            ),
          ),
          const SizedBox(height: 15),
          Text(
            widget.clientName,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.darkBlue),
          ),
          if (widget.clientPhone != null) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _callNumber(widget.clientPhone),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.phone_outlined, size: 16, color: AppTheme.emeraldGreen),
                  const SizedBox(width: 5),
                  Text(
                    widget.clientPhone!,
                    style: const TextStyle(fontSize: 14, color: AppTheme.emeraldGreen, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    onPressed: () => _openWhatsApp(widget.clientPhone),
                    icon: const Icon(Icons.message, size: 16, color: Colors.green),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard(AppLocalizations l10n) {
    return PremiumCard(
      child: Column(
        children: [
          _buildDetailRow(Icons.person_outline, l10n.clientName, widget.clientName, l10n),
          if (widget.clientPhone != null) ...[
            const Divider(height: 30),
            _buildDetailRow(
              Icons.phone_outlined, 
              l10n.phoneNumber, 
              widget.clientPhone!, 
              l10n,
              onCall: () => _callNumber(widget.clientPhone),
              onWhatsApp: () => _openWhatsApp(widget.clientPhone),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, AppLocalizations l10n, {VoidCallback? onCall, VoidCallback? onWhatsApp}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.grey.shade50, shape: BoxShape.circle),
          child: Icon(icon, size: 18, color: Colors.grey),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        if (onWhatsApp != null)
           IconButton(
             onPressed: onWhatsApp,
             icon: const Icon(Icons.message, size: 18, color: Colors.green),
             tooltip: l10n.whatsapp,
           ),
        if (onCall != null)
           IconButton(
             onPressed: onCall,
             icon: const Icon(Icons.phone_outlined, size: 18, color: AppTheme.emeraldGreen),
             tooltip: l10n.call,
           ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(paginatedClientWorkOrdersProvider(widget.clientName).notifier).fetchFirstPage();
    });
  }

  Widget _buildPaginatedWorkHistory(BuildContext context, AppLocalizations l10n) {
    final state = ref.watch(paginatedClientWorkOrdersProvider(widget.clientName));
    
    if (state.isLoading) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(20.0),
        child: CircularProgressIndicator(),
      ));
    }

    if (state.error != null && state.items.isEmpty) {
      return Center(child: Text('${l10n.error}: ${state.error}'));
    }

    final orders = state.items;

    if (orders.isEmpty) {
      return PremiumCard(
        child: Center(child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Text(l10n.noWorkHistory, style: const TextStyle(color: Colors.grey)),
        )),
      );
    }

    return Column(
      children: [
        PremiumCard(
          padding: EdgeInsets.zero,
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: orders.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final order = orders[index];
              return ListTile(
                onTap: () {
                   Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => TaskDetailScreen(
                        taskId: order.id,
                        clientName: order.clientName ?? 'Unknown',
                        clientPhone: order.clientPhoneNumber,
                        priority: order.priority.name,
                        initialStatus: order.status.name,
                      )),
                    );
                },
                shape: index == 0 
                  ? const RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)))
                  : index == orders.length - 1
                    ? const RoundedRectangleBorder(borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)))
                    : null,
                title: Text(order.serviceType ?? l10n.generalService, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text('${l10n.status}: ${order.status.name.toUpperCase()}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                trailing: const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
              );
            },
          ),
        ),
        if (state.hasMore)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: state.isFetchingMore 
              ? const CircularProgressIndicator()
              : TextButton(
                  onPressed: () {
                    ref.read(paginatedClientWorkOrdersProvider(widget.clientName).notifier).fetchNextPage();
                  },
                  child: const Text('Load More'),
                ),
          ),
      ],
    );
  }
}
