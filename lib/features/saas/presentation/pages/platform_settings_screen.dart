import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/pattern_painter.dart';
import '../providers/saas_provider.dart';
import '../../../../features/auth/presentation/pages/login_screen.dart';

class PlatformSettingsScreen extends ConsumerStatefulWidget {
  const PlatformSettingsScreen({super.key});

  @override
  ConsumerState<PlatformSettingsScreen> createState() => _PlatformSettingsScreenState();
}

class _PlatformSettingsScreenState extends ConsumerState<PlatformSettingsScreen> {
  bool _maintenanceMode = false;
  bool _trialEnabled = true;
  int _trialDays = 14;
  bool _emailNotifications = true;

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(platformStatsProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(statsAsync)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _sectionLabel('Platform Identity'),
                _buildPlatformIdentityCard(),
                const SizedBox(height: 24),

                _sectionLabel('Billing & Trial'),
                _buildBillingCard(),
                const SizedBox(height: 24),

                _sectionLabel('Notifications'),
                _buildNotificationsCard(),
                const SizedBox(height: 24),

                _sectionLabel('System'),
                _buildSystemCard(),
                const SizedBox(height: 24),

                _sectionLabel('Danger Zone'),
                _buildDangerZone(context),
                const SizedBox(height: 32),

                Center(
                  child: Column(children: [
                    const Text('POWERED BY', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    const SizedBox(height: 6),
                    Image.asset('assets/images/Xoviq Logo.jpeg', height: 28),
                    const SizedBox(height: 4),
                    Text('Platform Console · Build 2024.1', style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                  ]),
                ),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AsyncValue<Map<String, dynamic>> statsAsync) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.ink900, AppTheme.ink800],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: MashrabiyaPatternPainter(color: Colors.white.withValues(alpha: 0.03))),
          ),
          Positioned(
            top: -80, left: -60,
            child: Container(
              width: 240, height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.brand500.withValues(alpha: 0.12),
                boxShadow: [BoxShadow(color: AppTheme.brand500.withValues(alpha: 0.18), blurRadius: 100)],
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.brand400, AppTheme.brand600],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: AppTheme.brand500.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 6))],
                      ),
                      child: const Icon(Icons.manage_accounts_rounded, color: AppTheme.ink900, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Console Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 26, letterSpacing: -0.5)),
                      Text('PLATFORM CONFIGURATION', style: TextStyle(color: AppTheme.brand400.withValues(alpha: 0.95), fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                    ]),
                  ]),
                  const SizedBox(height: 32),
                  // Live stats strip
                  statsAsync.when(
                    loading: () => const LinearProgressIndicator(color: AppTheme.emeraldGreen, backgroundColor: Colors.white12),
                    error: (_, __) => const SizedBox(),
                    data: (s) => SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none,
                      child: Row(children: [
                        _headerStat('${s['totalOrgs']}', 'Orgs', Icons.business_outlined),
                        const SizedBox(width: 12),
                        _headerStat('${s['totalUsers']}', 'Users', Icons.people_outline),
                        const SizedBox(width: 12),
                        _headerStat('${s['activeSubscriptions']}', 'Active', Icons.check_circle_outline),
                        const SizedBox(width: 12),
                        _headerStat('${s['totalWorkOrders']}', 'Orders', Icons.assignment_outlined),
                      ]),
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

  Widget _headerStat(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1.5),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: Colors.white60),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 10, fontWeight: FontWeight.w600)),
        ]),
      ]),
    );
  }

  Widget _sectionLabel(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4, left: 4),
      child: Text(title.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF71717A), letterSpacing: 1.2)),
    );
  }

  Widget _card({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.12), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(children: children),
    );
  }

  Widget _settingTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.darkBlue)),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right, color: Colors.grey, size: 20) : null),
          onTap: onTap,
        ),
        if (showDivider) const Divider(height: 1, indent: 70, endIndent: 20),
      ],
    );
  }

  Widget _buildPlatformIdentityCard() {
    return _card(children: [
      _settingTile(
        icon: Icons.public_rounded,
        iconColor: AppTheme.emeraldGreen,
        title: 'Platform Name',
        subtitle: 'Workly by xoviq Labs',
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: AppTheme.backgroundLight, borderRadius: BorderRadius.circular(8)),
          child: const Text('Workly', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.darkBlue)),
        ),
      ),
      _settingTile(
        icon: Icons.link_rounded,
        iconColor: AppTheme.brand600,
        title: 'Platform Domain',
        subtitle: 'workly.xoviq.com',
        trailing: const Icon(Icons.open_in_new, size: 16, color: Colors.grey),
        onTap: () {},
      ),
      _settingTile(
        icon: Icons.tag_rounded,
        iconColor: AppTheme.statusCompleted,
        title: 'Platform Version',
        subtitle: 'Build 2024.1.42 — Latest',
        showDivider: false,
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: AppTheme.statusCompleted.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: const Text('Up to date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.statusCompleted)),
        ),
      ),
    ]);
  }

  Widget _buildBillingCard() {
    return _card(children: [
      _settingTile(
        icon: Icons.science_outlined,
        iconColor: AppTheme.statusProgress,
        title: 'Trial Period',
        subtitle: 'New organizations get a free trial',
        trailing: Switch(
          value: _trialEnabled,
          onChanged: (v) => setState(() => _trialEnabled = v),
          activeColor: AppTheme.emeraldGreen,
        ),
      ),
      if (_trialEnabled)
        _settingTile(
          icon: Icons.timer_outlined,
          iconColor: AppTheme.statusProgress,
          title: 'Trial Duration',
          subtitle: 'Days before trial expires',
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, size: 18, color: Colors.grey),
              onPressed: _trialDays > 1 ? () => setState(() => _trialDays--) : null,
            ),
            Text('$_trialDays d', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.darkBlue)),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, size: 18, color: AppTheme.emeraldGreen),
              onPressed: () => setState(() => _trialDays++),
            ),
          ]),
        ),
      _settingTile(
        icon: Icons.payments_outlined,
        iconColor: AppTheme.accentGold,
        title: 'Payment Gateway',
        subtitle: 'Stripe — connected',
        showDivider: false,
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: AppTheme.statusCompleted.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: const Text('Active', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.statusCompleted)),
        ),
      ),
    ]);
  }

  Widget _buildNotificationsCard() {
    return _card(children: [
      _settingTile(
        icon: Icons.email_outlined,
        iconColor: Colors.deepOrange,
        title: 'Email Notifications',
        subtitle: 'Send system alerts via email',
        trailing: Switch(
          value: _emailNotifications,
          onChanged: (v) => setState(() => _emailNotifications = v),
          activeColor: AppTheme.emeraldGreen,
        ),
      ),
      _settingTile(
        icon: Icons.sms_outlined,
        iconColor: AppTheme.statusCompleted,
        title: 'SMS Gateway',
        subtitle: 'Twilio — not configured',
        showDivider: false,
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: AppTheme.statusPending.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: const Text('Setup', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.statusPending)),
        ),
        onTap: () => _showComingSoon(context, 'SMS Gateway configuration'),
      ),
    ]);
  }

  Widget _buildSystemCard() {
    return _card(children: [
      _settingTile(
        icon: Icons.storage_rounded,
        iconColor: AppTheme.statusCompleted,
        title: 'Database',
        subtitle: 'Supabase PostgreSQL — healthy',
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: AppTheme.statusCompleted, shape: BoxShape.circle, boxShadow: [BoxShadow(color: AppTheme.statusCompleted.withValues(alpha: 0.5), blurRadius: 6)])),
          const SizedBox(width: 8),
          const Text('Online', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.statusCompleted)),
        ]),
      ),
      _settingTile(
        icon: Icons.api_rounded,
        iconColor: AppTheme.brand600,
        title: 'API & Webhooks',
        subtitle: 'Manage API keys and webhook endpoints',
        onTap: () => _showComingSoon(context, 'API key management'),
      ),
      _settingTile(
        icon: Icons.build_circle_outlined,
        iconColor: AppTheme.statusPending,
        title: 'Maintenance Mode',
        subtitle: _maintenanceMode ? 'Platform is in maintenance mode' : 'Platform is fully operational',
        showDivider: false,
        trailing: Switch(
          value: _maintenanceMode,
          onChanged: (v) async {
            if (v) {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Enable Maintenance Mode?'),
                  content: const Text('This will block access for all tenant users. Only platform admins can log in.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.pop(context, true), style: TextButton.styleFrom(foregroundColor: AppTheme.statusPending), child: const Text('Enable')),
                  ],
                ),
              );
              if (confirm == true) setState(() => _maintenanceMode = v);
            } else {
              setState(() => _maintenanceMode = v);
            }
          },
          activeColor: AppTheme.statusPending,
        ),
      ),
    ]);
  }

  Widget _buildDangerZone(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.errorRed.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [BoxShadow(color: AppTheme.errorRed.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          _settingTile(
            icon: Icons.person_off_outlined,
            iconColor: AppTheme.errorRed,
            title: 'Sign Out of Console',
            subtitle: 'End your current platform admin session',
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Sign Out?'),
                  content: const Text('You will be returned to the login screen.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.pop(context, true), style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed), child: const Text('Sign Out')),
                  ],
                ),
              );
              if (confirm == true && context.mounted) {
                await Supabase.instance.client.auth.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              }
            },
          ),
          _settingTile(
            icon: Icons.delete_sweep_outlined,
            iconColor: AppTheme.errorRed,
            title: 'Clear All Cache',
            subtitle: 'Force-refresh all provider caches',
            showDivider: false,
            onTap: () {
              ref.invalidate(allOrganizationsProvider);
              ref.invalidate(platformStatsProvider);
              ref.invalidate(orgPlansProvider);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All caches cleared'), backgroundColor: AppTheme.emeraldGreen),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature — coming soon'), behavior: SnackBarBehavior.floating),
    );
  }
}
