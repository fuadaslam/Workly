import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/collapsible_sidebar.dart';
import '../../../auth/presentation/providers/profile_provider.dart';
import '../../../auth/presentation/pages/login_screen.dart';
import '../../../../core/providers/theme_provider.dart';
import 'platform_admin_screen.dart';
import 'platform_plans_screen.dart';
import 'platform_settings_screen.dart';

final _platformTabProvider = StateProvider<int>((_) => 0);

class PlatformAdminShell extends ConsumerWidget {
  const PlatformAdminShell({super.key});

  Future<void> _signOut(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = ref.watch(_platformTabProvider);
    final profileAsync = ref.watch(profileProvider);
    final themeMode = ref.watch(themeModeProvider);

    final tabs = [
      const PlatformAdminScreen(),
      const PlatformPlansScreen(),
      const PlatformSettingsScreen(),
    ];

    final sidebarItems = [
      const SidebarItem(
        icon: Icons.business_outlined,
        label: 'Organizations',
      ),
      const SidebarItem(
        icon: Icons.layers_outlined,
        label: 'Plans',
      ),
      const SidebarItem(
        icon: Icons.manage_accounts_outlined,
        label: 'Console Settings',
      ),
    ];

    final isDesktop = MediaQuery.of(context).size.width >= 800;
    final userName = profileAsync.value?.name ?? 'Platform Admin';
    final userRole = 'Workly Operator';

    // Theme toggle widget for sidebar
    final themeToggle = IconButton(
      icon: Icon(
        themeMode == ThemeMode.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
        color: Colors.white,
        size: 20,
      ),
      onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
    );

    if (isDesktop) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        body: Row(
          children: [
            CollapsibleSidebar(
              selectedIndex: currentTab,
              items: sidebarItems,
              onDestinationSelected: (idx) => ref.read(_platformTabProvider.notifier).state = idx,
              onSignOut: () => _signOut(context),
              userName: userName,
              userRole: userRole,
              themeToggle: themeToggle,
            ),
            Expanded(
              child: IndexedStack(index: currentTab, children: tabs),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(index: currentTab, children: tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentTab,
        onDestinationSelected: (idx) => ref.read(_platformTabProvider.notifier).state = idx,
        backgroundColor: AppTheme.surfaceWhite,
        indicatorColor: AppTheme.emeraldGreen.withValues(alpha: 0.12),
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.business_outlined),
            selectedIcon: Icon(Icons.business_rounded, color: AppTheme.emeraldGreen),
            label: 'Organizations',
          ),
          NavigationDestination(
            icon: Icon(Icons.layers_outlined),
            selectedIcon: Icon(Icons.layers_rounded, color: AppTheme.emeraldGreen),
            label: 'Plans',
          ),
          NavigationDestination(
            icon: Icon(Icons.manage_accounts_outlined),
            selectedIcon: Icon(Icons.manage_accounts_rounded, color: AppTheme.emeraldGreen),
            label: 'Console',
          ),
        ],
      ),
    );
  }
}

