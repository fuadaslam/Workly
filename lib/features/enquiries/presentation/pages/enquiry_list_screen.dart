import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/enquiry.dart';
import '../providers/enquiry_provider.dart';
import 'add_enquiry_screen.dart';
import 'enquiry_detail_screen.dart';
import 'enquiry_summary_screen.dart';

class EnquiryListScreen extends ConsumerStatefulWidget {
  const EnquiryListScreen({super.key});

  @override
  ConsumerState<EnquiryListScreen> createState() => _EnquiryListScreenState();
}

class _EnquiryListScreenState extends ConsumerState<EnquiryListScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _openWhatsApp(String phone, Enquiry e) async {
    final clean = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final service = e.natureOfEnquiry ?? 'enquiry';
    final msg = Uri.encodeComponent(
      'Hello, regarding your $service enquiry (${e.enquiryCode}). How can we assist you today?'
    );
    final url = Uri.parse('https://wa.me/$clean?text=$msg');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Color _statusColor(EnquiryFinalStatus s) {
    switch (s) {
      case EnquiryFinalStatus.executed:
      case EnquiryFinalStatus.settled:
        return Colors.green;
      case EnquiryFinalStatus.inProgress:
        return AppTheme.accentGold;
      case EnquiryFinalStatus.postponedByClient:
        return Colors.orange;
      case EnquiryFinalStatus.rejectedByClient:
      case EnquiryFinalStatus.cancelled:
        return AppTheme.errorRed;
    }
  }

  String _statusLabel(EnquiryFinalStatus s) {
    switch (s) {
      case EnquiryFinalStatus.executed: return 'Executed';
      case EnquiryFinalStatus.settled: return 'Settled';
      case EnquiryFinalStatus.inProgress: return 'In Progress';
      case EnquiryFinalStatus.postponedByClient: return 'Postponed';
      case EnquiryFinalStatus.rejectedByClient: return 'Rejected';
      case EnquiryFinalStatus.cancelled: return 'Cancelled';
    }
  }

  Color _perfColor(PerformanceRating r) {
    switch (r) {
      case PerformanceRating.excellent: return Colors.green;
      case PerformanceRating.good: return Colors.teal;
      case PerformanceRating.average: return Colors.orange;
      case PerformanceRating.needsReview: return AppTheme.errorRed;
    }
  }

  String _perfLabel(PerformanceRating r) {
    switch (r) {
      case PerformanceRating.excellent: return 'Excellent';
      case PerformanceRating.good: return 'Good';
      case PerformanceRating.average: return 'Average';
      case PerformanceRating.needsReview: return 'Needs Review';
    }
  }

  @override
  Widget build(BuildContext context) {
    final enquiriesAsync = ref.watch(filteredEnquiriesProvider);
    final filter = ref.watch(enquiryFilterProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Enquiry Tracker', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.surfaceWhite,
        foregroundColor: AppTheme.emeraldGreen,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            tooltip: 'Summary',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EnquirySummaryScreen()),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(filter),
          Expanded(
            child: enquiriesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (enquiries) {
                if (enquiries.isEmpty) {
                  return _buildEmptyState();
                }
                return RefreshIndicator(
                  color: const Color(0xFF0D1B2E),
                  onRefresh: () async => ref.invalidate(allEnquiriesProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: enquiries.length,
                    itemBuilder: (ctx, i) => _buildCard(enquiries[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: FloatingActionButton.extended(
          onPressed: () async {
            final created = await Navigator.push<bool>(
              context,
              MaterialPageRoute(builder: (_) => const AddEnquiryScreen()),
            );
            if (created == true) ref.invalidate(allEnquiriesProvider);
          },
          backgroundColor: AppTheme.emeraldGreen,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('New Enquiry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter(EnquiryFilter filter) {
    return Container(
      color: AppTheme.surfaceWhite,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: [
          TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search by client, ID, phone...',
              prefixIcon: const Icon(Icons.search, color: AppTheme.emeraldGreen),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchCtrl.clear();
                        ref.read(enquiryFilterProvider.notifier).state =
                            filter.copyWith(searchQuery: '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppTheme.backgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
            onChanged: (v) {
              ref.read(enquiryFilterProvider.notifier).state =
                  filter.copyWith(searchQuery: v);
            },
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip('All', filter.status == null, () {
                  ref.read(enquiryFilterProvider.notifier).state =
                      filter.copyWith(status: null);
                }),
                _filterChip('In Progress', filter.status == 'inProgress', () {
                  ref.read(enquiryFilterProvider.notifier).state =
                      filter.copyWith(status: 'inProgress');
                }),
                _filterChip('Settled', filter.status == 'settled', () {
                  ref.read(enquiryFilterProvider.notifier).state =
                      filter.copyWith(status: 'settled');
                }),
                _filterChip('Executed', filter.status == 'executed', () {
                  ref.read(enquiryFilterProvider.notifier).state =
                      filter.copyWith(status: 'executed');
                }),
                _filterChip('Rejected', filter.status == 'rejectedByClient', () {
                  ref.read(enquiryFilterProvider.notifier).state =
                      filter.copyWith(status: 'rejectedByClient');
                }),
                _filterChip('Cancelled', filter.status == 'cancelled', () {
                  ref.read(enquiryFilterProvider.notifier).state =
                      filter.copyWith(status: 'cancelled');
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? AppTheme.emeraldGreen : AppTheme.backgroundLight,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppTheme.darkBlue,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(Enquiry e) {
    final statusColor = _statusColor(e.finalStatus);
    final perfColor = _perfColor(e.performanceRating);
    final df = DateFormat('dd MMM yyyy');

    return GestureDetector(
      onTap: () async {
        final updated = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (_) => EnquiryDetailScreen(enquiry: e)),
        );
        if (updated == true) ref.invalidate(allEnquiriesProvider);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            // Header bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.emeraldGreen.withValues(alpha: 0.05),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Text(e.enquiryCode,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.emeraldGreen, fontSize: 13)),
                  const SizedBox(width: 8),
                  if (e.natureOfEnquiry != null)
                    Expanded(
                      child: Text(e.natureOfEnquiry!,
                          style: const TextStyle(fontSize: 12, color: AppTheme.darkBlue),
                          overflow: TextOverflow.ellipsis),
                    ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(_statusLabel(e.finalStatus),
                        style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            // Body
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(e.clientName ?? '—',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      ),
                      if (e.contactNumber != null) ...[
                        GestureDetector(
                          onTap: () => _openWhatsApp(e.contactNumber!, e),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF25D366).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.chat_outlined, size: 13, color: Color(0xFF25D366)),
                              const SizedBox(width: 4),
                              Text(e.contactNumber!, style: const TextStyle(fontSize: 12, color: Color(0xFF25D366), fontWeight: FontWeight.w600)),
                            ]),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _infoChip(Icons.calendar_today_outlined,
                          e.dateOfEnquiry != null ? df.format(e.dateOfEnquiry!) : '—'),
                      const SizedBox(width: 8),
                      _infoChip(Icons.timelapse_outlined, '${e.daysOpen} days'),
                      const SizedBox(width: 8),
                      if (e.nationality != null) _infoChip(Icons.flag_outlined, e.nationality!),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Total Offered', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        Text('SAR ${e.totalOffered.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.emeraldGreen)),
                      ]),
                      if (e.finalAgreedServiceCharge != null)
                        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          const Text('Agreed', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          Text('SAR ${e.finalAgreedServiceCharge!.toStringAsFixed(0)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.teal)),
                        ]),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: perfColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(children: [
                          Icon(Icons.star_rounded, size: 13, color: perfColor),
                          const SizedBox(width: 4),
                          Text(_perfLabel(e.performanceRating),
                              style: TextStyle(fontSize: 11, color: perfColor, fontWeight: FontWeight.bold)),
                        ]),
                      ),
                    ],
                  ),
                  if (e.responsibleStaffName != null) ...[
                    const SizedBox(height: 8),
                    Row(children: [
                      const Icon(Icons.badge_outlined, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(e.responsibleStaffName!,
                          style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ]),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(children: [
        Icon(icon, size: 12, color: Colors.grey),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.darkBlue)),
      ]),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text('No enquiries found', style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
        const SizedBox(height: 8),
        Text('Tap + to add the first enquiry', style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
      ]),
    );
  }
}
