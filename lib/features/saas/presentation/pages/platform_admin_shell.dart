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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceWhite,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, -2))],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _tab(context, ref, 0, Icons.business_outlined, Icons.business, 'Organizations'),
                _tab(context, ref, 1, Icons.layers_outlined, Icons.layers, 'Plans'),
                _tab(context, ref, 2, Icons.manage_accounts_outlined, Icons.manage_accounts, 'Console'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tab(BuildContext context, WidgetRef ref, int idx, IconData icon, IconData activeIcon, String label) {
    final current = ref.watch(_platformTabProvider);
    final selected = current == idx;
    return GestureDetector(
      onTap: () => ref.read(_platformTabProvider.notifier).state = idx,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(selected ? activeIcon : icon,
              color: selected ? AppTheme.emeraldGreen : Colors.grey, size: 22),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? AppTheme.emeraldGreen : Colors.grey,
              )),
        ]),
      ),
    );
  }
}
