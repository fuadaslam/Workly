import 'package:flutter/material.dart';
import 'package:service_manager_app/l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/contact_utils.dart';
import '../../../../features/attendance/presentation/widgets/attendance_card.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/auth/presentation/providers/profile_provider.dart';
import '../../../../features/dashboard/presentation/providers/dashboard_provider.dart';
import '../../../../features/dashboard/domain/models/work_order.dart';
import '../../../../core/router/app_router.dart';
import '../../../../features/enquiries/domain/models/enquiry.dart';
import '../../../../features/enquiries/presentation/providers/enquiry_options_provider.dart';
import '../../../../features/enquiries/data/repositories/enquiry_options_repository.dart';

import '../../../../core/theme/pattern_painter.dart';
import 'profile_view.dart';
import '../pages/notifications_screen.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../../../core/widgets/premium_card.dart';
import '../../../../core/widgets/workly_primitives.dart';
import '../../../../features/leaves/presentation/widgets/leave_widgets.dart';
import '../../../../features/leaves/presentation/providers/leave_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/widgets/collapsible_sidebar.dart';

class StaffView extends StatefulWidget {
  const StaffView({super.key});

  @override
  State<StaffView> createState() => _StaffViewState();
}

class _StaffViewState extends State<StaffView> {
  int _tabIndex = 0;
  final List<GlobalKey<NavigatorState>> _navKeys = List.generate(
    5,
    (_) => GlobalKey<NavigatorState>(),
  );


  Future<void> _signOut(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    if (context.mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer(
      builder: (context, ref, child) {
        final profileAsync = ref.watch(profileProvider);
        final profile = profileAsync.value;
        final userName = profile?.name ?? 'Staff Member';
        final userRole = profile?.role.name.toUpperCase().replaceAll('_', ' ') ?? 'FIELD OPERATIONS SPECIALIST';

        final sidebarItems = [
          SidebarItem(icon: Icons.home_outlined, label: l10n.home),
          SidebarItem(icon: Icons.calendar_month_outlined, label: l10n.leaves),
          SidebarItem(icon: Icons.assignment_outlined, label: l10n.tasks),
          SidebarItem(icon: Icons.person_outline, label: l10n.profile),
        ];

        return LayoutBuilder(
          builder: (context, constraints) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final scaffoldBg = isDark ? AppTheme.darkBackground : AppTheme.backgroundLight;
            if (constraints.maxWidth >= 800) {
              // Desktop Layout with CollapsibleSidebar
              // Map _tabIndex (0, 1, 3, 4) to Sidebar Index (0, 1, 2, 3)
              final sidebarIndex = _tabIndex > 2 ? _tabIndex - 1 : _tabIndex;

              return Scaffold(
                backgroundColor: scaffoldBg,
                body: Row(
                  children: [
                    CollapsibleSidebar(
                      selectedIndex: sidebarIndex,
                      items: sidebarItems,
                      onDestinationSelected: (idx) {
                        // Map Sidebar Index (0, 1, 2, 3) back to _tabIndex (0, 1, 3, 4)
                        final newIndex = idx > 1 ? idx + 1 : idx;
                        setState(() => _tabIndex = newIndex);
                      },
                      onSignOut: () => _signOut(context),
                      userName: userName,
                      userRole: userRole,
                    ),
                    Expanded(
                      child: _buildBody(),
                    ),
                  ],
                ),
                floatingActionButton: FloatingActionButton.extended(
                  onPressed: () => _showAddTaskModal(context),
                  backgroundColor: isDark ? AppTheme.primaryAccent(isDark) : AppTheme.emeraldGreen,
                  elevation: 6,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  icon: Icon(Icons.add, color: isDark ? AppTheme.ink900 : Colors.white, size: 24),
                  label: Text(
                    l10n.createNewTask,
                    style: TextStyle(color: isDark ? AppTheme.ink900 : Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                ),
              );
            } else {
              // Mobile Layout
              return Scaffold(
                backgroundColor: scaffoldBg,
                body: _buildBody(),
                floatingActionButton: Container(
                   height: 64,
                   width: 64,
                   margin: const EdgeInsets.only(top: 30),
                   child: FloatingActionButton(
                    onPressed: () {
                       _showAddTaskModal(context);
                    },
                    backgroundColor: isDark ? AppTheme.primaryAccent(isDark) : AppTheme.emeraldGreen,
                    elevation: 4,
                    shape: const CircleBorder(),
                    child: Icon(Icons.add, color: isDark ? AppTheme.ink900 : Colors.white, size: 32),
                   ),
                ),
                floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
                bottomNavigationBar: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                       BoxShadow(
                         color: Colors.black.withValues(alpha: 0.05),
                         blurRadius: 10,
                         offset: const Offset(0, -5),
                       ),
                    ],
                  ),
                  child: NavigationBar(
                    backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
                    elevation: 0,
                    indicatorColor: Colors.transparent, // Disable pill indicator for custom look
                    selectedIndex: _tabIndex,
                    onDestinationSelected: (idx) {
                      // If tapping the Spacer (index 2), ignore or handle if possible
                      if (idx == 2) return; 
                      setState(() => _tabIndex = idx);
                    },
                    destinations: [
                      _buildNavItem(Icons.home_outlined, Icons.home, l10n.home, 0),
                      _buildNavItem(Icons.calendar_month_outlined, Icons.calendar_month, l10n.leaves, 1),
                      const SizedBox(width: 48), // Spacer for FAB
                      _buildNavItem(Icons.assignment_outlined, Icons.assignment, l10n.tasks, 3),
                      _buildNavItem(Icons.person_outline, Icons.person, l10n.profile, 4),
                    ],
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }
  
  Widget _buildNavItem(IconData unselected, IconData selected, String label, int index) {
    return NavigationDestination(
      icon: Icon(unselected, color: Colors.grey),
      selectedIcon: Icon(selected, color: AppTheme.emeraldGreen),
      label: label,
    );
  }

  Widget _buildBody() {
    return IndexedStack(
      index: _tabIndex,
      children: List.generate(5, (index) {
        return Navigator(
          key: _navKeys[index],
          onGenerateRoute: (settings) {
            return MaterialPageRoute(
              builder: (_) => _buildTab(index),
            );
          },
        );
      }),
    );
  }

  Widget _buildTab(int index) {
    switch (index) {
      case 0:
        return _HomeTab(
          onProfileTap: () => setState(() => _tabIndex = 4),
          onSwitchToTasks: () => setState(() => _tabIndex = 3),
        );
      case 1:
         return const _LeavesView();
      case 3:
         return const _TasksView(); 
      case 4:
         return const ProfileView();
      default:
        return _HomeTab(
          onProfileTap: () => setState(() => _tabIndex = 4),
          onSwitchToTasks: () => setState(() => _tabIndex = 3),
        );
    }
  }

  void _showAddTaskModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const CreateTaskSheet(),
    );
  }
}

class CreateTaskSheet extends StatefulWidget {
  const CreateTaskSheet({super.key});

  @override
  State<CreateTaskSheet> createState() => _CreateTaskSheetState();
}

class _CreateTaskSheetState extends State<CreateTaskSheet> {
  final _clientController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _selectedServiceType;
  String? _selectedNationality;
  String _priority = 'Medium';
  bool _isLoading = false;

  Future<void> _createTask(WidgetRef ref) async {
    if (_clientController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _selectedServiceType == null) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(workOrderRepositoryProvider);
      await repo.createWorkOrder(
        clientName: _clientController.text.trim(),
        clientPhoneNumber: _phoneController.text.trim(),
        serviceType: _selectedServiceType,
        nationality: _selectedNationality,
        priority: _priority,
      );
      
      ref.invalidate(myWorkOrdersProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Task Created Successfully')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer(
      builder: (context, ref, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.createNewTask, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.darkBlue)),
              const SizedBox(height: 20),
              TextField(
                controller: _clientController,
                decoration: InputDecoration(labelText: l10n.clientName, prefixIcon: const Icon(Icons.person)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: l10n.clientPhone, prefixIcon: const Icon(Icons.phone)),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedServiceType,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Nature of Enquiry',
                  prefixIcon: Icon(Icons.work),
                ),
                items: (ref.watch(enquiryOptionValuesProvider(EnquiryOptionCategory.nature)).valueOrNull ?? kNatureOfEnquiry)
                    .map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedServiceType = v),
                hint: const Text('Select nature of enquiry'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedNationality,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Nationality',
                  prefixIcon: Icon(Icons.flag_outlined),
                ),
                items: (ref.watch(enquiryOptionValuesProvider(EnquiryOptionCategory.nationality)).valueOrNull ?? kNationalities)
                    .map((n) => DropdownMenuItem(value: n, child: Text(n)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedNationality = v),
                hint: const Text('Select nationality'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _priority,
                decoration: InputDecoration(labelText: l10n.priority, prefixIcon: const Icon(Icons.flag)),
                items: [
                  DropdownMenuItem(value: 'High', child: Text(l10n.high)),
                  DropdownMenuItem(value: 'Medium', child: Text(l10n.medium)),
                  DropdownMenuItem(value: 'Low', child: Text(l10n.low)),
                ],
                onChanged: (v) => setState(() => _priority = v!),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () => _createTask(ref),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? AppTheme.primaryAccent(isDark) : AppTheme.emeraldGreen,
                      foregroundColor: isDark ? AppTheme.ink900 : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: _isLoading ? CircularProgressIndicator(color: isDark ? AppTheme.ink900 : Colors.white) : Text(l10n.createNewTask),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}


class _HomeTab extends ConsumerWidget {
  final VoidCallback? onProfileTap;
  final VoidCallback? onSwitchToTasks;

  const _HomeTab({this.onProfileTap, this.onSwitchToTasks});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final profileAsync = ref.watch(profileProvider);
    final userName = profileAsync.value?.name ?? 'Staff Member';
    final userRole = profileAsync.value?.role.name.toUpperCase().replaceAll('_', ' ') ?? 'FIELD OPERATIONS SPECIALIST';

    final statsAsync = ref.watch(dashboardStatsProvider);

    return RefreshIndicator(
      color: AppTheme.ink900,
      onRefresh: () async {
        ref.invalidate(dashboardStatsProvider);
        ref.invalidate(leaveProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
          children: [
             // 1. Header with Green Background
               Stack(
                 children: [
                  // Pattern Overlay
                   Positioned.fill(
                     child: ClipRRect(
                       borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
                       child: CustomPaint(
                         painter: MashrabiyaPatternPainter(color: Colors.white.withValues(alpha: 0.05)),
                       ),
                     ),
                   ),
                   Container(
                     padding: const EdgeInsets.fromLTRB(24, 60, 24, 80), // Extra bottom padding for overlap
                     decoration: const BoxDecoration(
                       color: AppTheme.emeraldGreen,
                       borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
                     ),
                     child: Row(
                 children: [
                   GestureDetector(
                     onTap: onProfileTap,
                     child: const CircleAvatar(
                       radius: 26,
                       backgroundColor: Colors.white24,
                       child: Icon(Icons.person, color: Colors.white, size: 30),
                     ),
                   ),
                   const SizedBox(width: 16),
                   Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text(
                           userName,
                           style: const TextStyle(
                             color: Colors.white,
                             fontSize: 18,
                             fontWeight: FontWeight.bold,
                           ),
                         ),
                         Text(
                           userRole,
                           style: TextStyle(
                             color: Colors.white.withValues(alpha: 0.8),
                             fontSize: 10,
                             letterSpacing: 1.0,
                           ),
                         ),
                         const SizedBox(height: 4),
                         // ID Badge or similar
                         Container(
                           padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                           decoration: BoxDecoration(
                             color: Colors.black12,
                             borderRadius: BorderRadius.circular(4),
                           ),
                           child: Text(
                             'ID: ${profileAsync.value?.id.substring(0,8).toUpperCase() ?? "---"}',
                             style: const TextStyle(color: Colors.white70, fontSize: 10),
                           ),
                         )
                       ],
                     ),
                   ),
                   Row(
                     children: [
                        Consumer(
                          builder: (ctx, cRef, _) {
                            final pendingCount = cRef.watch(myWorkOrdersProvider).when(
                              data: (orders) => orders.where((o) => o.status == WorkStatus.pending).length,
                              loading: () => 0,
                              error: (_, __) => 0,
                            );
                            return Badge(
                              isLabelVisible: pendingCount > 0,
                              label: Text('$pendingCount', style: const TextStyle(fontSize: 10)),
                              backgroundColor: AppTheme.errorRed,
                              child: IconButton(
                                onPressed: () => NotificationsScreen.showAsDrawer(context),
                                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                                style: IconButton.styleFrom(backgroundColor: Colors.white12),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => _showLanguageBottomSheet(context, ref),
                          icon: const Icon(Icons.translate, color: Colors.white),
                          style: IconButton.styleFrom(backgroundColor: Colors.white12),
                        ),
                     ],
                   )
                 ],
               ),
             ),
           ],
         ),
  
             // 2. Overlapping Content (All shifted up together)
             ResponsiveLayout(
               maxWidth: double.infinity,
               padding: EdgeInsets.zero,
               child: Transform.translate(
                 offset: const Offset(0, -50),
                 child: Column(
                   children: [
                   // Cards
                   Padding(
                     padding: const EdgeInsets.symmetric(horizontal: 24),
                     child: Column(
                       children: [
                         const AttendanceCard(),
                         const SizedBox(height: 12),
                         _buildWorksSummaryCard(context, statsAsync.value?['pending'] ?? 0),
                         const SizedBox(height: 12),
                         _buildLeavesSummaryCard(context, ref),
                       ],
                     ),
                   ),
   
                   const SizedBox(height: 12), // Reduced Status Spacing
   
                   // 3. Performance
                   Padding(
                     padding: const EdgeInsets.symmetric(horizontal: 24),
                     child: Column(
                       children: [
                         _buildSectionHeader(l10n.performance.toUpperCase()),
                         const SizedBox(height: 8),
                         Row(
                           children: [
                             Expanded(child: _buildStatCard(
                               icon: Icons.check_circle,
                               value: '${statsAsync.value?['completed'] ?? 0} ${l10n.tasks}',
                               label: l10n.completedOverall,
                               badge: '+${statsAsync.value?['completedThisWeek'] ?? 0}',
                               badgeColor: AppTheme.emeraldLight,
                               badgeTextColor: AppTheme.emeraldGreen,
                             )),
                             const SizedBox(width: 12),
                             Expanded(child: _buildStatCard(
                               icon: Icons.access_time_filled,
                               value: statsAsync.value?['avgResponseTime'] ?? '---',
                               label: l10n.avgResponseTime,
                               badge: '-5%',
                               badgeColor: AppTheme.errorRedLight,
                               badgeTextColor: AppTheme.errorRed,
                               isGold: true,
                             )),
                           ],
                         ),
                       ],
                     ),
                   ),
   
                   const SizedBox(height: 12),
   
                   // 4. Quick Access
                   Padding(
                     padding: const EdgeInsets.symmetric(horizontal: 24),
                     child: Column(
                        children: [
                           _buildSectionHeader(l10n.quickAccess.toUpperCase()),
                           const SizedBox(height: 8),
                           Row(
                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
                             children: [
                               _buildQuickAccessItem(context, Icons.qr_code_scanner, l10n.scanDoc, AppTheme.emeraldGreen),
                               _buildQuickAccessItem(context, Icons.assignment, l10n.dailyReport, AppTheme.accentGold),
                               _buildQuickAccessItem(context, Icons.chat_bubble, l10n.support, AppTheme.darkBlue),
                             ],
                           ),
                        ],
                     ),
                   ),
                   
                   const SizedBox(height: 20),
                 ],
               ),
             ),
             ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.0)),
      ],
    );
  }

  Widget _buildWorksSummaryCard(BuildContext context, int pendingCount) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PremiumCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.work_outline, color: AppTheme.emeraldGreen),
                  const SizedBox(width: 8),
                  Text(l10n.myWorks.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.emeraldGreen, fontSize: 12)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppTheme.emeraldLight, borderRadius: BorderRadius.circular(12)),
                child: const Text('Active', style: TextStyle(color: AppTheme.emeraldGreen, fontSize: 10, fontWeight: FontWeight.bold))
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.emeraldLight.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: const Border(left: BorderSide(color: AppTheme.emeraldGreen, width: 4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: AppTheme.emeraldGreen, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text(l10n.assignedTasks.toUpperCase(), style: const TextStyle(color: AppTheme.emeraldGreen, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                ]),
                const SizedBox(height: 8),
                Text('$pendingCount ${l10n.tasksPending}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.darkBlue)),
                Text(l10n.checkTaskList, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                 if (onSwitchToTasks != null) {
                   onSwitchToTasks!();
                 } else {
                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.error)));
                 }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? AppTheme.primaryAccent(isDark) : AppTheme.emeraldGreen,
                foregroundColor: isDark ? AppTheme.ink900 : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(l10n.viewAllWorks),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeavesSummaryCard(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return PremiumCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today, color: AppTheme.accentGold),
                  const SizedBox(width: 8),
                  Text(l10n.leaves.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accentGold, fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     Text('${ref.watch(leaveBalanceProvider)} ${l10n.days}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.darkBlue)),
                     Text(l10n.annualLeaveBalance, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                   showModalBottomSheet(
                     context: context,
                     isScrollControlled: true,
                     builder: (context) => ApplyLeaveForm(onSuccess: () {
                       // Refresh data if needed
                     }),
                   );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentGold,
                  foregroundColor: Colors.white, 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(l10n.apply),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required String badge,
    required Color badgeColor,
    required Color badgeTextColor,
    bool isGold = false,
  }) {
    return PremiumCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isGold ? AppTheme.accentGoldLight : AppTheme.emeraldLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: isGold ? AppTheme.accentGold : AppTheme.emeraldGreen, size: 20),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(badge, style: TextStyle(color: badgeTextColor, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.darkBlue)),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildQuickAccessItem(BuildContext context, IconData icon, String label, Color color) {
    final l10n = AppLocalizations.of(context)!;
    return Expanded(
      child: InkWell(
        onTap: () {
          if (label == l10n.dailyReport) {
            onSwitchToTasks?.call();
          } else if (label == l10n.support) {
            ContactUtils.openWhatsApp('966500000000', message: 'Assalamu Alaikum, I need operational support.');
          } else if (label == l10n.scanDoc) {
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.scannerInitializing)));
          }
        },
        child: PremiumCard(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
          child: Column(
            children: [
              Container(
                 padding: const EdgeInsets.all(12),
                 decoration: BoxDecoration(
                   color: color,
                   shape: BoxShape.circle,
                   boxShadow: [
                     BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
                   ],
                 ),
                 child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(height: 12),
              Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.darkBlue), overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
  void _showLanguageBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final currentLocale = ref.watch(localeProvider);
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.language, color: AppTheme.emeraldGreen),
                  const SizedBox(width: 12),
                  Text(
                    'Select Language / اختر اللغة',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkBlue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildLanguageOption(context, ref, 'English', 'En', 'en', currentLocale.languageCode == 'en'),
              const SizedBox(height: 12),
              _buildLanguageOption(context, ref, 'Arabic / العربية', 'Ar', 'ar', currentLocale.languageCode == 'ar'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(BuildContext context, WidgetRef ref, String label, String displayCode, String languageCode, bool isSelected) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AppTheme.primaryAccent(isDark);
    return InkWell(
      onTap: () {
        ref.read(localeProvider.notifier).state = Locale(languageCode);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Language settings updated'), backgroundColor: AppTheme.emeraldGreen),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? accent.withValues(alpha: 0.12) : (isDark ? AppTheme.darkCardAlt : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? accent : (isDark ? AppTheme.darkBorder : Colors.grey.shade300),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? accent : (isDark ? AppTheme.darkCard : Colors.grey.shade200),
                shape: BoxShape.circle,
              ),
              child: Text(
                displayCode,
                style: TextStyle(
                  color: isSelected ? (isDark ? AppTheme.ink900 : Colors.white) : (isDark ? AppTheme.darkSubtext : Colors.grey.shade700),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppTheme.darkBlue,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppTheme.emeraldGreen),
          ],
        ),
      ),
    );
  }
}

// Reusing and adapting the Tasks Tab logic for the "Inbox/Docs" tab
class _TasksView extends StatefulWidget {
  const _TasksView();

  @override
  State<_TasksView> createState() => _TasksViewState();
}

class _TasksViewState extends State<_TasksView> {
  String _selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.backgroundLight,
      body: SafeArea(
        child: ResponsiveLayout(
          maxWidth: double.infinity,
          padding: EdgeInsets.zero,
          child: Consumer(
            builder: (context, ref, child) {
              final workOrdersAsync = ref.watch(myWorkOrdersProvider);

              return Column(
                children: [
                  // Header & Search
                  Container(
                    padding: const EdgeInsets.all(24),
                    color: isDark ? AppTheme.darkBackground : AppTheme.backgroundLight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         Text(
                           l10n.workInbox,
                           style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? AppTheme.darkOnSurface : AppTheme.darkBlue),
                         ),
                         const SizedBox(height: 20),
                         // Search Bar
                         PremiumCard(
                           padding: EdgeInsets.zero,
                           child: TextField(
                             controller: _searchController,
                             onChanged: (v) => setState(() => _searchQuery = v),
                             decoration: InputDecoration(
                               hintText: l10n.searchPassport,
                               prefixIcon: const Icon(Icons.search, color: Colors.grey),
                               suffixIcon: _searchQuery.isNotEmpty 
                                 ? IconButton(
                                     icon: const Icon(Icons.close, size: 18),
                                     onPressed: () {
                                       _searchController.clear();
                                       setState(() => _searchQuery = '');
                                     },
                                   )
                                 : null,
                               border: InputBorder.none,
                               contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                               hintStyle: TextStyle(color: Colors.grey[400]),
                             ),
                           ),
                         ),
                      ],
                    ),
                  ),
                  
                  // Filter Chips
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      children: [
                        _buildFilterChip(l10n.all),
                        _buildFilterChip(l10n.high),
                        _buildFilterChip(l10n.pending),
                        _buildFilterChip(l10n.completed),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
  
                  // Task List
                  Expanded(
                    child: workOrdersAsync.when(
                      data: (orders) {
                        final filteredOrders = orders.where((o) {
                          // Priority/Status Filter
                          bool matchesFilter = true;
                          if (_selectedFilter == l10n.high) {
                            matchesFilter = o.priority == PriorityLevel.high;
                          } else if (_selectedFilter == l10n.pending) {
                            matchesFilter = o.status == WorkStatus.pending;
                          } else if (_selectedFilter == l10n.completed) {
                            matchesFilter = o.status == WorkStatus.completed;
                          }
   
                          if (!matchesFilter) return false;
   
                          // Search Query Filter
                          if (_searchQuery.isEmpty) return true;
                          final query = _searchQuery.toLowerCase();
                          final clientName = (o.clientName ?? '').toLowerCase();
                          final phone = (o.clientPhoneNumber ?? '').toLowerCase();
                          final service = (o.serviceType ?? '').toLowerCase();
                          
                          return clientName.contains(query) || 
                                 phone.contains(query) || 
                                 service.contains(query);
                        }).toList();
   
                        if (filteredOrders.isEmpty) {
                          return RefreshIndicator(
                          color: AppTheme.ink900,
                          onRefresh: () async => ref.refresh(myWorkOrdersProvider),
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: SizedBox(
                              height: MediaQuery.of(context).size.height - 200,
                              child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                Text(
                                  _searchQuery.isEmpty ? l10n.noTasksFound : l10n.noResultsFor(_searchQuery),
                                  style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                        }
   
                        return RefreshIndicator(
                          color: AppTheme.ink900,
                          onRefresh: () async => ref.refresh(myWorkOrdersProvider),
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          itemCount: filteredOrders.length,
                          itemBuilder: (context, index) {
                            return _buildTaskCard(context, ref, filteredOrders[index]);
                          },
                          ),
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, st) => Center(child: Text('${l10n.error}: $e')),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AppTheme.primaryAccent(isDark);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (v) => setState(() => _selectedFilter = label),
        backgroundColor: isDark ? AppTheme.darkCardAlt : Colors.white,
        selectedColor: accent.withValues(alpha: isDark ? 0.18 : 0.15),
        checkmarkColor: accent,
        labelStyle: TextStyle(
          color: isSelected ? accent : (isDark ? AppTheme.darkSubtext : Colors.grey),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
                color: isSelected ? accent : (isDark ? AppTheme.darkBorder : Colors.grey.shade200))),
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, WidgetRef ref, WorkOrder order) {
    final status = switch (order.status) {
      WorkStatus.inProgress => WorqlyOrderStatus.progress,
      WorkStatus.completed => WorqlyOrderStatus.completed,
      WorkStatus.pending => WorqlyOrderStatus.pending,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: WorqlyWorkOrderCard(
        serviceType: order.serviceType ?? 'General Task',
        orderId: order.id.length > 8 ? 'WO-${order.id.substring(0, 6).toUpperCase()}' : order.id,
        clientName: order.clientName,
        staffName: order.assignedStaffName,
        officeName: order.assignedOfficeName,
        status: status,
        highPriority: order.priority == PriorityLevel.high,
        contactable: (order.clientPhoneNumber ?? '').isNotEmpty,
        actionButton: IconButton(
          icon: const Icon(Icons.edit, size: 16, color: Colors.grey),
          onPressed: () => _showUpdateWorkModal(context, ref, order),
          constraints: const BoxConstraints(),
          padding: EdgeInsets.zero,
        ),
        onTap: () {
          context.push(
            '/dashboard/task/${order.id}',
            extra: TaskRouteArgs(
              clientName: order.clientName ?? 'Unknown',
              clientPhone: order.clientPhoneNumber,
              priority: order.priority.name,
              initialStatus: order.status.name,
            ),
          );
        },
      ),
    );
  }

  void _showUpdateWorkModal(BuildContext context, WidgetRef ref, WorkOrder order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _UpdateWorkSheet(order: order),
    );
  }
}

class _UpdateWorkSheet extends ConsumerStatefulWidget {
  final WorkOrder order;
  const _UpdateWorkSheet({required this.order});

  @override
  ConsumerState<_UpdateWorkSheet> createState() => _UpdateWorkSheetState();
}

class _UpdateWorkSheetState extends ConsumerState<_UpdateWorkSheet> {
  late String _status;
  final TextEditingController _totalController = TextEditingController();
  final TextEditingController _paidController = TextEditingController();
  double balance = 0.0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _status = widget.order.status == WorkStatus.pending
        ? 'Pending'
        : (widget.order.status == WorkStatus.inProgress ? 'In-Progress' : 'Completed');
    _totalController.addListener(_calcBalance);
    _paidController.addListener(_calcBalance);
    _loadPaymentData();
  }

  Future<void> _loadPaymentData() async {
    final repo = ref.read(workOrderRepositoryProvider);
    final payment = await repo.getPaymentForWorkOrder(widget.order.id);
    if (payment != null && mounted) {
      setState(() {
        _totalController.text = payment['total_amount']?.toString() ?? '';
        _paidController.text = payment['paid_amount']?.toString() ?? '';
      });
      _calcBalance();
    }
  }

  void _calcBalance() {
    final total = double.tryParse(_totalController.text) ?? 0.0;
    final paid = double.tryParse(_paidController.text) ?? 0.0;
    setState(() {
      balance = total - paid;
    });
  }

  Future<void> _updateStatus() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(workOrderRepositoryProvider);
      await repo.updateWorkOrderStatus(widget.order.id, _status);
      
      final total = double.tryParse(_totalController.text) ?? 0.0;
      final paid = double.tryParse(_paidController.text) ?? 0.0;
      
      if (total > 0 || paid > 0) {
        await repo.updatePayment(widget.order.id, total, paid);
      }
      
      ref.invalidate(myWorkOrdersProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _launchWhatsApp() async {
    final message = "Update on your ${widget.order.serviceType}: Status is now $_status.";
    await ContactUtils.openWhatsApp(widget.order.clientPhoneNumber, message: message);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${l10n.updateStatus}: ${widget.order.serviceType ?? l10n.generalTask}', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.darkBlue)),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            value: _status,
            decoration: InputDecoration(labelText: l10n.workStatus, border: const OutlineInputBorder()),
            items: [
              DropdownMenuItem(value: 'Pending', child: Text(l10n.pending)),
              DropdownMenuItem(value: 'In-Progress', child: Text(l10n.inProgress)),
              DropdownMenuItem(value: 'Completed', child: Text(l10n.completed)),
            ],
            onChanged: (v) => setState(() => _status = v!),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: TextField(
                      controller: _totalController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: l10n.totalFee))),
              const SizedBox(width: 12),
              Expanded(
                  child: TextField(
                      controller: _paidController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: l10n.paidToday))),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: isDark ? AppTheme.darkCardAlt : Colors.grey[100], borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.remainingBalance, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('SAR ${balance.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                  child: ElevatedButton(
                      onPressed: _isLoading ? null : _updateStatus,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? AppTheme.primaryAccent(isDark) : AppTheme.emeraldGreen,
                          foregroundColor: isDark ? AppTheme.ink900 : Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: _isLoading ? CircularProgressIndicator(color: isDark ? AppTheme.ink900 : Colors.white) : Text(l10n.updateStatus))),
              const SizedBox(width: 12),
              IconButton(
                  onPressed: _launchWhatsApp,
                  icon: const Icon(Icons.message, color: Colors.green),
                  style: IconButton.styleFrom(side: const BorderSide(color: Colors.green))),
            ],
          ),
        ],
      ),
    );
  }
}

class _LeavesView extends ConsumerWidget {
  const _LeavesView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
     return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.backgroundLight,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) => ApplyLeaveForm(onSuccess: () {}),
          );
        },
        label: Text(l10n.applyLeave),
        icon: const Icon(Icons.add, color: Colors.white),
        backgroundColor: AppTheme.accentGold,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.ink900,
          onRefresh: () async {
            ref.invalidate(leaveProvider);
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
                   padding: const EdgeInsets.all(24.0),
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                        Text(
                          l10n.leaveManagement,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.darkBlue),
                        ),
                        const SizedBox(height: 20),
                        
                        // Balance Card
                        _buildBalanceCard(context, ref),
                        const SizedBox(height: 24),
  
                        // Upcoming Holidays
                        const UpcomingHolidaysList(),
                        const SizedBox(height: 24),
  
                        // History Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l10n.leaveHistory,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.darkBlue),
                            ),
                            // Filter button could go here
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        // History List
                        const LeaveHistoryList(),
                        const SizedBox(height: 80), // Space for FAB
                     ],
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

  Widget _buildBalanceCard(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.accentGold, Color(0xFFC49A00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
           BoxShadow(color: AppTheme.accentGold.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
           Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Text(l10n.annualBal, style: const TextStyle(color: Colors.white, fontSize: 14)),
               const SizedBox(height: 8),
               Text('${ref.watch(leaveBalanceProvider)} ${l10n.days}', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
               const SizedBox(height: 4),
               Text(l10n.validUntil('Dec 31, ${DateTime.now().year}'), style: const TextStyle(color: Colors.white70, fontSize: 12)),
             ],
           ),
           Container(
             padding: const EdgeInsets.all(16),
             decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
             child: const Icon(Icons.beach_access, color: Colors.white, size: 36),
           ),
        ],
      ),
    );
  }
}
