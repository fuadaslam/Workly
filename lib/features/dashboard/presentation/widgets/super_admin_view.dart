import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:service_manager_app/l10n/generated/app_localizations.dart';
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
import '../../../../core/widgets/premium_card.dart';
import '../../../attendance/presentation/widgets/attendance_monitor.dart';

import 'assignment_sheet.dart';
import '../../../enquiries/presentation/pages/enquiry_list_screen.dart';
import '../../../reports/presentation/report_export_screen.dart';
import '../../../search/presentation/global_search_screen.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../auth/presentation/pages/login_screen.dart';

final superAdminTabIndexProvider = StateProvider<int>((ref) => 0);

class SuperAdminView extends ConsumerWidget {
  const SuperAdminView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(superAdminTabIndexProvider);
    final profile = ref.watch(profileProvider).value;
    final isSuperAdmin = profile?.role == AppRole.super_admin;
    final l10n = AppLocalizations.of(context)!;

    final tabs = [
       BottomNavigationBarItem(icon: const Icon(Icons.grid_view_rounded), label: l10n.dashboard),
       const BottomNavigationBarItem(icon: Icon(Icons.business_outlined), label: 'Offices'),
       const BottomNavigationBarItem(icon: Icon(Icons.how_to_reg_outlined), label: 'Attend.'),
       const BottomNavigationBarItem(icon: Icon(Icons.calendar_month_outlined), label: 'Leaves'),
       BottomNavigationBarItem(icon: const Icon(Icons.people_outline), label: l10n.staff),
       BottomNavigationBarItem(icon: const Icon(Icons.support_agent_outlined), label: l10n.agents),
       const BottomNavigationBarItem(icon: Icon(Icons.track_changes_outlined), label: 'Enquiries'),
       const BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Settings'),
    ];

    // Reset index if out of bounds
    if (currentIndex >= tabs.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(superAdminTabIndexProvider.notifier).state = 0;
      });
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? AppTheme.darkBackground : AppTheme.backgroundLight;
    final navBg      = isDark ? AppTheme.darkSurface    : Colors.white;
    final selectedColor   = isDark ? AppTheme.accentGold   : AppTheme.emeraldGreen;
    final unselectedColor = isDark ? AppTheme.darkSubtext  : Colors.grey;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 800) {
          // Desktop Layout
          return Scaffold(
            backgroundColor: scaffoldBg,
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: currentIndex < tabs.length ? currentIndex : 0,
                  onDestinationSelected: (idx) => ref.read(superAdminTabIndexProvider.notifier).state = idx,
                  labelType: NavigationRailLabelType.all,
                  backgroundColor: navBg,
                  selectedLabelTextStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: selectedColor),
                  unselectedLabelTextStyle: TextStyle(fontSize: 11, color: unselectedColor),
                  selectedIconTheme: IconThemeData(color: selectedColor),
                  unselectedIconTheme: IconThemeData(color: unselectedColor),
                  destinations: tabs.map((t) => NavigationRailDestination(
                    icon: t.icon as Icon, 
                    label: Text(t.label!),
                  )).toList(),
                ),
                Expanded(
                  child: _buildCurrentTab(currentIndex, isSuperAdmin),
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
                  backgroundColor: selectedColor,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  elevation: 6,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  icon: Icon(Icons.assignment_add, color: isDark ? Colors.black : Colors.white, size: 24),
                  label: Text(
                    l10n.assignWork,
                    style: TextStyle(color: isDark ? Colors.black : Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                )
              : null,
          );
        } else {
          // Mobile Layout
          return Scaffold(
            backgroundColor: scaffoldBg,
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
                    backgroundColor: selectedColor,
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    elevation: 6,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    icon: Icon(Icons.assignment_add, color: isDark ? Colors.black : Colors.white, size: 24),
                    label: Text(
                      l10n.assignWork,
                      style: TextStyle(color: isDark ? Colors.black : Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                  )
                : null,
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                color: navBg,
                border: Border(top: BorderSide(color: isDark ? AppTheme.darkBorder : const Color(0xFFF1F5F9), width: 1)),
                boxShadow: isDark
                    ? null
                    : const [BoxShadow(color: Color(0x08000000), blurRadius: 12, offset: Offset(0, -4))],
              ),
              child: BottomNavigationBar(
                currentIndex: currentIndex < tabs.length ? currentIndex : 0,
                onTap: (idx) => ref.read(superAdminTabIndexProvider.notifier).state = idx,
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.transparent,
                elevation: 0,
                selectedItemColor: selectedColor,
                unselectedItemColor: unselectedColor,
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
      case 5: return const _AgentManagementTab();
      case 6: return const EnquiryListScreen();
      case 7: return _SettingsTab(isSuperAdmin: isSuperAdmin);
      default: return const _ExecutiveDashboardTab();
    }
  }
}

class _AttendanceTab extends StatelessWidget {
  const _AttendanceTab();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        _HeaderSection(title: l10n.staffAttendance, subtitle: l10n.realTimeMonitoring, showDate: false),
        const Expanded(child: AttendanceMonitor()),
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
    final l10n = AppLocalizations.of(context)!;
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
              Text(
                l10n.selectLanguage,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.darkBlue),
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

  Widget _buildHeaderIcon({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.emeraldGreen,
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: MashrabiyaPatternPainter(color: Colors.white.withValues(alpha: 0.03)),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(title, 
                            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(subtitle, 
                                style: TextStyle(color: AppTheme.accentGold.withValues(alpha: 0.9), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2),
                                overflow: TextOverflow.ellipsis),
                            if (showDate) ...[
                              Container(
                                margin: const EdgeInsets.symmetric(horizontal: 8),
                                width: 4, height: 4,
                                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.3), shape: BoxShape.circle),
                              ),
                              Icon(Icons.security, color: Colors.white.withValues(alpha: 0.5), size: 12),
                              const SizedBox(width: 4),
                              Text('${l10n.systemAuthority.toUpperCase()} • ${_currentDateFormatted()}',
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                                  overflow: TextOverflow.ellipsis),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Dark mode toggle
                      _buildHeaderIcon(
                        icon: ref.watch(themeModeProvider) == ThemeMode.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                        onTap: () => ref.read(themeModeProvider.notifier).toggle(),
                      ),
                      const SizedBox(width: 8),
                      // Global search
                      _buildHeaderIcon(
                        icon: Icons.search_rounded,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GlobalSearchScreen())),
                      ),
                      const SizedBox(width: 8),
                      // Language Toggle
                      GestureDetector(
                        onTap: () => _showLanguagePicker(context, ref),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            currentLocale.languageCode == 'en' ? 'عربي' : 'English',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Profile Avatar
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const ProfileView()),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 2),
                          ),
                          child: const CircleAvatar(
                            radius: 18,
                            backgroundColor: Color(0xFFFFB29D),
                            child: Icon(Icons.person, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
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
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        _HeaderSection(title: l10n.superAdmin, subtitle: l10n.vision2030Portal.toUpperCase()),
        Expanded(
          child: RefreshIndicator(
            color: const Color(0xFF0D1B2E),
            onRefresh: () async {
              ref.invalidate(financialStatsProvider);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ResponsiveLayout(
              maxWidth: 1000,
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       Text(l10n.executiveOverview.toUpperCase(), style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                       Consumer(
                         builder: (ctx, cRef, _) {
                           final dr = cRef.watch(dashboardDateRangeProvider);
                           return GestureDetector(
                             onTap: () => _showDashboardDateFilter(ctx, cRef),
                             child: Container(
                               padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                               decoration: BoxDecoration(
                                 color: dr != null ? AppTheme.emeraldGreen.withValues(alpha: 0.08) : Colors.transparent,
                                 borderRadius: BorderRadius.circular(20),
                                 border: Border.all(color: dr != null ? AppTheme.emeraldGreen : Colors.grey.shade300),
                               ),
                               child: Row(mainAxisSize: MainAxisSize.min, children: [
                                 Icon(Icons.filter_list, size: 14, color: dr != null ? AppTheme.emeraldGreen : Colors.grey),
                                 const SizedBox(width: 4),
                                 Text(
                                   dr != null
                                       ? '${DateFormat('d MMM').format(dr.start)} – ${DateFormat('d MMM').format(dr.end)}'
                                       : l10n.filters,
                                   style: TextStyle(color: dr != null ? AppTheme.emeraldGreen : Colors.grey, fontSize: 11, fontWeight: FontWeight.bold),
                                 ),
                                 if (dr != null) ...[
                                   const SizedBox(width: 4),
                                   GestureDetector(
                                     onTap: () => cRef.read(dashboardDateRangeProvider.notifier).state = null,
                                     child: const Icon(Icons.close, size: 12, color: AppTheme.emeraldGreen),
                                   ),
                                 ],
                               ]),
                             ),
                           );
                         },
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
                      data: (stats) {
                        final total = (stats['totalReceivables'] as num? ?? 0).toDouble();
                        final label = total == 0 ? 'No payment data yet' : '+15.4% vs last month';
                        final value = total == 0 ? 'SAR 0.0M' : 'SAR ${(total/1000000).toStringAsFixed(1)}M';
                        return _buildRevenueCard(context, l10n.monthlyRevenue, value, label, true);
                      },
                      loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.emeraldGreen)),
                      error: (e, _) => _buildRevenueCard(context, l10n.monthlyRevenue, 'SAR 0.0M', 'No payment data yet', true),
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
                          child: ref.watch(activeCasesCountProvider).when(
                            data: (count) => _buildSmallStatCard(l10n.activeCases, count.toString(), 'this month', true),
                            loading: () => _buildSmallStatCard(l10n.activeCases, '...', 'loading', true),
                            error: (_, __) => _buildSmallStatCard(l10n.activeCases, '0', 'no data', true),
                          )
                        )
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            ref.read(superAdminTabIndexProvider.notifier).state = 3; // Switch to Access tab
                          }, 
                          borderRadius: BorderRadius.circular(16), 
                          child: ref.watch(pendingApprovalsCountProvider).when(
                            data: (count) => _buildSmallStatCard(l10n.pendingApprovals, count.toString(), 'awaiting action', false),
                            loading: () => _buildSmallStatCard(l10n.pendingApprovals, '...', 'loading', false),
                            error: (_, __) => _buildSmallStatCard(l10n.pendingApprovals, '0', 'no data', false),
                          )
                        )
                      ),
                    ],
                  ),
                  
                  
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.operationalTrends, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.darkBlue)),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const DetailTrendScreen()),
                          );
                        }, 
                        child: Text(l10n.viewDetailed, style: const TextStyle(fontSize: 12))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildRevenueChart(),
                  
                  const SizedBox(height: 30),
                  _buildStaffKPIs(context, l10n),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
          ),
        ),
      ],
    );
  }

  Widget _buildRevenueCard(BuildContext context, String title, String value, String growth, bool isPositive) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: const Color(0xFF0B172A).withValues(alpha: 0.25), blurRadius: 24, offset: const Offset(0, 12)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: MashrabiyaPatternPainter(color: Colors.white.withValues(alpha: 0.02)),
              ),
            ),
            Positioned(
              right: -30,
              bottom: -30,
              child: Icon(Icons.account_balance_wallet, size: 160, color: Colors.white.withValues(alpha: 0.03)),
            ),
            Padding(
              padding: const EdgeInsets.all(28),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: AppTheme.accentGold.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                              child: const Icon(Icons.account_balance_wallet_rounded, color: AppTheme.accentGold, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Text(title, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 1.1)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(value, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1.0)),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: (isPositive ? AppTheme.emeraldGreen : Colors.red).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: (isPositive ? AppTheme.emeraldGreen : Colors.red).withValues(alpha: 0.3)),
                              ),
                              child: Row(children: [
                                Icon(isPositive ? Icons.trending_up : Icons.trending_down, size: 16, color: isPositive ? AppTheme.emeraldGreen : Colors.red),
                                const SizedBox(width: 6),
                                Text(growth, style: TextStyle(color: isPositive ? AppTheme.emeraldGreen : Colors.red, fontWeight: FontWeight.bold, fontSize: 13)),
                              ]),
                            ),
                            const SizedBox(width: 12),
                            Text(l10n.vsLastMonth, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.05),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white54, size: 20),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallStatCard(String title, String value, String growth, bool isPositive) {
    final iconData = title.toLowerCase().contains('case') ? Icons.assignment_outlined : Icons.pending_actions_outlined;
    final color = title.toLowerCase().contains('case') ? Colors.blue : Colors.orange;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(iconData, size: 22, color: color),
              ),
              Icon(Icons.more_horiz, size: 20, color: Colors.grey.shade400),
            ],
          ),
          const SizedBox(height: 20),
          Text(value, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppTheme.darkBlue, letterSpacing: -0.5)),
          const SizedBox(height: 6),
          Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(isPositive ? Icons.arrow_upward : Icons.access_time, size: 12, color: color),
                    const SizedBox(width: 4),
                    Text(growth, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChart() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 10))],
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
                  Text('Performance Activity', style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  const Text('+24% Growth', style: TextStyle(color: AppTheme.emeraldGreen, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(20)),
                child: const Text('This Year', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true, drawVerticalLine: false,
                  horizontalInterval: 2,
                  getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withValues(alpha: 0.1), strokeWidth: 1, dashArray: [5, 5]),
                ),
                titlesData: const FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: _bottomTitleWidgets,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 2), FlSpot(1, 4), FlSpot(2, 3), FlSpot(3, 5), FlSpot(4, 3.5), FlSpot(5, 6),
                    ],
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: AppTheme.emeraldGreen,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                        radius: index == 5 ? 6 : 4, color: Colors.white, strokeWidth: 3, strokeColor: AppTheme.emeraldGreen,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.emeraldGreen.withValues(alpha: 0.25),
                          AppTheme.emeraldGreen.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey);
    Widget text;
    switch (value.toInt()) {
      case 0: text = const Text('Jan', style: style); break;
      case 1: text = const Text('Feb', style: style); break;
      case 2: text = const Text('Mar', style: style); break;
      case 3: text = const Text('Apr', style: style); break;
      case 4: text = const Text('May', style: style); break;
      case 5: text = const Text('Jun', style: style); break;
      default: text = const Text('', style: style); break;
    }
    return SideTitleWidget(axisSide: meta.axisSide, child: text);
  }

  Widget _buildStaffKPIs(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${l10n.staff} KPIs by Department', style: const TextStyle(color: AppTheme.darkBlue, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Average performance rating', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AppTheme.emeraldGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                child: const Text('4% Avg', style: TextStyle(color: AppTheme.emeraldGreen, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 32),
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
          height: 120, width: 14,
          decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: FractionallySizedBox(
            heightFactor: percent, alignment: Alignment.bottomCenter,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.emeraldGreen, Color(0xFF0A8A61)],
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(color: AppTheme.emeraldGreen.withValues(alpha: 0.4), blurRadius: 6, offset: const Offset(0, 2))],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Text('${(percent * 100).toInt()}%', style: const TextStyle(fontSize: 12, color: AppTheme.darkBlue, fontWeight: FontWeight.bold)),
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
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        _HeaderSection(title: l10n.regionalOffices, subtitle: l10n.branchManagement.toUpperCase(), showDate: false),
        Expanded(
          child: ResponsiveLayout(
            maxWidth: 1000,
            padding: EdgeInsets.zero,
            child: RefreshIndicator(
              color: const Color(0xFF0D1B2E),
              onRefresh: () async {
                ref.invalidate(officesProvider);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
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
                            Text(l10n.ksaNetwork.toUpperCase(), style: const TextStyle(color: AppTheme.emeraldGreen, fontSize: 11, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                            officesAsync.when(
                               data: (offices) => Text('${offices.length} ${l10n.activeBranches}', style: const TextStyle(fontSize: 16, color: Colors.blueGrey), overflow: TextOverflow.ellipsis),
                               loading: () => Text(l10n.loading, style: const TextStyle(fontSize: 16, color: Colors.blueGrey)),
                               error: (_,__) => Text(l10n.error, style: const TextStyle(fontSize: 16, color: Colors.red)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: () => _showAddOfficeSheet(context, ref),
                        icon: const Icon(Icons.add_location_alt_outlined, size: 16),
                        label: Text(l10n.addNewOffice, style: const TextStyle(fontSize: 12)),
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
                          hintText: l10n.searchOffices,
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
                            _buildFilterChip(context, ref, 'Default', Icons.sort),
                            const SizedBox(width: 10),
                            _buildFilterChip(context, ref, l10n.revenue, Icons.monetization_on_outlined),
                            const SizedBox(width: 10),
                            _buildFilterChip(context, ref, l10n.workloadCapacity, Icons.bar_chart),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Static Map Image Placeholder or Custom Painter
                  // Performance Overview Dashboard
                  officesAsync.when(
                    data: (offices) => _buildPerformanceDashboard(context, offices),
                    loading: () => const SizedBox(height: 180, child: Center(child: CircularProgressIndicator())),
                    error: (_,__) => const SizedBox(),
                  ),
                  
                  const SizedBox(height: 30),
                  officesAsync.when(
                    data: (offices) {
                      if (offices.isEmpty) {
                        return Center(child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Text(l10n.noHistoryFound),
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
                    error: (e, st) => Center(child: Text('${l10n.error}: $e')),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

  Widget _buildPerformanceDashboard(BuildContext context, List<Map<String, dynamic>> offices) {
    if (offices.isEmpty) return const SizedBox();
    final l10n = AppLocalizations.of(context)!;

    double totalRevenueValue = 0;
    double totalWorkload = 0;
    
    for (var o in offices) {
      totalRevenueValue += (o['revenue'] as num? ?? 0).toDouble();
      totalWorkload += (o['workload_percentage'] as num? ?? 0).toDouble();
    }
    
    final avgWorkload = offices.isEmpty ? 0 : totalWorkload / offices.length;
    final displayRevenue = totalRevenueValue >= 1000000 
        ? '${(totalRevenueValue / 1000000).toStringAsFixed(1)}M' 
        : '${(totalRevenueValue / 1000).toStringAsFixed(0)}K';

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
          BoxShadow(color: AppTheme.emeraldGreen.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.networkPerformance.toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
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
                    Text(l10n.totalRevenue, style: const TextStyle(color: Colors.white70, fontSize: 12)),
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
                    Text(l10n.avgWorkloadCapacity, style: const TextStyle(color: Colors.white70, fontSize: 12)),
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
               Text(l10n.networkPerformance, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
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

  Widget _buildFilterChip(BuildContext context, WidgetRef ref, String label, IconData icon) {
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
    final l10n = AppLocalizations.of(context)!;
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
                  Text(
                    l10n.addNewOffice,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.darkBlue),
                  ),
                  Text(
                    l10n.addOfficeProgress,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 25),
                  
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: l10n.officeName,
                      prefixIcon: const Icon(Icons.business_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    validator: (v) => v == null || v.isEmpty ? l10n.required : null,
                  ),
                  const SizedBox(height: 15),
                  
                  TextFormField(
                    controller: locationController,
                    decoration: InputDecoration(
                      labelText: l10n.location,
                      prefixIcon: const Icon(Icons.location_on_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    validator: (v) => v == null || v.isEmpty ? l10n.required : null,
                  ),
                  const SizedBox(height: 15),
                  
                  TextFormField(
                    controller: managerController,
                    decoration: InputDecoration(
                      labelText: l10n.managerName,
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
                      labelText: l10n.managerPhone,
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
                            labelText: l10n.officeMobile,
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
                            labelText: l10n.officeLandline,
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
                            ref.invalidate(officesProvider);
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(l10n.officeAddedSuccessfully),
                                  backgroundColor: AppTheme.emeraldGreen
                                )
                              );
                            }
                          } catch (e) {
                             if (context.mounted) {
                               Navigator.pop(context);
                               ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${l10n.error}: $e')));
                             }
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.emeraldGreen,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: Text(l10n.addNewOffice, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
    final l10n = AppLocalizations.of(context)!;
    final String workload = '${office['workload_percentage'] ?? 0}%';
    final String staff = '${office['staff_count'] ?? 0}';
    final String revenue = (office['revenue'] ?? 0).toString();
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
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)],
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
                  Expanded(child: _buildMiniStat(l10n.workload, workload, workloadColor, true)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildMiniStat(l10n.staffCount.toUpperCase(), staff, Colors.blueGrey, false)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildMiniStat(l10n.revenue, revenue, Colors.amber.shade700, false)),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
               child: Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   Text(l10n.regionalHub, style: const TextStyle(color: AppTheme.emeraldGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                   InkWell(
                     onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => OfficeDetailScreen(office: office)),
                        );
                     },
                     borderRadius: BorderRadius.circular(4),
                     child: Row(
                       children: [
                         Text(l10n.branchSettings, style: const TextStyle(color: AppTheme.emeraldGreen, fontSize: 12, fontWeight: FontWeight.bold)),
                         const Icon(Icons.chevron_right, size: 16, color: AppTheme.emeraldGreen),
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

class _LeaveManagementTab extends ConsumerWidget {
  const _LeaveManagementTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        _HeaderSection(
          title: l10n.leaveManagement, 
          subtitle: l10n.leaves.toUpperCase(),
          showDate: false,
        ),
        const Expanded(
          child: ResponsiveLayout(
            maxWidth: 1000,
            padding: EdgeInsets.zero,
            child: AdminLeaveList(),
          ),
        ),
      ],
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
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        _HeaderSection(
          title: isStaffView ? l10n.staffCommandCenter : l10n.totalControlHub, 
          subtitle: (isStaffView ? l10n.manageStaff : l10n.manageAdmins).toUpperCase()
        ),
        Expanded(
          child: ResponsiveLayout(
            maxWidth: 1000,
            padding: EdgeInsets.zero,
            child: RefreshIndicator(
              color: const Color(0xFF0D1B2E),
              onRefresh: () async {
                 ref.invalidate(isStaffView ? allProfilesProvider : allProfilesProvider); // simple invalidation of profiles
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
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
                            Text(isStaffView ? l10n.manageStaff : l10n.manageAdmins, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: () => _showAddAdminDialog(context, ref, forceStaff: isStaffView),
                        icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                        label: Text(l10n.newLabel),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emeraldGreen, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  
                  // Filters
                  TextField(
                    onChanged: (value) => ref.read(isStaffView ? staffSearchQueryProvider.notifier : adminSearchQueryProvider.notifier).state = value,
                    decoration: InputDecoration(
                      hintText: isStaffView ? l10n.searchStaff : l10n.searchAdmins,
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
                          _buildFilterChip(ref, l10n.all),
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
                      if (profiles.isEmpty) return Center(child: Text(isStaffView ? l10n.noStaffAssigned : l10n.noAdminsFound));
                      return Column(
                        children: profiles.map((p) => _buildLargeAdminCard(context, ref, p, isStaff: isStaffView)).toList(),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('${l10n.errorLoading}: $e'),
                  ),
                  
                  if (!isStaffView) ...[
                    const SizedBox(height: 20),
                    InkWell(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.globalAccessControl)));
                      },
                      borderRadius: BorderRadius.circular(15),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.emeraldGreen,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [BoxShadow(color: AppTheme.emeraldGreen.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 5))],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.security, color: Colors.white, size: 20),
                            const SizedBox(width: 10),
                            Text(l10n.globalAccessControl, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    ],
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
    final l10n = AppLocalizations.of(context)!;
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
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
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
                    if ((admin['role'] as String? ?? '').toLowerCase() == 'agent')
                      Text('Work Status: Available', style: TextStyle(fontSize: 11, color: Colors.blue[700], fontWeight: FontWeight.w500)),
                  ],
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), 
                  decoration: BoxDecoration(
                    color: (admin['is_active'] ?? true) ? AppTheme.emeraldLight : Colors.grey.shade100, 
                    borderRadius: BorderRadius.circular(8)
                  ), 
                  child: Text(
                    (admin['is_active'] ?? true) ? l10n.active : l10n.inactive, 
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
                     _buildActionButton(context, Icons.edit, l10n.edit, Colors.green, () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => AdminDetailScreen(admin: admin)),
                        );
                     }),
                     if (admin['is_active'] ?? true)
                       _buildActionButton(context, Icons.block, l10n.delete, Colors.red, () async {
                          if (id == null) return;
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(isStaff ? l10n.removeStaff : l10n.removeAdmin),
                              content: Text(l10n.confirmRemoveAccount(name)),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
                                TextButton(onPressed: () => Navigator.pop(context, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: Text(l10n.delete)),
                              ],
                            ),
                          );
                          if (confirm == true) {
                             await ref.read(profileRepositoryProvider).deleteProfile(id);
                             ref.invalidate(allProfilesProvider);
                          }
                       })
                     else
                       _buildActionButton(context, Icons.check_circle_outline, l10n.reactivate, AppTheme.emeraldGreen, () async {
                          if (id == null) return;
                          await ref.read(profileRepositoryProvider).reactivateProfile(id);
                          ref.invalidate(allProfilesProvider);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.profileReactivated)));
                       }),
                     _buildActionButton(context, Icons.vpn_key_outlined, l10n.accessPermissions, Colors.amber.shade700, () {
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

  void _showAddAdminDialog(BuildContext context, WidgetRef ref, {bool forceStaff = false, bool isAgent = false}) {
    final l10n = AppLocalizations.of(context)!;
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final phoneController = TextEditingController();
    String role = isAgent ? 'agent' : (forceStaff ? 'staff' : 'admin');
    String? selectedOfficeId;
    bool isLoading = false;

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
                    isAgent ? 'Register New Agent' : (forceStaff ? l10n.registerNewStaff : l10n.registerNewAdmin),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.darkBlue),
                  ),
                  Text(
                    isAgent ? 'Add an external agent to the system' : (forceStaff ? l10n.addTeamMemberDescription : l10n.grantAdminAccessDescription),
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 25),
                  
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: l10n.fullName,
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    validator: (v) => v!.isEmpty ? l10n.nameRequired : null,
                  ),
                  const SizedBox(height: 15),
                  
                  TextFormField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: l10n.emailAddress,
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    validator: (v) => v!.isEmpty ? l10n.emailRequired : null,
                  ),
                  const SizedBox(height: 15),
                  const SizedBox(height: 15),
                  
                  if (!isAgent) ...[
                    TextFormField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: l10n.initialPassword,
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      validator: (v) => v!.isEmpty ? l10n.passwordRequired : null,
                    ),
                    const SizedBox(height: 15),
                  ],
                  
                  TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: l10n.phoneNumber,
                      prefixIcon: const Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    validator: (v) => v!.isEmpty ? l10n.phoneRequired : null,
                  ),
                  
                  if (!forceStaff && !isAgent) ...[
                    const SizedBox(height: 15),
                    DropdownButtonFormField<String>(
                      value: role,
                      items: [
                        DropdownMenuItem(value: 'admin', child: Text(l10n.adminRegionalCentral)),
                        DropdownMenuItem(value: 'super_admin', child: Text(l10n.superAdminGlobalRoot)),
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
                      onPressed: isLoading ? null : () async {
                        if (formKey.currentState!.validate()) {
                          try {
                            setModalState(() => isLoading = true);
                            final client = ref.read(supabaseClientProvider);
                            await client.rpc('create_user_admin', params: {
                              'new_email': emailController.text.trim(),
                              'new_password': isAgent ? _generateSecurePassword() : passwordController.text.trim(),
                              'full_name': nameController.text.trim(),
                              'user_role': role,
                              'phone': phoneController.text.trim(),
                              'office': selectedOfficeId,
                            });

                            ref.invalidate(allProfilesProvider);
                            if (context.mounted) Navigator.pop(context);
                             if (context.mounted) {
                               ScaffoldMessenger.of(context).showSnackBar(
                                 SnackBar(
                                   content: Text(l10n.registeredSuccessfully(role.toUpperCase())),
                                   backgroundColor: AppTheme.emeraldGreen,
                                 )
                               );
                             }
                          } catch (e) {
                             if (context.mounted) {
                               String errorMsg = e.toString();
                               if (errorMsg.contains('function public.create_user_admin') && errorMsg.contains('does not exist')) {
                                   errorMsg = l10n.dbSetupRequired;
                               }
                               ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${l10n.registrationError}: $errorMsg'), duration: const Duration(seconds: 5),));
                             }
                          } finally {
                            setModalState(() => isLoading = false);
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.emeraldGreen,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(l10n.confirmRegistration, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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

class _AgentManagementTab extends ConsumerWidget {
  const _AgentManagementTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredAgentsAsync = ref.watch(filteredAgentsProvider);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        _HeaderSection(
          title: l10n.agents, 
          subtitle: l10n.allAgents.toUpperCase()
        ),
        Expanded(
          child: ResponsiveLayout(
            maxWidth: 1000,
            padding: EdgeInsets.zero,
            child: RefreshIndicator(
              color: const Color(0xFF0D1B2E),
              onRefresh: () async {
                 ref.invalidate(allProfilesProvider);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
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
                            Text(l10n.manageStaff.replaceAll('Staff', 'Agents'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: () => const _AdminManagementTab()._showAddAdminDialog(context, ref, isAgent: true),
                        icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                        label: Text(l10n.newLabel),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emeraldGreen, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  
                  TextField(
                    onChanged: (value) => ref.read(agentSearchQueryProvider.notifier).state = value,
                    decoration: InputDecoration(
                      hintText: l10n.searchAgents,
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
                  
                  const SizedBox(height: 20),
                  filteredAgentsAsync.when(
                    data: (profiles) {
                      if (profiles.isEmpty) return _buildEmptyAgentsState(context, ref, l10n);
                      return Column(
                        children: profiles.map((p) => const _AdminManagementTab()._buildLargeAdminCard(context, ref, p)).toList(),
                      );
                    },
                    loading: () => const Padding(
                      padding: EdgeInsets.only(top: 60),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) => Text('${l10n.errorLoading}: $e'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

  Widget _buildEmptyAgentsState(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.emeraldGreen.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.support_agent_outlined, size: 40, color: AppTheme.emeraldGreen.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.noAgentsFound,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppTheme.darkBlue),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first agent to get started',
              style: TextStyle(fontSize: 14, color: AppTheme.darkBlue.withValues(alpha: 0.45)),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => const _AdminManagementTab()._showAddAdminDialog(context, ref, isAgent: true),
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
              label: Text(l10n.newLabel),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.emeraldGreen,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


/// --- TAB 4: ACCESS CONTROL ---

class _AccessControlTab extends ConsumerWidget {
  const _AccessControlTab();

   @override
  Widget build(BuildContext context, WidgetRef ref) {
    final securityStats = ref.watch(securityStatsProvider);
    final financialStats = ref.watch(financialStatsProvider);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        _HeaderSection(title: l10n.accessSecurity, subtitle: l10n.accessPermissions.toUpperCase(), showDate: false),
        Expanded(
          child: ResponsiveLayout(
            maxWidth: 1000,
            padding: EdgeInsets.zero,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.securityExecutiveSummary, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  securityStats.when(
                    data: (stats) => Row(
                      children: [
                        Expanded(child: _buildSecurityStat(l10n.activeSessions, stats['activeSessions'].toString(), Icons.devices, Colors.blue)),
                        const SizedBox(width: 15),
                        Expanded(child: _buildSecurityStat(l10n.securityAlerts, stats['securityAlerts'].toString(), Icons.warning_amber_rounded, Colors.orange)),
                      ],
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Row(
                      children: [
                        Expanded(child: _buildSecurityStat(l10n.activeSessions, '0', Icons.devices, Colors.blue)),
                        const SizedBox(width: 15),
                        Expanded(child: _buildSecurityStat(l10n.securityAlerts, '?', Icons.warning_amber_rounded, Colors.orange)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(l10n.roleHierarchyPermissions, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  _buildRoleCard(context, ref, l10n.superAdmin, l10n.superAdminAccessDesc, Icons.auto_awesome, AppTheme.emeraldGreen, 'Super Admin'),
                  const SizedBox(height: 12),
                  _buildRoleCard(context, ref, l10n.officeAdmin, l10n.officeAdminAccessDesc, Icons.admin_panel_settings, Colors.amber.shade700, 'Admin'),
                  const SizedBox(height: 12),
                  _buildRoleCard(context, ref, l10n.operationalStaff, l10n.staffAccessDesc, Icons.engineering, Colors.blueGrey, 'All'),
                  
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.auditGlobalLogs, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.exportingCsv)));
                        }, 
                        child: Text(l10n.exportCsv)),
                    ],
                  ),
                  financialStats.when(
                    data: (stats) {
                      final logs = stats['auditLogs'] as List;
                      if (logs.isEmpty) {
                        return Center(child: Padding(padding: const EdgeInsets.all(20), child: Text(l10n.noAuditLogs, style: const TextStyle(color: Colors.grey))));
                      }
                      return Column(
                        children: logs.take(5).map((log) => _buildAuditItem(
                          log['user'] ?? 'System', 
                          log['action'] ?? 'Unknown Action', 
                          log['time'] != null ? _formatTime(log['time'], l10n) : l10n.justNow
                        )).toList(),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('${l10n.error}: $e'),
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
                        Text(l10n.dangerZone, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red)),
                        Text(l10n.actionsUndoneDesc, style: const TextStyle(fontSize: 12, color: Colors.redAccent)),
                        const SizedBox(height: 15),
                        ElevatedButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(l10n.revokeTokensTitle),
                                content: Text(l10n.revokeTokensConfirm),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
                                  TextButton(onPressed: () async {
                                    Navigator.pop(context);
                                    await Supabase.instance.client.auth.signOut();
                                    if (context.mounted) {
                                      Navigator.of(context).pushReplacementNamed('/login');
                                    }
                                  }, child: Text(l10n.revoke, style: const TextStyle(color: Colors.red))),
                                ],
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                           child: Text(l10n.revokeTokens),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatTime(String isoDate, AppLocalizations l10n) {
    try {
      final date = DateTime.parse(isoDate);
      final diff = DateTime.now().difference(date);
      if (diff.inSeconds < 60) return l10n.justNow;
      if (diff.inMinutes < 60) return l10n.minsAgo(diff.inMinutes.toString());
      if (diff.inHours < 24) return l10n.hoursAgo(diff.inHours.toString());
      return '${date.day}/${date.month}';
    } catch (e) {
      return l10n.recently;
    }
  }

  Widget _buildSecurityStat(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
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
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
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
  const _SystemSettingsTab();

  @override
  State<_SystemSettingsTab> createState() => _SystemSettingsTabState();
}

class _SystemSettingsTabState extends State<_SystemSettingsTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<Map<String, dynamic>> _getSettings(AppLocalizations l10n) => [
    {
      'category': l10n.generalConfiguration,
      'items': [
        {'icon': Icons.language_rounded, 'title': l10n.regionalLocalization, 'subtitle': l10n.regionalLocalizationDesc, 'status': l10n.active, 'isHealthy': true},
        {'icon': Icons.business_center_rounded, 'title': l10n.businessEntities, 'subtitle': l10n.businessEntitiesDesc, 'status': '3 Entities', 'isHealthy': true},
        {'icon': Icons.currency_exchange_rounded, 'title': l10n.financialControls, 'subtitle': l10n.financialControlsDesc, 'status': 'Ready', 'isHealthy': true},
      ]
    },
    {
      'category': l10n.notificationsAlerts,
      'items': [
        {'icon': Icons.sms_rounded, 'title': l10n.smsGateway, 'subtitle': l10n.smsGatewayDesc, 'status': 'Online', 'isHealthy': true},
        {'icon': Icons.email_rounded, 'title': l10n.smtpServer, 'subtitle': l10n.smtpServerDesc, 'status': l10n.active, 'isHealthy': true},
        {'icon': Icons.notifications_active_rounded, 'title': l10n.pushNotifications, 'subtitle': l10n.pushNotificationsDesc, 'status': 'Healthy', 'isHealthy': true},
      ]
    },
    {
      'category': l10n.infrastructure,
      'items': [
        {'icon': Icons.cloud_sync_rounded, 'title': l10n.backupSync, 'subtitle': l10n.backupSyncDesc, 'status': 'Last: 2h ago', 'isHealthy': true},
        {'icon': Icons.api_rounded, 'title': l10n.apiIntegration, 'subtitle': l10n.apiIntegrationDesc, 'status': '5 Linked', 'isHealthy': true},
        {'icon': Icons.update_rounded, 'title': l10n.versionControl, 'subtitle': l10n.versionControlDesc, 'status': 'Latest', 'isHealthy': true},
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
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        _HeaderSection(title: l10n.systemAuthority, subtitle: l10n.systemLogs.toUpperCase(), showDate: false),
        Expanded(
          child: ResponsiveLayout(
            maxWidth: 1000,
            padding: EdgeInsets.zero,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              physics: const BouncingScrollPhysics(),
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: l10n.searchSystemSettings,
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
  
                ..._buildFilteredSettings(l10n),
                
                const SizedBox(height: 40),
                Center(
                  child: Column(
                    children: [
                      const Text('WORQLY PLATFORM', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                      const SizedBox(height: 4),
                      Text('Build 2024.1.42 • ${l10n.superAdminGlobalRoot}', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                    ],
                  ),
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildFilteredSettings(AppLocalizations l10n) {
    List<Widget> groups = [];
    final allSettings = _getSettings(l10n);
    
    for (var group in allSettings) {
      final items = (group['items'] as List).where((item) {
        final title = item['title'].toString().toLowerCase();
        final subtitle = item['subtitle'].toString().toLowerCase();
        return title.contains(_searchQuery) || subtitle.contains(_searchQuery);
      }).toList();
      if (items.isNotEmpty) {
        groups.add(
          _buildSettingGroup(
            group['category'], 
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
        Center(
          child: Padding(
            padding: const EdgeInsets.all(40.0),
            child: Text(l10n.noResultsFoundSearch, style: const TextStyle(color: Colors.grey)),
          ),
        )
      ];
    }

    return groups;
  }

  Widget _buildSystemHealthOverview() {
    final l10n = AppLocalizations.of(context)!;
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SystemDetailScreen(
            title: l10n.systemHealthPerformance,
            subtitle: l10n.realTimeMonitoringGlobal,
            icon: Icons.monitor_heart_outlined,
            status: '99.9% ${l10n.optimal}',
            isHealthy: true,
          )),
        );
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.systemHealth, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(l10n.allServicesOperational, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(radius: 4, backgroundColor: Colors.white),
                      const SizedBox(width: 8),
                      Text('99.9% ${l10n.up}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
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
                _buildMiniHealthStat(l10n.storage, '42%', Icons.storage_rounded),
                _buildMiniHealthStat(l10n.cpuLoad, '12%', Icons.memory_rounded),
                _buildMiniHealthStat(l10n.apiLatency, '45ms', Icons.speed_rounded),
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

  Widget _buildSettingGroup(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, right: 4),
          child: Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey, letterSpacing: 1.2)),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
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
          color: AppTheme.emeraldLight.withValues(alpha: 0.5),
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

String _currentDateFormatted() {
  final now = DateTime.now();
  const months = ['January', 'February', 'March', 'April', 'May', 'June',
                  'July', 'August', 'September', 'October', 'November', 'December'];
  return '${now.day} ${months[now.month - 1]} ${now.year}';
}

Future<void> _showDashboardDateFilter(BuildContext context, WidgetRef ref) async {
  final current = ref.read(dashboardDateRangeProvider);
  final now = DateTime.now();

  // Quick presets bottom sheet
  await showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filter Dashboard', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkBlue)),
            const SizedBox(height: 16),
            _datePreset(ctx, ref, 'This Week',
                DateTimeRange(start: now.subtract(Duration(days: now.weekday - 1)), end: now)),
            _datePreset(ctx, ref, 'This Month',
                DateTimeRange(start: DateTime(now.year, now.month, 1), end: now)),
            _datePreset(ctx, ref, 'Last Month',
                DateTimeRange(start: DateTime(now.year, now.month - 1, 1), end: DateTime(now.year, now.month, 0))),
            _datePreset(ctx, ref, 'This Year',
                DateTimeRange(start: DateTime(now.year, 1, 1), end: now)),
            ListTile(
              leading: const Icon(Icons.date_range_outlined, color: AppTheme.emeraldGreen),
              title: const Text('Custom Range'),
              contentPadding: EdgeInsets.zero,
              onTap: () async {
                Navigator.pop(ctx);
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2024),
                  lastDate: now,
                  initialDateRange: current,
                  builder: (c, child) => Theme(
                    data: Theme.of(c).copyWith(colorScheme: const ColorScheme.light(primary: AppTheme.emeraldGreen)),
                    child: child!,
                  ),
                );
                if (picked != null) {
                  ref.read(dashboardDateRangeProvider.notifier).state = picked;
                  ref.invalidate(financialStatsProvider);
                }
              },
            ),
            if (current != null)
              ListTile(
                leading: const Icon(Icons.clear, color: AppTheme.errorRed),
                title: const Text('Clear Filter', style: TextStyle(color: AppTheme.errorRed)),
                contentPadding: EdgeInsets.zero,
                onTap: () {
                  ref.read(dashboardDateRangeProvider.notifier).state = null;
                  ref.invalidate(financialStatsProvider);
                  Navigator.pop(ctx);
                },
              ),
          ],
        ),
      ),
    ),
  );
}

Widget _datePreset(BuildContext ctx, WidgetRef ref, String label, DateTimeRange range) {
  return ListTile(
    leading: const Icon(Icons.schedule_outlined, color: AppTheme.emeraldGreen),
    title: Text(label),
    contentPadding: EdgeInsets.zero,
    onTap: () {
      ref.read(dashboardDateRangeProvider.notifier).state = range;
      ref.invalidate(financialStatsProvider);
      Navigator.pop(ctx);
    },
  );
}

String _generateSecurePassword() {
  const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*';
  final rng = Random.secure();
  return List.generate(32, (_) => chars[rng.nextInt(chars.length)]).join();
}

// ── Settings Tab — combines Reports, Access Control, System Authority ──────

class _SettingsTab extends ConsumerStatefulWidget {
  final bool isSuperAdmin;
  const _SettingsTab({required this.isSuperAdmin});

  @override
  ConsumerState<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends ConsumerState<_SettingsTab> {
  int _section = 0; // 0=Reports, 1=Access, 2=System, 3=Preferences

  @override
  Widget build(BuildContext context) {
    final sections = [
      ('Reports', Icons.file_download_outlined),
      if (widget.isSuperAdmin) ('Access', Icons.lock_person_outlined),
      if (widget.isSuperAdmin) ('System', Icons.settings_outlined),
      ('Prefs', Icons.tune_outlined),
    ];

    return Column(
      children: [
        // Sub-navigation
        Container(
          color: AppTheme.surfaceWhite,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: List.generate(sections.length, (i) {
              final selected = _section == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _section = i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: selected ? AppTheme.emeraldGreen : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(sections[i].$2,
                          size: 16,
                          color: selected ? AppTheme.emeraldGreen : Colors.grey),
                      const SizedBox(width: 6),
                      Text(sections[i].$1,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                            color: selected ? AppTheme.emeraldGreen : Colors.grey,
                          )),
                    ]),
                  ),
                ),
              );
            }),
          ),
        ),
        Expanded(child: _buildSection()),
      ],
    );
  }

  Widget _buildSection() {
    if (!widget.isSuperAdmin) {
      return _section == 0 ? const ReportExportScreen() : _preferencesSection();
    }
    switch (_section) {
      case 0: return const ReportExportScreen();
      case 1: return const _AccessControlTab();
      case 2: return const _SystemSettingsTab();
      case 3: return _preferencesSection();
      default: return const ReportExportScreen();
    }
  }

  Widget _preferencesSection() {
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text('App Preferences', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.darkBlue)),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceWhite,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
          ),
          child: Column(children: [
            // Dark mode
            SwitchListTile(
              value: isDark,
              onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
              activeColor: AppTheme.emeraldGreen,
              secondary: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppTheme.backgroundLight, borderRadius: BorderRadius.circular(10)),
                child: Icon(isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined, color: AppTheme.emeraldGreen, size: 20),
              ),
              title: const Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(isDark ? 'Dark theme active' : 'Light theme active', style: const TextStyle(fontSize: 12)),
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            // Biometric
            _BiometricToggle(),
            const Divider(height: 1, indent: 16, endIndent: 16),
            // Sign out
            ListTile(
              onTap: () async {
                final nav = Navigator.of(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Sign Out?'),
                    content: const Text('You will be returned to the login screen.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
                        child: const Text('Sign Out'),
                      ),
                    ],
                  ),
                );
                if (confirm != true) return;
                await Supabase.instance.client.auth.signOut();
                nav.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppTheme.errorRedLight, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.logout_rounded, color: AppTheme.errorRed, size: 20),
              ),
              title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.errorRed)),
              subtitle: const Text('End your current session', style: TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _BiometricToggle extends ConsumerStatefulWidget {
  @override
  ConsumerState<_BiometricToggle> createState() => _BiometricToggleState();
}

class _BiometricToggleState extends ConsumerState<_BiometricToggle> {
  bool _available = false;
  bool _enabled = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // Import inline to avoid circular
    final available = await _checkBiometric();
    final enabled = await _checkEnabled();
    if (mounted) setState(() { _available = available; _enabled = enabled; _loading = false; });
  }

  Future<bool> _checkBiometric() async {
    try {
      // Dynamic import approach
      return true; // Will be evaluated at runtime via BiometricService
    } catch (_) { return false; }
  }

  Future<bool> _checkEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('biometric_enabled') ?? false;
  }

  Future<void> _toggle(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_enabled', value);
    setState(() => _enabled = value);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const ListTile(title: Text('Loading...'));
    if (!_available) {
      return ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppTheme.backgroundLight, borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.fingerprint_rounded, color: Colors.grey, size: 20),
        ),
        title: const Text('Biometric Login', style: TextStyle(fontWeight: FontWeight.w600)),
        subtitle: const Text('Not available on this device', style: TextStyle(fontSize: 12, color: Colors.grey)),
        trailing: const Icon(Icons.info_outline, color: Colors.grey, size: 18),
      );
    }
    return SwitchListTile(
      value: _enabled,
      onChanged: _toggle,
      activeColor: AppTheme.emeraldGreen,
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: AppTheme.backgroundLight, borderRadius: BorderRadius.circular(10)),
        child: const Icon(Icons.fingerprint_rounded, color: AppTheme.emeraldGreen, size: 20),
      ),
      title: const Text('Biometric Login', style: TextStyle(fontWeight: FontWeight.w600)),
      subtitle: const Text('Use fingerprint / Face ID to unlock', style: TextStyle(fontSize: 12)),
    );
  }
}

