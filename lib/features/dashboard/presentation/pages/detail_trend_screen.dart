import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/dashboard_provider.dart';
import '../../../../core/widgets/responsive_layout.dart';
import 'package:service_manager_app/core/widgets/app_bar.dart';

class DetailTrendScreen extends ConsumerStatefulWidget {
  const DetailTrendScreen({super.key});

  @override
  ConsumerState<DetailTrendScreen> createState() => _DetailTrendScreenState();
}

class _DetailTrendScreenState extends ConsumerState<DetailTrendScreen> {
  int _selectedTimeRange = 1; // 0: 1W, 1: 1M, 2: 3M, 3: 1Y

  @override
  Widget build(BuildContext context) {
    final performanceAsync = ref.watch(staffPerformanceProvider);
    final financialStats = ref.watch(financialStatsProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: WorkqlyAppBar(
        title: 'Detailed Trends',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.invalidate(staffPerformanceProvider);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: ResponsiveLayout(
          maxWidth: 1000,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTimeRangeSelector(),
              const SizedBox(height: 24),
              _buildMainTrendChart(financialStats.value?['totalReceivables'] ?? 0.0),
              const SizedBox(height: 24),
              const Text(
                'Staff Performance Metrics',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkBlue,
                ),
              ),
              const SizedBox(height: 16),
              performanceAsync.when(
                data: (performance) => _buildPerformanceList(performance),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error: $e'),
              ),
              const SizedBox(height: 24),
              _buildServiceDistribution(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeRangeSelector() {
    final ranges = ['1W', '1M', '3M', '1Y'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(ranges.length, (index) {
          final isSelected = _selectedTimeRange == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTimeRange = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.emeraldGreen : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  ranges[index],
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

  Widget _buildMainTrendChart(double total) {
    final trendAsync = ref.watch(monthlyWorkOrderTrendProvider);

    final now = DateTime.now();
    final monthLabels = List.generate(6, (i) {
      final m = DateTime(now.year, now.month - 5 + i, 1);
      final abbr = const ['JAN','FEB','MAR','APR','MAY','JUN','JUL','AUG','SEP','OCT','NOV','DEC'];
      return abbr[(m.month - 1) % 12];
    });

    return trendAsync.when(
      loading: () => const SizedBox(height: 320, child: Center(child: CircularProgressIndicator(color: AppTheme.emeraldGreen))),
      error: (_, __) => const SizedBox(height: 60, child: Center(child: Text('No trend data', style: TextStyle(color: Colors.grey)))),
      data: (counts) {
        final maxVal = counts.isEmpty ? 5.0 : counts.reduce((a, b) => a > b ? a : b);
        final spots = counts.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList();

        String growthLabel;
        bool isUp = true;
        if (counts.length >= 2 && counts[counts.length - 2] > 0) {
          final g = (counts.last - counts[counts.length - 2]) / counts[counts.length - 2] * 100;
          isUp = g >= 0;
          growthLabel = '${g >= 0 ? '+' : ''}${g.toStringAsFixed(1)}%';
        } else {
          growthLabel = counts.isNotEmpty && counts.last > 0 ? 'New' : '—';
        }

        return Container(
          height: 320,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 5))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Operational Growth', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'SAR ${(total / 1000000).toStringAsFixed(1)}M',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.darkBlue),
                          ),
                          const SizedBox(width: 8),
                          Icon(isUp ? Icons.arrow_upward : Icons.arrow_downward, size: 16, color: isUp ? AppTheme.emeraldGreen : AppTheme.errorRed),
                          Text(growthLabel, style: TextStyle(color: isUp ? AppTheme.emeraldGreen : AppTheme.errorRed, fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppTheme.emeraldGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.show_chart, color: AppTheme.emeraldGreen),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Expanded(
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: maxVal > 0 ? (maxVal / 4).ceilToDouble() : 1,
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx < 0 || idx >= monthLabels.length) return const SizedBox.shrink();
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              child: Text(monthLabels[idx], style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 10)),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    minX: 0,
                    maxX: 5,
                    minY: 0,
                    maxY: maxVal > 0 ? maxVal * 1.2 : 5,
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        gradient: const LinearGradient(colors: [AppTheme.emeraldGreen, AppTheme.chartTeal]),
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [AppTheme.emeraldGreen.withValues(alpha: 0.2), AppTheme.emeraldGreen.withValues(alpha: 0.0)],
                            begin: Alignment.topCenter, end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPerformanceList(List<Map<String, dynamic>> performance) {
    if (performance.isEmpty) return const Text('No performance data recorded yet.');
    
    return Column(
      children: performance.map((p) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
          ),
          child: Row(
            children: [
               CircleAvatar(
                 backgroundColor: AppTheme.emeraldLight,
                 child: Text(p['name']?[0] ?? '?', style: const TextStyle(color: AppTheme.emeraldGreen, fontWeight: FontWeight.bold)),
               ),
               const SizedBox(width: 16),
               Expanded(
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Text(p['name'] ?? 'Staff', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                     Text('Avg Completion: ${p['avgCompletionTime']}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                   ],
                 ),
               ),
               Column(
                 crossAxisAlignment: CrossAxisAlignment.end,
                 children: [
                   Text(p['completedCount'].toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.emeraldGreen)),
                   const Text('TASKS', style: TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold)),
                 ],
               ),
            ],
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildServiceDistribution() {
    final kpiAsync = ref.watch(serviceTypeKpiProvider);
    final sectionColors = [AppTheme.emeraldGreen, AppTheme.statBlue, AppTheme.statAmber, AppTheme.statPurple];

    return kpiAsync.when(
      loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator(color: AppTheme.emeraldGreen))),
      error: (_, __) => const SizedBox.shrink(),
      data: (kpis) {
        if (kpis.isEmpty) {
          return const SizedBox(height: 60, child: Center(child: Text('No service data', style: TextStyle(color: Colors.grey))));
        }
        final totalOrders = kpis.fold<int>(0, (sum, k) => sum + (k['total'] as int));
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Operational Workload Distribution',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkBlue),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        startDegreeOffset: 180,
                        sections: kpis.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final kpi = entry.value;
                          final pct = totalOrders > 0 ? (kpi['total'] as int) / totalOrders * 100 : 0.0;
                          return PieChartSectionData(
                            color: sectionColors[idx % sectionColors.length],
                            value: pct,
                            title: '${pct.toStringAsFixed(0)}%',
                            radius: 50,
                            titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                          );
                        }).toList(),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('$totalOrders', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkBlue)),
                        const Text('Total', style: TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ...kpis.asMap().entries.map((entry) {
                final idx = entry.key;
                final kpi = entry.value;
                return _buildLegendItem(kpi['fullLabel'] as String, sectionColors[idx % sectionColors.length]);
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegendItem(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}
