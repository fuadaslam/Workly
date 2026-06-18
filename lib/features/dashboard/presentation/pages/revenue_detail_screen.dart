import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/dashboard_provider.dart';
import '../../../../core/widgets/responsive_layout.dart';
import 'package:service_manager_app/core/widgets/app_bar.dart';

class RevenueDetailScreen extends ConsumerStatefulWidget {
  const RevenueDetailScreen({super.key});

  @override
  ConsumerState<RevenueDetailScreen> createState() => _RevenueDetailScreenState();
}

class _RevenueDetailScreenState extends ConsumerState<RevenueDetailScreen> {
  int _selectedPeriod = 0; // 0: Month, 1: Quarter, 2: Year

  @override
  Widget build(BuildContext context) {
    final financialStats = ref.watch(financialStatsProvider);
    final officesAsync = ref.watch(filteredOfficesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.backgroundLight,
      appBar: WorkqlyAppBar(
        title: 'Revenue Analytics',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.refresh(financialStatsProvider),
          ),
        ],
      ),
      body: financialStats.when(
        data: (stats) => SingleChildScrollView(
          child: ResponsiveLayout(
            maxWidth: double.infinity,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTotalRevenueCard(stats['totalReceivables'] ?? 0),
                const SizedBox(height: 24),
                _buildPeriodSelector(isDark),
                const SizedBox(height: 24),
                Text(
                  'Revenue Breakdown',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? AppTheme.darkOnSurface : AppTheme.darkBlue),
                ),
                const SizedBox(height: 16),
                _buildRevenueChart(stats['totalReceivables'] ?? 0, isDark),
                const SizedBox(height: 24),
                Text(
                  'Top Performing Branches',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? AppTheme.darkOnSurface : AppTheme.darkBlue),
                ),
                const SizedBox(height: 16),
                officesAsync.maybeWhen(
                  data: (offices) => _buildBranchList(offices, isDark),
                  orElse: () => const Center(child: CircularProgressIndicator()),
                ),
                const SizedBox(height: 24),
                _buildRecentTransactions(stats['auditLogs'] ?? [], isDark),
              ],
            ),
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildTotalRevenueCard(double total) {
    final formatter = NumberFormat.currency(symbol: 'SAR ', decimalDigits: 0);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.emeraldGreen, AppTheme.emeraldGreen.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.emeraldGreen.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Total Active Receivables',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            formatter.format(total),
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_upward, color: Colors.white, size: 16),
                SizedBox(width: 4),
                Text(
                  '+15.4% vs last period',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector(bool isDark) {
    final periods = ['Month', 'Quarter', 'Year'];
    final accent = AppTheme.primaryAccent(isDark);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: List.generate(periods.length, (index) {
          final isSelected = _selectedPeriod == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedPeriod = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  periods[index],
                  style: TextStyle(
                    color: isSelected ? (isDark ? AppTheme.ink900 : Colors.white) : (isDark ? AppTheme.darkSubtext : Colors.grey),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildRevenueChart(double total, bool isDark) {
    final accent = AppTheme.primaryAccent(isDark);
    final barBg = isDark ? AppTheme.darkBorder : Colors.grey.shade100;
    final labelStyle = TextStyle(color: isDark ? AppTheme.darkSubtext : Colors.grey, fontWeight: FontWeight.bold, fontSize: 10);
    return Container(
      height: 250,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 20,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => isDark ? AppTheme.darkCardAlt : AppTheme.darkBlue,
              tooltipRoundedRadius: 8,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                 return BarTooltipItem(
                    '${rod.toY.toInt()}M',
                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                 );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  String text;
                  switch (value.toInt()) {
                    case 0: text = 'W1'; break;
                    case 1: text = 'W2'; break;
                    case 2: text = 'W3'; break;
                    case 3: text = 'W4'; break;
                    default: text = '';
                  }
                  return SideTitleWidget(axisSide: meta.axisSide, child: Text(text, style: labelStyle));
                },
                reservedSize: 30,
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: [
            BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 8, color: accent, width: 40, borderRadius: BorderRadius.circular(6), backDrawRodData: BackgroundBarChartRodData(show: true, toY: 20, color: barBg))]),
            BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 12, color: accent, width: 40, borderRadius: BorderRadius.circular(6), backDrawRodData: BackgroundBarChartRodData(show: true, toY: 20, color: barBg))]),
            BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 15, color: accent, width: 40, borderRadius: BorderRadius.circular(6), backDrawRodData: BackgroundBarChartRodData(show: true, toY: 20, color: barBg))]),
            BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 10, color: accent, width: 40, borderRadius: BorderRadius.circular(6), backDrawRodData: BackgroundBarChartRodData(show: true, toY: 20, color: barBg))]),
          ],
        ),
      ),
    );
  }

  Widget _buildBranchList(List<Map<String, dynamic>> offices, bool isDark) {
    if (offices.isEmpty) return const Text('No branch data available');
    final accent = AppTheme.primaryAccent(isDark);

    return Column(
      children: offices.take(3).map((office) {
        final revenue = (office['revenue'] as num?)?.toDouble() ?? 0.0;
        final workload = (office['workload_percentage'] as num?)?.toDouble() ?? 0.0;
        final formatter = NumberFormat.currency(symbol: 'SAR ', decimalDigits: 0);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(office['name'] ?? 'Branch', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? AppTheme.darkOnSurface : AppTheme.darkBlue)),
                    Text(formatter.format(revenue), style: TextStyle(fontWeight: FontWeight.bold, color: accent)),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: workload / 100,
                    minHeight: 10,
                    backgroundColor: isDark ? AppTheme.darkBorder : Colors.grey.shade100,
                    color: accent,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecentTransactions(List<dynamic> logs, bool isDark) {
    if (logs.isEmpty) return const Text('No recent receipts found');
    final accent = AppTheme.primaryAccent(isDark);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Receipts',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? AppTheme.darkOnSurface : AppTheme.darkBlue),
        ),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: logs.length > 5 ? 5 : logs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final log = logs[index];
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.receipt_long, color: accent, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(log['user'] ?? 'Payment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? AppTheme.darkOnSurface : null)),
                        Text(log['action'] ?? 'Unknown Action', style: TextStyle(color: isDark ? AppTheme.darkSubtext : Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  Text(
                    DateFormat('MMM d').format(DateTime.parse(log['time'])),
                    style: TextStyle(color: isDark ? AppTheme.darkSubtext : Colors.grey, fontSize: 11)
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
