import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:service_manager_app/l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';
import 'collapsible_sidebar.dart';
import '../../features/auth/presentation/providers/profile_provider.dart';
import '../../features/auth/domain/models/profile.dart';
import '../../features/dashboard/presentation/widgets/staff_view.dart';
import '../../features/dashboard/presentation/widgets/super_admin_view.dart';
import '../../features/saas/presentation/pages/platform_admin_shell.dart';

/// Wraps a detail screen (e.g. Task Details, Enquiry Details) that is pushed
/// as its own full-screen route under `/dashboard`, so the same
/// [CollapsibleSidebar] the dashboard shows on desktop widths stays visible
/// instead of disappearing behind the pushed page. On narrow widths this is
/// a no-op — mobile keeps just the screen's own back arrow, as before.
///
/// Tapping a sidebar destination sets that role's tab-index provider (the
/// same one the dashboard shell reads) and navigates back to `/dashboard`,
/// which lands on the newly selected tab regardless of how deep the current
/// route stack is.
class DashboardSidebarShell extends ConsumerWidget {
  final Widget child;
  const DashboardSidebarShell({super.key, required this.child});

  Future<void> _signOut(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    if (context.mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (MediaQuery.of(context).size.width < 800) return child;

    final l10n = AppLocalizations.of(context)!;
    final profile = ref.watch(profileProvider).valueOrNull;

    late final List<SidebarItem> items;
    late final int selectedIndex;
    late final ValueChanged<int> onDestinationSelected;
    late final String userName;
    late final String userRole;

    if (profile?.isPlatformAdmin == true) {
      items = const [
        SidebarItem(icon: Icons.business_outlined, label: 'Organizations'),
        SidebarItem(icon: Icons.layers_outlined, label: 'Plans'),
        SidebarItem(icon: Icons.manage_accounts_outlined, label: 'Console Settings'),
      ];
      selectedIndex = ref.watch(platformAdminTabIndexProvider);
      onDestinationSelected = (idx) => ref.read(platformAdminTabIndexProvider.notifier).state = idx;
      userName = profile?.name ?? 'Platform Admin';
      userRole = 'Workly Operator';
    } else if (profile?.role == AppRole.super_admin || profile?.role == AppRole.admin) {
      items = [
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
      selectedIndex = ref.watch(superAdminTabIndexProvider);
      onDestinationSelected = (idx) => ref.read(superAdminTabIndexProvider.notifier).state = idx;
      userName = profile?.name ?? 'Super Admin';
      userRole = profile?.role == AppRole.super_admin ? 'Super Admin' : 'Admin';
    } else {
      items = [
        SidebarItem(icon: Icons.home_outlined, label: l10n.home),
        SidebarItem(icon: Icons.calendar_month_outlined, label: l10n.leaves),
        const SidebarItem(icon: Icons.assignment_outlined, label: 'Works'),
        SidebarItem(icon: Icons.person_outline, label: l10n.profile),
        const SidebarItem(icon: Icons.track_changes_outlined, label: 'Enquiries'),
      ];
      selectedIndex = ref.watch(staffTabIndexProvider);
      onDestinationSelected = (idx) => ref.read(staffTabIndexProvider.notifier).state = idx;
      userName = profile?.name ?? 'Staff Member';
      userRole = profile?.role.name.toUpperCase().replaceAll('_', ' ') ?? 'FIELD OPERATIONS SPECIALIST';
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.backgroundLight,
      body: Row(
        children: [
          CollapsibleSidebar(
            selectedIndex: selectedIndex,
            items: items,
            onDestinationSelected: (idx) {
              onDestinationSelected(idx);
              context.go('/dashboard');
            },
            onSignOut: () => _signOut(context),
            userName: userName,
            userRole: userRole,
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
