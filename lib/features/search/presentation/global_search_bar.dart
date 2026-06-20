import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../features/dashboard/presentation/providers/dashboard_provider.dart';
import '../../../features/enquiries/presentation/providers/enquiry_provider.dart';
import '../../../features/dashboard/domain/models/work_order.dart';
import '../../../features/enquiries/domain/models/enquiry.dart';

/// Inline app-bar search field with a typeahead dropdown anchored beneath it.
/// As the user types (≥2 chars) matching work orders & enquiries appear in a
/// floating dropdown without leaving the current screen.
class GlobalSearchBar extends ConsumerStatefulWidget {
  final double width;
  const GlobalSearchBar({super.key, this.width = 320});

  @override
  ConsumerState<GlobalSearchBar> createState() => _GlobalSearchBarState();
}

class _GlobalSearchBarState extends ConsumerState<GlobalSearchBar> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  final _link = LayerLink();
  final _fieldKey = GlobalKey();
  OverlayEntry? _overlay;
  String _query = '';

  @override
  void dispose() {
    _removeOverlay();
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  bool get _active => _query.length >= 2;

  void _onChanged(String v) {
    setState(() => _query = v.trim().toLowerCase());
    if (_active) {
      _showOverlay();
      _overlay?.markNeedsBuild();
    } else {
      _removeOverlay();
    }
  }

  void _showOverlay() {
    if (_overlay != null) return;
    _overlay = OverlayEntry(builder: _buildOverlay);
    Overlay.of(context).insert(_overlay!);
  }

  void _removeOverlay() {
    _overlay?.remove();
    _overlay = null;
  }

  void _close() {
    _removeOverlay();
    _focus.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Keep providers warm + rebuild overlay when their data lands.
    ref.watch(allWorkOrdersProvider);
    ref.watch(allEnquiriesProvider);
    if (_overlay != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _overlay?.markNeedsBuild());
    }

    final fillColor = isDark ? AppTheme.darkCard : Colors.white;
    final borderColor = isDark ? AppTheme.darkBorder : const Color(0xFFE4E4E7);
    final textColor = isDark ? AppTheme.darkOnSurface : AppTheme.ink900;
    final hintColor = isDark ? AppTheme.darkSubtext : const Color(0xFFA1A1AA);
    final accent = AppTheme.primaryAccent(isDark);

    return CompositedTransformTarget(
      link: _link,
      child: Container(
        key: _fieldKey,
        width: widget.width,
        height: 40,
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _focus.hasFocus ? accent : borderColor, width: _focus.hasFocus ? 1.5 : 1),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            Icon(Icons.search_rounded, size: 18, color: _focus.hasFocus ? accent : hintColor),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _ctrl,
                focusNode: _focus,
                style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w500),
                cursorColor: accent,
                textInputAction: TextInputAction.search,
                onTap: () { if (_active) _showOverlay(); },
                onChanged: _onChanged,
                decoration: InputDecoration(
                  isCollapsed: true,
                  hintText: 'Search clients, services, enquiries…',
                  hintStyle: TextStyle(color: hintColor, fontSize: 14, fontWeight: FontWeight.w400),
                  border: InputBorder.none,
                ),
              ),
            ),
            if (_query.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _ctrl.clear();
                  _onChanged('');
                },
                child: Icon(Icons.close_rounded, size: 16, color: hintColor),
              ),
          ],
        ),
      ),
    );
  }

  // ── Overlay dropdown ───────────────────────────────────────────────────────
  Widget _buildOverlay(BuildContext context) {
    final isDark = Theme.of(this.context).brightness == Brightness.dark;
    final fieldWidth = widget.width;
    const fieldHeight = 40.0;

    return Stack(
      children: [
        // Tap-outside catcher.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _close,
          ),
        ),
        CompositedTransformFollower(
          link: _link,
          showWhenUnlinked: false,
          targetAnchor: Alignment.bottomLeft,
          followerAnchor: Alignment.topLeft,
          offset: const Offset(0, fieldHeight + 6),
          child: SizedBox(
            width: fieldWidth,
            child: _dropdownCard(isDark),
          ),
        ),
      ],
    );
  }

  Widget _dropdownCard(bool isDark) {
    final cardBg = isDark ? AppTheme.darkCard : Colors.white;
    final border = isDark ? AppTheme.darkBorder : const Color(0xFFE4E4E7);

    final orders = ref.read(allWorkOrdersProvider).valueOrNull ?? const [];
    final enquiries = ref.read(allEnquiriesProvider).valueOrNull ?? const [];
    final loading = ref.read(allWorkOrdersProvider).isLoading || ref.read(allEnquiriesProvider).isLoading;

    final orderTiles = orders.where((o) {
      final name = (o.clientName ?? '').toLowerCase();
      final service = (o.serviceType ?? '').toLowerCase();
      final phone = (o.clientPhoneNumber ?? '').toLowerCase();
      return name.contains(_query) || service.contains(_query) || phone.contains(_query);
    }).take(8).map(_workOrderTile).toList();

    final enquiryTiles = enquiries.where((e) {
      final name = (e.clientName ?? '').toLowerCase();
      final code = e.enquiryCode.toLowerCase();
      final service = (e.natureOfEnquiry ?? '').toLowerCase();
      final phone = (e.contactNumber ?? '').toLowerCase();
      return name.contains(_query) || code.contains(_query) ||
          service.contains(_query) || phone.contains(_query);
    }).take(8).map(_enquiryTile).toList();

    final hasResults = orderTiles.isNotEmpty || enquiryTiles.isNotEmpty;

    Widget content;
    if (!hasResults && loading) {
      content = const Padding(
        padding: EdgeInsets.symmetric(vertical: 22),
        child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.2))),
      );
    } else if (!hasResults) {
      final muted = isDark ? AppTheme.darkSubtext : const Color(0xFFA1A1AA);
      content = Padding(
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.search_off_rounded, size: 28, color: muted),
          const SizedBox(height: 6),
          Text('No results for “$_query”', style: TextStyle(color: muted, fontSize: 12.5, fontWeight: FontWeight.w500)),
        ]),
      );
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
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border, width: 1),
          boxShadow: AppTheme.cardShadow(isDark),
        ),
        clipBehavior: Clip.antiAlias,
        child: content,
      ),
    );
  }

  List<Widget> _section(String title, List<Widget> tiles, bool isDark) {
    final muted = isDark ? AppTheme.darkSubtext : const Color(0xFF71717A);
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
        child: Text('${title.toUpperCase()}  ·  ${tiles.length}',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: muted, letterSpacing: 1.1)),
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
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: isDark ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Icon(icon, size: 17, color: accent),
    );
  }

  Widget _workOrderTile(WorkOrder o) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? AppTheme.darkOnSurface : AppTheme.ink900;
    final subColor = isDark ? AppTheme.darkSubtext : const Color(0xFF71717A);
    final statusColor = _statusColor(o.status.name);
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      onTap: () {
        _close();
        context.push(
          '/dashboard/task/${o.id}',
          extra: TaskRouteArgs(
            clientName: o.clientName ?? '—',
            clientPhone: o.clientPhoneNumber,
            priority: o.priority.name,
            initialStatus: o.status.name,
          ),
        );
      },
      leading: _leadingIcon(Icons.assignment_outlined, isDark),
      title: Text(o.clientName ?? '—',
          maxLines: 1, overflow: TextOverflow.ellipsis,
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: titleColor)),
      subtitle: Text(o.serviceType ?? '—',
          maxLines: 1, overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 11.5, color: subColor)),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(_statusLabel(o.status.name),
            style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _enquiryTile(Enquiry e) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? AppTheme.darkOnSurface : AppTheme.ink900;
    final subColor = isDark ? AppTheme.darkSubtext : const Color(0xFF71717A);
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      onTap: () async {
        _close();
        await context.push('/dashboard/enquiries/detail', extra: e);
        ref.invalidate(allEnquiriesProvider);
      },
      leading: _leadingIcon(Icons.track_changes_outlined, isDark),
      title: Text(e.clientName ?? '—',
          maxLines: 1, overflow: TextOverflow.ellipsis,
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: titleColor)),
      subtitle: Text('${e.enquiryCode} · ${e.natureOfEnquiry ?? '—'}',
          maxLines: 1, overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 11.5, color: subColor)),
      trailing: e.contactNumber != null
          ? Text(e.contactNumber!, style: TextStyle(fontSize: 10.5, color: subColor))
          : null,
    );
  }
}
