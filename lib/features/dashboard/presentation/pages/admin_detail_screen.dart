import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/dashboard_provider.dart';
import '../../domain/models/work_order.dart';
import 'task_detail_screen.dart';
import 'client_detail_screen.dart';
import '../../../../core/widgets/responsive_layout.dart';

class AdminDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> admin;

  const AdminDetailScreen({super.key, required this.admin});

  @override
  ConsumerState<AdminDetailScreen> createState() => _AdminDetailScreenState();
}

class _AdminDetailScreenState extends ConsumerState<AdminDetailScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late String _role;
  String? _officeId;
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.admin['name'] ?? '');
    _emailController = TextEditingController(text: widget.admin['email'] ?? '');
    _phoneController = TextEditingController(text: widget.admin['phone_number'] ?? '');
    _role = widget.admin['role'] ?? 'admin';
    _officeId = widget.admin['office_id'];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    try {
      final repo = ref.read(profileRepositoryProvider);
      await repo.updateProfile(widget.admin['id'], {
        'name': _nameController.text,
        'email': _emailController.text,
        'phone_number': _phoneController.text,
        'role': _role,
        'office_id': _officeId,
      });
      
      ref.invalidate(allProfilesProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully'), backgroundColor: AppTheme.emeraldGreen),
        );
        setState(() => _isEditing = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isStaff = _role == 'staff';
    final performanceAsync = ref.watch(staffWorkOrdersProvider(widget.admin['id']));

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppTheme.darkBlue),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isStaff ? 'Staff Details' : 'Admin Details',
          style: const TextStyle(color: AppTheme.darkBlue, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.emeraldGreen),
            onPressed: () {
              ref.refresh(staffWorkOrdersProvider(widget.admin['id']));
              ref.invalidate(allProfilesProvider);
            },
          ),
          if (!_isEditing)
            IconButton(
              onPressed: () => setState(() => _isEditing = true),
              icon: const Icon(Icons.edit_outlined, color: AppTheme.darkBlue),
            ),
          if (_isEditing)
            IconButton(
              onPressed: _isSaving ? null : _saveChanges,
              icon: _isSaving 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.check, color: AppTheme.emeraldGreen),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: ResponsiveLayout(
          maxWidth: 1000,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('PROFESSIONAL PROFILE'),
                    const SizedBox(height: 12),
                    _buildProfileCard(),
                    const SizedBox(height: 24),
                    
                    if (isStaff) ...[
                      _buildSectionHeader('PERFORMANCE METRICS'),
                      const SizedBox(height: 12),
                      performanceAsync.when(
                        data: (orders) => _buildStatsRow(orders),
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => _buildStatsRow([]),
                      ),
                      const SizedBox(height: 24),
                      
                      _buildSectionHeader('WORK HISTORY / تاريخ العمل'),
                      const SizedBox(height: 12),
                      _buildWorkHistorySection(ref),
                      const SizedBox(height: 24),

                      _buildSectionHeader('CLIENT LIST / قائمة العملاء'),
                      const SizedBox(height: 12),
                      _buildClientListSection(ref),
                      const SizedBox(height: 24),
                    ],

                    _buildSectionHeader('ACCESS & PERMISSIONS'),
                    const SizedBox(height: 12),
                    _buildPermissionsCard(),
                    const SizedBox(height: 30),
                    
                    if (_isEditing)
                       ElevatedButton.icon(
                        onPressed: () async {
                          final isActive = widget.admin['is_active'] ?? true;
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(isActive ? 'Deactivate User' : 'Reactivate User'),
                              content: Text('Are you sure you want to ${isActive ? 'deactivate' : 'reactivate'} ${_nameController.text}?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true), 
                                  style: TextButton.styleFrom(foregroundColor: isActive ? Colors.red : AppTheme.emeraldGreen), 
                                  child: Text(isActive ? 'Deactivate' : 'Reactivate')
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            if (isActive) {
                              await ref.read(profileRepositoryProvider).deleteProfile(widget.admin['id']);
                            } else {
                              await ref.read(profileRepositoryProvider).reactivateProfile(widget.admin['id']);
                            }
                            ref.invalidate(allProfilesProvider);
                            if (mounted) Navigator.pop(context);
                          }
                        },
                        icon: Icon((widget.admin['is_active'] ?? true) ? Icons.person_remove_outlined : Icons.person_add_alt_1_outlined),
                        label: Text((widget.admin['is_active'] ?? true) ? 'Deactivate Account' : 'Reactivate Account'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: (widget.admin['is_active'] ?? true) ? Colors.red.shade50 : AppTheme.emeraldLight,
                          foregroundColor: (widget.admin['is_active'] ?? true) ? Colors.red : AppTheme.emeraldGreen,
                          elevation: 0,
                          minimumSize: const Size(double.infinity, 55),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.emeraldGreen, width: 2),
                ),
                child: const CircleAvatar(
                  radius: 50,
                  backgroundColor: AppTheme.emeraldLight,
                  child: Icon(Icons.person, size: 60, color: AppTheme.emeraldGreen),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: AppTheme.emeraldGreen, shape: BoxShape.circle),
                  child: const Icon(Icons.verified, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            _nameController.text,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.darkBlue),
          ),
          Text(
            _role.toUpperCase().replaceAll('_', ' '),
            style: const TextStyle(fontSize: 14, color: AppTheme.emeraldGreen, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Column(
        children: [
          _buildDetailRow(
            Icons.person_outline, 
            'Full Name', 
            _isEditing 
                ? TextField(controller: _nameController, decoration: const InputDecoration(isDense: true, border: InputBorder.none))
                : Text(_nameController.text, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          const Divider(height: 30),
          _buildDetailRow(
            Icons.email_outlined, 
            'Email Address', 
            _isEditing 
                ? TextField(controller: _emailController, decoration: const InputDecoration(isDense: true, border: InputBorder.none))
                : Text(_emailController.text, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          const Divider(height: 30),
          _buildDetailRow(
            Icons.phone_outlined, 
            'Phone Number', 
            _isEditing 
                ? TextField(controller: _phoneController, decoration: const InputDecoration(isDense: true, border: InputBorder.none))
                : Text(_phoneController.text.isEmpty ? 'N/A' : _phoneController.text, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          if (!_isEditing) ...[
            const Divider(height: 30),
            _buildDetailRow(
              Icons.calendar_today_outlined, 
              'Joined Date', 
              Text(widget.admin['created_at'] != null ? widget.admin['created_at'].substring(0, 10) : 'N/A', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ],
      ),
    );
  }

  bool _biometricAuth = true;

  Widget _buildPermissionsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Column(
        children: [
          _buildDetailRow(
            Icons.security_outlined, 
            'Portal Role', 
            _isEditing 
                ? DropdownButton<String>(
                    value: _role,
                    isDense: true,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'staff', child: Text('Staff')),
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                      DropdownMenuItem(value: 'super_admin', child: Text('Super Admin')),
                    ],
                    onChanged: (v) => setState(() => _role = v!),
                  )
                : Text(_role.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.emeraldGreen)),
          ),
          const Divider(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Biometric Auth', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('Enhanced security for login', style: TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
              Switch(
                value: _biometricAuth, 
                onChanged: (v) => setState(() => _biometricAuth = v), 
                activeColor: AppTheme.emeraldGreen
              ),
            ],
          ),
          const Divider(height: 30),
          _buildDetailRow(
            Icons.business_outlined, 
            'Assigned Office', 
            _isEditing 
                ? ref.watch(officesProvider).when(
                    data: (offices) => DropdownButton<String?>(
                      value: _officeId,
                      isDense: true,
                      underline: const SizedBox(),
                      hint: const Text('Select Office'),
                      items: [
                        const DropdownMenuItem<String?>(value: null, child: Text('No Office')),
                        ...offices.map((o) => DropdownMenuItem<String?>(
                          value: o['id'],
                          child: Text(o['name'] ?? 'Unknown'),
                        )),
                      ],
                      onChanged: (v) => setState(() => _officeId = v),
                    ),
                    loading: () => const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                    error: (_, __) => const Text('Error loading offices'),
                  )
                : Text(
                    ref.watch(officesProvider).maybeWhen(
                      data: (offices) {
                        if (_officeId == null) return 'Not Assigned';
                        final office = offices.firstWhere((o) => o['id'] == _officeId, orElse: () => {});
                        return office['name'] ?? 'Not Assigned';
                      },
                      orElse: () => widget.admin['offices']?['name'] ?? 'Not Assigned',
                    ),
                    style: const TextStyle(fontWeight: FontWeight.bold)
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(List<WorkOrder> orders) {
    final completedCount = orders.where((o) => o.status == WorkStatus.completed).length;
    final totalCount = orders.length;
    final efficiency = totalCount == 0 ? 0 : (completedCount / totalCount * 100).toInt();

    return Row(
      children: [
        Expanded(child: _buildSmallStat('Tasks Done', completedCount.toString(), Icons.check_circle_outline, Colors.blue)),
        const SizedBox(width: 15),
        Expanded(child: _buildSmallStat('Efficiency', '$efficiency%', Icons.speed, Colors.orange)),
      ],
    );
  }

  Widget _buildSmallStat(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, Widget valueWidget) {
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
              valueWidget,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWorkHistorySection(WidgetRef ref) {
    final workOrdersAsync = ref.watch(staffWorkOrdersProvider(widget.admin['id']));

    return workOrdersAsync.when(
      data: (orders) {
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
                        priority: order.priority.name,
                        initialStatus: order.status.name,
                      ),
                    ),
                  );
                },
                title: Text(order.serviceType ?? 'General Service', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text(order.clientName ?? 'Unknown Client', style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
    final workOrdersAsync = ref.watch(staffWorkOrdersProvider(widget.admin['id']));

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
}
