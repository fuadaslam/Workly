import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/dashboard_provider.dart';
import 'package:service_manager_app/l10n/generated/app_localizations.dart';
import 'package:service_manager_app/features/enquiries/domain/models/enquiry.dart';

class AssignmentSheet extends ConsumerStatefulWidget {
  const AssignmentSheet({super.key});

  @override
  ConsumerState<AssignmentSheet> createState() => _AssignmentSheetState();
}

class _AssignmentSheetState extends ConsumerState<AssignmentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _clientController = TextEditingController();
  final _phoneController = TextEditingController();

  String? _selectedStaffId;
  String? _selectedServiceType;
  String? _selectedNationality;
  String _priority = 'Medium';
  bool _isLoading = false;

  @override
  void dispose() {
    _clientController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final staffAsync = ref.watch(staffProfilesProvider);

      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(l10n.assignNewTask, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.darkBlue)),
                        IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Client Info Section
                    _buildSectionTitle(l10n.contactInfo),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _clientController,
                      decoration: InputDecoration(
                        labelText: l10n.clientName,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                      validator: (v) => v == null || v.isEmpty ? l10n.required : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: l10n.phoneNumber,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.phone_outlined),
                      ),
                      validator: (v) => v == null || v.isEmpty ? l10n.required : null,
                    ),
                    const SizedBox(height: 24),

                    // Task Info Section
                    _buildSectionTitle(l10n.taskDetails),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedServiceType,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Nature of Enquiry',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.work_outline),
                      ),
                      items: kNatureOfEnquiry
                          .map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedServiceType = v),
                      validator: (v) => v == null ? 'Required' : null,
                      hint: const Text('Select nature of enquiry'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedNationality,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Nationality',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.flag_outlined),
                      ),
                      items: kNationalities
                          .map((n) => DropdownMenuItem(value: n, child: Text(n)))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedNationality = v),
                      hint: const Text('Select nationality'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _priority,
                      decoration: InputDecoration(
                        labelText: l10n.priorityLevel,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.flag_outlined),
                      ),
                      items: [
                        DropdownMenuItem(value: 'High', child: Text(l10n.highUrgent)),
                        DropdownMenuItem(value: 'Medium', child: Text(l10n.medium)),
                        DropdownMenuItem(value: 'Low', child: Text(l10n.low)),
                      ],
                      onChanged: (v) => setState(() => _priority = v!),
                    ),
                    const SizedBox(height: 24),

                    // Assignment Target Section
                    _buildSectionTitle(l10n.assign),
                    const SizedBox(height: 12),
                    
                    staffAsync.when(
                      data: (staff) => DropdownButtonFormField<String>(
                        value: _selectedStaffId,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: l10n.selectStaffMember,
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.badge_outlined),
                        ),
                        items: staff.map((s) {
                          final officeName = s['offices'] != null ? s['offices']['name'] : l10n.noOffice;
                          return DropdownMenuItem(
                            value: s['id'] as String,
                            child: Text(
                              '${s['name'] ?? s['email'] ?? 'Unknown'} ($officeName)',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => _selectedStaffId = v),
                        validator: (v) => v == null ? l10n.pleaseSelectStaff : null,
                      ),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (_, __) => Text(l10n.errorLoadingStaff),
                    ),

                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitAssignment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.emeraldGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: _isLoading 
                          ? const CircularProgressIndicator(color: Colors.white) 
                          : Text(l10n.confirmCreateAssignment, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.1),
    );
  }

  void _submitAssignment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    try {
      final repository = ref.read(workOrderRepositoryProvider);
      await repository.createWorkOrder(
        clientName: _clientController.text.trim(),
        clientPhoneNumber: _phoneController.text.trim(),
        serviceType: _selectedServiceType,
        nationality: _selectedNationality,
        priority: _priority,
        assignedStaffId: _selectedStaffId,
        assignedOfficeId: null,
      );
      
        if (mounted) {
          // Invalidate providers to refresh UI
          ref.invalidate(allWorkOrdersProvider);
          
          final l10n = AppLocalizations.of(context)!;
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.taskAssignedSuccessfully),
              backgroundColor: AppTheme.emeraldGreen,
            ),
          );
        }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.errorCreatingAssignment}: $e'), backgroundColor: AppTheme.errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
