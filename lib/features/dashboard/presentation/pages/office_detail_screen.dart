import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/contact_utils.dart';
import '../providers/dashboard_provider.dart';
import '../../domain/models/work_order.dart';
import 'admin_detail_screen.dart';
import 'task_detail_screen.dart';
import 'client_detail_screen.dart';
import '../../../../core/widgets/responsive_layout.dart';

class OfficeDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> office;

  const OfficeDetailScreen({super.key, required this.office});

  @override
  ConsumerState<OfficeDetailScreen> createState() => _OfficeDetailScreenState();
}

class _OfficeDetailScreenState extends ConsumerState<OfficeDetailScreen> {
  late TextEditingController _nameController;
  late TextEditingController _locationController;
  late TextEditingController _managerController;
  late TextEditingController _managerPhoneController;
  late TextEditingController _mobilePhoneController;
  late TextEditingController _landlinePhoneController;
  bool _isEditing = false;
  bool _isLoading = false;

  Future<void> _callNumber(String? number) async {
    await ContactUtils.callNumber(number);
  }

  Future<void> _openWhatsApp(String? number) async {
    await ContactUtils.openWhatsApp(number);
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.office['name']);
    _locationController = TextEditingController(text: widget.office['location']);
    _managerController = TextEditingController(text: widget.office['manager_name']);
    _managerPhoneController = TextEditingController(text: widget.office['manager_phone']);
    
    final phoneNumbers = widget.office['phone_numbers'] as List? ?? [];
    String mobile = '';
    String landline = '';
    for (var p in phoneNumbers) {
      if (p['type'] == 'mobile') mobile = p['number'] ?? '';
      if (p['type'] == 'landline') landline = p['number'] ?? '';
    }
    _mobilePhoneController = TextEditingController(text: mobile);
    _landlinePhoneController = TextEditingController(text: landline);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _managerController.dispose();
    _managerPhoneController.dispose();
    _mobilePhoneController.dispose();
    _landlinePhoneController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(officeRepositoryProvider).updateOffice(widget.office['id'], {
        'name': _nameController.text,
        'location': _locationController.text,
        'manager_name': _managerController.text,
        'manager_phone': _managerPhoneController.text,
        'phone_numbers': [
          if (_mobilePhoneController.text.isNotEmpty) {'number': _mobilePhoneController.text, 'type': 'mobile'},
          if (_landlinePhoneController.text.isNotEmpty) {'number': _landlinePhoneController.text, 'type': 'landline'},
        ],
      });
      // Refresh the list in the background
      ref.refresh(officesProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Office updated successfully'), backgroundColor: AppTheme.emeraldGreen),
        );
        setState(() => _isEditing = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating office: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteOffice() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Office'),
        content: const Text('Are you sure you want to delete this office?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete')
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await ref.read(officeRepositoryProvider).deleteOffice(widget.office['id']);
        ref.refresh(officesProvider);
        if (mounted) {
          Navigator.pop(context); // Go back
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting office: $e'), backgroundColor: Colors.red),
          );
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine dynamic color or default
    final hexColor = widget.office['color_hex'] as String? ?? '#10B981';
    final color = _getColorFromHex(hexColor);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Office Details', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.emeraldGreen),
            onPressed: () {
              ref.refresh(officesProvider);
              ref.refresh(staffProfilesProvider);
              ref.refresh(allWorkOrdersProvider);
            },
          ),
          if (!_isEditing)
            IconButton(
              onPressed: () => setState(() => _isEditing = true),
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit Office',
            ),
          if (_isEditing)
             IconButton(
              onPressed: _saveChanges,
              icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.check, color: AppTheme.emeraldGreen),
              tooltip: 'Save Changes',
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: ResponsiveLayout(
          maxWidth: 1000,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _buildHeader(color),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                     _buildInfoCard(),
                    const SizedBox(height: 20),
                     _buildStatsSection(),
                     const SizedBox(height: 20),
                     const SizedBox(height: 20),
                     _buildStaffSection(context, ref),
                     const SizedBox(height: 24),

                     _buildSectionHeader('OFFICE WORK HISTORY / تاريخ عمل المكتب'),
                     const SizedBox(height: 12),
                     _buildWorkHistorySection(ref),
                     const SizedBox(height: 24),

                     _buildSectionHeader('OFFICE CLIENTS / عملاء المكتب'),
                     const SizedBox(height: 12),
                     _buildClientListSection(ref),
                     const SizedBox(height: 24),

                     if (_isEditing) 
                       ElevatedButton.icon(
                         onPressed: _deleteOffice,
                         icon: const Icon(Icons.delete_outline, size: 18),
                         label: const Text('Delete Office'),
                         style: ElevatedButton.styleFrom(
                           backgroundColor: Colors.red.shade50,
                           foregroundColor: Colors.red,
                           elevation: 0,
                           minimumSize: const Size(double.infinity, 50),
                         ),
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

  Widget _buildHeader(Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Column(
        children: [
           Container(
             padding: const EdgeInsets.all(20),
             decoration: BoxDecoration(
               color: color.withOpacity(0.1),
               shape: BoxShape.circle,
             ),
             child: Icon(Icons.business, size: 40, color: color),
           ),
           const SizedBox(height: 15),
           Text(
             _isEditing ? 'Editing ${_nameController.text}' : widget.office['name'],
             style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.darkBlue),
           ),
           Text(
             widget.office['location'],
             style: const TextStyle(fontSize: 14, color: Colors.grey),
           ),
           if (widget.office['phone_numbers'] != null && (widget.office['phone_numbers'] as List).isNotEmpty) ...[
             const SizedBox(height: 8),
             InkWell(
               onTap: () {
                  final numbers = widget.office['phone_numbers'] as List;
                  if (numbers.isNotEmpty) _callNumber(numbers[0]['number']);
               },
               child: Row(
                 mainAxisSize: MainAxisSize.min,
                 children: [
                   const Icon(Icons.phone_outlined, size: 14, color: AppTheme.emeraldGreen),
                   const SizedBox(width: 5),
                   Text(
                     (widget.office['phone_numbers'] as List)[0]['number'],
                     style: const TextStyle(fontSize: 13, color: AppTheme.emeraldGreen, fontWeight: FontWeight.w600),
                   ),
                   const SizedBox(width: 8),
                   IconButton(
                     onPressed: () => _openWhatsApp((widget.office['phone_numbers'] as List)[0]['number']),
                     icon: const Icon(Icons.message, size: 14, color: Colors.green),
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          if (_isEditing) ...[
             const Text('EDIT DETAILS', style: TextStyle( fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
             const SizedBox(height: 15),
             TextField(
               controller: _nameController,
               decoration: InputDecoration(
                 labelText: 'Office Name',
                 prefixIcon: const Icon(Icons.business_outlined),
                 filled: true,
                 fillColor: Colors.grey.shade50,
                 border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
               ),
             ),
             const SizedBox(height: 10),
             TextField(
               controller: _locationController,
               decoration: InputDecoration(
                 labelText: 'Location',
                 prefixIcon: const Icon(Icons.location_on_outlined),
                 filled: true,
                 fillColor: Colors.grey.shade50,
                 border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
               ),
             ),
             const SizedBox(height: 10),
             TextField(
               controller: _managerController,
               decoration: InputDecoration(
                 labelText: 'Manager Name',
                 prefixIcon: const Icon(Icons.person_outline),
                 filled: true,
                 fillColor: Colors.grey.shade50,
                 border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
               ),
             ),
             const SizedBox(height: 10),
             TextField(
               controller: _managerPhoneController,
               decoration: InputDecoration(
                 labelText: 'Manager Phone',
                 prefixIcon: const Icon(Icons.phone_iphone),
                 filled: true,
                 fillColor: Colors.grey.shade50,
                 border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
               ),
             ),
             const SizedBox(height: 10),
             TextField(
               controller: _mobilePhoneController,
               decoration: InputDecoration(
                 labelText: 'Office Mobile',
                 prefixIcon: const Icon(Icons.smartphone),
                 filled: true,
                 fillColor: Colors.grey.shade50,
                 border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
               ),
             ),
             const SizedBox(height: 10),
             TextField(
               controller: _landlinePhoneController,
               decoration: InputDecoration(
                 labelText: 'Office Landline',
                 prefixIcon: const Icon(Icons.phone),
                 filled: true,
                 fillColor: Colors.grey.shade50,
                 border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
               ),
             ),
          ] else ...[
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 const Text('OFFICE DETAILS', style: TextStyle( fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                 if (widget.office['manager_name'] != null)
                   InkWell(
                     onTap: () => _callNumber(widget.office['manager_phone']),
                     child: Chip(
                       avatar: const Icon(Icons.person, size: 14), 
                       label: Row(
                         mainAxisSize: MainAxisSize.min,
                         children: [
                           Text(widget.office['manager_name'], style: const TextStyle(fontSize: 11)),
                           if (widget.office['manager_phone'] != null && widget.office['manager_phone'].toString().isNotEmpty) ...[
                             const SizedBox(width: 5),
                             const Icon(Icons.phone, size: 12, color: AppTheme.emeraldGreen),
                           ],
                         ],
                       ),
                       backgroundColor: AppTheme.emeraldLight.withOpacity(0.5),
                       side: BorderSide.none,
                     ),
                   ),
                   if (widget.office['manager_phone'] != null && widget.office['manager_phone'].toString().isNotEmpty)
                     IconButton(
                       onPressed: () => _openWhatsApp(widget.office['manager_phone']),
                       icon: const Icon(Icons.message, size: 16, color: Colors.green),
                       padding: const EdgeInsets.symmetric(horizontal: 4),
                       constraints: const BoxConstraints(),
                     ),
               ],
             ),
             const SizedBox(height: 15),
             _buildDetailRow(Icons.location_on, 'Location', widget.office['location']),
             if (widget.office['manager_phone'] != null && widget.office['manager_phone'].toString().isNotEmpty) ...[
               const Divider(height: 30),
               _buildDetailRow(
                 Icons.phone_iphone, 
                 'Manager Phone', 
                 widget.office['manager_phone'], 
                 onCall: () => _callNumber(widget.office['manager_phone']),
                 onWhatsApp: () => _openWhatsApp(widget.office['manager_phone']),
               ),
             ],
             if (widget.office['phone_numbers'] != null) ...[
               for (var p in (widget.office['phone_numbers'] as List))
                  if (p['number'] != null && p['number'].toString().isNotEmpty) ...[
                    const Divider(height: 30),
                    _buildDetailRow(
                      p['type'] == 'mobile' ? Icons.smartphone : Icons.phone, 
                      p['type'] == 'mobile' ? 'Office Mobile' : 'Office Landline', 
                      p['number'],
                      onCall: () => _callNumber(p['number']),
                      onWhatsApp: p['type'] == 'mobile' ? () => _openWhatsApp(p['number']) : null,
                    ),
                  ],
             ],
             const Divider(height: 30),
             _buildDetailRow(Icons.calendar_today, 'Created At', widget.office['created_at'] != null ? widget.office['created_at'].substring(0, 10) : 'N/A'),
          ],
        ],
      ),
    );
  }
  
  Widget _buildDetailRow(IconData icon, String label, String value, {VoidCallback? onCall, VoidCallback? onWhatsApp}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        if (onWhatsApp != null)
          IconButton(
            onPressed: onWhatsApp,
            icon: const Icon(Icons.message, size: 18, color: Colors.green),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        if (onWhatsApp != null) const SizedBox(width: 10),
        if (onCall != null)
          IconButton(
            onPressed: onCall,
            icon: const Icon(Icons.phone_outlined, size: 18, color: AppTheme.emeraldGreen),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
      ],
    );
  }

  Widget _buildStatsSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildBigStatCard('Revenue', '${(widget.office['revenue'] ?? 0)}', Colors.amber)),
            const SizedBox(width: 15),
            Expanded(child: _buildBigStatCard('Staff', '${widget.office['staff_count'] ?? 0}', Colors.blue)),
          ],
        ),
        const SizedBox(height: 15),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.emeraldGreen,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: AppTheme.emeraldGreen.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('WORKLOAD CAPACITY', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${widget.office['workload_percentage'] ?? 0}%', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                    child: const Text('Optimal', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: (widget.office['workload_percentage'] ?? 0) / 100,
                backgroundColor: Colors.black12,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBigStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
        border: Border(top: BorderSide(color: color, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
              Icon(label == 'Revenue' ? Icons.monetization_on_outlined : Icons.people_outline, color: color, size: 18),
            ],
          ),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildStaffSection(BuildContext context, WidgetRef ref) {
    final staffAsync = ref.watch(staffProfilesProvider);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('ASSIGNED STAFF', style: TextStyle( fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
              TextButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Manage Staff assignments feature coming soon')));
                },
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Assign'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          staffAsync.when(
            data: (staffList) {
               // Filter staff if 'office_id' was available. Now just showing top 3 as example
               if (staffList.isEmpty) return const Text('No staff assigned.', style: TextStyle(color: Colors.grey));
               return Column(
                 children: staffList.take(3).map((staff) {
                   return ListTile(
                     contentPadding: EdgeInsets.zero,
                     leading: CircleAvatar(
                       backgroundColor: AppTheme.emeraldLight,
                       child: Text(staff['name']?[0] ?? 'S', style: const TextStyle(color: AppTheme.emeraldGreen)),
                     ),
                     title: Text(staff['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                     subtitle: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text(staff['role']?.toString().toUpperCase() ?? 'STAFF', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                         if (staff['phone_number'] != null && staff['phone_number'].toString().isNotEmpty)
                           Text(staff['phone_number'], style: const TextStyle(fontSize: 10, color: AppTheme.emeraldGreen, fontWeight: FontWeight.bold)),
                       ],
                     ),
                     trailing: Row(
                       mainAxisSize: MainAxisSize.min,
                       children: [
                         if (staff['phone_number'] != null && staff['phone_number'].toString().isNotEmpty)
                           IconButton(
                             onPressed: () => _callNumber(staff['phone_number']),
                             icon: const Icon(Icons.phone_outlined, size: 16, color: AppTheme.emeraldGreen),
                             padding: EdgeInsets.zero,
                             constraints: const BoxConstraints(),
                           ),
                         const SizedBox(width: 8),
                         if (staff['phone_number'] != null && staff['phone_number'].toString().isNotEmpty)
                           IconButton(
                             onPressed: () => _openWhatsApp(staff['phone_number']),
                             icon: const Icon(Icons.message, size: 16, color: Colors.green),
                             padding: EdgeInsets.zero,
                             constraints: const BoxConstraints(),
                           ),
                         const SizedBox(width: 8),
                         const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                       ],
                     ),
                     onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => AdminDetailScreen(admin: staff)),
                        );
                     },
                   );
                 }).toList(),
               );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => const Text('Error loading staff'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
    );
  }

  Widget _buildWorkHistorySection(WidgetRef ref) {
    final workOrdersAsync = ref.watch(allWorkOrdersProvider);

    return workOrdersAsync.when(
      data: (orders) {
        if (orders.isEmpty) {
          return const Center(child: Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text('No work history found for this office.', style: TextStyle(color: Colors.grey)),
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
            itemCount: orders.length > 5 ? 5 : orders.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final order = orders[index];
              return ListTile(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TaskDetailScreen(
                        taskId: order.id,
                        clientName: order.clientName ?? 'Unknown',
                        clientPhone: order.clientPhoneNumber,
                        priority: order.priority.name,
                        initialStatus: order.status.name,
                      ),
                    ),
                  );
                },
                title: Text(order.serviceType ?? 'General Service', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text('By: ${order.assignedStaffId?.substring(0, 8) ?? "Unassigned"} • Client: ${order.clientName ?? "N/A"}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      order.status.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: order.status == WorkStatus.completed ? AppTheme.emeraldGreen : AppTheme.accentGold,
                      ),
                    ),
                    Text(
                      order.createdAt?.toString().substring(0, 10) ?? '',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Error: $e'),
    );
  }

  Widget _buildClientListSection(WidgetRef ref) {
    final workOrdersAsync = ref.watch(allWorkOrdersProvider);

    return workOrdersAsync.when(
      data: (orders) {
        final clients = orders
            .where((o) => o.clientName != null)
            .map((o) => {'name': o.clientName, 'phone': o.clientPhoneNumber})
            .fold<List<Map<String, String?>>>(
              [],
              (prev, element) {
                if (!prev.any((e) => e['name'] == element['name'])) {
                  prev.add(element);
                }
                return prev;
              },
            );

        if (clients.isEmpty) {
          return const Center(child: Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text('No clients found.', style: TextStyle(color: Colors.grey)),
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
            itemCount: clients.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final client = clients[index];
              return ListTile(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ClientDetailScreen(
                        clientName: client['name']!,
                        clientPhone: client['phone'],
                      ),
                    ),
                  );
                },
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.emeraldLight.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_outline, color: AppTheme.emeraldGreen, size: 20),
                ),
                title: Text(client['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text(
                  client['phone'] != null && client['phone']!.isNotEmpty ? client['phone']! : 'No phone number',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Error: $e'),
    );
  }

  Color _getColorFromHex(String? hexColor) {
    if (hexColor == null) return AppTheme.emeraldGreen;
    try {
      hexColor = hexColor.replaceAll('#', '');
      if (hexColor.length == 6) {
        hexColor = 'FF$hexColor';
      }
      return Color(int.parse(hexColor, radix: 16));
    } catch (_) {
      return AppTheme.emeraldGreen;
    }
  }
}
