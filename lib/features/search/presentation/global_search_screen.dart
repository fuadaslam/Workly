import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/dashboard/presentation/providers/dashboard_provider.dart';
import '../../../features/enquiries/presentation/providers/enquiry_provider.dart';
import '../../../features/enquiries/presentation/pages/enquiry_detail_screen.dart';
import '../../../features/dashboard/presentation/pages/task_detail_screen.dart';
import '../../../features/dashboard/domain/models/work_order.dart';
import '../../../features/enquiries/domain/models/enquiry.dart';

/// Command-palette style global search. The field stays pinned near the top
/// and matches surface as a floating **dropdown** card directly beneath it.
class GlobalSearchScreen extends ConsumerStatefulWidget {
  const GlobalSearchScreen({super.key});

  /// Opens the search as a translucent overlay so results float as a dropdown
  /// over the current page rather than on an opaque full-screen route.
  static Route<void> route() => PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 160),
        pageBuilder: (_, __, ___) => const GlobalSearchScreen(),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: anim,
          child: child,
        ),
      );

  @override
  ConsumerState<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends ConsumerState<GlobalSearchScreen> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  bool get _active => _query.length >= 2;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scrim = isDark ? Colors.black.withValues(alpha: 0.55) : Colors.black.withValues(alpha: 0.30);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Tap-out scrim to dismiss.
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: Container(color: scrim),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _searchField(isDark),
                      if (_active) ...[
                        const SizedBox(height: 8),
                        Flexible(child: _dropdown(isDark)),
                      ] else ...[
                        const SizedBox(height: 8),
                        _hintCard(isDark),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Search input ────────────────────────────────────────────────────────
  Widget _searchField(bool isDark) {
    final cardBg = isDark ? AppTheme.darkCard : Colors.white;
    final border = isDark ? AppTheme.darkBorder : const Color(0xFFE4E4E7);
    final textColor = isDark ? AppTheme.darkOnSurface : AppTheme.ink900;
    final hintColor = isDark ? AppTheme.darkSubtext : const Color(0xFFA1A1AA);
    final accent = AppTheme.primaryAccent(isDark);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 1),
        boxShadow: AppTheme.cardShadow(isDark),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: 20, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _ctrl,
              focusNode: _focus,
              style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w500),
              cursorColor: accent,
              decoration: InputDecoration(
                hintText: 'Search clients, services, enquiries…',
                hintStyle: TextStyle(color: hintColor, fontSize: 15),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            ),
          ),
          if (_query.isNotEmpty)
            IconButton(
              icon: Icon(Icons.close_rounded, size: 18, color: hintColor),
              splashRadius: 18,
              onPressed: () {
                _ctrl.clear();
                setState(() => _query = '');
                _focus.requestFocus();
              },
            )
          else
            IconButton(
              icon: Icon(Icons.keyboard_return_rounded, size: 16, color: hintColor),
              splashRadius: 18,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
        ],
      ),
    );
  }

  Widget _hintCard(bool isDark) {
    final hintColor = isDark ? AppTheme.darkSubtext : const Color(0xFFA1A1AA);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text('Type at least 2 characters to search',
          textAlign: TextAlign.center,
          style: TextStyle(color: hintColor, fontSize: 13)),
    );
  }

  // ── Results dropdown ──────────────────────────────────────────────────────
  Widget _dropdown(bool isDark) {
    final cardBg = isDark ? AppTheme.darkCard : Colors.white;
    final border = isDark ? AppTheme.darkBorder : const Color(0xFFE4E4E7);

    final workOrdersAsync = ref.watch(allWorkOrdersProvider);
    final enquiriesAsync = ref.watch(allEnquiriesProvider);

    final orderTiles = workOrdersAsync.maybeWhen(
      data: (orders) => orders.where((o) {
        final name = (o.clientName ?? '').toLowerCase();
        final service = (o.serviceType ?? '').toLowerCase();
        final phone = (o.clientPhoneNumber ?? '').toLowerCase();
        return name.contains(_query) || service.contains(_query) || phone.contains(_query);
      }).take(10).map(_workOrderTile).toList(),
      orElse: () => <Widget>[],
    );
    final enquiryTiles = enquiriesAsync.maybeWhen(
      data: (enquiries) => enquiries.where((e) {
        final name = (e.clientName ?? '').toLowerCase();
        final code = e.enquiryCode.toLowerCase();
        final service = (e.natureOfEnquiry ?? '').toLowerCase();
        final phone = (e.contactNumber ?? '').toLowerCase();
        return name.contains(_query) || code.contains(_query) ||
            service.contains(_query) || phone.contains(_query);
      }).take(10).map(_enquiryTile).toList(),
      orElse: () => <Widget>[],
    );

    final loading = workOrdersAsync.isLoading || enquiriesAsync.isLoading;
    final hasResults = orderTiles.isNotEmpty || enquiryTiles.isNotEmpty;

    Widget content;
    if (!hasResults && loading) {
      content = const Padding(
        padding: EdgeInsets.symmetric(vertical: 28),
        child: Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4))),
      );
    } else if (!hasResults) {
      content = _emptyState(isDark);
    } else {
      content = ListView(
        padding: const EdgeInsets.symmetric(vertical: 6),
        shrinkWrap: true,
        children: [
          if (orderTiles.isNotEmpty) ..._section('Work Orders', orderTiles, isDark),
          if (enquiryTiles.isNotEmpty) ..._section('Enquiries', enquiryTiles, isDark),
        ],
      );
    }

    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border, width: 1),
          boxShadow: AppTheme.cardShadow(isDark),
        ),
        clipBehavior: Clip.antiAlias,
        child: content,
      ),
    );
  }

  Widget _emptyState(bool isDark) {
    final muted = isDark ? AppTheme.darkSubtext : const Color(0xFFA1A1AA);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.search_off_rounded, size: 34, color: muted),
        const SizedBox(height: 8),
        Text('No results for “$_query”',
            style: TextStyle(color: muted, fontSize: 13, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  List<Widget> _section(String title, List<Widget> tiles, bool isDark) {
    final muted = isDark ? AppTheme.darkSubtext : const Color(0xFF71717A);
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
        child: Row(children: [
          Text(title.toUpperCase(),
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: muted, letterSpacing: 1.2)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: muted.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('${tiles.length}',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: muted)),
          ),
        ]),
      ),
      ...tiles,
    ];
  }

  // ── Result tiles ───────────────────────────────────────────────────────────
  Color _statusColor(String name) => switch (name) {
        'completed' => AppTheme.statusCompleted,
        'inProgress' => AppTheme.statusProgress,
        _ => AppTheme.statusPending,
      };

  String _statusLabel(String name) => switch (name) {
        'completed' => 'Completed',
        'inProgress' => 'In-Progress',
        _ => 'Pending',
      };

  Widget _leadingIcon(IconData icon, bool isDark) {
    final accent = AppTheme.primaryAccent(isDark);
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: isDark ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 18, color: accent),
    );
  }

  Widget _workOrderTile(WorkOrder o) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? AppTheme.darkOnSurface : AppTheme.ink900;
    final subColor = isDark ? AppTheme.darkSubtext : const Color(0xFF71717A);
    final statusColor = _statusColor(o.status.name);
    return ListTile(
      onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (_) => TaskDetailScreen(
          taskId: o.id,
          clientName: o.clientName ?? '—',
          clientPhone: o.clientPhoneNumber,
          priority: o.priority.name,
          initialStatus: o.status.name,
        ),
      )),
      leading: _leadingIcon(Icons.assignment_outlined, isDark),
      title: Text(o.clientName ?? '—',
          maxLines: 1, overflow: TextOverflow.ellipsis,
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: titleColor)),
      subtitle: Text(o.serviceType ?? '—',
          maxLines: 1, overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12, color: subColor)),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(_statusLabel(o.status.name),
            style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _enquiryTile(Enquiry e) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? AppTheme.darkOnSurface : AppTheme.ink900;
    final subColor = isDark ? AppTheme.darkSubtext : const Color(0xFF71717A);
    return ListTile(
      onTap: () async {
        await Navigator.pushReplacement(context, MaterialPageRoute(
          builder: (_) => EnquiryDetailScreen(enquiry: e),
        ));
        ref.invalidate(allEnquiriesProvider);
      },
      leading: _leadingIcon(Icons.track_changes_outlined, isDark),
      title: Text(e.clientName ?? '—',
          maxLines: 1, overflow: TextOverflow.ellipsis,
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: titleColor)),
      subtitle: Text('${e.enquiryCode} · ${e.natureOfEnquiry ?? '—'}',
          maxLines: 1, overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12, color: subColor)),
      trailing: e.contactNumber != null
          ? Text(e.contactNumber!, style: TextStyle(fontSize: 11, color: subColor))
          : null,
    );
  }
}
