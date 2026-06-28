import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/workly_primitives.dart';
import '../../domain/models/enquiry.dart';
import '../providers/enquiry_provider.dart';
import '../providers/enquiry_fields_provider.dart';
import 'package:service_manager_app/core/widgets/app_bar.dart';
import 'package:service_manager_app/core/widgets/infinite_scroll_list.dart';

class EnquiryListScreen extends ConsumerStatefulWidget {
  /// When true (pushed as its own route, e.g. from the staff view) the app bar
  /// shows a back button. When used as an admin dashboard tab it stays false.
  final bool showBack;
  const EnquiryListScreen({super.key, this.showBack = false});

  @override
  ConsumerState<EnquiryListScreen> createState() => _EnquiryListScreenState();
}

class _EnquiryListScreenState extends ConsumerState<EnquiryListScreen> {
  final _searchCtrl = TextEditingController();
  // Populated each build from the org's custom field definitions.
  Map<String, String> _customLabels = {};
  Map<String, String> _customTypes = {};

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _openWhatsApp(String phone, Enquiry e) async {
    final clean = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final service = e.natureOfEnquiry ?? 'enquiry';
    final msg = Uri.encodeComponent(
      'Hello, regarding your $service enquiry (${e.enquiryCode}). How can we assist you today?',
    );
    final url = Uri.parse('https://wa.me/$clean?text=$msg');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  // ── Status helpers ──────────────────────────────────────────────────────────

  Color _statusColor(EnquiryFinalStatus s) {
    switch (s) {
      case EnquiryFinalStatus.executed:
      case EnquiryFinalStatus.settled:
        return AppTheme.mintGreen;
      case EnquiryFinalStatus.inProgress:
        return AppTheme.electricBlue;
      case EnquiryFinalStatus.postponedByClient:
        return AppTheme.mutedAmber;
      case EnquiryFinalStatus.rejectedByClient:
      case EnquiryFinalStatus.cancelled:
        return AppTheme.errorRed;
    }
  }

  String _statusLabel(EnquiryFinalStatus s) {
    switch (s) {
      case EnquiryFinalStatus.executed:        return 'Executed';
      case EnquiryFinalStatus.settled:         return 'Settled';
      case EnquiryFinalStatus.inProgress:      return 'In Progress';
      case EnquiryFinalStatus.postponedByClient: return 'Postponed';
      case EnquiryFinalStatus.rejectedByClient:  return 'Rejected';
      case EnquiryFinalStatus.cancelled:       return 'Cancelled';
    }
  }

  Color _perfColor(PerformanceRating r) {
    switch (r) {
      case PerformanceRating.excellent:   return AppTheme.mintGreen;
      case PerformanceRating.good:        return AppTheme.electricBlue;
      case PerformanceRating.average:     return AppTheme.mutedAmber;
      case PerformanceRating.needsReview: return AppTheme.errorRed;
    }
  }

  String _perfLabel(PerformanceRating r) {
    switch (r) {
      case PerformanceRating.excellent:   return 'Excellent';
      case PerformanceRating.good:        return 'Good';
      case PerformanceRating.average:     return 'Average';
      case PerformanceRating.needsReview: return 'Needs Review';
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(enquiryFilterProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? AppTheme.darkBackground : AppTheme.backgroundLight;
    final fieldDefs = ref.watch(enquiryFieldRowsProvider).valueOrNull ?? const [];
    _customLabels = {for (final f in fieldDefs) f.fieldKey: f.label};
    _customTypes = {for (final f in fieldDefs) f.fieldKey: f.fieldType};

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: WorkqlyAppBar(
        title: 'Enquiry Tracker',
        automaticallyImplyLeading: widget.showBack,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            tooltip: 'Summary',
            onPressed: () => context.push('/dashboard/enquiries/summary'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: InfiniteScrollList<Enquiry>(
        provider: paginatedEnquiriesProvider,
        filterWidget: _buildSearchAndFilter(filter, isDark),
        emptyState: _buildEmptyState(isDark),
        itemBuilder: (ctx, enquiry) => _buildCard(enquiry, isDark),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: FloatingActionButton.extended(
          onPressed: () async {
            final created = await context.push<bool>('/dashboard/enquiries/add');
            if (created == true) ref.read(paginatedEnquiriesProvider.notifier).refresh();
          },
          backgroundColor: AppTheme.electricBlue,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'New Enquiry',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  // ── Filter bar ──────────────────────────────────────────────────────────────

  Widget _buildSearchAndFilter(EnquiryFilter filter, bool isDark) {
    final barBg = isDark ? AppTheme.darkSurface : AppTheme.surfaceWhite;
    final barBorder = isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0);

    return Container(
      decoration: BoxDecoration(
        color: barBg,
        border: Border(bottom: BorderSide(color: barBorder, width: 1)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WorklySearchBar(
            controller: _searchCtrl,
            hint: 'Search by client, ID, phone…',
            onChanged: (v) {
              ref.read(enquiryFilterProvider.notifier).state =
                  filter.copyWith(searchQuery: v);
            },
            onClear: () {
              _searchCtrl.clear();
              ref.read(enquiryFilterProvider.notifier).state =
                  filter.copyWith(searchQuery: '');
            },
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                WorklyFilterChip(
                  label: 'All',
                  selected: filter.status == null,
                  onTap: () => ref.read(enquiryFilterProvider.notifier).state =
                      EnquiryFilter(
                        status: null,
                        staffId: filter.staffId,
                        service: filter.service,
                        searchQuery: filter.searchQuery,
                      ),
                ),
                const SizedBox(width: 8),
                WorklyFilterChip(
                  label: 'In Progress',
                  selected: filter.status == 'In Progress',
                  icon: Icons.timelapse_outlined,
                  onTap: () => ref.read(enquiryFilterProvider.notifier).state =
                      filter.copyWith(status: 'In Progress'),
                ),
                const SizedBox(width: 8),
                WorklyFilterChip(
                  label: 'Settled',
                  selected: filter.status == 'Settled',
                  icon: Icons.check_circle_outline_rounded,
                  onTap: () => ref.read(enquiryFilterProvider.notifier).state =
                      filter.copyWith(status: 'Settled'),
                ),
                const SizedBox(width: 8),
                WorklyFilterChip(
                  label: 'Executed',
                  selected: filter.status == 'Executed',
                  icon: Icons.task_alt_rounded,
                  onTap: () => ref.read(enquiryFilterProvider.notifier).state =
                      filter.copyWith(status: 'Executed'),
                ),
                const SizedBox(width: 8),
                WorklyFilterChip(
                  label: 'Rejected',
                  selected: filter.status == 'Rejected by client',
                  icon: Icons.cancel_outlined,
                  onTap: () => ref.read(enquiryFilterProvider.notifier).state =
                      filter.copyWith(status: 'Rejected by client'),
                ),
                const SizedBox(width: 8),
                WorklyFilterChip(
                  label: 'Cancelled',
                  selected: filter.status == 'Cancelled',
                  icon: Icons.block_outlined,
                  onTap: () => ref.read(enquiryFilterProvider.notifier).state =
                      filter.copyWith(status: 'Cancelled'),
                ),
                const SizedBox(width: 8),
                WorklyFilterChip(
                  label: 'Converted',
                  selected: filter.converted == true,
                  icon: Icons.assignment_turned_in_outlined,
                  onTap: () => ref.read(enquiryFilterProvider.notifier).state = EnquiryFilter(
                    status: filter.status,
                    staffId: filter.staffId,
                    service: filter.service,
                    searchQuery: filter.searchQuery,
                    converted: filter.converted == true ? null : true,
                  ),
                ),
                const SizedBox(width: 8),
                WorklyFilterChip(
                  label: 'Not Converted',
                  selected: filter.converted == false,
                  icon: Icons.pending_actions_outlined,
                  onTap: () => ref.read(enquiryFilterProvider.notifier).state = EnquiryFilter(
                    status: filter.status,
                    staffId: filter.staffId,
                    service: filter.service,
                    searchQuery: filter.searchQuery,
                    converted: filter.converted == false ? null : false,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Enquiry card ─────────────────────────────────────────────────────────────

  Widget _buildCard(Enquiry e, bool isDark) {
    final statusColor = _statusColor(e.finalStatus);
    final perfColor = _perfColor(e.performanceRating);
    final df = DateFormat('dd MMM yyyy');
    final cardBg = isDark ? AppTheme.darkCard : AppTheme.surfaceWhite;
    final cardBorder = isDark ? AppTheme.darkBorder : const Color(0xFFE9EEF5);
    final titleColor = isDark ? AppTheme.darkOnSurface : AppTheme.darkBlue;
    final metaColor = isDark ? AppTheme.darkSubtext : const Color(0xFF64748B);
    final dividerColor = isDark ? AppTheme.darkBorder : const Color(0xFFF1F5F9);

    return GestureDetector(
      onTap: () async {
        final updated = await context.push<bool>('/dashboard/enquiries/detail', extra: e);
        if (updated == true) ref.read(paginatedEnquiriesProvider.notifier).refresh();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorder, width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              // ── Header row ─────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: isDark ? 0.07 : 0.05),
                  border: Border(
                    bottom: BorderSide(
                      color: statusColor.withValues(alpha: isDark ? 0.15 : 0.10),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    // Enquiry code badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.electricBlue.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        e.enquiryCode,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.electricBlue,
                          fontSize: 11,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (e.natureOfEnquiry != null)
                      Expanded(
                        child: Text(
                          e.natureOfEnquiry!,
                          style: TextStyle(
                            fontSize: 12,
                            color: metaColor,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    else
                      const Spacer(),
                    if (e.workOrderId != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.mintGreen.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.assignment_turned_in, size: 11, color: AppTheme.mintGreen),
                          SizedBox(width: 3),
                          Text('Converted',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.mintGreen)),
                        ]),
                      ),
                      const SizedBox(width: 6),
                    ],
                    WorklyStatusBadge(
                      label: _statusLabel(e.finalStatus),
                      color: statusColor,
                    ),
                  ],
                ),
              ),

              // ── Body ────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Client name + WhatsApp
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            e.clientName ?? '—',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: titleColor,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        if (e.contactNumber != null)
                          GestureDetector(
                            onTap: () => _openWhatsApp(e.contactNumber!, e),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 9, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF25D366).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFF25D366).withValues(alpha: 0.20),
                                ),
                              ),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                const Icon(Icons.chat_outlined,
                                    size: 12, color: Color(0xFF25D366)),
                                const SizedBox(width: 4),
                                Text(
                                  e.contactNumber!,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF25D366),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ]),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Meta chips
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        WorklyInfoChip(
                          icon: Icons.calendar_today_outlined,
                          label: e.dateOfEnquiry != null
                              ? df.format(e.dateOfEnquiry!)
                              : '—',
                        ),
                        WorklyInfoChip(
                          icon: Icons.timelapse_outlined,
                          label: '${e.daysOpen} days',
                        ),
                        if (e.nationality != null)
                          WorklyInfoChip(
                            icon: Icons.flag_outlined,
                            label: e.nationality!,
                          ),
                        ..._customChips(e),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Financials + performance
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkCardAlt : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: dividerColor),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'OFFERED',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: metaColor,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'SAR ${e.totalOffered.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: titleColor,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (e.finalAgreedServiceCharge != null) ...[
                            Container(
                              width: 1,
                              height: 32,
                              color: dividerColor,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'AGREED',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: metaColor,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'SAR ${e.finalAgreedServiceCharge!.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: AppTheme.mintGreen,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          WorklyStatusBadge(
                            label: _perfLabel(e.performanceRating),
                            color: perfColor,
                            icon: Icons.star_rounded,
                            dotIndicator: false,
                          ),
                        ],
                      ),
                    ),

                    if (e.responsibleStaffName != null || e.assignedOfficeName != null) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 14,
                        runSpacing: 6,
                        children: [
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.badge_outlined, size: 13, color: metaColor),
                            const SizedBox(width: 5),
                            Text(
                              e.responsibleStaffName ?? 'Unassigned',
                              style: TextStyle(fontSize: 12, color: metaColor),
                            ),
                          ]),
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.business_outlined, size: 13, color: metaColor),
                            const SizedBox(width: 5),
                            Text(
                              e.assignedOfficeName ?? 'No office',
                              style: TextStyle(fontSize: 12, color: metaColor),
                            ),
                          ]),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Up to 3 custom-field values as chips, labelled from the org's field defs.
  List<Widget> _customChips(Enquiry e) {
    if (e.customData.isEmpty) return const [];
    final entries = e.customData.entries
        .where((en) => en.value != null && en.value.toString().trim().isNotEmpty)
        .take(3)
        .toList();
    final df = DateFormat('dd MMM yyyy');
    return entries.map((en) {
      final label = _customLabels[en.key] ?? en.key.replaceAll('_', ' ');
      var value = en.value.toString();
      if (_customTypes[en.key] == 'date') {
        final d = DateTime.tryParse(value);
        if (d != null) value = df.format(d);
      }
      return WorklyInfoChip(icon: Icons.label_outline, label: '$label: $value');
    }).toList();
  }

  // ── Empty state ─────────────────────────────────────────────────────────────

  Widget _buildEmptyState(bool isDark) {
    final iconColor = isDark
        ? AppTheme.darkSubtext.withValues(alpha: 0.4)
        : const Color(0xFFCBD5E1);
    final titleColor = isDark ? AppTheme.darkSubtext : const Color(0xFF64748B);
    final bodyColor = isDark
        ? AppTheme.darkSubtext.withValues(alpha: 0.6)
        : const Color(0xFF94A3B8);

    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.inbox_outlined, size: 56, color: iconColor),
        const SizedBox(height: 16),
        Text(
          'No enquiries found',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: titleColor),
        ),
        const SizedBox(height: 6),
        Text(
          'Tap + to add the first enquiry',
          style: TextStyle(fontSize: 13, color: bodyColor),
        ),
      ]),
    );
  }
}
