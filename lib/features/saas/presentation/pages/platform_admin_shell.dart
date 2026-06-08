import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import 'platform_admin_screen.dart';
import 'platform_plans_screen.dart';
import 'platform_settings_screen.dart';

final _platformTabProvider = StateProvider<int>((_) => 0);

class PlatformAdminShell extends ConsumerWidget {
  const PlatformAdminShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = ref.watch(_platformTabProvider);

    final tabs = [
      const PlatformAdminScreen(),
      const PlatformPlansScreen(),
      const PlatformSettingsScreen(),
    ];

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
