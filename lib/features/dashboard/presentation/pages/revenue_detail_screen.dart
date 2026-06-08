import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/dashboard_provider.dart';
import '../../../../core/widgets/responsive_layout.dart';

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

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Revenue Analytics',
          style: TextStyle(color: AppTheme.darkBlue, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.darkBlue),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.emeraldGreen),
            onPressed: () => ref.refresh(financialStatsProvider),
          ),
        ],
      ),
      body: financialStats.when(
        data: (stats) => SingleChildScrollView(
          child: ResponsiveLayout(
            maxWidth: 1000,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTotalRevenueCard(stats['totalReceivables'] ?? 0),
                const SizedBox(height: 24),
                _buildPeriodSelector(),
                const SizedBox(height: 24),
                const Text(
                  'Revenue Breakdown',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.darkBlue),
                ),
                const SizedBox(height: 16),
                _buildRevenueChart(stats['totalReceivables'] ?? 0),
                const SizedBox(height: 24),
                const Text(
                  'Top Performing Branches',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.darkBlue),
                ),
                const SizedBox(height: 16),
                officesAsync.maybeWhen(
                  data: (offices) => _buildBranchList(offices),
                  orElse: () => const Center(child: CircularProgressIndicator()),
                ),
                const SizedBox(height: 24),
                _buildRecentTransactions(stats['auditLogs'] ?? []),
              ],
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

  Widget _buildPeriodSelector() {
    final periods = ['Month', 'Quarter', 'Year'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
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
                  color: isSelected ? AppTheme.emeraldGreen : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  periods[index],
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey,
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

  Widget _buildRevenueChart(double total) {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 20,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppTheme.darkBlue,
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
                  const style = TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 10);
                  String text;
                  switch (value.toInt()) {
                    case 0: text = 'W1'; break;
                    case 1: text = 'W2'; break;
                    case 2: text = 'W3'; break;
                    case 3: text = 'W4'; break;
                    default: text = '';
                  }
                  return SideTitleWidget(axisSide: meta.axisSide, child: Text(text, style: style));
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
            BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 8, color: AppTheme.emeraldGreen, width: 20, borderRadius: BorderRadius.circular(4))]),
            BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 12, color: AppTheme.emeraldGreen, width: 20, borderRadius: BorderRadius.circular(4))]),
            BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 15, color: AppTheme.emeraldGreen, width: 20, borderRadius: BorderRadius.circular(4))]),
            BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 10, color: AppTheme.emeraldGreen, width: 20, borderRadius: BorderRadius.circular(4))]),
          ],
        ),
      ),
    );
  }

  Widget _buildBranchList(List<Map<String, dynamic>> offices) {
    if (offices.isEmpty) return const Text('No branch data available');
    
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(office['name'] ?? 'Branch', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.darkBlue)),
                    Text(formatter.format(revenue), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.emeraldGreen)),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: workload / 100,
                  backgroundColor: Colors.grey.shade100,
                  color: AppTheme.emeraldGreen,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecentTransactions(List<dynamic> logs) {
    if (logs.isEmpty) return const Text('No recent receipts found');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Receipts',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.darkBlue),
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.emeraldGreen.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.receipt_long, color: AppTheme.emeraldGreen, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(log['user'] ?? 'Payment', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text(log['action'] ?? 'Unknown Action', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  Text(
                    DateFormat('MMM d').format(DateTime.parse(log['time'])), 
                    style: const TextStyle(color: Colors.grey, fontSize: 11)
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
