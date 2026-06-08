import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/auth/presentation/pages/login_screen.dart';
import '../../../../features/auth/presentation/providers/profile_provider.dart';
import '../../../../features/auth/presentation/pages/edit_profile_screen.dart';
import '../../../../features/auth/presentation/pages/change_password_screen.dart';
import '../../../../features/dashboard/presentation/pages/notifications_screen.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/widgets/responsive_layout.dart';
import 'package:service_manager_app/core/widgets/app_bar.dart';

class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  Future<void> _signOut(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

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
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: WorkqlyAppBar(title: 'My Profile'),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Profile not found.'));
          }
          final name = profile.name ?? 'Staff Member';
          final email = profile.email ?? 'No Email';
          final role = profile.role.name.toUpperCase().replaceAll('_', ' ');

          return ResponsiveLayout(
            maxWidth: 800,
            padding: EdgeInsets.zero,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Profile Header
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.emeraldGreen, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const CircleAvatar(
                            radius: 50,
                            backgroundColor: AppTheme.emeraldLight,
                            child: Icon(Icons.person, size: 50, color: AppTheme.emeraldGreen),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          name,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.darkBlue,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.emeraldGreen.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            role,
                            style: const TextStyle(
                              color: AppTheme.emeraldGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
  
                  // Settings Section
                  _buildSectionHeader('Account Settings / إعدادات الحساب'),
                  const SizedBox(height: 16),
                  _buildSettingsTile(
                    icon: Icons.person_outline,
                    title: 'Edit Profile / تعديل الملف الشخصي',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => EditProfileScreen(profile: profile)),
                      );
                    },
                  ),
                  _buildSettingsTile(
                    icon: Icons.notifications_outlined,
                    title: 'Notifications / الإشعارات',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                      );
                    },
                    trailing: Switch(value: true, onChanged: (v) {}, activeColor: AppTheme.emeraldGreen),
                  ),
                  _buildSettingsTile(
                    icon: Icons.language,
                    title: 'Language / اللغة',
                    onTap: () => _showLanguagePicker(context, ref),
                    trailing: Text(
                      ref.watch(localeProvider).languageCode == 'en' ? 'English' : 'العربية',
                      style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                    ),
                  ),
                  _buildSettingsTile(
                    icon: Icons.security,
                    title: 'Change Password / تغيير كلمة المرور',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                      );
                    },
                  ),
  
                  const SizedBox(height: 32),
                  _buildSectionHeader('Support / الدعم'),
                  const SizedBox(height: 16),
                  _buildSettingsTile(
                    icon: Icons.help_outline,
                    title: 'Help Center / مركز المساعدة',
                    onTap: () {
                       ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Help Center coming soon! / مركز المساعدة قريباً!')),
                      );
                    },
                  ),
                  _buildSettingsTile(
                    icon: Icons.info_outline,
                    title: 'About App / عن التطبيق',
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'Worqly',
                        applicationVersion: '1.0.0',
                        applicationIcon: const Icon(Icons.work_rounded, color: AppTheme.emeraldGreen, size: 40),
                        children: [
                          const Text('Intelligent service management platform for modern teams, by xoviq Labs.'),
                        ],
                      );
                    },
                  ),
  
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _signOut(context),
                      icon: const Icon(Icons.logout, color: Colors.white),
                      label: const Text('Sign Out / تسجيل الخروج'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.errorRed,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Version 1.0.0',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Powered by ',
                        style: TextStyle(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      Image.asset(
                        'assets/images/Logo Xoviq.png',
                        height: 24,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return  Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: AppTheme.backgroundLight,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppTheme.darkBlue, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
