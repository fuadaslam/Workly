import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/contact_utils.dart';
import 'package:intl/intl.dart';
import '../providers/dashboard_provider.dart';
import '../../../../core/widgets/responsive_layout.dart';

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
  final TextEditingController _notesController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Normalize status string to match dropdown items (Capitalized)
    _status = _normalizeStatus(widget.initialStatus);
  }

  String _normalizeStatus(String s) {
    final lower = s.toLowerCase();
    if (lower == 'pending') return 'Pending';
    if (lower == 'in-progress' || lower == 'inprogress') return 'In Progress';
    if (lower == 'completed') return 'Completed';
    return 'Pending';
  }
  
  // Mock Data for Documents
  List<Map<String, dynamic>> _documents = [
    {'title': 'Passport / جواز السفر', 'icon': Icons.book, 'color': Colors.blueGrey, 'verified': true},
    {'title': 'CR / السجل التجاري', 'icon': Icons.article, 'color': Colors.brown, 'verified': true},
    {'title': 'Medical / التقرير الطبي', 'icon': Icons.monitor_heart, 'color': Colors.teal, 'verified': false},
  ];

  Future<void> _updateTask() async {
    setState(() => _isSaving = true);
    try {
      final repo = ref.read(workOrderRepositoryProvider);
      // Map display status back to API status
      // 'Pending', 'In Progress', 'Completed'
      String apiStatus = 'Pending';
      if (_status == 'In Progress') apiStatus = 'In-Progress';
      if (_status == 'Completed') apiStatus = 'Completed';
      
      await repo.updateWorkOrderStatus(widget.taskId, apiStatus);
      
      // Save Daily Update Note if provided
      if (_notesController.text.isNotEmpty) {
        await repo.addTaskHistory(
          widget.taskId,
          'Manual Update / تحديث يدوي',
          description: _notesController.text,
          status: apiStatus,
        );
      } else {
        // Log status change even if no note
        await repo.addTaskHistory(
          widget.taskId,
          'Status Changed to $_status / تم تغيير الحالة إلى $_status',
          status: apiStatus,
        );
      }
      
      ref.invalidate(myWorkOrdersProvider); // Refresh list
      ref.invalidate(taskHistoryProvider(widget.taskId)); // Refresh timeline
      
      if (mounted) {
        _notesController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Task Updated to $_status')),
        );
        // We don't necessarily need to pop if we want to see the timeline update
        // Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
  
  void _deleteDocument(int index) {
    setState(() {
      _documents.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document Removed')));
  }

  void _addDocumentMock() {
    setState(() {
      _documents.add({
        'title': 'New Doc ${DateTime.now().second}',
        'icon': Icons.description,
        'color': Colors.orangeAccent,
        'verified': false
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundLight,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Task Details / تفاصيل المهمة',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              '#${widget.taskId.length > 8 ? widget.taskId.substring(0, 8) : widget.taskId}...',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.phone_outlined, color: Colors.blue),
              onPressed: () => ContactUtils.callNumber(widget.clientPhone),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.message_outlined, color: Colors.green),
              onPressed: () {
                final message = "Update on Task #${widget.taskId.substring(0, 8)}: Status is now $_status.";
                ContactUtils.openWhatsApp(widget.clientPhone, message: message);
              },
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: ResponsiveLayout(
          maxWidth: 1000,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('General Information / معلومات عامة'),
              const SizedBox(height: 12),
              _buildInfoCard(),
              const SizedBox(height: 24),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionHeader('Documents / المستندات'),
                  TextButton.icon(
                    onPressed: _addDocumentMock,
                    icon: const Icon(Icons.add_circle, size: 16),
                    label: const Text('Add / إضافة'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.emeraldGreen,
                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
                  return _buildDocumentsGrid(crossAxisCount);
                },
              ),
              
              const SizedBox(height: 24),
              _buildSectionHeader('Timeline / الخط الزمني'),
              const SizedBox(height: 12),
              _buildTimeline(),

              const SizedBox(height: 24),
              _buildSectionHeader('Daily Update Notes / تحديث يومي'),
              const SizedBox(height: 12),
              _buildNotesInput(),
              
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
                    children: const [
                      Icon(Icons.save, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text('Save Changes / حفظ التغييرات', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppTheme.darkBlue,
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow('Case ID / رقم القضية', '#${widget.taskId}', false),
          const Divider(height: 24),
          _buildInfoRow('Client / العميل', widget.clientName, false),
          const Divider(height: 24),
          _buildInfoRow('Priority / الأولوية', widget.priority.toUpperCase(), true),
          const Divider(height: 24),
          // Status Dropdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Status / الحالة', style: TextStyle(color: AppTheme.emeraldGreen, fontWeight: FontWeight.w500)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _status,
                    items: ['Pending', 'In Progress', 'Completed'].map((e) {
                      return DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)));
                    }).toList(),
                    onChanged: (v) => setState(() => _status = v!),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isBadge) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.emeraldGreen, fontWeight: FontWeight.w500)),
        const SizedBox(width: 16),
        isBadge 
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.accentGold.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              value,
              style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          )
        : Flexible(
            child: Text(
              value, 
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.darkBlue),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              textAlign: TextAlign.end,
            ),
          ),
      ],
    );
  }

  Widget _buildDocumentsGrid(int crossAxisCount) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: _documents.length + 1,
      itemBuilder: (context, index) {
        if (index == _documents.length) {
          return GestureDetector(onTap: _addDocumentMock, child: _buildUploadItem());
        }
        final doc = _documents[index];
        return GestureDetector(
          onLongPress: () => _deleteDocument(index),
          child: _buildDocItem(doc['title'], doc['icon'], doc['verified'], doc['color']),
        );
      },
    );
  }

  Widget _buildDocItem(String title, IconData icon, bool verified, Color color) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: double.infinity, 
          decoration: BoxDecoration(
            color: color.withOpacity(0.8),
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color, color.withOpacity(0.6)],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 40),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  title, 
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
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
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
              child: const Icon(Icons.check, color: Colors.white, size: 14),
            ),
          ),
        if (!verified)
           Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
              child: const Icon(Icons.hourglass_top, color: Colors.white, size: 14),
            ),
          ),
      ],
    );
  }

  Widget _buildUploadItem() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.upload_file, color: Colors.grey, size: 30),
          SizedBox(height: 8),
          Text('UPLOAD NEW / رفع ملف', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    final historyAsync = ref.watch(taskHistoryProvider(widget.taskId));

    return historyAsync.when(
      data: (history) {
        if (history.isEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Center(
              child: Text(
                'No history recorded yet / لا يوجد سجل مسجل بعد',
                style: TextStyle(color: Colors.grey, fontSize: 12),
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

            // Format date: Today, Yesterday, or Mar 15, 2024
            String dateStr;
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            final yesterday = today.subtract(const Duration(days: 1));
            final itemDate = DateTime(item.createdAt.year, item.createdAt.month, item.createdAt.day);

            if (itemDate == today) {
              dateStr = 'Today / اليوم';
            } else if (itemDate == yesterday) {
              dateStr = 'Yesterday / أمس';
            } else {
              dateStr = DateFormat('MMM dd, yyyy').format(item.createdAt);
            }

            return _buildTimelineItem(
              title: item.title,
              subtitle: item.description ?? 'No details provided / لا توجد تفاصيل',
              date: dateStr,
              isActive: isFirst,
              isLast: isLast,
            );
          }).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error loading history: $e')),
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
                  color: isActive ? Colors.green : Colors.grey.shade300,
                  shape: BoxShape.circle,
                  border: isActive ? Border.all(color: Colors.green.withOpacity(0.3), width: 4) : null,
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
                            color: isActive ? Colors.black : Colors.grey[700]
                          ),
                        ),
                      ),
                      Text(date, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: _notesController,
        maxLines: 4,
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: 'Enter today\'s status updates here... / أدخل تحديثات الحالة اليومية هنا...',
          hintStyle: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ),
    );
  }
}
