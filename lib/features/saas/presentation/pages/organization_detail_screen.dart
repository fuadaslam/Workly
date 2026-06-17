import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/organization.dart';
import '../providers/saas_provider.dart';

class OrganizationDetailScreen extends ConsumerStatefulWidget {
  final Organization org;
  const OrganizationDetailScreen({super.key, required this.org});

  @override
  ConsumerState<OrganizationDetailScreen> createState() => _OrganizationDetailScreenState();
}

class _OrganizationDetailScreenState extends ConsumerState<OrganizationDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Organization _org;

  @override
  void initState() {
    super.initState();
    _org = widget.org;
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _statusColor(String? s) {
    switch (s) {
      case 'active': return AppTheme.statusCompleted;
      case 'trialing': return AppTheme.statusProgress;
      case 'past_due': return AppTheme.statusPending;
      case 'paused': case 'cancelled': return AppTheme.errorRed;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sc = _statusColor(_org.subStatus);
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppTheme.emeraldGreen,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [AppTheme.ink900, AppTheme.ink800]),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Container(
                          width: 52, height: 52,
                          decoration: BoxDecoration(color: AppTheme.accentGold, borderRadius: BorderRadius.circular(14)),
                          child: Center(child: Text(
                            _org.name.isNotEmpty ? _org.name[0].toUpperCase() : '?',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
                          )),
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(_org.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                          Text(_org.slug, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
                        ])),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(color: sc.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                          child: Text(
                            (_org.subStatus ?? '—').replaceAll('_', ' ').toUpperCase(),
                            style: TextStyle(color: sc, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 14),
                      Row(children: [
                        _quickStat('${_org.memberCount}', 'Members'),
                        const SizedBox(width: 24),
                        _quickStat(_org.planDisplayName ?? '—', 'Plan'),
                        const SizedBox(width: 24),
                        if (_org.priceMonthly != null)
                          _quickStat('SAR ${_org.priceMonthly!.toStringAsFixed(0)}/mo', 'Billing'),
                      ]),
                    ]),
                  ),
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              indicatorColor: AppTheme.accentGold,
              indicatorWeight: 3,
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Members'),
                Tab(text: 'Invitations'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _OverviewTab(org: _org, onOrgUpdated: (updated) => setState(() => _org = updated)),
            _MembersTab(org: _org),
            _InvitationsTab(org: _org),
          ],
        ),
      ),
    );
  }

  Widget _quickStat(String value, String label) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
    Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 10)),
  ]);
}

// ─── Overview Tab ───────────────────────────────────────────────────────────

class _OverviewTab extends ConsumerStatefulWidget {
  final Organization org;
  final void Function(Organization) onOrgUpdated;
  const _OverviewTab({required this.org, required this.onOrgUpdated});

  @override
  ConsumerState<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends ConsumerState<_OverviewTab> {
  late TextEditingController _nameCtrl;
  late TextEditingController _websiteCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _addressCtrl;
  bool _editing = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.org.name);
    _websiteCtrl = TextEditingController(text: widget.org.website ?? '');
    _phoneCtrl = TextEditingController(text: widget.org.phone ?? '');
    _addressCtrl = TextEditingController(text: widget.org.address ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _websiteCtrl.dispose(); _phoneCtrl.dispose(); _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(saasRepositoryProvider).updateOrganization(
        widget.org.id,
        name: _nameCtrl.text.trim(),
        website: _websiteCtrl.text.trim().isEmpty ? null : _websiteCtrl.text.trim(),
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
      );
      setState(() => _editing = false);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final plansAsync = ref.watch(orgPlansProvider);
    final df = DateFormat('dd MMM yyyy');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Details card
        _card('Organization Details', Icons.business_outlined, [
          _detailRow('Name', _editing ? _editField(_nameCtrl) : Text(_nameCtrl.text)),
          _detailRow('Slug', Row(children: [
            Text(widget.org.slug, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () { Clipboard.setData(ClipboardData(text: widget.org.slug)); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied!')));},
              child: const Icon(Icons.copy_outlined, size: 14, color: Colors.grey),
            ),
          ])),
          _detailRow('Website', _editing ? _editField(_websiteCtrl) : Text(widget.org.website ?? '—')),
          _detailRow('Phone', _editing ? _editField(_phoneCtrl, keyboardType: TextInputType.phone) : Text(widget.org.phone ?? '—')),
          _detailRow('Address', _editing ? _editField(_addressCtrl, maxLines: 2) : Text(widget.org.address ?? '—')),
          _detailRow('Created', Text(df.format(widget.org.createdAt))),
        ], action: _editing
            ? Row(children: [
                TextButton(onPressed: () => setState(() => _editing = false), child: const Text('Cancel')),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _saving ? null : _save, child: const Text('Save')),
              ])
            : IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => setState(() => _editing = true))),

        const SizedBox(height: 16),

        // Subscription card
        _card('Subscription', Icons.credit_card_outlined, [
          _detailRow('Plan', Text(widget.org.planDisplayName ?? '—', style: const TextStyle(fontWeight: FontWeight.bold))),
          _detailRow('Status', _StatusBadge(status: widget.org.subStatus ?? '—')),
          if (widget.org.periodEnd != null)
            _detailRow('Renews', Text(df.format(widget.org.periodEnd!))),
          if (widget.org.trialEndsAt != null)
            _detailRow('Trial ends', Text(df.format(widget.org.trialEndsAt!), style: const TextStyle(color: AppTheme.statusProgress))),
          _detailRow('Monthly fee', Text(widget.org.priceMonthly != null ? 'SAR ${widget.org.priceMonthly!.toStringAsFixed(0)}' : '—')),
        ], action: plansAsync.when(
          loading: () => const SizedBox(),
          error: (_, __) => const SizedBox(),
          data: (plans) => TextButton.icon(
            icon: const Icon(Icons.swap_horiz_outlined, size: 16),
            label: const Text('Change Plan'),
            onPressed: () => _showChangePlanDialog(context, plans),
          ),
        )),

        const SizedBox(height: 16),

        // Danger zone
        _card('Danger Zone', Icons.warning_amber_outlined, [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppTheme.statusPending.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.pause_circle_outline, color: AppTheme.statusPending, size: 20)),
            title: const Text('Suspend Organization', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: const Text('Blocks user access, preserves all data', style: TextStyle(fontSize: 12)),
            trailing: OutlinedButton(
              onPressed: () => _confirmSuspend(context),
              style: OutlinedButton.styleFrom(foregroundColor: AppTheme.statusPending, side: const BorderSide(color: AppTheme.statusPending)),
              child: const Text('Suspend'),
            ),
          ),
        ], color: AppTheme.errorRed.withValues(alpha: 0.05)),

        const SizedBox(height: 40),
      ]),
    );
  }

  void _showChangePlanDialog(BuildContext context, List<OrgPlan> plans) {
    String? selected = plans.firstWhere((p) => p.name == widget.org.planName, orElse: () => plans.first).id;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Plan'),
        content: StatefulBuilder(
          builder: (ctx, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: plans.map((p) => RadioListTile<String>(
              value: p.id,
              groupValue: selected,
              onChanged: (v) => setState(() => selected = v),
              activeColor: AppTheme.emeraldGreen,
              title: Text('${p.displayName} — SAR ${p.priceMonthly.toStringAsFixed(0)}/mo'),
              contentPadding: EdgeInsets.zero,
            )).toList(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emeraldGreen),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(saasRepositoryProvider).updateSubscriptionPlan(widget.org.id, selected!, 'active');
              ref.invalidate(allOrganizationsProvider);
            },
            child: const Text('Update Plan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmSuspend(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Suspend Organization?'),
        content: Text('This will block all users in "${widget.org.name}" from accessing the app.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.statusPending),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(saasRepositoryProvider).suspendOrganization(widget.org.id);
              ref.invalidate(allOrganizationsProvider);
              if (!context.mounted) return;
              Navigator.pop(context);
            },
            child: const Text('Suspend', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _card(String title, IconData icon, List<Widget> children, {Widget? action, Color? color}) {
    return Container(
      decoration: BoxDecoration(
        color: color ?? AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 0),
          child: Row(children: [
            Icon(icon, size: 18, color: AppTheme.emeraldGreen),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.darkBlue)),
            const Spacer(),
            if (action != null) action,
          ]),
        ),
        const Divider(height: 20),
        Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 14), child: Column(children: children)),
      ]),
    );
  }

  Widget _detailRow(String label, Widget value) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 100, child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12))),
      Expanded(child: value),
    ]),
  );

  Widget _editField(TextEditingController ctrl, {TextInputType? keyboardType, int maxLines = 1}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: AppTheme.backgroundLight,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.emeraldGreen)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
    );
  }
}

// ─── Members Tab ─────────────────────────────────────────────────────────────

class _MembersTab extends ConsumerWidget {
  final Organization org;
  const _MembersTab({required this.org});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(orgMembersProvider(org.id));

    return RefreshIndicator(
      color: AppTheme.emeraldGreen,
      onRefresh: () async => ref.invalidate(orgMembersProvider(org.id)),
      child: membersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.emeraldGreen)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (members) {
          if (members.isEmpty) {
            return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.group_outlined, size: 56, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text('No members yet', style: TextStyle(color: Colors.grey.shade400)),
            ]));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: members.length,
            itemBuilder: (ctx, i) => _MemberTile(member: members[i], org: org, ref: ref),
          );
        },
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final OrgMember member;
  final Organization org;
  final WidgetRef ref;
  const _MemberTile({required this.member, required this.org, required this.ref});

  Color _roleColor(String role) {
    switch (role) {
      case 'super_admin': return AppTheme.brand500;
      case 'admin': return AppTheme.emeraldGreen;
      case 'agent': return AppTheme.brand600;
      default: return AppTheme.statusCompleted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final rc = _roleColor(member.role);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 20, backgroundColor: rc,
          child: Text(
            (member.name?.isNotEmpty == true ? member.name![0] : '?').toUpperCase(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(member.name ?? '—', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          Text(member.email ?? '—', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          if (member.officeName != null)
            Text(member.officeName!, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: rc.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(member.role.replaceAll('_', ' '), style: TextStyle(color: rc, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 4),
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: member.isActive ? AppTheme.statusCompleted : Colors.grey,
            ),
          ),
        ]),
      ]),
    );
  }
}

// ─── Invitations Tab ─────────────────────────────────────────────────────────

class _InvitationsTab extends ConsumerStatefulWidget {
  final Organization org;
  const _InvitationsTab({required this.org});

  @override
  ConsumerState<_InvitationsTab> createState() => _InvitationsTabState();
}

class _InvitationsTabState extends ConsumerState<_InvitationsTab> {
  final _emailCtrl = TextEditingController();
  String _selectedRole = 'staff';
  bool _sending = false;

  @override
  void dispose() { _emailCtrl.dispose(); super.dispose(); }

  Future<void> _sendInvite() async {
    if (_emailCtrl.text.trim().isEmpty || !_emailCtrl.text.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid email.')));
      return;
    }
    setState(() => _sending = true);
    try {
      await ref.read(saasRepositoryProvider).sendInvitation(widget.org.id, _emailCtrl.text, _selectedRole);
      _emailCtrl.clear();
      ref.invalidate(orgInvitationsProvider(widget.org.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invitation sent!'), backgroundColor: AppTheme.statusCompleted),
      );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorRed));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final invitesAsync = ref.watch(orgInvitationsProvider(widget.org.id));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Send invite form
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceWhite,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Invite Member', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.darkBlue)),
            const SizedBox(height: 12),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'Email address',
                prefixIcon: const Icon(Icons.email_outlined, size: 18, color: AppTheme.emeraldGreen),
                filled: true, fillColor: AppTheme.backgroundLight,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: InputDecoration(
                    labelText: 'Role',
                    filled: true, fillColor: AppTheme.backgroundLight,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'super_admin', child: Text('Super Admin')),
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    DropdownMenuItem(value: 'staff', child: Text('Staff')),
                    DropdownMenuItem(value: 'agent', child: Text('Agent')),
                  ],
                  onChanged: (v) => setState(() => _selectedRole = v!),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: _sending ? null : _sendInvite,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.emeraldGreen,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: _sending
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_outlined, color: Colors.white, size: 18),
                label: const Text('Send', style: TextStyle(color: Colors.white)),
              ),
            ]),
          ]),
        ),
        const SizedBox(height: 16),

        // Invite list
        invitesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.emeraldGreen)),
          error: (e, _) => Text('Error: $e'),
          data: (invites) {
            if (invites.isEmpty) {
              return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(children: [
                  Icon(Icons.mail_outline, size: 48, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text('No invitations sent yet', style: TextStyle(color: Colors.grey.shade400)),
                ]),
              ),
            );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${invites.length} invitation${invites.length == 1 ? '' : 's'}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 8),
                ...invites.map((inv) => _InviteTile(invite: inv, orgId: widget.org.id, ref: ref)),
              ],
            );
          },
        ),
      ]),
    );
  }
}

class _InviteTile extends StatelessWidget {
  final OrgInvitation invite;
  final String orgId;
  final WidgetRef ref;
  const _InviteTile({required this.invite, required this.orgId, required this.ref});

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd MMM yyyy');
    Color statusColor = invite.isAccepted ? AppTheme.statusCompleted : invite.isExpired ? AppTheme.statusPending : AppTheme.statusProgress;
    String statusLabel = invite.isAccepted ? 'Accepted' : invite.isExpired ? 'Expired' : 'Pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(Icons.mail_outline, color: statusColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(invite.email, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          Text('${invite.role.replaceAll('_', ' ')} · Expires ${df.format(invite.expiresAt)}',
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
        if (invite.isPending) ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () async {
              await ref.read(saasRepositoryProvider).cancelInvitation(invite.id);
              ref.invalidate(orgInvitationsProvider(orgId));
            },
            child: const Icon(Icons.close, size: 16, color: Colors.grey),
          ),
        ],
      ]),
    );
  }
}

// ─── Shared Widgets ──────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color c = switch (status) {
      'active' => AppTheme.statusCompleted,
      'trialing' => AppTheme.statusProgress,
      'past_due' => AppTheme.statusPending,
      _ => Colors.grey,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status.replaceAll('_', ' ').toUpperCase(), style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}
