import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:service_manager_app/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/dashboard_provider.dart';
import '../../domain/models/work_order.dart';
import 'task_detail_screen.dart';
import 'client_detail_screen.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../../../core/widgets/premium_card.dart';
import '../../../../core/widgets/app_section_header.dart';
import 'package:service_manager_app/core/widgets/app_bar.dart';

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
    final l10n = AppLocalizations.of(context)!;
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
          SnackBar(content: Text(l10n.profileUpdated), backgroundColor: AppTheme.emeraldGreen),
        );
        setState(() => _isEditing = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.errorUpdatingProfile}: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isStaff = _role == 'staff';
    final performanceAsync = ref.watch(staffWorkOrdersProvider(widget.admin['id']));

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: WorkqlyAppBar(
        title: isStaff ? l10n.staffDetails : l10n.adminDetails,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.invalidate(staffWorkOrdersProvider(widget.admin['id']));
              ref.invalidate(allProfilesProvider);
            },
          ),
          if (!_isEditing)
            IconButton(
              onPressed: () => setState(() => _isEditing = true),
              icon: const Icon(Icons.edit_outlined),
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
      body: RefreshIndicator(
        color: const Color(0xFF0D1B2E),
        onRefresh: () async {
          ref.invalidate(staffWorkOrdersProvider(widget.admin['id']));
          ref.invalidate(allProfilesProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ResponsiveLayout(
          maxWidth: 1000,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSectionHeader(title: l10n.professionalProfile),
                    const SizedBox(height: 8),
                    _buildProfileCard(),
                    const SizedBox(height: 24),
                    
                    if (isStaff) ...[
                      AppSectionHeader(title: l10n.performanceMetrics),
                      const SizedBox(height: 8),
                      performanceAsync.when(
                        data: (orders) => _buildStatsRow(orders),
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => _buildStatsRow([]),
                      ),
                      const SizedBox(height: 24),
                      
                      AppSectionHeader(title: l10n.officeWorkHistory),
                      const SizedBox(height: 8),
                      _buildWorkHistorySection(ref),
                      const SizedBox(height: 24),

                      AppSectionHeader(title: l10n.officeClients),
                      const SizedBox(height: 8),
                      _buildClientListSection(ref),
                      const SizedBox(height: 24),
                    ],

                    AppSectionHeader(title: l10n.accessPermissions),
                    const SizedBox(height: 8),
                    _buildPermissionsCard(),
                    const SizedBox(height: 30),
                    
                    if (_isEditing)
                       ElevatedButton.icon(
                        onPressed: () async {
                          final isActive = widget.admin['is_active'] ?? true;
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(isActive ? l10n.deactivateUser : l10n.reactivateUser),
                              content: Text(isActive 
                                ? l10n.confirmDeactivate(_nameController.text) 
                                : l10n.confirmReactivate(_nameController.text)),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true), 
                                  style: TextButton.styleFrom(foregroundColor: isActive ? Colors.red : AppTheme.emeraldGreen), 
                                  child: Text(isActive ? l10n.delete : l10n.success) // Reusing existing strings or should use labels
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
                            if (!context.mounted) return;
                            Navigator.pop(context);
                          }
                        },
                        icon: Icon((widget.admin['is_active'] ?? true) ? Icons.person_remove_outlined : Icons.person_add_alt_1_outlined),
                        label: Text((widget.admin['is_active'] ?? true) ? l10n.deactivateAccount : l10n.reactivateAccount),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: (widget.admin['is_active'] ?? true) ? Colors.red.shade50 : AppTheme.emeraldLight,
                          foregroundColor: (widget.admin['is_active'] ?? true) ? Colors.red : AppTheme.emeraldGreen,
                          elevation: 0,
                          minimumSize: const Size(double.infinity, 55),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                      ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
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
      padding: const EdgeInsets.symmetric(vertical: 30),
      color: Colors.white,
      child: Column(
        children: [
          Hero(
            tag: 'admin_${widget.admin['id']}',
            child: Stack(
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
    final l10n = AppLocalizations.of(context)!;
    return PremiumCard(
      child: Column(
        children: [
          _buildDetailRow(
            Icons.person_outline, 
            l10n.fullName, 
            _isEditing 
                ? TextField(controller: _nameController, decoration: const InputDecoration(isDense: true, border: InputBorder.none))
                : Text(_nameController.text, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          const Divider(height: 30),
          _buildDetailRow(
            Icons.email_outlined, 
            l10n.email, 
            _isEditing 
                ? TextField(controller: _emailController, decoration: const InputDecoration(isDense: true, border: InputBorder.none))
                : Text(_emailController.text, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          const Divider(height: 30),
          _buildDetailRow(
            Icons.phone_outlined, 
            l10n.phoneNumber, 
            _isEditing 
                ? TextField(controller: _phoneController, decoration: const InputDecoration(isDense: true, border: InputBorder.none))
                : Text(_phoneController.text.isEmpty ? 'N/A' : _phoneController.text, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          if (!_isEditing) ...[
            const Divider(height: 30),
            _buildDetailRow(
              Icons.calendar_today_outlined, 
              l10n.joinedDate, 
              Text(widget.admin['created_at'] != null ? widget.admin['created_at'].substring(0, 10) : 'N/A', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ],
      ),
    );
  }

  bool _biometricAuth = true;

  Widget _buildPermissionsCard() {
    final l10n = AppLocalizations.of(context)!;
    return PremiumCard(
      child: Column(
        children: [
          _buildDetailRow(
            Icons.security_outlined, 
            l10n.portalRole, 
            _isEditing 
                ? DropdownButton<String>(
                    value: _role,
                    isDense: true,
                    underline: const SizedBox(),
                    items: [
                      DropdownMenuItem(value: 'staff', child: Text(l10n.staff)),
                      const DropdownMenuItem(value: 'admin', child: Text('Admin')),
                      DropdownMenuItem(value: 'super_admin', child: Text(l10n.superAdmin)),
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
                children: [
                  Text(l10n.biometricAuth, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(l10n.enhancedSecurity, style: const TextStyle(fontSize: 11, color: Colors.grey)),
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
            l10n.assignedOffice, 
            _isEditing 
                ? ref.watch(officesProvider).when(
                    data: (offices) => DropdownButton<String?>(
                      value: _officeId,
                      isDense: true,
                      underline: const SizedBox(),
                      hint: Text(l10n.noOffice),
                      items: [
                        DropdownMenuItem<String?>(value: null, child: Text(l10n.noOffice)),
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
                        if (_officeId == null) return l10n.notAssigned;
                        final office = offices.firstWhere((o) => o['id'] == _officeId, orElse: () => {});
                        return office['name'] ?? l10n.notAssigned;
                      },
                      orElse: () => widget.admin['offices']?['name'] ?? l10n.notAssigned,
                    ),
                    style: const TextStyle(fontWeight: FontWeight.bold)
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(List<WorkOrder> orders) {
    final l10n = AppLocalizations.of(context)!;
    final completedCount = orders.where((o) => o.status == WorkStatus.completed).length;
    final totalCount = orders.length;
    final efficiencyValue = totalCount == 0 ? 0 : (completedCount / totalCount * 100).toInt();

    return Row(
      children: [
        Expanded(child: _buildSmallStat(l10n.tasksDone, completedCount.toString(), Icons.check_circle_outline, Colors.blue)),
        const SizedBox(width: 15),
        Expanded(child: _buildSmallStat(l10n.efficiency, '$efficiencyValue%', Icons.speed, Colors.orange)),
      ],
    );
  }

  Widget _buildSmallStat(String label, String value, IconData icon, Color color) {
    return PremiumCard(
      padding: const EdgeInsets.all(15),
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
    final l10n = AppLocalizations.of(context)!;
    final workOrdersAsync = ref.watch(staffWorkOrdersProvider(widget.admin['id']));

    return workOrdersAsync.when(
      data: (orders) {
        if (orders.isEmpty) {
          return Center(child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(l10n.noWorkHistory, style: const TextStyle(color: Colors.grey)),
          ));
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
                        priority: order.priority.name,
                        initialStatus: order.status.name,
                      ),
                    ),
                  );
                },
                title: Text(order.serviceType ?? l10n.generalService, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
      error: (e, _) => Text('${l10n.error}: $e'),
    );
  }

  Widget _buildClientListSection(WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
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
          return Center(child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(l10n.noClientsFound, style: const TextStyle(color: Colors.grey)),
          ));
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
}
