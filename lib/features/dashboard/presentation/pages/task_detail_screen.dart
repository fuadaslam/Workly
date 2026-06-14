import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/contact_utils.dart';
import 'package:intl/intl.dart';
import '../providers/dashboard_provider.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../../../core/widgets/premium_card.dart';
import '../../../../core/widgets/app_section_header.dart';
import 'package:service_manager_app/l10n/generated/app_localizations.dart';
import 'package:service_manager_app/core/widgets/app_bar.dart';
import 'package:service_manager_app/features/enquiries/domain/models/enquiry.dart';

class TaskDetailScreen extends ConsumerStatefulWidget {
  final String taskId;
  final String clientName;
  final String? clientPhone;
  final String priority;
  final String initialStatus;

  const TaskDetailScreen({
    super.key,
    required this.taskId,
    required this.clientName,
    this.clientPhone,
    required this.priority,
    this.initialStatus = 'Pending',
  });

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  late String _status;
  String? _finalStatus;
  String? _rejectionReason;
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _agentFeeController = TextEditingController();
  String? _selectedAgentId;
  bool _isSaving = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _status = _normalizeStatus(widget.initialStatus);
  }

  String _normalizeStatus(String s) {
    final lower = s.toLowerCase();
    if (lower == 'pending') return 'Pending';
    if (lower == 'in-progress' || lower == 'inprogress') return 'In Progress';
    if (lower == 'completed') return 'Completed';
    return 'Pending';
  }
  
  List<Map<String, dynamic>> _getDocuments(AppLocalizations l10n) => [
    {'title': l10n.passport, 'icon': Icons.book, 'color': Colors.blueGrey, 'verified': true},
    {'title': l10n.crNumber, 'icon': Icons.article, 'color': Colors.brown, 'verified': true},
    {'title': l10n.medicalReport, 'icon': Icons.monitor_heart, 'color': Colors.teal, 'verified': false},
  ];

  Future<void> _updateTask() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isSaving = true);
    try {
      final repo = ref.read(workOrderRepositoryProvider);
      String apiStatus = 'Pending';
      if (_status == 'In Progress') apiStatus = 'In-Progress';
      if (_status == 'Completed') apiStatus = 'Completed';
      
      await repo.updateWorkOrderStatus(widget.taskId, apiStatus);

      if (_finalStatus != null || _rejectionReason != null) {
        await repo.updateWorkOrderFinalStatus(
          widget.taskId,
          finalStatus: _finalStatus,
          rejectionReason: _rejectionReason,
        );
      }

      if (_selectedAgentId != null || _agentFeeController.text.isNotEmpty) {
        final fee = double.tryParse(_agentFeeController.text);
        await repo.updateWorkOrderAgent(widget.taskId, agentId: _selectedAgentId, agentFee: fee);
      }
      
      if (_notesController.text.isNotEmpty) {
        await repo.addTaskHistory(
          widget.taskId,
          'Manual Update',
          description: _notesController.text,
          status: apiStatus,
        );
      } else {
        await repo.addTaskHistory(
          widget.taskId,
          'Status Changed to $_status',
          status: apiStatus,
        );
      }
      
      ref.invalidate(myWorkOrdersProvider);
      ref.invalidate(taskHistoryProvider(widget.taskId));
      
      if (mounted) {
        _notesController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.taskUpdated(_getStatusLabel(_status, l10n)))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${l10n.error}: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
  
  void _deleteDocument(int index, AppLocalizations l10n) {
    // Mock delete logic
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.documentRemoved)));
  }

  void _addDocumentMock(AppLocalizations l10n) {
     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.scannerInitializing)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    // Initialize data once
    ref.listen(workOrderByIdProvider(widget.taskId), (previous, next) {
      if (next.hasValue && next.value != null && !_initialized) {
        final order = next.value!;
        setState(() {
          _selectedAgentId = order.agentId;
          if (order.agentFee != null) {
            _agentFeeController.text = order.agentFee!.toString();
          }
          _finalStatus = order.finalStatus;
          _rejectionReason = order.rejectionReason;
          _initialized = true;
        });
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: WorkqlyAppBar(
        titleWidget: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.taskDetails, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.darkBlue)),
            Text('#${widget.taskId.length > 8 ? widget.taskId.substring(0, 8) : widget.taskId}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
        actions: [
          _buildActionButton(Icons.phone_outlined, Colors.blue,
            () => ContactUtils.callNumber(widget.clientPhone)),
          _buildActionButton(Icons.message_outlined, Colors.green, () {
            final message = "Update on Task #${widget.taskId.substring(0, 8)}: Status is now $_status.";
            ContactUtils.openWhatsApp(widget.clientPhone, message: message);
          }),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF0D1B2E),
        onRefresh: () async {
          ref.invalidate(taskHistoryProvider(widget.taskId));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ResponsiveLayout(
            maxWidth: double.infinity,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              AppSectionHeader(title: l10n.generalInfo),
              const SizedBox(height: 8),
              _buildInfoCard(l10n),
              const SizedBox(height: 24),
              
              AppSectionHeader(
                title: l10n.documents,
                actionLabel: l10n.uploadNew,
                onActionPressed: () => _addDocumentMock(l10n),
              ),
              const SizedBox(height: 8),
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
                  return _buildDocumentsGrid(crossAxisCount, l10n);
                },
              ),
              
              const SizedBox(height: 24),
              AppSectionHeader(title: l10n.transferToAgent),
              const SizedBox(height: 8),
              _buildAgentTransferSection(l10n),

              const SizedBox(height: 24),
              AppSectionHeader(title: l10n.timeline),
              const SizedBox(height: 8),
              _buildTimeline(l10n),

              const SizedBox(height: 24),
              AppSectionHeader(title: l10n.dailyUpdateNotes),
              const SizedBox(height: 8),
              _buildNotesInput(l10n),
              
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _updateTask,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.emeraldGreen,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving 
                     ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                     : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.save, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(l10n.saveChanges, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, Color color, VoidCallback onPressed) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 20),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildInfoCard(AppLocalizations l10n) {
    return PremiumCard(
      child: Column(
        children: [
          _buildInfoRow(l10n.caseId, Text('#${widget.taskId}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.darkBlue))),
          _buildInfoRow(l10n.clientName, Text(widget.clientName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppTheme.darkBlue))),
          _buildInfoRow(l10n.priority, _buildPriorityBadge(widget.priority, l10n)),
          _buildInfoRow(l10n.status, _buildStatusDropdown(l10n)),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Divider(color: Colors.grey.shade200, height: 1),
          ),
          _buildInfoRow('Project Final Status', DropdownButtonFormField<String>(
            value: _finalStatus,
            isExpanded: true,
            decoration: InputDecoration(
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            items: kFinalStatusLabels
                .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 14))))
                .toList(),
            onChanged: (v) => setState(() => _finalStatus = v),
            hint: const Text('Select final status', style: TextStyle(fontSize: 14)),
          )),
          _buildInfoRow('Reason for Rejecting', DropdownButtonFormField<String>(
            value: _rejectionReason,
            isExpanded: true,
            decoration: InputDecoration(
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            items: kRejectionReasons
                .map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 14))))
                .toList(),
            onChanged: (v) => setState(() => _rejectionReason = v),
            hint: const Text('Select reason', style: TextStyle(fontSize: 14)),
          )),
        ],
      ),
    );
  }

  Widget _buildPriorityBadge(String priority, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.accentGold.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.accentGold.withValues(alpha: 0.5)),
      ),
      child: Text(
        _getPriorityLabel(priority, l10n),
        style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }

  Widget _buildStatusDropdown(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _status,
          isDense: true,
          items: ['Pending', 'In Progress', 'Completed'].map((e) {
            return DropdownMenuItem(
              value: e,
              child: Text(_getStatusLabel(e, l10n), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            );
          }).toList(),
          onChanged: (v) => setState(() => _status = v!),
        ),
      ),
    );
  }

  String _getPriorityLabel(String priority, AppLocalizations l10n) {
    final p = priority.toLowerCase();
    if (p == 'high') return l10n.high;
    if (p == 'medium') return l10n.medium;
    if (p == 'low') return l10n.low;
    return priority;
  }

  String _getStatusLabel(String status, AppLocalizations l10n) {
    final s = status.toLowerCase();
    if (s == 'pending') return l10n.pending;
    if (s == 'in progress') return l10n.inProgress;
    if (s == 'completed') return l10n.completed;
    return status;
  }

  Widget _buildInfoRow(String label, Widget valueWidget) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160, 
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(label.toUpperCase(), style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
            ),
          ),
          Expanded(child: valueWidget),
        ],
      ),
    );
  }

  Widget _buildDocumentsGrid(int crossAxisCount, AppLocalizations l10n) {
    final docs = _getDocuments(l10n);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final doc = docs[index];
        return GestureDetector(
          onLongPress: () => _deleteDocument(index, l10n),
          child: _buildDocItem(doc['title'], doc['icon'], doc['verified'], doc['color']),
        );
      },
    );
  }

  Widget _buildDocItem(String title, IconData icon, bool verified, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 32),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    title, 
                    style: const TextStyle(color: AppTheme.darkBlue, fontSize: 14, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          if (verified)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                child: const Icon(Icons.check, color: Colors.white, size: 14),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimeline(AppLocalizations l10n) {
    final historyAsync = ref.watch(taskHistoryProvider(widget.taskId));

    return historyAsync.when(
      data: (history) {
        if (history.isEmpty) {
          return PremiumCard(
            child: Center(
              child: Text(
                l10n.noHistoryFound,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          );
        }

        return Column(
          children: history.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isLast = index == history.length - 1;
            final isFirst = index == 0;

            String dateStr;
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            final yesterday = today.subtract(const Duration(days: 1));
            final itemDate = DateTime(item.createdAt.year, item.createdAt.month, item.createdAt.day);

            if (itemDate == today) {
              dateStr = l10n.today;
            } else if (itemDate == yesterday) {
              dateStr = l10n.yesterday;
            } else {
              dateStr = DateFormat('MMM dd, yyyy').format(item.createdAt);
            }

            return _buildTimelineItem(
              title: item.title,
              subtitle: item.description ?? '',
              date: dateStr,
              isActive: isFirst,
              isLast: isLast,
            );
          }).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('${l10n.errorLoadingHistory}: $e')),
    );
  }

  Widget _buildTimelineItem({
    required String title,
    required String subtitle,
    required String date,
    bool isActive = false,
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: isActive ? AppTheme.emeraldGreen : Colors.grey.shade300,
                  shape: BoxShape.circle,
                  border: isActive ? Border.all(color: AppTheme.emeraldGreen.withValues(alpha: 0.3), width: 4) : null,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: Colors.grey.shade200,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title, 
                          style: TextStyle(
                            fontWeight: FontWeight.bold, 
                            fontSize: 14,
                            color: isActive ? AppTheme.darkBlue : Colors.grey[700]
                          ),
                        ),
                      ),
                      Text(date, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                    ],
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgentTransferSection(AppLocalizations l10n) {
    final agentsAsync = ref.watch(filteredAgentsProvider);
    
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.transfer_within_a_station, color: AppTheme.emeraldGreen, size: 20),
              const SizedBox(width: 8),
              Text(l10n.mentionAgent, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.darkBlue)),
            ],
          ),
          const SizedBox(height: 16),
          agentsAsync.when(
            data: (agents) => DropdownButtonFormField<String?>(
              value: _selectedAgentId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l10n.agents,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('No Agent')),
                ...agents.map((a) => DropdownMenuItem(
                  value: a['id'] as String,
                  child: Text('${a['name'] ?? 'Unknown'} (${a['phone_number'] ?? 'No Phone'})'),
                )),
              ],
              onChanged: (v) => setState(() => _selectedAgentId = v),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('${l10n.error}: $e'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _agentFeeController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l10n.agentFee,
              prefixIcon: const Icon(Icons.monetization_on_outlined, color: AppTheme.emeraldGreen),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              hintText: '0.00',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesInput(AppLocalizations l10n) {
    return PremiumCard(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _notesController,
        maxLines: 4,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: l10n.notesHint,
          hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ),
    );
  }
}
