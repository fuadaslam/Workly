import 'dart:math' show min;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/saas_provider.dart';

/// Shows the New Organisation form as a right-side slide-in drawer.
/// Returns `true` when an org is successfully created, `null`/`false` otherwise.
Future<bool?> showCreateOrgDrawer(BuildContext context) {
  return showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: Colors.black.withValues(alpha: 0.45),
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (ctx, _, __) => const _CreateOrgDrawer(),
    transitionBuilder: (ctx, animation, _, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return SlideTransition(
        position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(curved),
        child: child,
      );
    },
  );
}

class _CreateOrgDrawer extends ConsumerStatefulWidget {
  const _CreateOrgDrawer();

  @override
  ConsumerState<_CreateOrgDrawer> createState() => _CreateOrgDrawerState();
}

class _CreateOrgDrawerState extends ConsumerState<_CreateOrgDrawer> {
  final _form = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _slugCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  String? _selectedPlanId;
  String _selectedStatus = 'active';
  bool _saving = false;

  static const _statusOptions = [
    ('active',   'Active',  'Full access — billing starts now'),
    ('trialing', 'Trial',   'Free trial period — no billing yet'),
    ('paused',   'Paused',  'Access suspended — keep data'),
  ];

  @override
  void dispose() {
    _nameCtrl.dispose(); _slugCtrl.dispose();
    _websiteCtrl.dispose(); _phoneCtrl.dispose(); _addressCtrl.dispose();
    super.dispose();
  }

  void _onNameChanged(String v) {
    _slugCtrl.text = v.toLowerCase().trim()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-');
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate() || _selectedPlanId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields and select a plan.'), backgroundColor: AppTheme.errorRed),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(saasRepositoryProvider).createOrganization(
        name: _nameCtrl.text.trim(),
        slug: _slugCtrl.text.trim(),
        planId: _selectedPlanId!,
        website: _websiteCtrl.text.trim().isEmpty ? null : _websiteCtrl.text.trim(),
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorRed),
        );
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final plansAsync = ref.watch(orgPlansProvider);
    final drawerWidth = min(520.0, MediaQuery.of(context).size.width * 0.92);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: drawerWidth,
          height: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : AppTheme.backgroundLight,
            borderRadius: BorderRadius.horizontal(left: Radius.circular(24)),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 40, offset: Offset(-8, 0))],
          ),
          child: SafeArea(
            child: Column(
              children: [
                // ── Header ────────────────────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkCard : AppTheme.surfaceWhite,
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(24)),
                    border: const Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: isDark ? AppTheme.darkCardAlt : AppTheme.backgroundLight, borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.close, size: 18, color: AppTheme.darkBlue),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('New Organization', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.darkBlue, letterSpacing: -0.3)),
                            Text('Create a new tenant account', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                      // Save button
                      FilledButton(
                        onPressed: _saving ? null : _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: isDark ? AppTheme.primaryAccent(isDark) : AppTheme.emeraldGreen,
                          foregroundColor: isDark ? AppTheme.ink900 : Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _saving
                            ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: isDark ? AppTheme.ink900 : Colors.white))
                            : Text('Create', style: TextStyle(color: isDark ? AppTheme.ink900 : Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),

                // ── Scrollable body ───────────────────────────────────
                Expanded(
                  child: Form(
                    key: _form,
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        // Org Info
                        _sectionLabel('Organization Info'),
                        _card([
                          _field('Organization Name *', _nameCtrl, required: true, onChanged: _onNameChanged),
                          _divider(),
                          _field('Slug *', _slugCtrl, required: true,
                            hint: 'e.g. spot-services',
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              if (!RegExp(r'^[a-z0-9-]+$').hasMatch(v)) return 'Only lowercase letters, numbers, hyphens';
                              return null;
                            },
                          ),
                          _divider(),
                          _field('Website', _websiteCtrl, hint: 'https://example.com', keyboardType: TextInputType.url),
                          _divider(),
                          _field('Phone', _phoneCtrl, keyboardType: TextInputType.phone),
                          _divider(),
                          _field('Address', _addressCtrl, maxLines: 2),
                        ]),
                        const SizedBox(height: 20),

                        // Plans
                        _sectionLabel('Subscription Plan *'),
                        plansAsync.when(
                          loading: () => const LinearProgressIndicator(color: AppTheme.emeraldGreen),
                          error: (e, _) => Text('Error loading plans: $e'),
                          data: (plans) => Column(
                            children: plans.map((plan) {
                              final selected = _selectedPlanId == plan.id;
                              return GestureDetector(
                                onTap: () => setState(() => _selectedPlanId = plan.id),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppTheme.darkCard : AppTheme.surfaceWhite,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: selected ? AppTheme.emeraldGreen : Colors.grey.shade200,
                                      width: selected ? 2 : 1.5,
                                    ),
                                    boxShadow: selected
                                        ? [BoxShadow(color: AppTheme.emeraldGreen.withValues(alpha: 0.12), blurRadius: 12, offset: const Offset(0, 4))]
                                        : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8)],
                                  ),
                                  child: Row(children: [
                                    // Radio dot
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 180),
                                      width: 22, height: 22,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: selected ? AppTheme.emeraldGreen : Colors.transparent,
                                        border: Border.all(color: selected ? AppTheme.emeraldGreen : Colors.grey.shade300, width: 2),
                                      ),
                                      child: selected ? const Icon(Icons.check, size: 13, color: Colors.white) : null,
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Row(children: [
                                        Text(plan.displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.darkBlue)),
                                        const SizedBox(width: 8),
                                        _badge(
                                          plan.priceMonthly == 0 ? 'Free' : 'SAR ${plan.priceMonthly.toStringAsFixed(0)}/mo',
                                          plan.priceMonthly == 0 ? Colors.grey : AppTheme.emeraldGreen,
                                        ),
                                      ]),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${plan.limitLabel(plan.maxUsers)} users · ${plan.limitLabel(plan.maxOffices)} offices · ${plan.limitLabel(plan.maxWorkOrdersPerMonth)} orders/mo',
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                      if (plan.features.isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Wrap(spacing: 6, children: [
                                          if (plan.features['reports'] == true) _featureChip('Reports'),
                                          if (plan.features['api_access'] == true) _featureChip('API Access'),
                                          if (plan.features['white_label'] == true) _featureChip('White Label'),
                                        ]),
                                      ],
                                    ])),
                                  ]),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Status
                        _sectionLabel('Subscription Status'),
                        _card([
                          ..._statusOptions.map((opt) {
                            final selected = _selectedStatus == opt.$1;
                            return RadioListTile<String>(
                              value: opt.$1,
                              groupValue: _selectedStatus,
                              onChanged: (v) => setState(() => _selectedStatus = v!),
                              activeColor: AppTheme.emeraldGreen,
                              title: Text(opt.$2, style: TextStyle(fontSize: 14, fontWeight: selected ? FontWeight.bold : FontWeight.w500, color: selected ? AppTheme.darkBlue : Colors.grey.shade700)),
                              subtitle: Text(opt.$3, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                            );
                          }),
                        ]),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 2),
    child: Text(t, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppTheme.emeraldGreen, letterSpacing: 0.5)),
  );

  Widget _card(List<Widget> children) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
    decoration: BoxDecoration(
      color: isDark ? AppTheme.darkCard : AppTheme.surfaceWhite,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey.withValues(alpha: 0.12), width: 1.5),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
    ),
    child: Column(children: children),
  );
  }

  Widget _divider() => const Divider(height: 1, indent: 16, endIndent: 16);

  Widget _field(String label, TextEditingController ctrl, {
    bool required = false, TextInputType? keyboardType, String? hint,
    int maxLines = 1, String? Function(String?)? validator, void Function(String)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        maxLines: maxLines,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          filled: true,
          fillColor: Colors.transparent,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
        validator: validator ?? (required ? (v) => (v == null || v.isEmpty) ? 'Required' : null : null),
      ),
    );
  }

  Widget _badge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
    child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
  );

  Widget _featureChip(String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: isDark ? AppTheme.darkCardAlt : AppTheme.backgroundLight, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.grey.shade200)),
      child: Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.emeraldGreen, fontWeight: FontWeight.w600)),
    );
  }
}
