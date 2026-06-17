import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/contact_utils.dart';
import 'package:intl/intl.dart';
import '../providers/dashboard_provider.dart';
import '../../../../core/widgets/responsive_layout.dart';
import 'package:service_manager_app/l10n/generated/app_localizations.dart';
import 'package:service_manager_app/core/widgets/app_bar.dart';
import 'package:service_manager_app/features/enquiries/domain/models/enquiry.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/models/task_document.dart';

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
  bool _isUploadingDoc = false;

  @override
  void initState() {
    super.initState();
    _status = _normalizeStatus(widget.initialStatus);
  }

  @override
  void dispose() {
    _notesController.dispose();
    _agentFeeController.dispose();
    super.dispose();
  }

  String _normalizeStatus(String s) {
    final lower = s.toLowerCase();
    if (lower == 'pending') return 'Pending';
    if (lower == 'in-progress' || lower == 'inprogress') return 'In Progress';
    if (lower == 'completed') return 'Completed';
    return 'Pending';
  }

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
      ref.invalidate(allWorkOrdersProvider);
      ref.invalidate(activeWorkOrdersProvider);
      ref.invalidate(activeCasesCountProvider);
      ref.invalidate(pendingApprovalsCountProvider);
      ref.invalidate(dashboardStatsProvider);
      ref.invalidate(workOrderByIdProvider(widget.taskId));
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

  // ── Document upload ────────────────────────────────────────────────────────

  Future<void> _showAddDocumentSheet() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_camera, color: AppTheme.darkBlue),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppTheme.darkBlue),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.description, color: AppTheme.darkBlue),
              title: const Text('Upload Document (PDF / DOC)'),
              onTap: () => Navigator.pop(context, 'document'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (choice == null || !mounted) return;

    if (choice == 'camera' || choice == 'gallery') {
      await _pickAndUploadImage(
        source: choice == 'camera' ? ImageSource.camera : ImageSource.gallery,
      );
    } else {
      await _pickAndUploadDocument();
    }
  }

  static const int _maxDocBytes = 8 * 1024 * 1024; // 8 MB hard limit for docs

  String _fmtBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  Future<void> _pickAndUploadImage({required ImageSource source}) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 100);
    if (picked == null || !mounted) return;

    final title = await _askForTitle(defaultTitle: 'Image');
    if (title == null || !mounted) return;

    setState(() => _isUploadingDoc = true);
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storagePath = '${widget.taskId}/$timestamp.jpg';

      late Uint8List bytes;
      late int originalSize;

      if (kIsWeb) {
        // Web: dart:io and FlutterImageCompress are unavailable — read bytes directly.
        bytes = await picked.readAsBytes();
        originalSize = bytes.length;
      } else {
        // Native: two-pass compression via FlutterImageCompress.
        originalSize = await File(picked.path).length();
        final tmpDir = await getTemporaryDirectory();
        final outPath = '${tmpDir.path}/task_img_$timestamp.jpg';

        var compressed = await FlutterImageCompress.compressAndGetFile(
          picked.path, outPath,
          format: CompressFormat.jpeg,
          quality: 68,
          minWidth: 1280,
          minHeight: 1280,
        );
        if (compressed == null) return;

        int compressedSize = await File(compressed.path).length();
        if (compressedSize > 600 * 1024) {
          final pass2 = '${tmpDir.path}/task_img_${timestamp}_p2.jpg';
          final recompressed = await FlutterImageCompress.compressAndGetFile(
            compressed.path, pass2,
            format: CompressFormat.jpeg,
            quality: 50,
            minWidth: 900,
            minHeight: 900,
          );
          if (recompressed != null) compressed = recompressed;
        }

        bytes = await File(compressed.path).readAsBytes();
      }

      await Supabase.instance.client.storage
          .from('task-files')
          .uploadBinary(storagePath, bytes,
              fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: false));

      final fileUrl = Supabase.instance.client.storage
          .from('task-files')
          .getPublicUrl(storagePath);

      final repo = ref.read(workOrderRepositoryProvider);
      await repo.addTaskDocument(
        workOrderId: widget.taskId,
        title: title,
        fileUrl: fileUrl,
        iconName: 'image',
      );

      ref.invalidate(taskDocumentsProvider(widget.taskId));

      if (mounted) {
        final uploadedSize = bytes.length;
        final reduction = originalSize > 0
            ? ((1 - uploadedSize / originalSize) * 100).round().clamp(0, 100)
            : 0;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(
            'Image uploaded — ${_fmtBytes(uploadedSize)} (saved $reduction% from ${_fmtBytes(originalSize)})',
          )),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingDoc = false);
    }
  }

  Future<void> _pickAndUploadDocument() async {
    FilePickerResult? result;
    try {
      result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
        withData: true,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('File picker error: $e')));
      }
      return;
    }

    if (result == null || !mounted) return;
    final file = result.files.single;
    final ext = (file.extension ?? 'pdf').toLowerCase();
    final bytes = file.bytes ?? Uint8List(0);
    if (bytes.isEmpty) return;

    // Hard size gate — PDF/DOC cannot be re-compressed in Flutter
    if (bytes.length > _maxDocBytes) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'File too large (${_fmtBytes(bytes.length)}). Please reduce it to under 8 MB before uploading.',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      return;
    }

    final defaultTitle = file.name.replaceAll('.$ext', '');
    final title = await _askForTitle(defaultTitle: defaultTitle);
    if (title == null || !mounted) return;

    setState(() => _isUploadingDoc = true);
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storagePath = '${widget.taskId}/$timestamp.$ext';

      final contentType = ext == 'pdf'
          ? 'application/pdf'
          : ext == 'doc'
              ? 'application/msword'
              : 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';

      await Supabase.instance.client.storage
          .from('task-files')
          .uploadBinary(storagePath, bytes,
              fileOptions: FileOptions(contentType: contentType, upsert: false));

      final fileUrl = Supabase.instance.client.storage
          .from('task-files')
          .getPublicUrl(storagePath);

      final repo = ref.read(workOrderRepositoryProvider);
      await repo.addTaskDocument(
        workOrderId: widget.taskId,
        title: title,
        fileUrl: fileUrl,
        iconName: ext,
      );

      ref.invalidate(taskDocumentsProvider(widget.taskId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Document uploaded — ${_fmtBytes(bytes.length)}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingDoc = false);
    }
  }

  Future<String?> _askForTitle({String defaultTitle = ''}) async {
    final controller = TextEditingController(text: defaultTitle);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Document Name', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter a name for this file'),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim().isEmpty ? defaultTitle : v.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final v = controller.text.trim();
              Navigator.pop(ctx, v.isEmpty ? defaultTitle : v);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emeraldGreen, foregroundColor: Colors.white),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteDocument(TaskDocument doc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text('Remove "${doc.title}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      String? storagePath;
      if (doc.fileUrl != null) {
        final uri = Uri.tryParse(doc.fileUrl!);
        final segments = uri?.pathSegments ?? [];
        final idx = segments.indexOf('task-files');
        if (idx != -1 && idx + 1 < segments.length) {
          storagePath = segments.sublist(idx + 1).join('/');
        }
      }

      final repo = ref.read(workOrderRepositoryProvider);
      await repo.deleteTaskDocument(doc.id, storagePath: storagePath);
      ref.invalidate(taskDocumentsProvider(widget.taskId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e')),
        );
      }
    }
  }

  void _openFile(TaskDocument doc) async {
    if (doc.fileUrl == null) return;

    if (doc.isImage) {
      showDialog(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.black,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            children: [
              InteractiveViewer(
                child: Image.network(doc.fileUrl!, fit: BoxFit.contain),
              ),
              Positioned(
                top: 40, right: 16,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      final uri = Uri.parse(doc.fileUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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

    final statusColor = _getStatusColor(_status);
    final priorityColor = _getPriorityColor(widget.priority);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: WorkqlyAppBar(
        title: l10n.taskDetails,
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
        color: AppTheme.ink900,
        onRefresh: () async {
          ref.invalidate(taskHistoryProvider(widget.taskId));
          ref.invalidate(taskDocumentsProvider(widget.taskId));
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
                  _metricsBar(statusColor, priorityColor, l10n, isDark),
                  const SizedBox(height: 32),

                  _sectionTitle(l10n.generalInfo),
                  _card([
                    _detailRow(l10n.caseId, Text('#${widget.taskId}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.darkBlue))),
                    _detailRow(l10n.clientName, Text(widget.clientName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppTheme.darkBlue))),
                    _detailRow(l10n.priority, _buildPriorityBadge(widget.priority, l10n)),
                    _detailRow(l10n.status, _buildStatusDropdown(l10n)),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Divider(color: Colors.grey.shade200, height: 1),
                    ),
                    _detailRow('Project Final Status', DropdownButtonFormField<String>(
                      value: _finalStatus,
                      isExpanded: true,
                      decoration: const InputDecoration(isDense: true),
                      items: kFinalStatusLabels
                          .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 14))))
                          .toList(),
                      onChanged: (v) => setState(() => _finalStatus = v),
                      hint: const Text('Select final status', style: TextStyle(fontSize: 14)),
                    )),
                    _detailRow('Reason for Rejecting', DropdownButtonFormField<String>(
                      value: _rejectionReason,
                      isExpanded: true,
                      decoration: const InputDecoration(isDense: true),
                      items: kRejectionReasons
                          .map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 14))))
                          .toList(),
                      onChanged: (v) => setState(() => _rejectionReason = v),
                      hint: const Text('Select reason', style: TextStyle(fontSize: 14)),
                    )),
                  ], isDark: isDark),

                  const SizedBox(height: 24),

                  // ── Documents section ──────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _sectionTitle(l10n.documents),
                      _isUploadingDoc
                          ? const Padding(
                              padding: EdgeInsets.only(right: 8),
                              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                            )
                          : TextButton.icon(
                              icon: const Icon(Icons.add, size: 16),
                              label: Text(l10n.uploadNew),
                              onPressed: _showAddDocumentSheet,
                              style: TextButton.styleFrom(foregroundColor: AppTheme.emeraldGreen),
                            ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildDocumentsSection(isDark),

                  const SizedBox(height: 24),
                  _sectionTitle(l10n.transferToAgent),
                  _card([_buildAgentTransferSection(l10n)], isDark: isDark),

                  const SizedBox(height: 24),
                  _sectionTitle(l10n.timeline),
                  _card([_buildTimeline(l10n)], isDark: isDark),

                  const SizedBox(height: 24),
                  _sectionTitle(l10n.dailyUpdateNotes),
                  _card([_buildNotesInput(l10n)], isDark: isDark),

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

  // ── Documents grid ─────────────────────────────────────────────────────────

  Widget _buildDocumentsSection(bool isDark) {
    final docsAsync = ref.watch(taskDocumentsProvider(widget.taskId));

    return docsAsync.when(
      data: (docs) {
        if (docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.folder_open, size: 40, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text('No documents yet', style: TextStyle(color: Colors.grey[500])),
                  const SizedBox(height: 4),
                  Text('Tap "+ Upload New" to add images or documents',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                ],
              ),
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: _docAspect(crossAxisCount),
              ),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                return GestureDetector(
                  onTap: () => _openFile(doc),
                  onLongPress: _isUploadingDoc ? null : () => _confirmDeleteDocument(doc),
                  child: _buildDocCard(doc, isDark),
                );
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Error loading documents: $e'),
    );
  }

  double _docAspect(int columns) => columns == 4 ? 1.0 : 1.1;

  Widget _buildDocCard(TaskDocument doc, bool isDark) {
    final isImage = doc.isImage;
    final isPdf = doc.isPdf;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
        boxShadow: AppTheme.cardShadow(isDark),
      ),
      child: Stack(
        children: [
          if (isImage && doc.fileUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox.expand(
                child: Image.network(
                  doc.fileUrl!,
                  fit: BoxFit.cover,
                  loadingBuilder: (_, child, progress) => progress == null
                      ? child
                      : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                ),
              ),
            )
          else
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: (isPdf ? Colors.red : Colors.blueGrey).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isPdf ? Icons.picture_as_pdf : Icons.description,
                      color: isPdf ? Colors.red : Colors.blueGrey,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      doc.title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, fontSize: 12),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

          // Overlay title for images
          if (isImage)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent],
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Text(
                  doc.title,
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

          // Verified badge
          if (doc.isVerified)
            Positioned(
              top: 8, right: 8,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                child: const Icon(Icons.check, color: Colors.white, size: 10),
              ),
            ),

          // File type badge for non-images
          if (!isImage)
            Positioned(
              top: 8, left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (isPdf ? Colors.red : Colors.blueGrey).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  (doc.iconName ?? 'doc').toUpperCase(),
                  style: TextStyle(
                    fontSize: 9, fontWeight: FontWeight.bold,
                    color: isPdf ? Colors.red : Colors.blueGrey,
                  ),
                ),
              ),
            ),

          // Long press hint
          Positioned(
            bottom: isImage ? 28 : 4,
            right: 4,
            child: Tooltip(
              message: 'Long press to delete',
              child: Icon(Icons.more_vert, size: 14, color: isImage ? Colors.white60 : Colors.grey[400]),
            ),
          ),
        ],
      ),
    );
  }

  // ── Existing helpers (unchanged) ───────────────────────────────────────────

  Widget _metricsBar(Color statusColor, Color priorityColor, AppLocalizations l10n, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
        boxShadow: AppTheme.cardShadow(isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.clientName, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 24)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.tag, size: 14, color: Theme.of(context).textTheme.bodySmall?.color),
                        const SizedBox(width: 4),
                        Text(
                          widget.taskId.length > 8 ? widget.taskId.substring(0, 8) : widget.taskId,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Text(_getStatusLabel(_status, l10n), style: TextStyle(color: statusColor, fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Divider(color: Theme.of(context).dividerColor.withValues(alpha: 0.5), height: 1),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _metricTile('Priority', _getPriorityLabel(widget.priority, l10n), priorityColor, isDark: isDark, icon: Icons.flag)),
              Container(width: 1, height: 30, color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
              Expanded(child: Center(child: _metricTile('Phone', widget.clientPhone?.isNotEmpty == true ? widget.clientPhone! : '—', Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black, isDark: isDark, icon: Icons.phone))),
              Container(width: 1, height: 30, color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
              Expanded(child: Align(alignment: Alignment.centerRight, child: _metricTile('Role', 'Client', Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey, isDark: isDark, icon: Icons.person))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricTile(String label, String value, Color valueColor, {required bool isDark, IconData? icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 10, letterSpacing: 1.0, color: Theme.of(context).textTheme.bodySmall?.color)),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: 16, color: valueColor), const SizedBox(width: 6)],
            Flexible(child: Text(value, style: TextStyle(color: valueColor, fontWeight: FontWeight.w600, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ],
    );
  }

  Widget _sectionTitle(String t) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Row(
        children: [
          Container(width: 4, height: 16, decoration: BoxDecoration(color: AppTheme.primaryAccent(isDark), borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 10),
          Text(t.toUpperCase(), style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 1.0, color: Theme.of(context).textTheme.bodyMedium?.color)),
        ],
      ),
    );
  }

  Widget _card(List<Widget> children, {required bool isDark}) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
      boxShadow: AppTheme.cardShadow(isDark),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
  );

  Widget _detailRow(String label, Widget value) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 160,
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(label.toUpperCase(), style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 11)),
          ),
        ),
        Expanded(child: value),
      ],
    ),
  );

  Widget _buildActionButton(IconData icon, Color color, VoidCallback onPressed) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
      child: IconButton(icon: Icon(icon, color: color, size: 20), onPressed: onPressed),
    );
  }

  Color _getStatusColor(String status) {
    final s = status.toLowerCase();
    if (s == 'completed') return AppTheme.emeraldGreen;
    if (s == 'in progress') return Colors.blue;
    return AppTheme.statAmber;
  }

  Color _getPriorityColor(String priority) {
    final p = priority.toLowerCase();
    if (p == 'high') return AppTheme.errorRed;
    if (p == 'low') return Colors.green;
    return AppTheme.accentGold;
  }

  Widget _buildPriorityBadge(String priority, AppLocalizations l10n) {
    final pColor = _getPriorityColor(priority);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: pColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: pColor.withValues(alpha: 0.5)),
      ),
      child: Text(_getPriorityLabel(priority, l10n), style: TextStyle(color: pColor, fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }

  Widget _buildStatusDropdown(AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardAlt : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _status,
          isDense: true,
          items: ['Pending', 'In Progress', 'Completed'].map((e) {
            return DropdownMenuItem(value: e, child: Text(_getStatusLabel(e, l10n), style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13, fontWeight: FontWeight.w600)));
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

  Widget _buildTimeline(AppLocalizations l10n) {
    final historyAsync = ref.watch(taskHistoryProvider(widget.taskId));
    return historyAsync.when(
      data: (history) {
        if (history.isEmpty) {
          return Center(child: Text(l10n.noHistoryFound, style: const TextStyle(color: Colors.grey, fontSize: 12)));
        }
        return Column(
          children: history.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isLast = index == history.length - 1;
            final isFirst = index == 0;
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            final yesterday = today.subtract(const Duration(days: 1));
            final itemDate = DateTime(item.createdAt.year, item.createdAt.month, item.createdAt.day);
            String dateStr;
            if (itemDate == today) {
              dateStr = l10n.today;
            } else if (itemDate == yesterday) {
              dateStr = l10n.yesterday;
            } else {
              dateStr = DateFormat('MMM dd, yyyy').format(item.createdAt);
            }
            return _buildTimelineItem(title: item.title, subtitle: item.description ?? '', date: dateStr, isActive: isFirst, isLast: isLast);
          }).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('${l10n.errorLoadingHistory}: $e')),
    );
  }

  Widget _buildTimelineItem({required String title, required String subtitle, required String date, bool isActive = false, bool isLast = false}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 12, height: 12,
                decoration: BoxDecoration(
                  color: isActive ? AppTheme.emeraldGreen : Colors.grey.shade300,
                  shape: BoxShape.circle,
                  border: isActive ? Border.all(color: AppTheme.emeraldGreen.withValues(alpha: 0.3), width: 4) : null,
                ),
              ),
              if (!isLast) Expanded(child: Container(width: 2, color: Colors.grey.shade200)),
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
                      Expanded(child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isActive ? AppTheme.darkBlue : Colors.grey[700]))),
                      Text(date, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                    ],
                  ),
                  if (subtitle.isNotEmpty) ...[const SizedBox(height: 4), Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 12))],
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
    return Column(
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
            decoration: InputDecoration(labelText: l10n.agents, isDense: true),
            items: [
              const DropdownMenuItem(value: null, child: Text('No Agent')),
              ...agents.map((a) => DropdownMenuItem(value: a['id'] as String, child: Text('${a['name'] ?? 'Unknown'} (${a['phone_number'] ?? 'No Phone'})'))),
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
            prefixIcon: Icon(Icons.monetization_on_outlined, color: AppTheme.primaryAccent(Theme.of(context).brightness == Brightness.dark)),
            isDense: true,
            hintText: '0.00',
          ),
        ),
      ],
    );
  }

  Widget _buildNotesInput(AppLocalizations l10n) {
    return TextField(controller: _notesController, maxLines: 4, decoration: InputDecoration(hintText: l10n.notesHint));
  }
}
