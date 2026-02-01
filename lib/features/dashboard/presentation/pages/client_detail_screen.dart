import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/contact_utils.dart';
import '../providers/dashboard_provider.dart';
import '../../domain/models/work_order.dart';
import 'task_detail_screen.dart';
import '../../../../core/widgets/responsive_layout.dart';

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

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppTheme.darkBlue),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Client Details',
          style: TextStyle(color: AppTheme.darkBlue, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
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
                    _buildSectionHeader('CONTACT INFO'),
                    const SizedBox(height: 12),
                    _buildInfoCard(),
                    const SizedBox(height: 24),
                    
                    _buildSectionHeader('PROJECT HISTORY / سجل المشاريع'),
                    const SizedBox(height: 12),
                    workOrdersAsync.when(
                      data: (orders) {
                        final clientOrders = orders.where((o) => o.clientName == widget.clientName).toList();
                        return _buildWorkHistoryList(clientOrders);
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Text('Error: $e'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      color: Colors.white,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.emeraldLight.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, size: 40, color: AppTheme.emeraldGreen),
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

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Column(
        children: [
          _buildDetailRow(Icons.person_outline, 'Client Name', widget.clientName),
          if (widget.clientPhone != null) ...[
            const Divider(height: 30),
            _buildDetailRow(
              Icons.phone_outlined, 
              'Phone Number', 
              widget.clientPhone!, 
              onCall: () => _callNumber(widget.clientPhone),
              onWhatsApp: () => _openWhatsApp(widget.clientPhone),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {VoidCallback? onCall, VoidCallback? onWhatsApp}) {
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
           ),
        if (onCall != null)
           IconButton(
             onPressed: onCall,
             icon: const Icon(Icons.phone_outlined, size: 18, color: AppTheme.emeraldGreen),
           ),
      ],
    );
  }

  Widget _buildWorkHistoryList(List<WorkOrder> orders) {
    if (orders.isEmpty) {
      return const Center(child: Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Text('No work history found.', style: TextStyle(color: Colors.grey)),
      ));
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
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
            title: Text(order.serviceType ?? 'General Service', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text('Status: ${order.status.name.toUpperCase()}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
            trailing: const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
          );
        },
      ),
    );
  }
}
