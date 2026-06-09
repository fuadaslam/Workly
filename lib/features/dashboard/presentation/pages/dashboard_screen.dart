import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:service_manager_app/l10n/generated/app_localizations.dart';
import '../../../../features/auth/presentation/pages/login_screen.dart';
import '../../../../features/auth/presentation/providers/profile_provider.dart';
import '../../../../features/auth/domain/models/profile.dart';
import '../widgets/super_admin_view.dart';
import '../widgets/staff_view.dart';
import '../../../saas/presentation/pages/platform_admin_shell.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {

  Future<void> _signOut(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);

    return profileAsync.when(
      data: (profile) {
        if (profile == null) {
          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(AppLocalizations.of(context)!.profileNotFound),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => _signOut(context),
                    child: Text(AppLocalizations.of(context)!.signOut),
                  ),
                ],
              ),
            ),
          );
        }
        return _buildRoleView(profile);
      },
      error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.emeraldGreen)),
      ),
    );
  }

  Widget _buildRoleView(Profile profile) {
    // Platform admin (Workly operator) → SaaS console
    if (profile.isPlatformAdmin) {
      return const PlatformAdminShell();
    }
    switch (profile.role) {
      case AppRole.super_admin:
      case AppRole.admin:
        return const SuperAdminView();
      case AppRole.staff:
      case AppRole.agent:
        return const StaffView();
    }
  }
}
