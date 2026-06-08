import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/organization.dart';
import '../providers/saas_provider.dart';
import 'create_organization_screen.dart';
import 'organization_detail_screen.dart';
import '../../../../core/theme/pattern_painter.dart';

class PlatformAdminScreen extends ConsumerWidget {
  const PlatformAdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(platformStatsProvider);
    final orgsAsync = ref.watch(allOrganizationsProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: RefreshIndicator(
        color: AppTheme.emeraldGreen,
        onRefresh: () async {
          ref.invalidate(allOrganizationsProvider);
          ref.invalidate(platformStatsProvider);
        },
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(child: _buildHeader(context, ref, statsAsync)),
            // Org list
            orgsAsync.when(
              loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppTheme.emeraldGreen))),
              error: (e, _) => SliverFillRemaining(child: Center(child: Text('Error: $e'))),
              data: (orgs) => SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _OrgCard(org: orgs[i]),
                    childCount: orgs.length,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await showCreateOrgDrawer(context);
          if (created == true) {
            ref.invalidate(allOrganizationsProvider);
            ref.invalidate(platformStatsProvider);
          }
        },
        backgroundColor: AppTheme.emeraldGreen,
        icon: const Icon(Icons.add_business_outlined, color: Colors.white),
        label: const Text('New Org', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, AsyncValue<Map<String, dynamic>> statsAsync) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0B172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: MashrabiyaPatternPainter(color: Colors.white.withValues(alpha: 0.03)),
            ),
          ),
          Positioned(
            top: -100, right: -50,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.emeraldGreen.withValues(alpha: 0.15),
                boxShadow: [BoxShadow(color: AppTheme.emeraldGreen.withValues(alpha: 0.2), blurRadius: 120)],
              ),
            ),
          ),
          Positioned(
            bottom: -50, left: -50,
            child: Container(
              width: 200, height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.withValues(alpha: 0.1),
                boxShadow: [BoxShadow(color: Colors.blue.withValues(alpha: 0.15), blurRadius: 100)],
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
                          colors: [AppTheme.emeraldGreen, Color(0xFF0A8A61)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: AppTheme.emeraldGreen.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 6))],
                      ),
                      child: const Icon(Icons.public, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Worqly Platform', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 26, letterSpacing: -0.5)),
                      Text('GLOBAL SAAS CONSOLE', style: TextStyle(color: AppTheme.emeraldGreen.withValues(alpha: 0.9), fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                    ]),
                  ]),
                  const SizedBox(height: 40),
                  // KPI row
                  statsAsync.when(
                    loading: () => const LinearProgressIndicator(color: AppTheme.emeraldGreen, backgroundColor: Colors.white12),
                    error: (_, __) => const SizedBox(),
                    data: (s) => SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none,
                      child: Row(
                        children: [
                          _kpi('Organizations', '${s['totalOrgs']}', Icons.business_outlined, AppTheme.emeraldGreen),
                          const SizedBox(width: 16),
                          _kpi('Total Users', '${s['totalUsers']}', Icons.people_outline, Colors.blue),
                          const SizedBox(width: 16),
                          _kpi('Active Subs', '${s['activeSubscriptions']}', Icons.check_circle_outline, Colors.orange),
                          const SizedBox(width: 16),
                          _kpi('Monthly MRR', 'SAR ${_fmt(s['mrr'])}', Icons.payments_outlined, AppTheme.accentGold),
                        ],
                      ),
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

  Widget _kpi(String label, String value, IconData icon, Color color) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.08),
            Colors.white.withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 8))
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
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              Icon(Icons.trending_up, color: Colors.white.withValues(alpha: 0.2), size: 18),
            ],
          ),
          const SizedBox(height: 20),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 26, letterSpacing: -0.5)),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  String _fmt(dynamic v) {
    final d = (v as num? ?? 0).toDouble();
    if (d >= 1000) return '${(d / 1000).toStringAsFixed(1)}K';
    return d.toStringAsFixed(0);
  }
}

class _OrgCard extends ConsumerWidget {
  final Organization org;
  const _OrgCard({required this.org});

  Color _statusColor(String? s) {
    switch (s) {
      case 'active': return Colors.green;
      case 'trialing': return Colors.blue;
      case 'past_due': return Colors.orange;
      case 'paused':
      case 'cancelled': return AppTheme.errorRed;
      default: return Colors.grey;
    }
  }

  Color _planColor(String? plan) {
    switch (plan) {
      case 'enterprise': return const Color(0xFFD4AF37);
      case 'pro': return AppTheme.emeraldGreen;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = _statusColor(org.subStatus);
    final pc = _planColor(org.planName);
    final df = DateFormat('dd MMM yyyy');

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 24, offset: const Offset(0, 12)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => OrganizationDetailScreen(org: org),
          )).then((_) => ref.invalidate(allOrganizationsProvider)),
          child: Column(children: [
            // Top bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [sc.withValues(alpha: 0.02), sc.withValues(alpha: 0.08)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.08))),
              ),
              child: Row(children: [
                // Org avatar
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [pc, pc.withValues(alpha: 0.7)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [BoxShadow(color: pc.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6))],
                  ),
                  child: Center(child: Text(
                    org.name.isNotEmpty ? org.name[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24),
                  )),
                ),
                const SizedBox(width: 20),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(org.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.darkBlue, letterSpacing: -0.5)),
                  const SizedBox(height: 4),
                  Text('@${org.slug}', style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                ])),
                // Plan badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: pc.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: pc.withValues(alpha: 0.2), width: 1.5),
                  ),
                  child: Text(
                    org.planDisplayName?.toUpperCase() ?? '—',
                    style: TextStyle(color: pc, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.2),
                  ),
                ),
              ]),
            ),
            // Body
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(children: [
                Row(children: [
                  Expanded(child: _stat(Icons.people_outline, '${org.memberCount}', 'Members', Colors.teal)),
                  Container(width: 1, height: 40, color: Colors.grey.withValues(alpha: 0.2)),
                  Expanded(child: Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: _stat(Icons.assignment_outlined, '${org.workOrderCount}', 'Work Orders', Colors.indigo),
                  )),
                  // Status
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: sc.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: sc.withValues(alpha: 0.2), width: 1.5),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(width: 8, height: 8, decoration: BoxDecoration(
                        color: sc, shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: sc.withValues(alpha: 0.5), blurRadius: 6)],
                      )),
                      const SizedBox(width: 8),
                      Text(
                        org.subStatus?.replaceAll('_', ' ').toUpperCase() ?? '—',
                        style: TextStyle(color: sc, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.8),
                      ),
                    ]),
                  ),
                ]),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(children: [
                    const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text('Since ${df.format(org.createdAt)}', style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                    if (org.periodEnd != null) ...[
                      const SizedBox(width: 24),
                      const Icon(Icons.autorenew_outlined, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text('Renews ${df.format(org.periodEnd!)}', style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                    ],
                    if (org.isTrialing && org.trialEndsAt != null) ...[
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                        child: Text(
                          'Trial ends ${df.format(org.trialEndsAt!)}',
                          style: const TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ]),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _stat(IconData icon, String value, String label, Color color) {
    return Row(children: [
      Icon(icon, size: 14, color: color),
      const SizedBox(width: 4),
      Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
      const SizedBox(width: 3),
      Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
    ]);
  }
}
