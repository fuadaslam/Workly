import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/pattern_painter.dart';
import '../../domain/models/organization.dart';
import '../providers/saas_provider.dart';

class PlatformPlansScreen extends ConsumerWidget {
  const PlatformPlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(orgPlansProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: RefreshIndicator(
        color: AppTheme.emeraldGreen,
        onRefresh: () async => ref.invalidate(orgPlansProvider),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context)),
            plansAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: AppTheme.emeraldGreen)),
              ),
              error: (e, _) => SliverFillRemaining(
                child: Center(child: Text('Error loading plans: $e')),
              ),
              data: (plans) => SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _PlanCard(plan: plans[i]),
                    childCount: plans.length,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreatePlanSheet(context, ref),
        backgroundColor: AppTheme.emeraldGreen,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Plan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
            top: -80, right: -60,
            child: Container(
              width: 260, height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accentGold.withValues(alpha: 0.1),
                boxShadow: [BoxShadow(color: AppTheme.accentGold.withValues(alpha: 0.15), blurRadius: 100)],
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
                          colors: [AppTheme.accentGold, Color(0xFFB8960C)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: AppTheme.accentGold.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 6))],
                      ),
                      child: const Icon(Icons.layers_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Subscription Plans', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 26, letterSpacing: -0.5)),
                      Text('BILLING & PLAN MANAGEMENT', style: TextStyle(color: AppTheme.accentGold.withValues(alpha: 0.9), fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                    ]),
                  ]),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.white.withValues(alpha: 0.07), Colors.white.withValues(alpha: 0.02)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1.5),
                    ),
                    child: Row(children: [
                      const Icon(Icons.info_outline_rounded, color: Colors.white60, size: 18),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Plans control feature access and usage limits per organization.',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
                        ),
                      ),
                    ]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreatePlanSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PlanFormSheet(onSaved: () => ref.invalidate(orgPlansProvider)),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final OrgPlan plan;
  const _PlanCard({required this.plan});

  Color get _accentColor {
    switch (plan.name) {
      case 'enterprise': return const Color(0xFFD4AF37);
      case 'pro': return AppTheme.emeraldGreen;
      default: return Colors.blueGrey;
    }
  }

  IconData get _planIcon {
    switch (plan.name) {
      case 'enterprise': return Icons.diamond_outlined;
      case 'pro': return Icons.rocket_launch_outlined;
      default: return Icons.layers_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ac = _accentColor;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 24, offset: const Offset(0, 12))],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [ac.withValues(alpha: 0.04), ac.withValues(alpha: 0.10)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.08))),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: ac.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: ac.withValues(alpha: 0.25), width: 1.5),
                ),
                child: Icon(_planIcon, color: ac, size: 26),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(plan.displayName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppTheme.darkBlue, letterSpacing: -0.5)),
                  const SizedBox(height: 4),
                  Text(plan.name.toUpperCase(), style: TextStyle(fontSize: 11, color: ac, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                ]),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                RichText(
                  text: TextSpan(children: [
                    TextSpan(text: 'SAR ${plan.priceMonthly.toStringAsFixed(0)}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: ac)),
                    TextSpan(text: '/mo', style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                  ]),
                ),
                if (plan.priceYearly > 0)
                  Text('SAR ${plan.priceYearly.toStringAsFixed(0)}/yr', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              ]),
            ]),
          ),
          // Limits
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(children: [
                  Expanded(child: _limitTile(Icons.people_outline, plan.limitLabel(plan.maxUsers), 'Max Users', Colors.teal)),
                  Container(width: 1, height: 40, color: Colors.grey.withValues(alpha: 0.15)),
                  Expanded(child: _limitTile(Icons.business_outlined, plan.limitLabel(plan.maxOffices), 'Max Offices', Colors.indigo)),
                  Container(width: 1, height: 40, color: Colors.grey.withValues(alpha: 0.15)),
                  Expanded(child: _limitTile(Icons.assignment_outlined, plan.limitLabel(plan.maxWorkOrdersPerMonth), 'Orders/mo', Colors.deepOrange)),
                ]),
                if ((plan.features).isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: plan.features.entries
                        .where((e) => e.value == true || e.value is String)
                        .map((e) => _featureChip(e.key, ac))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _limitTile(IconData icon, String value, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: color)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _featureChip(String key, Color ac) {
    final label = key.replaceAll('_', ' ').split(' ').map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: ac.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ac.withValues(alpha: 0.2)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.check_circle_rounded, size: 12, color: ac),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 11, color: ac, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class _PlanFormSheet extends StatefulWidget {
  final VoidCallback onSaved;
  const _PlanFormSheet({required this.onSaved});

  @override
  State<_PlanFormSheet> createState() => _PlanFormSheetState();
}

class _PlanFormSheetState extends State<_PlanFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _displayController = TextEditingController();
  final _monthlyController = TextEditingController();
  final _yearlyController = TextEditingController();
  final _usersController = TextEditingController(text: '10');
  final _officesController = TextEditingController(text: '2');
  final _ordersController = TextEditingController(text: '500');

  @override
  void dispose() {
    _nameController.dispose(); _displayController.dispose();
    _monthlyController.dispose(); _yearlyController.dispose();
    _usersController.dispose(); _officesController.dispose();
    _ordersController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: EdgeInsets.only(
        top: 30, left: 24, right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 30,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 24),
              const Text('Create New Plan', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.darkBlue)),
              const SizedBox(height: 4),
              const Text('Define limits and pricing for this plan tier', style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(child: TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'Plan Key (e.g. pro)', prefixIcon: const Icon(Icons.key_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)), filled: true, fillColor: Colors.grey.shade50),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                )),
                const SizedBox(width: 12),
                Expanded(child: TextFormField(
                  controller: _displayController,
                  decoration: InputDecoration(labelText: 'Display Name', prefixIcon: const Icon(Icons.label_outline), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)), filled: true, fillColor: Colors.grey.shade50),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                )),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: TextFormField(
                  controller: _monthlyController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Monthly Price (SAR)', prefixIcon: const Icon(Icons.attach_money), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)), filled: true, fillColor: Colors.grey.shade50),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                )),
                const SizedBox(width: 12),
                Expanded(child: TextFormField(
                  controller: _yearlyController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Yearly Price (SAR)', prefixIcon: const Icon(Icons.calendar_today_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)), filled: true, fillColor: Colors.grey.shade50),
                )),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: TextFormField(
                  controller: _usersController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Max Users (-1=∞)', prefixIcon: const Icon(Icons.people_outline), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)), filled: true, fillColor: Colors.grey.shade50),
                )),
                const SizedBox(width: 12),
                Expanded(child: TextFormField(
                  controller: _officesController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Max Offices (-1=∞)', prefixIcon: const Icon(Icons.business_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)), filled: true, fillColor: Colors.grey.shade50),
                )),
                const SizedBox(width: 12),
                Expanded(child: TextFormField(
                  controller: _ordersController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Orders/mo (-1=∞)', prefixIcon: const Icon(Icons.assignment_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)), filled: true, fillColor: Colors.grey.shade50),
                )),
              ]),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      Navigator.pop(context);
                      widget.onSaved();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Plan created — save via Supabase dashboard to persist.'), backgroundColor: AppTheme.emeraldGreen),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emeraldGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), elevation: 0),
                  child: const Text('Create Plan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
