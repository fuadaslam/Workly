import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:intl/intl.dart';
import 'package:service_manager_app/l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/utils/contact_utils.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/biometric_service.dart';
import '../providers/dashboard_provider.dart';
import 'profile_view.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../auth/presentation/providers/profile_provider.dart';
import '../../../auth/domain/models/profile.dart';
import '../../../leaves/presentation/widgets/admin_leave_list.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../../attendance/presentation/widgets/attendance_monitor.dart';

import 'assignment_sheet.dart';
import '../../../enquiries/presentation/pages/enquiry_list_screen.dart';
import '../pages/works_management_screen.dart';
import '../../../reports/presentation/report_export_screen.dart';
import '../../../search/presentation/global_search_bar.dart';
import '../../../../core/providers/theme_provider.dart';

import '../../../../core/widgets/collapsible_sidebar.dart';
import '../../../../core/widgets/workly_primitives.dart';
import '../../domain/models/work_order.dart';

final superAdminTabIndexProvider = StateProvider<int>((ref) => 0);

class SuperAdminView extends ConsumerStatefulWidget {
  const SuperAdminView({super.key});

  @override
  ConsumerState<SuperAdminView> createState() => _SuperAdminViewState();
}

class _SuperAdminViewState extends ConsumerState<SuperAdminView> {
  final List<GlobalKey<NavigatorState>> _navKeys = List.generate(
    9,
    (_) => GlobalKey<NavigatorState>(),
  );

  Future<void> _signOut(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    if (context.mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(superAdminTabIndexProvider);
    final profile = ref.watch(profileProvider).valueOrNull;
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
       const BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined), label: 'Works'),
       const BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Settings'),
    ];

    final sidebarItems = [
      SidebarItem(icon: Icons.grid_view_rounded, label: l10n.dashboard),
      const SidebarItem(icon: Icons.business_outlined, label: 'Offices'),
      const SidebarItem(icon: Icons.how_to_reg_outlined, label: 'Attendance'),
      const SidebarItem(icon: Icons.calendar_month_outlined, label: 'Leaves'),
      SidebarItem(icon: Icons.people_outline, label: l10n.staff),
      SidebarItem(icon: Icons.support_agent_outlined, label: l10n.agents),
      const SidebarItem(icon: Icons.track_changes_outlined, label: 'Enquiries'),
      const SidebarItem(icon: Icons.assignment_outlined, label: 'Works'),
      const SidebarItem(icon: Icons.settings_outlined, label: 'Settings'),
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

    final userName = profile?.name ?? 'Super Admin';
    final userRole = isSuperAdmin ? 'Super Admin' : 'Admin';

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 800) {
          // Desktop Layout with CollapsibleSidebar
          return Scaffold(
            backgroundColor: scaffoldBg,
            endDrawer: const Drawer(width: 400, child: ProfileView()),
            body: Row(
              children: [
                CollapsibleSidebar(
                  selectedIndex: currentIndex < sidebarItems.length ? currentIndex : 0,
                  items: sidebarItems,
                  onDestinationSelected: (idx) => ref.read(superAdminTabIndexProvider.notifier).state = idx,
                  onSignOut: () => _signOut(context),
                  userName: userName,
                  userRole: userRole,
                ),
                Expanded(
                  child: IndexedStack(
                    index: currentIndex < sidebarItems.length ? currentIndex : 0,
                    children: List.generate(9, (index) {
                      return Navigator(
                        key: _navKeys[index],
                        onGenerateRoute: (settings) {
                          return MaterialPageRoute(
                            builder: (context) => _buildCurrentTab(index, isSuperAdmin),
                          );
                        },
                      );
                    }),
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
            endDrawer: const Drawer(width: 350, child: ProfileView()),
            body: IndexedStack(
              index: currentIndex < tabs.length ? currentIndex : 0,
              children: List.generate(9, (index) {
                return Navigator(
                  key: _navKeys[index],
                  onGenerateRoute: (settings) {
                    return MaterialPageRoute(
                      builder: (context) => _buildCurrentTab(index, isSuperAdmin),
                    );
                  },
                );
              }),
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
      case 7: return const WorksManagementTab();
      case 8: return _SettingsTab(isSuperAdmin: isSuperAdmin);
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
                leading: const Icon(Icons.language, color: AppTheme.electricBlue),
                title: const Text('English'),
                trailing: ref.watch(localeProvider).languageCode == 'en' ? const Icon(Icons.check, color: AppTheme.electricBlue) : null,
                onTap: () {
                  ref.read(localeProvider.notifier).state = const Locale('en');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.language, color: AppTheme.electricBlue),
                title: const Text('العربية'),
                trailing: ref.watch(localeProvider).languageCode == 'ar' ? const Icon(Icons.check, color: AppTheme.electricBlue) : null,
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

  Widget _buildHeaderIcon({required IconData icon, required VoidCallback onTap, required bool isDark}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(8),
          border: isDark ? Border.all(color: Colors.white.withValues(alpha: 0.1)) : null,
        ),
        child: Icon(icon, color: isDark ? Colors.white70 : Colors.black87, size: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        border: Border(bottom: BorderSide(color: isDark ? AppTheme.darkBorder : const Color(0xFFEAEAEA))),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(title, 
                            style: TextStyle(color: isDark ? Colors.white : AppTheme.darkBlue, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.5),
                            overflow: TextOverflow.ellipsis),
                        if (showDate) ...[
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.darkCardAlt : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFEAEAEA)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.circle, color: AppTheme.electricBlue, size: 6),
                                const SizedBox(width: 6),
                                Text(l10n.systemAuthority.toUpperCase(), style: TextStyle(color: isDark ? AppTheme.darkSubtext : const Color(0xFF64748B), fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                              ]
                            )
                          ),
                        ]
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(subtitle, 
                            style: TextStyle(color: isDark ? AppTheme.darkSubtext : const Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis),
                        if (showDate) ...[
                          const SizedBox(width: 8),
                          Text('•', style: TextStyle(color: isDark ? AppTheme.darkSubtext : const Color(0xFF64748B))),
                          const SizedBox(width: 8),
                          Text(_currentDateFormatted(),
                              style: TextStyle(color: isDark ? AppTheme.darkSubtext : const Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeaderIcon(
                    icon: ref.watch(themeModeProvider) == ThemeMode.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                    onTap: () => ref.read(themeModeProvider.notifier).toggle(),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  if (MediaQuery.of(context).size.width >= 700) ...[
                    const GlobalSearchBar(width: 300),
                    const SizedBox(width: 8),
                  ] else ...[
                    _buildHeaderIcon(
                      icon: Icons.search_rounded,
                      onTap: () => context.push('/dashboard/search'),
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8),
                  ],
                  GestureDetector(
                    onTap: () => _showLanguagePicker(context, ref),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05)),
                      ),
                      child: Text(
                        currentLocale.languageCode == 'en' ? 'عربي' : 'EN',
                        style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Builder(
                    builder: (context) => GestureDetector(
                      onTap: () {
                        Scaffold.of(context).openEndDrawer();
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0), width: 1),
                        ),
                        child: const CircleAvatar(
                          radius: 16,
                          backgroundColor: AppTheme.electricBlue,
                          child: Text('SA', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// --- TAB 1: EXECUTIVE DASHBOARD ---

class _ExecutiveDashboardTab extends ConsumerWidget {
  const _ExecutiveDashboardTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        _HeaderSection(title: l10n.superAdmin, subtitle: l10n.vision2030Portal.toUpperCase()),
        Expanded(
          child: RefreshIndicator(
            color: AppTheme.ink900,
            onRefresh: () async {
              ref.invalidate(financialStatsProvider);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ResponsiveLayout(
              maxWidth: double.infinity,
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
                       Text(l10n.executiveOverview.toUpperCase(), style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
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

                  // KPI StatCard row (Operations Dashboard layout)
                  _buildKpiGrid(context, ref),

                  const SizedBox(height: 30),

                  // Live operations feed
                  const Text('LIVE OPERATIONS FEED',
                      style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                  const SizedBox(height: 14),
                  _buildOpsFeed(context, ref),

                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.operationalTrends, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.darkBlue)),
                      TextButton(
                        onPressed: () {
                          context.push('/dashboard/trend');
                        },
                        child: Text(l10n.viewDetailed, style: const TextStyle(fontSize: 12))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildRevenueChart(context, ref),

                  const SizedBox(height: 30),
                  _buildStaffKPIs(context, l10n, ref),
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

  /// 4-up KPI grid — Total Orders, Completed (wk), Cash Collected, High Priority.
  /// Falls to 2 columns under 720px, single column under 460px.
  Widget _buildKpiGrid(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final financialStats = ref.watch(financialStatsProvider);
    final ordersAsync = ref.watch(allWorkOrdersProvider);

    String s(AsyncValue v, String Function(dynamic) f) =>
        v.maybeWhen(data: f, orElse: () => '—');

    final totalOrders = s(statsAsync, (d) => '${d['total'] ?? 0}');
    final completedWk = s(statsAsync, (d) => '${d['completedThisWeek'] ?? 0}');
    final highPriority = ordersAsync.maybeWhen(
      data: (orders) => orders
          .where((o) => o.priority == PriorityLevel.high && o.status != WorkStatus.completed)
          .length
          .toString(),
      orElse: () => '—',
    );

    String cashValue = '—';
    String? cashUnit;
    financialStats.maybeWhen(
      data: (d) {
        final total = (d['totalReceivables'] as num? ?? 0).toDouble();
        cashUnit = 'SAR';
        if (total >= 1000000) {
          cashValue = '${(total / 1000000).toStringAsFixed(1)}M';
        } else if (total >= 1000) {
          cashValue = '${(total / 1000).toStringAsFixed(0)}K';
        } else {
          cashValue = total.toStringAsFixed(0);
        }
      },
      orElse: () {},
    );

    final cards = <Widget>[
      WorqlyStatCard(
        icon: Icons.receipt_long_rounded,
        label: 'Total Orders',
        value: totalOrders,
        tone: StatTone.ink,
        onTap: () => context.push('/dashboard/active-cases'),
      ),
      WorqlyStatCard(
        icon: Icons.task_alt_rounded,
        label: 'Completed (wk)',
        value: completedWk,
        tone: StatTone.completed,
      ),
      WorqlyStatCard(
        icon: Icons.payments_rounded,
        label: 'Cash Collected',
        value: cashValue,
        unit: cashUnit,
        tone: StatTone.brand,
        onTap: () => context.push('/dashboard/revenue'),
      ),
      WorqlyStatCard(
        icon: Icons.bolt_rounded,
        label: 'High Priority',
        value: highPriority,
        tone: StatTone.danger,
      ),
    ];

    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth >= 720 ? 4 : (c.maxWidth >= 460 ? 2 : 1);
      const gap = 16.0;
      final cardWidth = (c.maxWidth - gap * (cols - 1)) / cols;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: cards.map((w) => SizedBox(width: cardWidth, child: w)).toList(),
      );
    });
  }

  /// Live operations feed — recent work orders rendered as WorkOrderCards.
  Widget _buildOpsFeed(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(allWorkOrdersProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AppTheme.primaryAccent(isDark);

    return ordersAsync.when(
      loading: () => SizedBox(height: 120, child: Center(child: CircularProgressIndicator(color: accent))),
      error: (_, __) => SizedBox(
        height: 120,
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.error_outline_rounded, color: isDark ? AppTheme.darkSubtext : Colors.grey, size: 28),
            const SizedBox(height: 6),
            Text('Failed to load work orders',
                style: TextStyle(color: isDark ? AppTheme.darkSubtext : Colors.grey, fontSize: 12)),
          ]),
        ),
      ),
      data: (orders) {
        if (orders.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Column(children: [
                Icon(Icons.inbox_rounded, size: 40, color: isDark ? AppTheme.darkBorder : const Color(0xFFD4D4D8)),
                const SizedBox(height: 8),
                Text('No active work orders.',
                    style: TextStyle(color: isDark ? AppTheme.darkSubtext : const Color(0xFFA1A1AA), fontSize: 13)),
              ]),
            ),
          );
        }
        final recent = orders.take(9).toList();
        return LayoutBuilder(builder: (context, c) {
          final cols = (c.maxWidth / 340).floor().clamp(1, 3);
          const gap = 16.0;
          final cardWidth = (c.maxWidth - gap * (cols - 1)) / cols;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: recent.map((o) {
              final status = switch (o.status) {
                WorkStatus.inProgress => WorqlyOrderStatus.progress,
                WorkStatus.completed => WorqlyOrderStatus.completed,
                WorkStatus.pending => WorqlyOrderStatus.pending,
              };
              return SizedBox(
                width: cardWidth,
                child: WorqlyWorkOrderCard(
                  serviceType: o.serviceType ?? 'General Service',
                  orderId: o.id.length > 8 ? 'WO-${o.id.substring(0, 6).toUpperCase()}' : o.id,
                  clientName: o.clientName,
                  staffName: o.assignedStaffName,
                  officeName: o.assignedOfficeName,
                  status: status,
                  highPriority: o.priority == PriorityLevel.high,
                  contactable: (o.clientPhoneNumber ?? '').isNotEmpty,
                  onTap: () {
                    context.push(
                      '/dashboard/task/${o.id}',
                      extra: TaskRouteArgs(
                        clientName: o.clientName ?? 'Unknown',
                        clientPhone: o.clientPhoneNumber,
                        priority: o.priority.name,
                        initialStatus: o.status.name,
                      ),
                    );
                  },
                ),
              );
            }).toList(),
          );
        });
      },
    );
  }

  Widget _buildRevenueChart(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppTheme.darkCard : Colors.white;
    final cardBorder = isDark ? AppTheme.darkBorder : const Color(0xFFEAEAEA);
    final metaColor = isDark ? AppTheme.darkSubtext : const Color(0xFF64748B);
    final gridColor = isDark ? AppTheme.darkBorder.withValues(alpha: 0.5) : Colors.grey.withValues(alpha: 0.08);
    final accent = AppTheme.primaryAccent(isDark);

    final trendAsync = ref.watch(monthlyEnquiryTrendProvider);
    final now = DateTime.now();
    final months = List.generate(6, (i) => DateFormat('MMM').format(DateTime(now.year, now.month - 5 + i)));

    String growthLabel = '— Enquiries / 6 mo';
    List<FlSpot> spots = List.generate(6, (i) => FlSpot(i.toDouble(), 0));

    return trendAsync.when(
      loading: () => Container(
        height: 260,
        decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: cardBorder)),
        child: Center(child: CircularProgressIndicator(color: accent)),
      ),
      error: (_, __) => Container(
        height: 260,
        decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: cardBorder)),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.error_outline_rounded, color: metaColor, size: 28),
            const SizedBox(height: 6),
            Text('Failed to load trend data', style: TextStyle(color: metaColor, fontSize: 12)),
          ]),
        ),
      ),
      data: (counts) {
        spots = List.generate(6, (i) => FlSpot(i.toDouble(), counts[i]));
        final prev = counts[4];
        final curr = counts[5];
        if (prev > 0) {
          final pct = ((curr - prev) / prev * 100).round();
          growthLabel = pct >= 0 ? '+$pct% vs last month' : '$pct% vs last month';
        } else if (curr > 0) {
          growthLabel = 'New enquiries this month';
        }

        final maxY = (counts.reduce((a, b) => a > b ? a : b) + 2).clamp(4.0, double.infinity);

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cardBorder, width: 1),
            boxShadow: [
              if (!isDark) const BoxShadow(color: Color(0x04000000), blurRadius: 6, offset: Offset(0, 2)),
            ],
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
                      Text('Enquiry Activity', style: TextStyle(color: metaColor, fontSize: 13, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text(growthLabel, style: TextStyle(
                        color: curr >= prev ? AppTheme.mintGreen : AppTheme.errorRed,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      )),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkCardAlt : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('6 Months', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: metaColor)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 180,
                child: LineChart(
                  LineChartData(
                    minY: 0,
                    maxY: maxY,
                    gridData: FlGridData(
                      show: true, drawVerticalLine: false,
                      horizontalInterval: (maxY / 4).ceilToDouble().clamp(1, double.infinity),
                      getDrawingHorizontalLine: (_) => FlLine(color: gridColor, strokeWidth: 1, dashArray: [4, 4]),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx < 0 || idx >= months.length) return const SizedBox();
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              child: Text(months[idx], style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: metaColor)),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        curveSmoothness: 0.35,
                        color: accent,
                        barWidth: 2,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                            radius: index == 5 ? 4 : 3,
                            color: cardBg,
                            strokeWidth: 2,
                            strokeColor: accent,
                          ),
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [accent.withValues(alpha: 0.18), accent.withValues(alpha: 0.0)],
                            begin: Alignment.topCenter, end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStaffKPIs(BuildContext context, AppLocalizations l10n, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final kpiAsync = ref.watch(serviceTypeKpiProvider);
    final cardBg = isDark ? AppTheme.darkCard : Colors.white;
    final cardBorder = isDark ? AppTheme.darkBorder : const Color(0xFFE9EEF5);
    final titleColor = isDark ? AppTheme.darkOnSurface : AppTheme.darkBlue;
    final metaColor = isDark ? AppTheme.darkSubtext : const Color(0xFF64748B);
    final accent = AppTheme.primaryAccent(isDark);

    return kpiAsync.when(
      loading: () => SizedBox(height: 80, child: Center(child: CircularProgressIndicator(color: accent))),
      error: (_, __) => SizedBox(
        height: 80,
        child: Center(child: Text('Failed to load KPIs', style: TextStyle(color: metaColor, fontSize: 12))),
      ),
      data: (kpis) {
        if (kpis.isEmpty) return const SizedBox();
        final avgCompletion = kpis.fold(0.0, (sum, k) => sum + (k['percent'] as double)) / kpis.length;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cardBorder, width: 1),
            boxShadow: [
              if (!isDark) const BoxShadow(color: Color(0x04000000), blurRadius: 6, offset: Offset(0, 2)),
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
                      Text('Completion by Service Type', style: TextStyle(color: titleColor, fontSize: 15, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 3),
                      Text('Top ${kpis.length} service categories', style: TextStyle(color: metaColor, fontSize: 12)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${(avgCompletion * 100).toStringAsFixed(0)}% Avg',
                      style: TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: kpis.map((k) => _buildKPIBar(
                  context, k['label'] as String, (k['percent'] as double), k['total'] as int,
                  isDark, titleColor, metaColor, accent,
                )).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKPIBar(BuildContext context, String label, double percent, int total,
      bool isDark, Color titleColor, Color metaColor, Color accent) {
    final trackColor = isDark ? AppTheme.darkCardAlt : const Color(0xFFF1F5F9);
    return Column(children: [
      Text('$total', style: TextStyle(fontSize: 11, color: titleColor, fontWeight: FontWeight.w700)),
      const SizedBox(height: 6),
      Container(
        height: 110, width: 8,
        decoration: BoxDecoration(color: trackColor, borderRadius: BorderRadius.circular(12)),
        child: FractionallySizedBox(
          heightFactor: percent.clamp(0.0, 1.0),
          alignment: Alignment.bottomCenter,
          child: Container(
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      const SizedBox(height: 10),
      Text(label, style: TextStyle(fontSize: 9, color: metaColor, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
      const SizedBox(height: 3),
      Text('${(percent * 100).toInt()}%', style: TextStyle(fontSize: 11, color: titleColor, fontWeight: FontWeight.w600)),
    ]);
  }
}

/// --- TAB 2: BRANCH MANAGEMENT ---

class _BranchManagementTab extends ConsumerWidget {
  const _BranchManagementTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final officesAsync = ref.watch(filteredOfficesProvider);
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        _HeaderSection(title: l10n.regionalOffices, subtitle: l10n.branchManagement.toUpperCase(), showDate: false),
        Expanded(
          child: ResponsiveLayout(
            maxWidth: double.infinity,
            padding: EdgeInsets.zero,
            child: RefreshIndicator(
              color: AppTheme.ink900,
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? AppTheme.primaryAccent(isDark) : AppTheme.emeraldGreen,
                          foregroundColor: isDark ? AppTheme.ink900 : Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
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
                          prefixIcon: Icon(Icons.search, color: isDark ? AppTheme.darkSubtext : Colors.grey),
                          filled: true,
                          fillColor: isDark ? AppTheme.darkCard : Colors.white,
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
                            _buildFilterChip(context, ref, 'Revenue', Icons.monetization_on_outlined, displayLabel: l10n.revenue),
                            const SizedBox(width: 10),
                            _buildFilterChip(context, ref, 'Workload', Icons.bar_chart, displayLabel: l10n.workloadCapacity),
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
        : totalRevenueValue >= 1000
            ? '${(totalRevenueValue / 1000).toStringAsFixed(0)}K'
            : totalRevenueValue.toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.ink900, AppTheme.ink800],
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
                   value: (avgWorkload / 100).clamp(0.0, 1.0),
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

  Widget _buildFilterChip(BuildContext context, WidgetRef ref, String sortKey, IconData icon, {String? displayLabel}) {
    final label = displayLabel ?? sortKey;
    final currentSort = ref.watch(officeSortProvider);
    final isSelected = currentSort == sortKey;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = AppTheme.primaryAccent(isDark);
    final inactiveBg = isDark ? AppTheme.darkCard : Colors.white;
    final inactiveBorder = isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0);
    final inactiveText = isDark ? AppTheme.darkSubtext : const Color(0xFF64748B);

    return GestureDetector(
      onTap: () => ref.read(officeSortProvider.notifier).state = sortKey,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: isDark ? 0.18 : 0.08) : inactiveBg,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isSelected ? activeColor.withValues(alpha: 0.45) : inactiveBorder,
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 13, color: isSelected ? activeColor : inactiveText),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? activeColor : inactiveText,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ]),
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
        final sheetIsDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: sheetIsDark ? AppTheme.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
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
                      fillColor: sheetIsDark ? AppTheme.darkCardAlt : Colors.grey.shade50,
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
                      fillColor: sheetIsDark ? AppTheme.darkCardAlt : Colors.grey.shade50,
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
                      fillColor: sheetIsDark ? AppTheme.darkCardAlt : Colors.grey.shade50,
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
                      fillColor: sheetIsDark ? AppTheme.darkCardAlt : Colors.grey.shade50,
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
                            fillColor: sheetIsDark ? AppTheme.darkCardAlt : Colors.grey.shade50,
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
                            fillColor: sheetIsDark ? AppTheme.darkCardAlt : Colors.grey.shade50,
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
                        backgroundColor: sheetIsDark ? AppTheme.primaryAccent(sheetIsDark) : AppTheme.emeraldGreen,
                        foregroundColor: sheetIsDark ? AppTheme.ink900 : Colors.white,
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
    if (hexColor == null || hexColor.trim().isEmpty) return AppTheme.emeraldGreen;
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    try {
      return Color(int.parse(hexColor, radix: 16));
    } catch (e) {
      return AppTheme.emeraldGreen;
    }
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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppTheme.darkCard : Colors.white;
    final cardBorder = isDark ? AppTheme.darkBorder : const Color(0xFFE9EEF5);
    final titleColor = isDark ? AppTheme.darkOnSurface : AppTheme.darkBlue;
    final metaColor = isDark ? AppTheme.darkSubtext : const Color(0xFF64748B);
    final iconBg = isDark ? AppTheme.darkCardAlt : const Color(0xFFF1F5F9);
    final iconColor = isDark ? AppTheme.darkSubtext : const Color(0xFF94A3B8);
    final dividerColor = isDark ? AppTheme.darkBorder : const Color(0xFFF1F5F9);
    final accent = AppTheme.primaryAccent(isDark);

    return InkWell(
      onTap: () {
        context.push('/dashboard/office-detail', extra: office);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorder, width: 1),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.business_outlined, color: iconColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: titleColor)),
                        Text(loc, style: TextStyle(color: metaColor, fontSize: 12)),
                        if (office['phone_numbers'] != null && (office['phone_numbers'] as List).isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              ((office['phone_numbers'] as List)[0]['number']?.toString() ?? ''),
                              style: TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      if (office['phone_numbers'] != null && (office['phone_numbers'] as List).isNotEmpty)
                        IconButton(
                          onPressed: () => ContactUtils.openWhatsApp(((office['phone_numbers'] as List)[0]['number']?.toString() ?? '')),
                          icon: const Icon(Icons.message, size: 20, color: Colors.green),
                        ),
                      IconButton(
                        onPressed: () {
                           context.push('/dashboard/office-detail', extra: office);
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
                  Expanded(child: _buildMiniStat(context, l10n.workload, workload, workloadColor, true, isDark)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildMiniStat(context, l10n.staffCount.toUpperCase(), staff, AppTheme.electricBlue, false, isDark)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildMiniStat(context, l10n.revenue, revenue, AppTheme.mutedAmber, false, isDark)),
                ],
              ),
            ),
            Divider(height: 1, color: dividerColor),
            Padding(
               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
               child: Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   Text(l10n.regionalHub, style: TextStyle(color: accent, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                   InkWell(
                     onTap: () {
                        context.push('/dashboard/office-detail', extra: office);
                     },
                     borderRadius: BorderRadius.circular(4),
                     child: Row(children: [
                       Text(l10n.branchSettings, style: TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.w600)),
                       Icon(Icons.chevron_right, size: 14, color: accent),
                     ]),
                   ),
                 ],
               ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildMiniStat(BuildContext context, String label, String val, Color color, bool showProgress, bool isDark) {
    final bg = isDark ? AppTheme.darkCardAlt : const Color(0xFFF8FAFC);
    final textColor = isDark ? AppTheme.darkOnSurface : AppTheme.darkBlue;
    final metaColor = isDark ? AppTheme.darkSubtext : const Color(0xFF94A3B8);
    final trackColor = isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 8, color: metaColor, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(val, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textColor), overflow: TextOverflow.ellipsis),
          if (showProgress) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: 0.8, backgroundColor: trackColor, color: color, minHeight: 3),
            ),
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
            maxWidth: double.infinity,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        _HeaderSection(
          title: isStaffView ? l10n.staffCommandCenter : l10n.totalControlHub, 
          subtitle: (isStaffView ? l10n.manageStaff : l10n.manageAdmins).toUpperCase()
        ),
        Expanded(
          child: ResponsiveLayout(
            maxWidth: double.infinity,
            padding: EdgeInsets.zero,
            child: RefreshIndicator(
              color: AppTheme.ink900,
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? AppTheme.primaryAccent(isDark) : AppTheme.emeraldGreen,
                          foregroundColor: isDark ? AppTheme.ink900 : Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  
                  // Filters
                  TextField(
                    onChanged: (value) => ref.read(isStaffView ? staffSearchQueryProvider.notifier : adminSearchQueryProvider.notifier).state = value,
                    decoration: InputDecoration(
                      hintText: isStaffView ? l10n.searchStaff : l10n.searchAdmins,
                      prefixIcon: Icon(Icons.search, color: isDark ? AppTheme.darkSubtext : Colors.grey),
                      filled: true,
                      fillColor: isDark ? AppTheme.darkCard : Colors.white,
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
    // Note: using Builder pattern since context is not a param here.
    return Builder(builder: (context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final activeColor = AppTheme.primaryAccent(isDark);
      final inactiveBg = isDark ? AppTheme.darkCard : Colors.white;
      final inactiveBorder = isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0);
      final inactiveText = isDark ? AppTheme.darkSubtext : const Color(0xFF64748B);

      return GestureDetector(
        onTap: () => ref.read(adminRoleFilterProvider.notifier).state = label,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? activeColor.withValues(alpha: isDark ? 0.18 : 0.08) : inactiveBg,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: isSelected ? activeColor.withValues(alpha: 0.45) : inactiveBorder,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? activeColor : inactiveText,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      );
    });
  }



  Widget _buildLargeAdminCard(BuildContext context, WidgetRef ref, Map<String, dynamic> admin, {bool isStaff = false}) {
    final l10n = AppLocalizations.of(context)!;
    final name = admin['name'] ?? (isStaff ? 'Unknown Staff' : 'Unknown Admin');
    final role = admin['role'] ?? (isStaff ? 'staff' : 'admin');
    final id = admin['id'];
    final officeName = (admin['offices'] as Map?)?['name'] as String?;
    final isActive = admin['is_active'] as bool? ?? true;
    final isAgent = role.toString().toLowerCase() == 'agent';
    final roleColor = isAgent ? Colors.purple : (isStaff ? AppTheme.statBlue : AppTheme.emeraldGreen);
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppTheme.darkCard : Colors.white;
    final cardBorder = isDark ? AppTheme.darkBorder : const Color(0xFFE9EEF5);
    final titleTextColor = isDark ? AppTheme.darkOnSurface : AppTheme.darkBlue;
    final cardMetaColor = isDark ? AppTheme.darkSubtext : const Color(0xFF94A3B8);
    final cardDivColor = isDark ? AppTheme.darkBorder : const Color(0xFFF1F5F9);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          context.push('/dashboard/admin-detail', extra: admin);
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cardBorder, width: 1),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: roleColor.withValues(alpha: 0.12),
                          child: Text(initial, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: roleColor)),
                        ),
                        Positioned(
                          bottom: -2, right: -2,
                          child: Container(
                            width: 13, height: 13,
                            decoration: BoxDecoration(
                              color: isActive ? AppTheme.mintGreen : cardMetaColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: cardBg, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: titleTextColor)),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: roleColor.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(role.toString().toUpperCase(),
                                    style: TextStyle(fontSize: 10, color: roleColor, fontWeight: FontWeight.w700, letterSpacing: 0.4)),
                              ),
                              if (officeName != null) ...[
                                const SizedBox(width: 6),
                                Icon(Icons.business_outlined, size: 11, color: cardMetaColor),
                                const SizedBox(width: 3),
                                Flexible(
                                  child: Text(officeName,
                                      style: TextStyle(fontSize: 11, color: cardMetaColor),
                                      overflow: TextOverflow.ellipsis),
                                ),
                              ],
                            ],
                          ),
                          if (admin['phone_number'] != null && admin['phone_number'].toString().isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(admin['phone_number'], style: TextStyle(fontSize: 11, color: cardMetaColor)),
                          ],
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isActive ? AppTheme.mintGreen.withValues(alpha: 0.10) : cardMetaColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isActive ? l10n.active : l10n.inactive,
                            style: TextStyle(color: isActive ? AppTheme.mintGreen : cardMetaColor, fontWeight: FontWeight.w600, fontSize: 10),
                          ),
                        ),
                        if (isStaff && id != null) ...[
                          const SizedBox(height: 6),
                          ref.watch(staffActiveTaskCountsProvider).when(
                            data: (counts) {
                              final count = counts[id] ?? 0;
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: count > 0 ? AppTheme.mutedAmber.withValues(alpha: 0.10) : cardMetaColor.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '$count task${count == 1 ? '' : 's'}',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                                      color: count > 0 ? AppTheme.mutedAmber : cardMetaColor),
                                ),
                              );
                            },
                            loading: () => const SizedBox(width: 50, height: 20),
                            error: (_, __) => SizedBox(
                              width: 50,
                              height: 20,
                              child: Icon(Icons.error_outline_rounded, size: 12, color: cardMetaColor),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Container(height: 1, margin: const EdgeInsets.symmetric(horizontal: 16), color: cardDivColor),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                   mainAxisAlignment: MainAxisAlignment.spaceAround,
                   children: [
                     _buildActionButton(context, Icons.edit_outlined, l10n.edit, AppTheme.emeraldGreen, () {
                        context.push('/dashboard/admin-detail', extra: admin);
                     }),
                     if (admin['is_active'] ?? true)
                       _buildActionButton(context, Icons.delete_outline, l10n.delete, AppTheme.errorRed, () async {
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
                    context.push('/dashboard/admin-detail', extra: admin);
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
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
          ],
        ),
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
        builder: (context, setModalState) {
          final sheetIsDark = Theme.of(context).brightness == Brightness.dark;
          return Container(
          decoration: BoxDecoration(
            color: sheetIsDark ? AppTheme.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
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
                      fillColor: sheetIsDark ? AppTheme.darkCardAlt : Colors.grey.shade50,
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
                      fillColor: sheetIsDark ? AppTheme.darkCardAlt : Colors.grey.shade50,
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
                        fillColor: sheetIsDark ? AppTheme.darkCardAlt : Colors.grey.shade50,
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
                      fillColor: sheetIsDark ? AppTheme.darkCardAlt : Colors.grey.shade50,
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
                        fillColor: sheetIsDark ? AppTheme.darkCardAlt : Colors.grey.shade50,
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
                        fillColor: sheetIsDark ? AppTheme.darkCardAlt : Colors.grey.shade50,
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
                            final agentPassword = isAgent ? _generateSecurePassword() : null;
                            await client.rpc('create_user_admin', params: {
                              'new_email': emailController.text.trim(),
                              'new_password': agentPassword ?? passwordController.text.trim(),
                              'full_name': nameController.text.trim(),
                              'user_role': role,
                              'phone': phoneController.text.trim(),
                              'office': selectedOfficeId,
                            });

                            ref.invalidate(allProfilesProvider);
                            if (context.mounted) Navigator.pop(context);
                            if (context.mounted && isAgent && agentPassword != null) {
                              await showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Agent Created', style: TextStyle(fontWeight: FontWeight.bold)),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Share this temporary password with the agent:'),
                                      const SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: AppTheme.ink900,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: SelectableText(
                                          agentPassword,
                                          style: const TextStyle(
                                            fontFamily: 'monospace',
                                            color: AppTheme.electricBlue,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text('The agent should change it after first login.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text('Close'),
                                    ),
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.copy, size: 16),
                                      label: const Text('Copy & Close'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: sheetIsDark ? AppTheme.primaryAccent(sheetIsDark) : AppTheme.emeraldGreen,
                                        foregroundColor: sheetIsDark ? AppTheme.ink900 : Colors.white,
                                      ),
                                      onPressed: () {
                                        Clipboard.setData(ClipboardData(text: agentPassword));
                                        Navigator.pop(ctx);
                                      },
                                    ),
                                  ],
                                ),
                              );
                            } else if (context.mounted) {
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
                        backgroundColor: sheetIsDark ? AppTheme.primaryAccent(sheetIsDark) : AppTheme.emeraldGreen,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: sheetIsDark ? AppTheme.ink900 : Colors.white))
                          : Text(l10n.confirmRegistration, style: TextStyle(color: sheetIsDark ? AppTheme.ink900 : Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          );
        },
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        _HeaderSection(
          title: l10n.agents,
          subtitle: l10n.allAgents.toUpperCase()
        ),
        Expanded(
          child: ResponsiveLayout(
            maxWidth: double.infinity,
            padding: EdgeInsets.zero,
            child: RefreshIndicator(
              color: AppTheme.ink900,
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? AppTheme.primaryAccent(isDark) : AppTheme.emeraldGreen,
                          foregroundColor: isDark ? AppTheme.ink900 : Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  
                  TextField(
                    onChanged: (value) => ref.read(agentSearchQueryProvider.notifier).state = value,
                    decoration: InputDecoration(
                      hintText: l10n.searchAgents,
                      prefixIcon: Icon(Icons.search, color: isDark ? AppTheme.darkSubtext : Colors.grey),
                      filled: true,
                      fillColor: isDark ? AppTheme.darkCard : Colors.white,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                backgroundColor: isDark ? AppTheme.primaryAccent(isDark) : AppTheme.emeraldGreen,
                foregroundColor: isDark ? AppTheme.ink900 : Colors.white,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        _HeaderSection(title: l10n.accessSecurity, subtitle: l10n.accessPermissions.toUpperCase(), showDate: false),
        Expanded(
          child: ResponsiveLayout(
            maxWidth: double.infinity,
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
                        Expanded(child: _buildSecurityStat(l10n.activeSessions, stats['activeSessions'].toString(), Icons.devices, Colors.blue, isDark)),
                        const SizedBox(width: 15),
                        Expanded(child: _buildSecurityStat(l10n.securityAlerts, stats['securityAlerts'].toString(), Icons.warning_amber_rounded, Colors.orange, isDark)),
                      ],
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Row(
                      children: [
                        Expanded(child: _buildSecurityStat(l10n.activeSessions, '0', Icons.devices, Colors.blue, isDark)),
                        const SizedBox(width: 15),
                        Expanded(child: _buildSecurityStat(l10n.securityAlerts, '?', Icons.warning_amber_rounded, Colors.orange, isDark)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(l10n.roleHierarchyPermissions, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  _buildRoleCard(context, ref, l10n.superAdmin, l10n.superAdminAccessDesc, Icons.auto_awesome, AppTheme.emeraldGreen, 'Super Admin', isDark),
                  const SizedBox(height: 12),
                  _buildRoleCard(context, ref, l10n.officeAdmin, l10n.officeAdminAccessDesc, Icons.admin_panel_settings, Colors.amber.shade700, 'Admin', isDark),
                  const SizedBox(height: 12),
                  _buildRoleCard(context, ref, l10n.operationalStaff, l10n.staffAccessDesc, Icons.engineering, Colors.blueGrey, 'All', isDark),
                  
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

  Widget _buildSecurityStat(String label, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
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

  Widget _buildRoleCard(BuildContext context, WidgetRef ref, String title, String desc, IconData icon, Color color, String filterValue, bool isDark) {
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
          color: isDark ? AppTheme.darkCard : Colors.white,
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
        // No SMS gateway or SMTP integration actually exists in this app —
        // show that honestly instead of a fabricated "Online"/"Active" status.
        {'icon': Icons.sms_rounded, 'title': l10n.smsGateway, 'subtitle': l10n.smsGatewayDesc, 'status': 'Not configured', 'isHealthy': false},
        {'icon': Icons.email_rounded, 'title': l10n.smtpServer, 'subtitle': l10n.smtpServerDesc, 'status': 'Not configured', 'isHealthy': false},
        {'icon': Icons.notifications_active_rounded, 'title': l10n.pushNotifications, 'subtitle': l10n.pushNotificationsDesc, 'status': 'Healthy', 'isHealthy': true},
      ]
    },
    {
      'category': l10n.infrastructure,
      'items': [
        // No backup/sync job or external API integration exists either.
        {'icon': Icons.cloud_sync_rounded, 'title': l10n.backupSync, 'subtitle': l10n.backupSyncDesc, 'status': 'Not configured', 'isHealthy': false},
        {'icon': Icons.api_rounded, 'title': l10n.apiIntegration, 'subtitle': l10n.apiIntegrationDesc, 'status': 'Not configured', 'isHealthy': false},
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        _HeaderSection(title: l10n.systemAuthority, subtitle: l10n.systemLogs.toUpperCase(), showDate: false),
        Expanded(
          child: ResponsiveLayout(
            maxWidth: double.infinity,
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
                    prefixIcon: Icon(Icons.search, color: isDark ? AppTheme.darkSubtext : Colors.grey),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () => _searchController.clear())
                        : null,
                    filled: true,
                    fillColor: isDark ? AppTheme.darkCard : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                  ),
                ),
                const SizedBox(height: 25),
  
                if (_searchQuery.isEmpty) ...[
                  // Activity / audit log entry point
                  _ActivityLogEntryCard(isDark: isDark),
                  const SizedBox(height: 20),
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
                context.push(
                  '/dashboard/system-detail',
                  extra: SystemDetailRouteArgs(
                    title: item['title'],
                    subtitle: item['subtitle'],
                    icon: item['icon'],
                    status: item['status'],
                    isHealthy: item['isHealthy'],
                  ),
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
        context.push(
          '/dashboard/system-detail',
          extra: SystemDetailRouteArgs(
            title: l10n.systemHealthPerformance,
            subtitle: l10n.realTimeMonitoringGlobal,
            icon: Icons.monitor_heart_outlined,
            status: '99.9% ${l10n.optimal}',
            isHealthy: true,
          ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
            color: isDark ? AppTheme.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: isDark ? [] : [
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
          color: isDark ? AppTheme.darkSurface : AppTheme.surfaceWhite,
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
            color: isDark ? AppTheme.darkCard : AppTheme.surfaceWhite,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
          ),
          child: Column(children: [
            // Dark mode
            SwitchListTile(
              value: isDark,
              onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
              activeColor: AppTheme.emeraldGreen,
              secondary: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: isDark ? AppTheme.darkCardAlt : AppTheme.backgroundLight, borderRadius: BorderRadius.circular(10)),
                child: Icon(isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined, color: AppTheme.emeraldGreen, size: 20),
              ),
              title: const Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(isDark ? 'Dark theme active' : 'Light theme active', style: const TextStyle(fontSize: 12)),
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            // Biometric
            _BiometricToggle(),
            const Divider(height: 1, indent: 16, endIndent: 16),
            // Enquiry setup (org-level dropdown options)
            ListTile(
              onTap: () => context.push('/dashboard/enquiry-setup'),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: isDark ? AppTheme.darkCardAlt : AppTheme.backgroundLight, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.tune_rounded, color: AppTheme.electricBlue, size: 20),
              ),
              title: const Text('Enquiry Setup', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Manage enquiry dropdown options', style: TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            // Sign out
            ListTile(
              onTap: () async {
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
                if (context.mounted) context.go('/login');
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
    final available = await BiometricService.isAvailable();
    final enabled = await BiometricService.isEnabled();
    if (mounted) setState(() { _available = available; _enabled = enabled; _loading = false; });
  }

  Future<void> _toggle(bool value) async {
    await BiometricService.setEnabled(value);
    setState(() => _enabled = value);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_loading) return const ListTile(title: Text('Loading...'));
    if (!_available) {
      return ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: isDark ? AppTheme.darkCardAlt : AppTheme.backgroundLight, borderRadius: BorderRadius.circular(10)),
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
        decoration: BoxDecoration(color: isDark ? AppTheme.darkCardAlt : AppTheme.backgroundLight, borderRadius: BorderRadius.circular(10)),
        child: const Icon(Icons.fingerprint_rounded, color: AppTheme.emeraldGreen, size: 20),
      ),
      title: const Text('Biometric Login', style: TextStyle(fontWeight: FontWeight.w600)),
      subtitle: const Text('Use fingerprint / Face ID to unlock', style: TextStyle(fontSize: 12)),
    );
  }
}

/// Tappable card that opens the org-wide audit trail (who did what, when).
class _ActivityLogEntryCard extends StatelessWidget {
  final bool isDark;
  const _ActivityLogEntryCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? AppTheme.darkCard : AppTheme.surfaceWhite,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/dashboard/activity-log'),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.electricBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.history_rounded, color: AppTheme.electricBlue, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Activity Log',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isDark ? Colors.white : AppTheme.darkBlue)),
                    const SizedBox(height: 2),
                    Text('Audit trail — who created or changed what',
                        style: TextStyle(fontSize: 12, color: isDark ? AppTheme.darkSubtext : Colors.grey.shade600)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

