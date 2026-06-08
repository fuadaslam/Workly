import 'package:flutter/material.dart';
import 'package:service_manager_app/l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/contact_utils.dart';
import '../providers/dashboard_provider.dart';
import 'admin_detail_screen.dart';
import 'task_detail_screen.dart';
import 'client_detail_screen.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../../../core/widgets/premium_card.dart';
import '../../../../core/widgets/app_section_header.dart';
import 'package:service_manager_app/core/widgets/app_bar.dart';

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
      ref.invalidate(officesProvider);
      
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.officeUpdatedSuccessfully), backgroundColor: AppTheme.emeraldGreen),
        );
        setState(() => _isEditing = false);
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.errorUpdatingOffice}: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteOffice(AppLocalizations l10n) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteOffice),
        content: Text(l10n.confirmDelete),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.delete)
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await ref.read(officeRepositoryProvider).deleteOffice(widget.office['id']);
        ref.invalidate(officesProvider);
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${l10n.errorDeletingOffice}: $e'), backgroundColor: Colors.red),
          );
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hexColor = widget.office['color_hex'] as String? ?? '#0E693F';
    final color = _getColorFromHex(hexColor);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: WorkqlyAppBar(
        title: l10n.officeDetails,
        actions: [
          if (!_isEditing)
            IconButton(
              onPressed: () => setState(() => _isEditing = true),
              icon: const Icon(Icons.edit_outlined),
              tooltip: l10n.editOffice,
            ),
          if (_isEditing)
            IconButton(
              onPressed: _saveChanges,
              icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.check, color: AppTheme.emeraldGreen),
              tooltip: l10n.save,
            ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF0D1B2E),
        onRefresh: () async {
          ref.invalidate(officesProvider);
          ref.invalidate(staffProfilesProvider);
          ref.invalidate(allWorkOrdersProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ResponsiveLayout(
          maxWidth: 1000,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _buildHeader(color, l10n),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                     _buildInfoCard(l10n),
                    const SizedBox(height: 20),
                     _buildStatsSection(l10n),
                     const SizedBox(height: 20),
                     _buildStaffSection(context, ref, l10n),
                     const SizedBox(height: 24),

                     AppSectionHeader(title: l10n.officeWorkHistory),
                     const SizedBox(height: 8),
                     _buildWorkHistorySection(ref, l10n),
                     const SizedBox(height: 24),

                     AppSectionHeader(title: l10n.officeClients),
                     const SizedBox(height: 8),
                     _buildClientListSection(ref, l10n),
                     const SizedBox(height: 24),

                     if (_isEditing) 
                       ElevatedButton.icon(
                         onPressed: () => _deleteOffice(l10n),
                         icon: const Icon(Icons.delete_outline, size: 18),
                         label: Text(l10n.deleteOffice),
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
              const SizedBox(height: 40),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color color, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Column(
        children: [
           Container(
             padding: const EdgeInsets.all(20),
             decoration: BoxDecoration(
               color: color.withValues(alpha: 0.1),
               shape: BoxShape.circle,
             ),
             child: Icon(Icons.business, size: 40, color: color),
           ),
           const SizedBox(height: 15),
           Text(
             _isEditing ? _nameController.text : widget.office['name'],
             style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.darkBlue),
           ),
           Text(
             widget.office['location'],
             style: const TextStyle(fontSize: 14, color: Colors.grey),
           ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(AppLocalizations l10n) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isEditing) ...[
             TextField(
               controller: _nameController,
               decoration: InputDecoration(
                 labelText: l10n.officeName,
                 prefixIcon: const Icon(Icons.business_outlined),
               ),
             ),
             const SizedBox(height: 12),
             TextField(
               controller: _locationController,
               decoration: InputDecoration(
                 labelText: l10n.location,
                 prefixIcon: const Icon(Icons.location_on_outlined),
               ),
             ),
             const SizedBox(height: 12),
             TextField(
               controller: _managerController,
               decoration: InputDecoration(
                 labelText: l10n.managerName,
                 prefixIcon: const Icon(Icons.person_outline),
               ),
             ),
             const SizedBox(height: 12),
             TextField(
               controller: _managerPhoneController,
               decoration: InputDecoration(
                 labelText: l10n.managerPhone,
                 prefixIcon: const Icon(Icons.phone_iphone),
               ),
             ),
             const SizedBox(height: 12),
             TextField(
               controller: _mobilePhoneController,
               decoration: InputDecoration(
                 labelText: l10n.officeMobile,
                 prefixIcon: const Icon(Icons.smartphone),
               ),
             ),
             const SizedBox(height: 12),
             TextField(
               controller: _landlinePhoneController,
               decoration: InputDecoration(
                 labelText: l10n.officeLandline,
                 prefixIcon: const Icon(Icons.phone),
               ),
             ),
          ] else ...[
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 Text(l10n.contactInfo, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                 if (widget.office['manager_name'] != null)
                   Chip(
                     avatar: const Icon(Icons.person, size: 14, color: AppTheme.emeraldGreen), 
                     label: Text(widget.office['manager_name'], style: const TextStyle(fontSize: 11)),
                     backgroundColor: AppTheme.emeraldLight.withValues(alpha: 0.5),
                     side: BorderSide.none,
                   ),
               ],
             ),
             const SizedBox(height: 15),
             _buildDetailRow(Icons.location_on, l10n.location, widget.office['location']),
             if (widget.office['manager_phone'] != null && widget.office['manager_phone'].toString().isNotEmpty) ...[
               const Divider(height: 30),
               _buildDetailRow(
                 Icons.phone_iphone, 
                 l10n.managerPhone, 
                 widget.office['manager_phone'], 
                 onCall: () => ContactUtils.callNumber(widget.office['manager_phone']),
                 onWhatsApp: () => ContactUtils.openWhatsApp(widget.office['manager_phone']),
               ),
             ],
             if (widget.office['phone_numbers'] != null) ...[
               for (var p in (widget.office['phone_numbers'] as List))
                  if (p['number'] != null && p['number'].toString().isNotEmpty) ...[
                    const Divider(height: 30),
                    _buildDetailRow(
                      p['type'] == 'mobile' ? Icons.smartphone : Icons.phone, 
                      p['type'] == 'mobile' ? l10n.officeMobile : l10n.officeLandline, 
                      p['number'],
                      onCall: () => ContactUtils.callNumber(p['number']),
                      onWhatsApp: p['type'] == 'mobile' ? () => ContactUtils.openWhatsApp(p['number']) : null,
                    ),
                  ],
             ],
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

  Widget _buildStatsSection(AppLocalizations l10n) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildBigStatCard(l10n.revenue, '${(widget.office['revenue'] ?? 0)}', Colors.amber)),
            const SizedBox(width: 15),
            Expanded(child: _buildBigStatCard(l10n.staffCount, '${widget.office['staff_count'] ?? 0}', Colors.blue)),
          ],
        ),
        const SizedBox(height: 15),
        PremiumCard(
          color: AppTheme.emeraldGreen,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.workloadCapacity.toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${widget.office['workload_percentage'] ?? 0}%', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: (widget.office['workload_percentage'] ?? 0) / 100,
                backgroundColor: Colors.black12,
                color: Colors.white,
                borderRadius: BorderRadius.circular(5),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBigStatCard(String label, String value, Color color) {
    return PremiumCard(
      border: Border(top: BorderSide(color: color, width: 3)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
              Icon(label.contains('Revenue') || label.contains('الإيرادات') ? Icons.monetization_on_outlined : Icons.people_outline, color: color, size: 18),
            ],
          ),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildStaffSection(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final staffAsync = ref.watch(staffProfilesProvider);
    
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            title: l10n.assignedStaff,
            padding: EdgeInsets.zero,
            action: TextButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.manageStaffComingSoon)));
                },
                icon: const Icon(Icons.add, size: 16),
                label: Text(l10n.assign),
              ),
          ),
          const SizedBox(height: 10),
          staffAsync.when(
            data: (staffList) {
               if (staffList.isEmpty) return Text(l10n.noStaffAssigned, style: const TextStyle(color: Colors.grey));
               return Column(
                 children: staffList.take(3).map((staff) {
                   return ListTile(
                     contentPadding: EdgeInsets.zero,
                     leading: CircleAvatar(
                       backgroundColor: AppTheme.emeraldLight,
                       child: Text(staff['name']?[0] ?? 'S', style: const TextStyle(color: AppTheme.emeraldGreen, fontWeight: FontWeight.bold)),
                     ),
                     title: Text(staff['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                     subtitle: Text(staff['role']?.toString().toUpperCase() ?? l10n.staff, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                     trailing: const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
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
            error: (e, _) => Text(l10n.errorLoadingStaff),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkHistorySection(WidgetRef ref, AppLocalizations l10n) {
    final workOrdersAsync = ref.watch(allWorkOrdersProvider);

    return workOrdersAsync.when(
      data: (orders) {
        if (orders.isEmpty) {
          return PremiumCard(
            child: Center(child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(l10n.noWorkHistory, style: const TextStyle(color: Colors.grey)),
            )),
          );
        }

        return PremiumCard(
          padding: EdgeInsets.zero,
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
                title: Text(order.serviceType ?? l10n.generalService, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text('${l10n.status}: ${order.status.name.toUpperCase()}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                trailing: const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('${l10n.error}: $e'),
    );
  }

  Widget _buildClientListSection(WidgetRef ref, AppLocalizations l10n) {
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
          return PremiumCard(
            child: Center(child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(l10n.noClientsFound, style: const TextStyle(color: Colors.grey)),
            )),
          );
        }

        return PremiumCard(
          padding: EdgeInsets.zero,
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
                    color: AppTheme.emeraldLight.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_outline, color: AppTheme.emeraldGreen, size: 20),
                ),
                title: Text(client['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text(
                  client['phone'] != null && client['phone']!.isNotEmpty ? client['phone']! : l10n.noPhoneNumber,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('${l10n.error}: $e'),
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
