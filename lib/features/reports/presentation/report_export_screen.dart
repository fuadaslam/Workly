import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../data/report_repository.dart';
import '../services/excel_export_service.dart';
import '../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../enquiries/presentation/providers/enquiry_fields_provider.dart';
import 'package:service_manager_app/core/widgets/app_bar.dart';

enum _ReportRange { thisWeek, lastWeek, thisMonth, lastMonth, custom }

class ReportExportScreen extends ConsumerStatefulWidget {
  const ReportExportScreen({super.key});

  @override
  ConsumerState<ReportExportScreen> createState() => _ReportExportScreenState();
}

class _ReportExportScreenState extends ConsumerState<ReportExportScreen>
    with SingleTickerProviderStateMixin {
  _ReportRange _selected = _ReportRange.thisMonth;
  DateTime? _customFrom;
  DateTime? _customTo;
  bool _includeWorkOrders = true;
  bool _includeEnquiries = true;
  bool _includeAttendance = false;
  bool _exporting = false;
  bool _loadingOptions = true;

  ReportFilters _filters = const ReportFilters();
  Map<String, List<Map<String, String>>> _options = {};

  late TabController _tabController;
  final _df = DateFormat('dd MMM yyyy');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadOptions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOptions() async {
    try {
      final repo = ReportRepository(ref.read(supabaseClientProvider));
      final opts = await repo.getFilterOptions();
      if (mounted) setState(() { _options = opts; _loadingOptions = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingOptions = false);
    }
  }

  DateTimeRange _resolveRange() {
    final now = DateTime.now();
    switch (_selected) {
      case _ReportRange.thisWeek:
        final start = now.subtract(Duration(days: now.weekday - 1));
        return DateTimeRange(
            start: DateTime(start.year, start.month, start.day),
            end: DateTime(now.year, now.month, now.day, 23, 59, 59));
      case _ReportRange.lastWeek:
        final start = now.subtract(Duration(days: now.weekday + 6));
        final end = now.subtract(Duration(days: now.weekday));
        return DateTimeRange(
            start: DateTime(start.year, start.month, start.day),
            end: DateTime(end.year, end.month, end.day, 23, 59, 59));
      case _ReportRange.thisMonth:
        return DateTimeRange(
            start: DateTime(now.year, now.month, 1),
            end: DateTime(now.year, now.month, now.day, 23, 59, 59));
      case _ReportRange.lastMonth:
        final first = DateTime(now.year, now.month - 1, 1);
        final last = DateTime(now.year, now.month, 0, 23, 59, 59);
        return DateTimeRange(start: first, end: last);
      case _ReportRange.custom:
        return DateTimeRange(
            start: _customFrom ?? DateTime(now.year, now.month, 1),
            end: _customTo ?? now);
    }
  }

  String _rangeLabel() {
    final r = _resolveRange();
    return '${_df.format(r.start)}  →  ${_df.format(r.end)}';
  }

  String _reportTitle() {
    final r = _resolveRange();
    final tag = DateFormat('MMM yyyy').format(r.start);
    switch (_selected) {
      case _ReportRange.thisWeek: return 'Weekly Report — ${_df.format(r.start)}';
      case _ReportRange.lastWeek: return 'Last Week Report — ${_df.format(r.start)}';
      case _ReportRange.thisMonth: return 'Monthly Report — $tag';
      case _ReportRange.lastMonth: return 'Last Month Report — $tag';
      case _ReportRange.custom:
        return 'Custom Report — ${_df.format(r.start)} to ${_df.format(r.end)}';
    }
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: now,
      initialDateRange: DateTimeRange(
        start: _customFrom ?? DateTime(now.year, now.month, 1),
        end: _customTo ?? now,
      ),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.emeraldGreen),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _customFrom = picked.start;
        _customTo = DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59);
        _selected = _ReportRange.custom;
      });
    }
  }

  void _toggleFilter<T>(List<T> list, T value, void Function(List<T>) update) {
    final updated = List<T>.from(list);
    if (updated.contains(value)) {
      updated.remove(value);
    } else {
      updated.add(value);
    }
    setState(() => update(updated));
  }

  Future<void> _export() async {
    if (!_includeWorkOrders && !_includeEnquiries && !_includeAttendance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one report section.')),
      );
      return;
    }
    setState(() => _exporting = true);
    try {
      final range = _resolveRange();
      final repo = ReportRepository(ref.read(supabaseClientProvider));
      final results = await Future.wait([
        _includeWorkOrders
            ? repo.getWorkOrdersInRange(range.start, range.end, filters: _filters)
            : Future.value(<Map<String, dynamic>>[]),
        _includeEnquiries
            ? repo.getEnquiriesInRange(range.start, range.end, filters: _filters)
            : Future.value(<Map<String, dynamic>>[]),
        _includeAttendance
            ? repo.getAttendanceInRange(range.start, range.end)
            : Future.value(<Map<String, dynamic>>[]),
      ]);
      // Active custom enquiry fields → appended as extra columns in the export.
      final customFields = _includeEnquiries
          ? (await ref.read(enquiryFieldsRepositoryProvider).getFields())
              .where((f) => f.isActive)
              .map((f) => {'key': f.fieldKey, 'label': f.label, 'type': f.fieldType})
              .toList()
          : <Map<String, String>>[];

      await ExcelExportService.exportAndShare(
        reportTitle: _reportTitle(),
        from: range.start,
        to: range.end,
        workOrders: results[0],
        enquiries: results[1],
        attendance: results[2],
        filters: _filters,
        customFields: customFields,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: AppTheme.errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeFilters = _filters.activeCount;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.backgroundLight,
      appBar: WorkqlyAppBar(
        title: 'Export Report',
        actions: [
          if (activeFilters > 0)
            TextButton.icon(
              onPressed: () => setState(() => _filters = const ReportFilters()),
              icon: const Icon(Icons.filter_alt_off_outlined, size: 16),
              label: Text('Clear $activeFilters', style: const TextStyle(fontSize: 13)),
              style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
            ),
        ],
      ),
      body: Column(
        children: [
          // Tab bar
          Container(
            color: isDark ? AppTheme.darkSurface : AppTheme.surfaceWhite,
            child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.emeraldGreen,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppTheme.emeraldGreen,
              indicatorWeight: 3,
              tabs: [
                const Tab(text: 'Report Setup'),
                Tab(
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Text('Filters'),
                    if (activeFilters > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppTheme.emeraldGreen,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('$activeFilters',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ]),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _setupTab(),
                _filtersTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Setup Tab ────────────────────────────────────────────────────────────

  Widget _setupTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _heroHeader(),
          const SizedBox(height: 20),
          _sectionLabel('Report Period'),
          _rangeSelector(),
          const SizedBox(height: 16),
          if (_selected == _ReportRange.custom) ...[
            _customDateTile(),
            const SizedBox(height: 16),
          ],
          _previewCard(),
          const SizedBox(height: 16),
          _sectionLabel('Include in Report'),
          _sectionsCard(),
          const SizedBox(height: 24),
          _exportButton(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _heroHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.emeraldGreen, AppTheme.ink800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.file_download_outlined, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Excel Report Export',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
              const SizedBox(height: 4),
              Text('Work orders · Enquiries · Attendance',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 13)),
            ]),
          ),
          if (_filters.activeCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.accentGold.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('${_filters.activeCount} filters',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.darkBlue)),
  );

  Widget _rangeSelector() {
    final options = [
      (_ReportRange.thisWeek, 'This Week'),
      (_ReportRange.lastWeek, 'Last Week'),
      (_ReportRange.thisMonth, 'This Month'),
      (_ReportRange.lastMonth, 'Last Month'),
      (_ReportRange.custom, 'Custom'),
    ];
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: options.map((opt) {
        final active = _selected == opt.$1;
        return GestureDetector(
          onTap: () {
            if (opt.$1 == _ReportRange.custom) {
              _pickCustomRange();
            } else {
              setState(() => _selected = opt.$1);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: active ? AppTheme.emeraldGreen : AppTheme.surfaceWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: active ? AppTheme.emeraldGreen : Colors.grey.shade200),
              boxShadow: active
                  ? [BoxShadow(color: AppTheme.emeraldGreen.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 2))]
                  : [],
            ),
            child: Text(opt.$2,
                style: TextStyle(
                    color: active ? Colors.white : AppTheme.darkBlue,
                    fontWeight: active ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13)),
          ),
        );
      }).toList(),
    );
  }

  Widget _customDateTile() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: _pickCustomRange,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : AppTheme.surfaceWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.emeraldGreen.withValues(alpha: 0.4)),
        ),
        child: Row(children: [
          const Icon(Icons.date_range_outlined, color: AppTheme.emeraldGreen),
          const SizedBox(width: 12),
          Expanded(child: Text(_rangeLabel(),
              style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.emeraldGreen))),
          const Icon(Icons.edit_outlined, size: 16, color: AppTheme.emeraldGreen),
        ]),
      ),
    );
  }

  Widget _previewCard() {
    final activeFilters = _filters.activeCount;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.emeraldGreen.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.emeraldGreen.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.info_outline, size: 18, color: AppTheme.emeraldGreen),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_reportTitle(),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.emeraldGreen)),
              const SizedBox(height: 2),
              Text(_rangeLabel(), style: const TextStyle(fontSize: 12, color: AppTheme.darkBlue)),
            ])),
          ]),
          if (activeFilters > 0) ...[
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            _activeFilterSummary(),
          ],
        ],
      ),
    );
  }

  Widget _activeFilterSummary() {
    final chips = <Widget>[];
    void addChips(List<String> values, Color color) {
      for (final v in values) {
        chips.add(Container(
          margin: const EdgeInsets.only(right: 6, bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Text(v, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ));
      }
    }
    addChips(_filters.woStatuses, AppTheme.statusProgress);
    addChips(_filters.woPriorities, AppTheme.statusPending);
    addChips(_filters.woServiceTypes, AppTheme.brand600);
    // Show staff names for staff IDs
    final staffOpts = _options['staff'] ?? [];
    final selectedStaffNames = _filters.woStaffIds.map((id) =>
        staffOpts.firstWhere((s) => s['value'] == id, orElse: () => {'label': id})['label']!).toList();
    final eqStaffNames = _filters.eqStaffIds.map((id) =>
        staffOpts.firstWhere((s) => s['value'] == id, orElse: () => {'label': id})['label']!).toList();
    addChips(selectedStaffNames, AppTheme.emeraldGreen);
    addChips(_filters.eqFinalStatuses, AppTheme.statusCompleted);
    addChips(_filters.eqClientStatuses, AppTheme.brand600);
    addChips(_filters.eqServiceTypes, AppTheme.brand600);
    addChips(_filters.eqNationalities, Colors.brown);
    addChips(eqStaffNames, AppTheme.emeraldGreen);

    return Wrap(children: chips);
  }

  Widget _sectionsCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        _toggleTile(icon: Icons.assignment_outlined, title: 'Work Orders',
            subtitle: 'Status, payments, staff assignments', value: _includeWorkOrders,
            onChanged: (v) => setState(() => _includeWorkOrders = v)),
        const Divider(height: 1, indent: 16, endIndent: 16),
        _toggleTile(icon: Icons.track_changes_outlined, title: 'Enquiries',
            subtitle: 'Client enquiries, conversion, analytics', value: _includeEnquiries,
            onChanged: (v) => setState(() => _includeEnquiries = v)),
        const Divider(height: 1, indent: 16, endIndent: 16),
        _toggleTile(icon: Icons.how_to_reg_outlined, title: 'Attendance',
            subtitle: 'Staff check-in/out and hours worked', value: _includeAttendance,
            onChanged: (v) => setState(() => _includeAttendance = v)),
      ]),
    );
  }

  Widget _toggleTile({required IconData icon, required String title, required String subtitle,
      required bool value, required ValueChanged<bool> onChanged}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: value ? AppTheme.emeraldGreen.withValues(alpha: 0.1) : AppTheme.backgroundLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: value ? AppTheme.emeraldGreen : Colors.grey, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ])),
        Switch(value: value, onChanged: onChanged, activeColor: AppTheme.emeraldGreen),
      ]),
    );
  }

  Widget _exportButton() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _exporting ? null : _export,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? AppTheme.primaryAccent(isDark) : AppTheme.emeraldGreen,
          disabledBackgroundColor: Colors.grey.shade300,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        icon: _exporting
            ? SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: isDark ? AppTheme.ink900 : Colors.white))
            : Icon(Icons.download_rounded, color: isDark ? AppTheme.ink900 : Colors.white, size: 22),
        label: Text(
          _exporting ? 'Generating Excel...' : 'Export & Share Excel',
          style: TextStyle(color: isDark ? AppTheme.ink900 : Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
      ),
    );
  }

  // ─── Filters Tab ──────────────────────────────────────────────────────────

  Widget _filtersTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_loadingOptions) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(6, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              height: i == 0 ? 24 : 100,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : AppTheme.backgroundLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: LinearProgressIndicator(
                  backgroundColor: isDark ? AppTheme.darkCard : AppTheme.backgroundLight,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.emeraldGreen.withValues(alpha: 0.15),
                  ),
                ),
              ),
            ),
          )),
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Active filter count banner
          if (_filters.activeCount > 0)
            _filterBanner(),
          const SizedBox(height: 4),

          // ── Work Orders ──
          if (_includeWorkOrders) ...[
            _filterGroupHeader('Work Orders', Icons.assignment_outlined, AppTheme.statusProgress),
            _filterGroup(
              label: 'Status',
              icon: Icons.circle_outlined,
              options: _options['woStatuses'] ?? [],
              selected: _filters.woStatuses,
              onToggle: (v) => _toggleFilter<String>(
                  _filters.woStatuses, v,
                  (l) => _filters = _filters.copyWith(woStatuses: l)),
              chipColor: AppTheme.statusProgress,
            ),
            _filterGroup(
              label: 'Priority',
              icon: Icons.flag_outlined,
              options: _options['woPriorities'] ?? [],
              selected: _filters.woPriorities,
              onToggle: (v) => _toggleFilter<String>(
                  _filters.woPriorities, v,
                  (l) => _filters = _filters.copyWith(woPriorities: l)),
              chipColor: AppTheme.statusPending,
            ),
            _filterGroup(
              label: 'Service Type',
              icon: Icons.miscellaneous_services_outlined,
              options: _options['woServices'] ?? [],
              selected: _filters.woServiceTypes,
              onToggle: (v) => _toggleFilter<String>(
                  _filters.woServiceTypes, v,
                  (l) => _filters = _filters.copyWith(woServiceTypes: l)),
              chipColor: AppTheme.brand600,
            ),
            _filterGroup(
              label: 'Staff Member',
              icon: Icons.person_outlined,
              options: _options['staff'] ?? [],
              selected: _filters.woStaffIds,
              onToggle: (v) => _toggleFilter<String>(
                  _filters.woStaffIds, v,
                  (l) => _filters = _filters.copyWith(woStaffIds: l)),
              chipColor: AppTheme.emeraldGreen,
            ),
            const SizedBox(height: 8),
          ],

          // ── Enquiries ──
          if (_includeEnquiries) ...[
            _filterGroupHeader('Enquiries', Icons.track_changes_outlined, AppTheme.statusCompleted),
            _filterGroup(
              label: 'Final Status',
              icon: Icons.check_circle_outline,
              options: _options['eqStatuses'] ?? [],
              selected: _filters.eqFinalStatuses,
              onToggle: (v) => _toggleFilter<String>(
                  _filters.eqFinalStatuses, v,
                  (l) => _filters = _filters.copyWith(eqFinalStatuses: l)),
              chipColor: AppTheme.statusCompleted,
            ),
            _filterGroup(
              label: 'Client Decision',
              icon: Icons.thumbs_up_down_outlined,
              options: [
                {'label': 'Accepted', 'value': 'accepted'},
                {'label': 'Rejected', 'value': 'rejected'},
                {'label': 'Pending', 'value': 'pending'},
              ],
              selected: _filters.eqClientStatuses,
              onToggle: (v) => _toggleFilter<String>(
                  _filters.eqClientStatuses, v,
                  (l) => _filters = _filters.copyWith(eqClientStatuses: l)),
              chipColor: AppTheme.brand600,
            ),
            _filterGroup(
              label: 'Service Type',
              icon: Icons.miscellaneous_services_outlined,
              options: _options['eqServices'] ?? [],
              selected: _filters.eqServiceTypes,
              onToggle: (v) => _toggleFilter<String>(
                  _filters.eqServiceTypes, v,
                  (l) => _filters = _filters.copyWith(eqServiceTypes: l)),
              chipColor: AppTheme.brand600,
            ),
            _filterGroup(
              label: 'Nationality',
              icon: Icons.flag_outlined,
              options: _options['eqNationalities'] ?? [],
              selected: _filters.eqNationalities,
              onToggle: (v) => _toggleFilter<String>(
                  _filters.eqNationalities, v,
                  (l) => _filters = _filters.copyWith(eqNationalities: l)),
              chipColor: Colors.brown,
            ),
            _filterGroup(
              label: 'Responsible Staff',
              icon: Icons.person_outlined,
              options: _options['staff'] ?? [],
              selected: _filters.eqStaffIds,
              onToggle: (v) => _toggleFilter<String>(
                  _filters.eqStaffIds, v,
                  (l) => _filters = _filters.copyWith(eqStaffIds: l)),
              chipColor: AppTheme.emeraldGreen,
            ),
          ],

          if (!_includeWorkOrders && !_includeEnquiries)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(children: [
                  Icon(Icons.filter_alt_outlined, size: 48, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text('Enable Work Orders or Enquiries\nin the Report Setup tab to see filters.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
                ]),
              ),
            ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _filterBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.emeraldGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.emeraldGreen.withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        const Icon(Icons.filter_alt_outlined, size: 16, color: AppTheme.emeraldGreen),
        const SizedBox(width: 8),
        Expanded(
          child: Text('${_filters.activeCount} active filter${_filters.activeCount == 1 ? '' : 's'} — export will include only matching records',
              style: const TextStyle(fontSize: 12, color: AppTheme.emeraldGreen)),
        ),
        GestureDetector(
          onTap: () => setState(() => _filters = const ReportFilters()),
          child: const Text('Clear all', style: TextStyle(fontSize: 12, color: AppTheme.errorRed, fontWeight: FontWeight.bold)),
        ),
      ]),
    );
  }

  Widget _filterGroupHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
      ]),
    );
  }

  Widget _filterGroup({
    required String label,
    required IconData icon,
    required List<Map<String, String>> options,
    required List<String> selected,
    required void Function(String) onToggle,
    required Color chipColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (options.isEmpty) return const SizedBox();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 14, color: Colors.grey),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
            const Spacer(),
            if (selected.isNotEmpty)
              GestureDetector(
                onTap: () => setState(() {
                  // clear only this group
                  final ids = options.map((o) => o['value']!).toList();
                  onToggle('__clear__');
                  // rebuild by removing all of this group
                  for (final id in ids) {
                    if (selected.contains(id)) onToggle(id);
                  }
                }),
                child: Text('Clear', style: TextStyle(fontSize: 11, color: chipColor, fontWeight: FontWeight.bold)),
              ),
          ]),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((opt) {
              final val = opt['value']!;
              final lbl = opt['label']!;
              final isSelected = selected.contains(val);
              return GestureDetector(
                onTap: () => onToggle(val),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected ? chipColor : AppTheme.backgroundLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? chipColor : Colors.grey.shade200,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    if (isSelected) ...[
                      const Icon(Icons.check, size: 12, color: Colors.white),
                      const SizedBox(width: 4),
                    ],
                    Text(lbl,
                        style: TextStyle(
                            fontSize: 13,
                            color: isSelected ? Colors.white : AppTheme.darkBlue,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                  ]),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
