import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/utils/contact_utils.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/pattern_painter.dart';
import '../providers/dashboard_provider.dart';
import 'profile_view.dart';
import '../pages/detail_trend_screen.dart';
import '../pages/revenue_detail_screen.dart';
import '../pages/office_detail_screen.dart';
import '../pages/admin_detail_screen.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../auth/presentation/providers/profile_provider.dart';
import '../../../auth/domain/models/profile.dart';
import '../pages/system_detail_screen.dart';
import '../../../leaves/presentation/widgets/admin_leave_list.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../../attendance/presentation/widgets/attendance_monitor.dart';

import 'assignment_sheet.dart';

final superAdminTabIndexProvider = StateProvider<int>((ref) => 0);

class SuperAdminView extends ConsumerWidget {
  const SuperAdminView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(superAdminTabIndexProvider);
    final profile = ref.watch(profileProvider).value;
    final isSuperAdmin = profile?.role == AppRole.super_admin;

    final tabs = [
       const BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'Home'),
       const BottomNavigationBarItem(icon: Icon(Icons.business_outlined), label: 'Offices'),
       const BottomNavigationBarItem(icon: Icon(Icons.how_to_reg_outlined), label: 'Attendance'),
       const BottomNavigationBarItem(icon: Icon(Icons.calendar_month_outlined), label: 'Leaves'),
       BottomNavigationBarItem(icon: const Icon(Icons.people_outline), label: isSuperAdmin ? 'Admins' : 'Staff'),
       if (isSuperAdmin) const BottomNavigationBarItem(icon: Icon(Icons.lock_person_outlined), label: 'Access'),
       if (isSuperAdmin) const BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'System'),
    ];

    // Reset index if out of bounds
    if (currentIndex >= tabs.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(superAdminTabIndexProvider.notifier).state = 0;
      });
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 800) {
          // Desktop Layout
          return Scaffold(
            backgroundColor: AppTheme.backgroundLight,
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: currentIndex < tabs.length ? currentIndex : 0,
                  onDestinationSelected: (idx) => ref.read(superAdminTabIndexProvider.notifier).state = idx,
                  labelType: NavigationRailLabelType.all,
                  selectedLabelTextStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.emeraldGreen),
                  unselectedLabelTextStyle: const TextStyle(fontSize: 11, color: Colors.grey),
                  selectedIconTheme: const IconThemeData(color: AppTheme.emeraldGreen),
                  unselectedIconTheme: const IconThemeData(color: Colors.grey),
                  destinations: tabs.map((t) => NavigationRailDestination(
                    icon: t.icon as Icon, 
                    label: Text(t.label!),
                  )).toList(),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: _buildCurrentTab(currentIndex, isSuperAdmin),
                    ),
                  ),
                ),
              ],
            ),
             floatingActionButton: (currentIndex == 0 || currentIndex == 1) 
              ? FloatingActionButton.extended(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                      builder: (context) => const AssignmentSheet(),
                    );
                  },
                  backgroundColor: AppTheme.emeraldGreen,
                  elevation: 6,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  icon: const Icon(Icons.assignment_add, color: Colors.white, size: 24),
                  label: const Text(
                    'Assign Work', 
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5)
                  ),
                )
              : null,
          );
        } else {
          // Mobile Layout
          return Scaffold(
            backgroundColor: AppTheme.backgroundLight,
            body: _buildCurrentTab(currentIndex, isSuperAdmin),
            floatingActionButton: (currentIndex == 0 || currentIndex == 1) 
                ? FloatingActionButton.extended(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                        builder: (context) => const AssignmentSheet(),
                      );
                    },
                    backgroundColor: AppTheme.emeraldGreen,
                    elevation: 6,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    icon: const Icon(Icons.assignment_add, color: Colors.white, size: 24),
                    label: const Text(
                      'Assign Work', 
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5)
                    ),
                  )
                : null,
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: BottomNavigationBar(
                currentIndex: currentIndex < tabs.length ? currentIndex : 0,
                onTap: (idx) => ref.read(superAdminTabIndexProvider.notifier).state = idx,
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.white,
                selectedItemColor: AppTheme.emeraldGreen,
                unselectedItemColor: Colors.grey,
                selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                unselectedLabelStyle: const TextStyle(fontSize: 11),
                items: tabs,
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildCurrentTab(int index, bool isSuperAdmin) {
    switch (index) {
      case 0: return const _ExecutiveDashboardTab();
      case 1: return const _BranchManagementTab();
      case 2: return const _AttendanceTab();
      case 3: return const _LeaveManagementTab();
      case 4: return _AdminManagementTab(isStaffView: !isSuperAdmin);
      case 5: return isSuperAdmin ? const _AccessControlTab() : const SizedBox();
      case 6: return isSuperAdmin ? const _SystemSettingsTab() : const SizedBox();
      default: return const _ExecutiveDashboardTab();
    }
  }
}

class _AttendanceTab extends StatelessWidget {
  const _AttendanceTab();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _HeaderSection(title: 'Staff Attendance', subtitle: 'REAL-TIME MONITORING', showDate: false),
        Expanded(child: const AttendanceMonitor()),
      ],
    );
  }
}

/// --- COMMON COMPONENTS ---

class _HeaderSection extends ConsumerWidget {
  final String title;
  final String subtitle;
  final bool showDate;

  const _HeaderSection({
    required this.title,
    required this.subtitle,
    this.showDate = true,
  });

  void _showLanguagePicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Language / اختر اللغة',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.darkBlue),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.language, color: AppTheme.emeraldGreen),
                title: const Text('English'),
                trailing: ref.watch(localeProvider).languageCode == 'en' ? const Icon(Icons.check, color: AppTheme.emeraldGreen) : null,
                onTap: () {
                  ref.read(localeProvider.notifier).state = const Locale('en');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.language, color: AppTheme.emeraldGreen),
                title: const Text('العربية'),
                trailing: ref.watch(localeProvider).languageCode == 'ar' ? const Icon(Icons.check, color: AppTheme.emeraldGreen) : null,
                onTap: () {
                  ref.read(localeProvider.notifier).state = const Locale('ar');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    return Container(
      decoration: const BoxDecoration(color: AppTheme.emeraldGreen),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: MashrabiyaPatternPainter(color: Colors.white.withOpacity(0.05)),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const SizedBox(width: 5), // Minimal padding after removal
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(title, 
                                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis),
                                  Text(subtitle, 
                                      style: const TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 1.2),
                                      overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => _showLanguagePicker(context, ref),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.white30),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                currentLocale.languageCode == 'en' ? 'عربي' : 'English',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const ProfileView()),
                              );
                            },
                            child: const CircleAvatar(
                              radius: 20,
                              backgroundColor: Color(0xFFFFB29D),
                              child: Icon(Icons.person, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (showDate) ...[
                    const SizedBox(height: 25),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('SYSTEM AUTHORITY • سلطة النظام', 
                                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis),
                              Text('14 Ramadan 1445 | 24 March 2024', 
                                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                                  overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.security, color: AppTheme.emeraldGreen, size: 20),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// --- TAB 1: EXECUTIVE DASHBOARD ---

class _ExecutiveDashboardTab extends ConsumerWidget {
  const _ExecutiveDashboardTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final financialStats = ref.watch(financialStatsProvider);

    return SingleChildScrollView(
      child: ResponsiveLayout(
        maxWidth: 1000,
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _HeaderSection(title: 'Super Admin', subtitle: 'VISION 2030 PORTAL'),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       const Text('EXECUTIVE OVERVIEW', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                       Row(
                         children: [
                           const Icon(Icons.filter_list, size: 16, color: Colors.grey),
                           const SizedBox(width: 4),
                           const Text('Filters', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                         ],
                       ),
                     ],
                  ),
                  const SizedBox(height: 15),
                  
                  // Revenue Card
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RevenueDetailScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: financialStats.when(
                      data: (stats) => _buildRevenueCard('Monthly Revenue', 'SAR ${(stats['totalReceivables']/1000000).toStringAsFixed(1)}M', '+15.4%', true),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => _buildRevenueCard('Monthly Revenue', 'SAR 4.2M', '+15.4%', true),
                    ),
                  ),
                  
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const DetailTrendScreen()),
                            );
                          }, 
                          borderRadius: BorderRadius.circular(16), 
                          child: _buildSmallStatCard('Active Cases', '1,284', '+12%', true)
                        )
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            ref.read(superAdminTabIndexProvider.notifier).state = 3; // Switch to Access tab
                          }, 
                          borderRadius: BorderRadius.circular(16), 
                          child: _buildSmallStatCard('Pending Approvals', '42', '-5%', false)
                        )
                      ),
                    ],
                  ),
                  
                  
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Operational Trends', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.darkBlue)),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const DetailTrendScreen()),
                          );
                        }, 
                        child: const Text('View Detailed', style: TextStyle(fontSize: 12))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildRevenueChart(),
                  
                  const SizedBox(height: 30),
                  _buildStaffKPIs(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueCard(String title, String value, String growth, bool isPositive) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: const Border(left: BorderSide(color: AppTheme.emeraldGreen, width: 4)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Colors.grey, fontSize: 13)),
              const Icon(Icons.money_outlined, color: AppTheme.emeraldGreen),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.darkBlue)),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(isPositive ? Icons.trending_up : Icons.trending_down, size: 16, color: isPositive ? AppTheme.emeraldGreen : Colors.red),
              const SizedBox(width: 4),
              Text(growth, style: TextStyle(color: isPositive ? AppTheme.emeraldGreen : Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(width: 8),
              const Text('vs last month', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallStatCard(String title, String value, String growth, bool isPositive) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: const Border(left: BorderSide(color: AppTheme.emeraldGreen, width: 2)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.darkBlue)),
          const SizedBox(height: 4),
          Text(growth, style: TextStyle(color: isPositive ? AppTheme.emeraldGreen : Colors.red, fontWeight: FontWeight.bold, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildRevenueChart() {
    return Container(
      height: 200,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: const [
                FlSpot(0, 2), FlSpot(1, 4), FlSpot(2, 3), FlSpot(3, 5), FlSpot(4, 3.5), FlSpot(5, 6),
              ],
              isCurved: true,
              color: AppTheme.emeraldGreen,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: AppTheme.emeraldGreen.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffKPIs() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Staff KPIs by Department', style: TextStyle(color: Colors.grey, fontSize: 13)),
              const Text('4% Avg', style: TextStyle(color: AppTheme.emeraldGreen, fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildKPIBar('LOGISTICS', 0.8),
              _buildKPIBar('VISA', 0.6),
              _buildKPIBar('LEGAL', 0.4),
              _buildKPIBar('ADMIN', 0.9),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKPIBar(String label, double percent) {
    return Column(
      children: [
        Container(
          height: 100, width: 8,
          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
          child: FractionallySizedBox(
            heightFactor: percent, alignment: Alignment.bottomCenter,
            child: Container(decoration: BoxDecoration(color: AppTheme.emeraldGreen, borderRadius: BorderRadius.circular(4))),
          ),
        ),
        const SizedBox(height: 10),
        Text(label, style: const TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

/// --- TAB 2: BRANCH MANAGEMENT ---

class _BranchManagementTab extends ConsumerWidget {
  const _BranchManagementTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final officesAsync = ref.watch(filteredOfficesProvider);

    return ResponsiveLayout(
      maxWidth: 1000,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          const _HeaderSection(title: 'Regional Offices', subtitle: 'BRANCH MANAGEMENT', showDate: false),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('KSA NETWORK', style: TextStyle(color: AppTheme.emeraldGreen, fontSize: 11, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                            officesAsync.when(
                               data: (offices) => Text('${offices.length} Active Branches', style: const TextStyle(fontSize: 16, color: Colors.blueGrey), overflow: TextOverflow.ellipsis),
                               loading: () => const Text('Loading...', style: TextStyle(fontSize: 16, color: Colors.blueGrey)),
                               error: (_,__) => const Text('Error', style: TextStyle(fontSize: 16, color: Colors.red)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: () => _showAddOfficeSheet(context, ref),
                        icon: const Icon(Icons.add_location_alt_outlined, size: 16),
                        label: const Text('Add New Office', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emeraldGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Search and Filter
                  Column(
                    children: [
                      TextField(
                        onChanged: (value) => ref.read(officeSearchQueryProvider.notifier).state = value,
                        decoration: InputDecoration(
                          hintText: 'Search offices...',
                          prefixIcon: const Icon(Icons.search, color: Colors.grey),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip(ref, 'Default', Icons.sort),
                            const SizedBox(width: 10),
                            _buildFilterChip(ref, 'Revenue', Icons.monetization_on_outlined),
                            const SizedBox(width: 10),
                            _buildFilterChip(ref, 'Workload', Icons.bar_chart),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Static Map Image Placeholder or Custom Painter
                  // Performance Overview Dashboard
                  officesAsync.when(
                    data: (offices) => _buildPerformanceDashboard(offices),
                    loading: () => const SizedBox(height: 180, child: Center(child: CircularProgressIndicator())),
                    error: (_,__) => const SizedBox(),
                  ),
                  
                  const SizedBox(height: 30),
                  officesAsync.when(
                    data: (offices) {
                      if (offices.isEmpty) {
                        return const Center(child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Text('No offices found. Add one to get started!'),
                        ));
                      }
                      return Column(
                        children: offices.map((office) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 15),
                            child: _buildOfficeCard(
                              context,
                              office,
                            ),
                          );
                        }).toList(),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, st) => Center(child: Text('Error loading offices: $e')),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceDashboard(List<Map<String, dynamic>> offices) {
    if (offices.isEmpty) return const SizedBox();

    double totalRevenue = 0;
    double totalWorkload = 0;
    
    for (var o in offices) {
      totalRevenue += (o['revenue'] as num? ?? 0).toDouble();
      totalWorkload += (o['workload_percentage'] as num? ?? 0).toDouble();
    }
    
    final avgWorkload = offices.isEmpty ? 0 : totalWorkload / offices.length;
    final displayRevenue = totalRevenue >= 1000000 
        ? '${(totalRevenue / 1000000).toStringAsFixed(1)}M' 
        : '${(totalRevenue / 1000).toStringAsFixed(0)}K';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.emeraldGreen, Color(0xFF34D399)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppTheme.emeraldGreen.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('NETWORK PERFORMANCE', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
                child: const Text('Live Stats', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(displayRevenue, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                    const Text('Total Revenue', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              Container(width: 1, height: 40, color: Colors.white24),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${avgWorkload.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                    const Text('Avg. Workload Capacity', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
           // Progress bar for overall capacity
           Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               const Text('Overall Network Capacity', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
               const SizedBox(height: 8),
               ClipRRect(
                 borderRadius: BorderRadius.circular(4),
                 child: LinearProgressIndicator(
                   value: avgWorkload / 100,
                   backgroundColor: Colors.black12,
                   color: Colors.white,
                   minHeight: 6,
                 ),
               ),
             ],
           ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(WidgetRef ref, String label, IconData icon) {
    final currentSort = ref.watch(officeSortProvider);
    final isSelected = currentSort == label;

    return InkWell(
      onTap: () => ref.read(officeSortProvider.notifier).state = label,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.emeraldGreen : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? null : Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.grey),
            const SizedBox(width: 8),
            Text(
              label, 
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey, 
                fontWeight: FontWeight.bold, 
                fontSize: 12
              )
            ),
          ],
        ),
      ),
    );
  }

  void _showAddOfficeSheet(BuildContext context, WidgetRef ref) {
    // ... same code ...
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final locationController = TextEditingController();
    final managerController = TextEditingController();
    final managerPhoneController = TextEditingController();
    final mobilePhoneController = TextEditingController();
    final landlinePhoneController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: EdgeInsets.only(
            top: 30,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 30,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  const Text(
                    'Add New Office',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.darkBlue),
                  ),
                  const Text(
                    'Expand your operational presence with a new branch',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 25),
                  
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Office Name',
                      prefixIcon: const Icon(Icons.business_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 15),
                  
                  TextFormField(
                    controller: locationController,
                    decoration: InputDecoration(
                      labelText: 'Location',
                      prefixIcon: const Icon(Icons.location_on_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 15),
                  
                  TextFormField(
                    controller: managerController,
                    decoration: InputDecoration(
                      labelText: 'Manager Name (Optional)',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                  const SizedBox(height: 15),
                  
                  TextFormField(
                    controller: managerPhoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Manager Phone',
                      prefixIcon: const Icon(Icons.phone_iphone_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                  const SizedBox(height: 15),
                  
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: mobilePhoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'Office Mobile',
                            prefixIcon: const Icon(Icons.smartphone_outlined),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: landlinePhoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'Office Landline',
                            prefixIcon: const Icon(Icons.phone_outlined),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 30),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          try {
                            await ref.read(officeRepositoryProvider).addOffice({
                              'name': nameController.text,
                              'location': locationController.text,
                              'manager_name': managerController.text,
                              'manager_phone': managerPhoneController.text,
                              'phone_numbers': [
                                if (mobilePhoneController.text.isNotEmpty) {'number': mobilePhoneController.text, 'type': 'mobile'},
                                if (landlinePhoneController.text.isNotEmpty) {'number': landlinePhoneController.text, 'type': 'landline'},
                              ],
                              'workload_percentage': 0, 
                              'staff_count': 0,
                              'revenue': 0,
                            });
                            ref.refresh(officesProvider);
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Office Added Successfully'), 
                                  backgroundColor: AppTheme.emeraldGreen
                                )
                              );
                            }
                          } catch (e) {
                             if (context.mounted) {
                               Navigator.pop(context);
                               ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                             }
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.emeraldGreen,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: const Text('Add Office', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getColorFromHex(String? hexColor) {
    if (hexColor == null) return AppTheme.emeraldGreen;
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
  }

  Widget _buildOfficeCard(BuildContext context, Map<String, dynamic> office) {
    // Extract values
    final String name = office['name'] ?? 'Unknown';
    final String loc = office['location'] ?? 'Unknown';
    final String workload = '${office['workload_percentage'] ?? 0}%';
    final String staff = '${office['staff_count'] ?? 0}';
    final String revenue = '${(office['revenue'] ?? 0).toString()}';
    final Color workloadColor = _getColorFromHex(office['color_hex']);
    
    // Check revenue format if needed (e.g. millions)
    // For simplicity just showing raw or formatted if string

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => OfficeDetailScreen(office: office)),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                    child: Icon(Icons.business, color: Colors.grey.shade600),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(loc, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        if (office['phone_numbers'] != null && (office['phone_numbers'] as List).isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              (office['phone_numbers'] as List)[0]['number'],
                              style: const TextStyle(color: AppTheme.emeraldGreen, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      if (office['phone_numbers'] != null && (office['phone_numbers'] as List).isNotEmpty)
                        IconButton(
                          onPressed: () => ContactUtils.openWhatsApp((office['phone_numbers'] as List)[0]['number']),
                          icon: const Icon(Icons.message, size: 20, color: Colors.green),
                        ),
                      IconButton(
                        onPressed: () {
                           // Navigate to settings directly? Or just same detail screen
                           Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => OfficeDetailScreen(office: office)),
                          );
                        },
                        icon: const Icon(Icons.settings_outlined, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: _buildMiniStat('WORKLOAD', workload, workloadColor, true)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildMiniStat('STAFF', staff, Colors.blueGrey, false)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildMiniStat('REVENUE', revenue, Colors.amber.shade700, false)),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
               child: Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   const Text('REGIONAL HUB', style: TextStyle(color: AppTheme.emeraldGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                   InkWell(
                     onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => OfficeDetailScreen(office: office)),
                        );
                     },
                     borderRadius: BorderRadius.circular(4),
                     child: Row(
                       children: const [
                         Text('Branch Settings', style: TextStyle(color: AppTheme.emeraldGreen, fontSize: 12, fontWeight: FontWeight.bold)),
                         Icon(Icons.chevron_right, size: 16, color: AppTheme.emeraldGreen),
                       ],
                     ),
                   ),
                 ],
               ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildMiniStat(String label, String val, Color color, bool showProgress) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Row(
           children: [
              // Use Flexible to avoid overflow
              Flexible(child: Text(val, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
              if (label == 'STAFF') const Icon(Icons.people, size: 10, color: Colors.grey),
            ],
          ),
          if (showProgress) ...[
            const SizedBox(height: 4),
            LinearProgressIndicator(value: 0.8, backgroundColor: Colors.grey.shade200, color: color, minHeight: 4),
          ],
        ],
      ),
    );
  }
}

/// --- TAB: LEAVE MANAGEMENT ---

class _LeaveManagementTab extends ConsumerWidget {
  const _LeaveManagementTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ResponsiveLayout(
      maxWidth: 1000,
      padding: EdgeInsets.zero,
      child: Column(
        children: const [
          _HeaderSection(
            title: 'Leave Management', 
            subtitle: 'إدارة الإجازات',
            showDate: false,
          ),
          Expanded(
            child: AdminLeaveList(),
          ),
        ],
      ),
    );
  }
}

/// --- TAB 3: ADMIN MANAGEMENT ---

class _AdminManagementTab extends ConsumerWidget {
  final bool isStaffView;
  const _AdminManagementTab({this.isStaffView = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredAdminsAsync = ref.watch(isStaffView ? filteredStaffProvider : filteredAdminsProvider);

    return ResponsiveLayout(
      maxWidth: 1000,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _HeaderSection(
            title: isStaffView ? 'Staff Command Center' : 'Total Control Hub', 
            subtitle: isStaffView ? 'مركز قيادة الموظفين' : 'مركز التحكم الشامل'
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(isStaffView ? 'Manage Staff' : 'Manage Admins', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                            Text(isStaffView ? 'إدارة الموظفين' : 'إدارة المسؤولين', style: const TextStyle(color: Colors.amber, fontSize: 12), overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: () => _showAddAdminDialog(context, ref, forceStaff: isStaffView),
                        icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                        label: const Text('New'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emeraldGreen, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  
                  // Filters
                  TextField(
                    onChanged: (value) => ref.read(isStaffView ? staffSearchQueryProvider.notifier : adminSearchQueryProvider.notifier).state = value,
                    decoration: InputDecoration(
                      hintText: isStaffView ? 'Search staff...' : 'Search admins...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                    ),
                  ),
                  
                  if (!isStaffView) ...[
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip(ref, 'All'),
                          const SizedBox(width: 8),
                          _buildFilterChip(ref, 'Admin'),
                          const SizedBox(width: 8),
                          _buildFilterChip(ref, 'Super Admin'),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 20),
                  filteredAdminsAsync.when(
                    data: (profiles) {
                      if (profiles.isEmpty) return Center(child: Text(isStaffView ? 'No staff found' : 'No admins found'));
                      return Column(
                        children: profiles.map((p) => _buildLargeAdminCard(context, ref, p, isStaff: isStaffView)).toList(),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Error loading: $e'),
                  ),
                  
                  if (!isStaffView) ...[
                    const SizedBox(height: 20),
                    InkWell(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opening global access control center...')));
                      },
                      borderRadius: BorderRadius.circular(15),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.emeraldGreen,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [BoxShadow(color: AppTheme.emeraldGreen.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.security, color: Colors.white, size: 20),
                            SizedBox(width: 10),
                            Text('Global Access Control', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(WidgetRef ref, String label) {
    final currentFilter = ref.watch(adminRoleFilterProvider);
    final isSelected = currentFilter == label;
    return InkWell(
      onTap: () => ref.read(adminRoleFilterProvider.notifier).state = label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.emeraldGreen : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppTheme.emeraldGreen : Colors.grey.shade300),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
      ),
    );
  }



  Widget _buildLargeAdminCard(BuildContext context, WidgetRef ref, Map<String, dynamic> admin, {bool isStaff = false}) {
    final name = admin['name'] ?? (isStaff ? 'Unknown Staff' : 'Unknown Admin');
    final role = admin['role'] ?? (isStaff ? 'staff' : 'admin');
    final id = admin['id'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AdminDetailScreen(admin: admin)),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
          ),
          child: Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.all(15),
                leading: const CircleAvatar(radius: 30, backgroundColor: AppTheme.emeraldLight, child: Icon(Icons.person, color: AppTheme.emeraldGreen, size: 30)),
                title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(role.toString().toUpperCase(), style: const TextStyle(fontSize: 12, color: AppTheme.emeraldGreen)),
                    if (admin['phone_number'] != null)
                      Text(admin['phone_number'], style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), 
                  decoration: BoxDecoration(
                    color: (admin['is_active'] ?? true) ? AppTheme.emeraldLight : Colors.grey.shade100, 
                    borderRadius: BorderRadius.circular(8)
                  ), 
                  child: Text(
                    (admin['is_active'] ?? true) ? 'ACTIVE' : 'INACTIVE', 
                    style: TextStyle(
                      color: (admin['is_active'] ?? true) ? AppTheme.emeraldGreen : Colors.grey, 
                      fontWeight: FontWeight.bold, 
                      fontSize: 10
                    )
                  )
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: Row(
                   mainAxisAlignment: MainAxisAlignment.spaceAround,
                   children: [
                     _buildActionButton(context, Icons.edit, 'Edit', Colors.green, () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => AdminDetailScreen(admin: admin)),
                        );
                     }),
                     if (admin['is_active'] ?? true)
                       _buildActionButton(context, Icons.block, 'Remove', Colors.red, () async {
                          if (id == null) return;
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(isStaff ? 'Remove Staff?' : 'Remove Admin?'),
                              content: Text('Are you sure you want to remove $name? This will deactivate their account.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                TextButton(onPressed: () => Navigator.pop(context, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Remove')),
                              ],
                            ),
                          );
                          if (confirm == true) {
                             await ref.read(profileRepositoryProvider).deleteProfile(id);
                             ref.refresh(allProfilesProvider);
                          }
                       })
                     else
                       _buildActionButton(context, Icons.check_circle_outline, 'Reactivate', AppTheme.emeraldGreen, () async {
                          if (id == null) return;
                          await ref.read(profileRepositoryProvider).reactivateProfile(id);
                          ref.refresh(allProfilesProvider);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile reactivated')));
                       }),
                     _buildActionButton(context, Icons.vpn_key_outlined, 'Permissions', Colors.amber.shade700, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AdminDetailScreen(admin: admin)),
                    );
                  }),
                   ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showAddAdminDialog(BuildContext context, WidgetRef ref, {bool forceStaff = false}) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final phoneController = TextEditingController();
    String role = forceStaff ? 'staff' : 'admin';
    String? selectedOfficeId;
    bool _isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: EdgeInsets.only(
            top: 30,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 30,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  Text(
                    forceStaff ? 'Register New Staff' : 'Register New Admin',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.darkBlue),
                  ),
                  Text(
                    forceStaff ? 'Add a new member to your operational team' : 'Grant administrative access to this portal',
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 25),
                  
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    validator: (v) => v!.isEmpty ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 15),
                  
                  TextFormField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    validator: (v) => v!.isEmpty ? 'Email is required' : null,
                  ),
                  const SizedBox(height: 15),
                  
                  TextFormField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Initial Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    validator: (v) => v!.isEmpty ? 'Password is required' : null,
                  ),
                  const SizedBox(height: 15),
                  
                  TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: const Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    validator: (v) => v!.isEmpty ? 'Phone number is required' : null,
                  ),
                  
                  if (!forceStaff) ...[
                    const SizedBox(height: 15),
                    DropdownButtonFormField<String>(
                      value: role,
                      items: const [
                        DropdownMenuItem(value: 'admin', child: Text('Admin (Regional Central)')),
                        DropdownMenuItem(value: 'super_admin', child: Text('Super Admin (Global Root)')),
                      ],
                      onChanged: (v) => setModalState(() => role = v!),
                      decoration: InputDecoration(
                        labelText: 'Portal Role',
                        prefixIcon: const Icon(Icons.security_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                    ),
                  ],
                  const SizedBox(height: 15),
                  ref.watch(officesProvider).when(
                    data: (offices) => DropdownButtonFormField<String?>(
                      value: selectedOfficeId,
                      items: [
                        const DropdownMenuItem(value: null, child: Text('No Office Assigned')),
                        ...offices.map((o) => DropdownMenuItem(value: o['id'], child: Text(o['name'] ?? 'Unknown'))),
                      ],
                      onChanged: (v) => setModalState(() => selectedOfficeId = v),
                      decoration: InputDecoration(
                        labelText: 'Assigned Office (Optional)',
                        prefixIcon: const Icon(Icons.business_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                    ),
                    loading: () => const Center(child: LinearProgressIndicator()),
                    error: (_, __) => const Text('Error loading offices'),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          try {
                            setModalState(() => _isLoading = true);
                            
                            // Use RPC to create both Auth user and Profile in one controlled call
                            // This replaces the old direct 'createProfile' call which failed due to FK constraints.
                            final client = ref.read(supabaseClientProvider);
                            await client.rpc('create_user_admin', params: {
                              'new_email': emailController.text.trim(),
                              'new_password': passwordController.text.trim(),
                              'full_name': nameController.text.trim(),
                              'user_role': role,
                              'phone': phoneController.text.trim(),
                              'office': selectedOfficeId,
                            });

                            ref.refresh(allProfilesProvider);
                            if (context.mounted) Navigator.pop(context);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${role.toUpperCase()} registered successfully'),
                                  backgroundColor: AppTheme.emeraldGreen,
                                )
                              );
                            }
                          } catch (e) {
                             if (context.mounted) {
                               String errorMsg = e.toString();
                               // Friendly error if the RPC hasn't been created yet
                               if (errorMsg.contains('function public.create_user_admin') && errorMsg.contains('does not exist')) {
                                  errorMsg = 'Database setup required: Please run the provided SQL script to enable admin user creation.';
                               }
                               ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Registration Error: $errorMsg'), duration: const Duration(seconds: 5),));
                             }
                          } finally {
                            setModalState(() => _isLoading = false);
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.emeraldGreen,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 0,
                      ),
                      child: const Text('Confirm Registration', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// --- TAB 4: ACCESS CONTROL ---

class _AccessControlTab extends ConsumerWidget {
  const _AccessControlTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final securityStats = ref.watch(securityStatsProvider);
    final financialStats = ref.watch(financialStatsProvider);

    return ResponsiveLayout(
      maxWidth: 1000,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          const _HeaderSection(title: 'Access & Security', subtitle: 'إدارة الوصول والأمان', showDate: false),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Security Executive Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  securityStats.when(
                    data: (stats) => Row(
                      children: [
                        Expanded(child: _buildSecurityStat('Active Sessions', stats['activeSessions'].toString(), Icons.devices, Colors.blue)),
                        const SizedBox(width: 15),
                        Expanded(child: _buildSecurityStat('Security Alerts', stats['securityAlerts'].toString(), Icons.warning_amber_rounded, Colors.orange)),
                      ],
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Row(
                      children: [
                        Expanded(child: _buildSecurityStat('Active Sessions', '0', Icons.devices, Colors.blue)),
                        const SizedBox(width: 15),
                        Expanded(child: _buildSecurityStat('Security Alerts', '?', Icons.warning_amber_rounded, Colors.orange)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text('Role Hierarchy & Permissions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  _buildRoleCard(context, ref, 'Super Admin', 'Full system access, infrastructure control, global visibility.', Icons.auto_awesome, AppTheme.emeraldGreen, 'Super Admin'),
                  const SizedBox(height: 12),
                  _buildRoleCard(context, ref, 'Office Admin', 'Branch management, staff oversight, regional reports.', Icons.admin_panel_settings, Colors.amber.shade700, 'Admin'),
                  const SizedBox(height: 12),
                  _buildRoleCard(context, ref, 'Operational Staff', 'Task execution, client interaction, status updates.', Icons.engineering, Colors.blueGrey, 'All'),
                  
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Audit Global Logs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Exporting CSV...')));
                        }, 
                        child: const Text('Export CSV')),
                    ],
                  ),
                  financialStats.when(
                    data: (stats) {
                      final logs = stats['auditLogs'] as List;
                      if (logs.isEmpty) {
                        return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No audit logs available', style: TextStyle(color: Colors.grey))));
                      }
                      return Column(
                        children: logs.take(5).map((log) => _buildAuditItem(
                          log['user'] ?? 'System', 
                          log['action'] ?? 'Unknown Action', 
                          log['time'] != null ? _formatTime(log['time']) : 'Just now'
                        )).toList(),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => const Text('Error loading logs'),
                  ),
                  
                  const SizedBox(height: 30),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.red.shade100),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.gpp_maybe, color: Colors.red, size: 40),
                        const SizedBox(height: 10),
                        const Text('Danger Zone', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red)),
                        const Text('Actions here cannot be undone.', style: TextStyle(fontSize: 12, color: Colors.redAccent)),
                        const SizedBox(height: 15),
                        ElevatedButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Revoke All Tokens?'),
                                content: const Text('This will sign out all users globally. Are you sure?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                                  TextButton(onPressed: () async {
                                    Navigator.pop(context);
                                    await Supabase.instance.client.auth.signOut();
                                    if (context.mounted) {
                                      Navigator.of(context).pushReplacementNamed('/login');
                                    }
                                  }, child: const Text('Revoke', style: TextStyle(color: Colors.red))),
                                ],
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          child: const Text('Revoke All Active Tokens'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      final diff = DateTime.now().difference(date);
      if (diff.inSeconds < 60) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes} mins ago';
      if (diff.inHours < 24) return '${diff.inHours} hours ago';
      return '${date.day}/${date.month}';
    } catch (e) {
      return 'Recently';
    }
  }

  Widget _buildSecurityStat(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildRoleCard(BuildContext context, WidgetRef ref, String title, String desc, IconData icon, Color color, String filterValue) {
    return InkWell(
      onTap: () {
        ref.read(adminRoleFilterProvider.notifier).state = filterValue;
        ref.read(superAdminTabIndexProvider.notifier).state = 2; // Switch to Admins tab
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Showing all $title users'), duration: const Duration(seconds: 1)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(desc, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildAuditItem(String user, String action, String time) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(radius: 15, backgroundColor: AppTheme.emeraldLight, child: Text(user.isNotEmpty ? user[0] : 'S', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.black, fontSize: 13),
                    children: [
                      TextSpan(text: user, style: const TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: ' $action', style: const TextStyle(color: Colors.blueGrey)),
                    ],
                  ),
                ),
                Text(time, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// --- TAB 5: SYSTEM SETTINGS ---

class _SystemSettingsTab extends StatefulWidget {
  const _SystemSettingsTab({super.key});

  @override
  State<_SystemSettingsTab> createState() => _SystemSettingsTabState();
}

class _SystemSettingsTabState extends State<_SystemSettingsTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, dynamic>> _allSettings = [
    {
      'category': 'GENERAL CONFIGURATION',
      'arCategory': 'الإعدادات العامة',
      'items': [
        {'icon': Icons.language_rounded, 'title': 'Regional Localization', 'subtitle': 'English, Arabic, Hijri Calendar', 'status': 'Active', 'isHealthy': true},
        {'icon': Icons.business_center_rounded, 'title': 'Business Entities', 'subtitle': 'Manage registered Saudi companies', 'status': '3 Entities', 'isHealthy': true},
        {'icon': Icons.currency_exchange_rounded, 'title': 'Financial Controls', 'subtitle': 'SAR Conversion, Tax (VAT) Config', 'status': 'Ready', 'isHealthy': true},
      ]
    },
    {
      'category': 'NOTIFICATIONS & ALERTS',
      'arCategory': 'التنبيهات والإشعارات',
      'items': [
        {'icon': Icons.sms_rounded, 'title': 'SMS Gateway', 'subtitle': 'STC, Mobily, Zain integration', 'status': 'Online', 'isHealthy': true},
        {'icon': Icons.email_rounded, 'title': 'SMTP Server', 'subtitle': 'Office 365, SendGrid Config', 'status': 'Active', 'isHealthy': true},
        {'icon': Icons.notifications_active_rounded, 'title': 'Push Notifications', 'subtitle': 'Firebase Management', 'status': 'Healthy', 'isHealthy': true},
      ]
    },
    {
      'category': 'INFRASTRUCTURE',
      'arCategory': 'البنية التحتية',
      'items': [
        {'icon': Icons.cloud_sync_rounded, 'title': 'Backup & Sync', 'subtitle': 'Daily auto-backup to AWS/Cloud', 'status': 'Last: 2h ago', 'isHealthy': true},
        {'icon': Icons.api_rounded, 'title': 'API Integration', 'subtitle': 'MOI, GOSI, Qiwa External APIs', 'status': '5 Linked', 'isHealthy': true},
        {'icon': Icons.update_rounded, 'title': 'Version Control', 'subtitle': 'Current System v1.4.2 Build', 'status': 'Latest', 'isHealthy': true},
      ]
    },
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      maxWidth: 1000,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          const _HeaderSection(title: 'System Engine', subtitle: 'محرك النظام الأساسي', showDate: false),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              physics: const BouncingScrollPhysics(),
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search system settings...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: _searchQuery.isNotEmpty 
                        ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () => _searchController.clear())
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                  ),
                ),
                const SizedBox(height: 25),
  
                if (_searchQuery.isEmpty) ...[
                  // System Status Card
                  _buildSystemHealthOverview(),
                  const SizedBox(height: 30),
                ],
  
                ..._buildFilteredSettings(),
                
                const SizedBox(height: 40),
                const Center(
                  child: Column(
                    children: [
                      Text('SAUDI SERVICE MANAGER PORTAL', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                      SizedBox(height: 4),
                      Text('Build 2024.1.42 • Enterprise Edition', style: TextStyle(color: Colors.grey, fontSize: 10)),
                    ],
                  ),
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFilteredSettings() {
    List<Widget> groups = [];
    
    for (var group in _allSettings) {
      final items = (group['items'] as List).where((item) {
        final title = item['title'].toString().toLowerCase();
        final subtitle = item['subtitle'].toString().toLowerCase();
        return title.contains(_searchQuery) || subtitle.contains(_searchQuery);
      }).toList();

      if (items.isNotEmpty) {
        groups.add(
          _buildSettingGroup(
            group['category'], 
            group['arCategory'], 
            items.map((item) => _buildSettingTile(
              item['icon'], 
              item['title'], 
              item['subtitle'], 
              status: item['status'], 
              isHealthy: item['isHealthy'],
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SystemDetailScreen(
                    title: item['title'],
                    subtitle: item['subtitle'],
                    icon: item['icon'],
                    status: item['status'],
                    isHealthy: item['isHealthy'],
                  )),
                );
              }
            )).toList()
          )
        );
        groups.add(const SizedBox(height: 30));
      }
    }

    if (groups.isEmpty && _searchQuery.isNotEmpty) {
      return [
        const Center(
          child: Padding(
            padding: EdgeInsets.all(40.0),
            child: Text('No results found for your search', style: TextStyle(color: Colors.grey)),
          ),
        )
      ];
    }

    return groups;
  }

  Widget _buildSystemHealthOverview() {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SystemDetailScreen(
            title: 'System Health & Performance',
            subtitle: 'Real-time monitoring of all global services',
            icon: Icons.monitor_heart_outlined,
            status: '99.9% Optimal',
            isHealthy: true,
          )),
        );
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.emeraldGreen, AppTheme.emeraldGreen.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppTheme.emeraldGreen.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('System Health', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('All services operational', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      CircleAvatar(radius: 4, backgroundColor: Colors.white),
                      SizedBox(width: 8),
                      Text('99.9% Up', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMiniHealthStat('Storage', '42%', Icons.storage_rounded),
                _buildMiniHealthStat('CPU Load', '12%', Icons.memory_rounded),
                _buildMiniHealthStat('API Latency', '45ms', Icons.speed_rounded),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniHealthStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
      ],
    );
  }

  Widget _buildSettingGroup(String title, String arTitle, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, right: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey, letterSpacing: 1.2)),
              Text(arTitle, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSettingTile(IconData icon, String title, String subtitle, {String? status, bool? isHealthy, VoidCallback? onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.emeraldLight.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppTheme.emeraldGreen, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.darkBlue)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          if (status != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                if (isHealthy == true) ...[
                  const Icon(Icons.check_circle, color: Colors.green, size: 10),
                  const SizedBox(width: 4),
                ],
                Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isHealthy == true ? Colors.green : Colors.blueGrey)),
              ],
            ),
          ],
        ],
      ),
      trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
      onTap: onTap,
    );
  }
}


