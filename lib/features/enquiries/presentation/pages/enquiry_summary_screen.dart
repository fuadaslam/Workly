import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/enquiry_provider.dart';
import 'package:service_manager_app/core/widgets/app_bar.dart';

class EnquirySummaryScreen extends ConsumerWidget {
  const EnquirySummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(enquirySummaryProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.backgroundLight,
      appBar: WorkqlyAppBar(
        title: 'Enquiry Summary',
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'Export Report',
            onPressed: () => context.push('/dashboard/reports/export'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(enquirySummaryProvider),
          ),
        ],
      ),
      body: summaryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (stats) => _buildBody(context, stats),
      ),
    );
  }

  Widget _buildBody(BuildContext context, Map<String, dynamic> stats) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total = stats['total'] as int;
    final accepted = stats['accepted'] as int;
    final rejected = stats['rejected'] as int;
    final settled = stats['settled'] as int;
    final inProgress = stats['inProgress'] as int;
    final convRate = stats['conversionRate'] as double;
    final avgDays = stats['avgDaysToSettle'] as double;
    final revenue = stats['totalRevenue'] as double;
    final byService = stats['byService'] as Map<String, int>;
    final byStaff = stats['byStaff'] as Map<String, Map<String, dynamic>>;

    return RefreshIndicator(
      color: AppTheme.ink900,
      onRefresh: () async {},
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero KPI cards
            _heroCard(total, accepted, rejected, convRate),
            const SizedBox(height: 16),

            // Status breakdown
            _sectionLabel('Status Breakdown'),
            Row(children: [
              Expanded(child: _kpiTile('Settled / Executed', '$settled', AppTheme.statusCompleted, Icons.check_circle_outline, isDark)),
              const SizedBox(width: 12),
              Expanded(child: _kpiTile('In Progress', '$inProgress', AppTheme.accentGold, Icons.timelapse_outlined, isDark)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _kpiTile('Avg. Days to Settle', '${avgDays.toStringAsFixed(1)} days', AppTheme.statusCompleted, Icons.schedule_outlined, isDark)),
              const SizedBox(width: 12),
              Expanded(child: _kpiTile('Total Revenue', 'SAR ${_fmt(revenue)}', AppTheme.emeraldGreen, Icons.payments_outlined, isDark)),
            ]),
            const SizedBox(height: 20),

            // By Staff
            if (byStaff.isNotEmpty) ...[
              _sectionLabel('Performance by Employee'),
              _card(_buildStaffTable(byStaff), isDark),
              const SizedBox(height: 20),
            ],

            // By Service
            if (byService.isNotEmpty) ...[
              _sectionLabel('Enquiries by Service Type'),
              _card(_buildServiceChart(byService, total, isDark), isDark),
              const SizedBox(height: 40),
            ],
          ],
        ),
      ),
    );
  }

  Widget _heroCard(int total, int accepted, int rejected, double convRate) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Overview', style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text('$total Total Enquiries',
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _heroStat('Accepted', '$accepted', AppTheme.statusCompleted),
              _heroStat('Rejected', '$rejected', Colors.redAccent),
              _heroStat('Conv. Rate', '${(convRate * 100).toStringAsFixed(1)}%', Colors.amberAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroStat(String label, String value, Color color) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
      const SizedBox(height: 2),
      Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
    ]);
  }

  Widget _sectionLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.darkBlue)),
  );

  Widget _card(Widget child, bool isDark) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: isDark ? AppTheme.darkCard : AppTheme.surfaceWhite,
      borderRadius: BorderRadius.circular(16),
      boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: child,
  );

  Widget _kpiTile(String label, String value, Color color, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ]),
    );
  }

  Widget _buildStaffTable(Map<String, Map<String, dynamic>> byStaff) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(children: [
          Expanded(flex: 3, child: Text('Staff Member', style: _hdr())),
          Expanded(child: Text('Cases', style: _hdr(), textAlign: TextAlign.center)),
          Expanded(child: Text('Settled', style: _hdr(), textAlign: TextAlign.center)),
          Expanded(flex: 2, child: Text('Avg Days', style: _hdr(), textAlign: TextAlign.center)),
        ]),
        const Divider(height: 16),
        ...byStaff.entries.map((entry) {
          final name = entry.key;
          final data = entry.value;
          final count = data['count'] as int;
          final settled = data['settled'] as int;
          final totalDays = data['totalDays'] as int;
          final avgDays = settled > 0 ? totalDays / settled : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              Expanded(flex: 3, child: Row(children: [
                CircleAvatar(radius: 14, backgroundColor: AppTheme.emeraldGreen,
                    child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
                const SizedBox(width: 8),
                Expanded(child: Text(name, overflow: TextOverflow.ellipsis)),
              ])),
              Expanded(child: Text('$count', textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold))),
              Expanded(child: Text('$settled', textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.statusCompleted, fontWeight: FontWeight.bold))),
              Expanded(flex: 2, child: Text(
                settled > 0 ? '${avgDays.toStringAsFixed(1)}d' : '—',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.statusCompleted),
              )),
            ]),
          );
        }),
      ],
    );
  }

  Widget _buildServiceChart(Map<String, int> byService, int total, bool isDark) {
    final sorted = byService.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final maxCount = sorted.isNotEmpty ? sorted.first.value : 1;

    return Column(
      children: sorted.map((entry) {
        final pct = total > 0 ? entry.value / total : 0.0;
        final barPct = maxCount > 0 ? entry.value / maxCount : 0.0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Expanded(child: Text(entry.key, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),
              Text('${entry.value}  (${(pct * 100).toStringAsFixed(0)}%)',
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ]),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: barPct,
                minHeight: 8,
                backgroundColor: isDark ? AppTheme.darkBorder : AppTheme.backgroundLight,
                valueColor: const AlwaysStoppedAnimation(AppTheme.emeraldGreen),
              ),
            ),
          ]),
        );
      }).toList(),
    );
  }

  TextStyle _hdr() => const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey);

  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}
