import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Semantic tone for [WorqlyStatCard] — drives the icon tile color + tint.
enum StatTone { ink, brand, completed, progress, pending, danger }

/// Direction of a KPI delta indicator.
enum DeltaDir { up, down, flat }

// ─── WorqlyStatCard ───────────────────────────────────────────────────────────
/// KPI tile mirroring the Operations Dashboard `StatCard`: tinted icon chip,
/// optional trend delta, large value + uppercase label.
class WorqlyStatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final IconData icon;
  final StatTone tone;
  final String? delta;
  final DeltaDir deltaDir;
  final String? caption;
  final VoidCallback? onTap;

  const WorqlyStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.unit,
    this.tone = StatTone.ink,
    this.delta,
    this.deltaDir = DeltaDir.up,
    this.caption,
    this.onTap,
  });

  ({Color fg, Color tint}) _tone(bool isDark) {
    switch (tone) {
      case StatTone.brand:
        return (fg: isDark ? AppTheme.brand400 : AppTheme.brand700, tint: isDark ? AppTheme.brand500.withValues(alpha: 0.14) : AppTheme.brand50);
      case StatTone.completed:
        return (fg: AppTheme.statusCompleted, tint: AppTheme.statusCompleted.withValues(alpha: isDark ? 0.16 : 0.10));
      case StatTone.progress:
        return (fg: AppTheme.statusProgress, tint: AppTheme.statusProgress.withValues(alpha: isDark ? 0.16 : 0.10));
      case StatTone.pending:
        return (fg: AppTheme.statusPending, tint: AppTheme.statusPending.withValues(alpha: isDark ? 0.16 : 0.10));
      case StatTone.danger:
        return (fg: AppTheme.statusDanger, tint: AppTheme.statusDanger.withValues(alpha: isDark ? 0.16 : 0.10));
      case StatTone.ink:
        return (fg: isDark ? AppTheme.darkOnSurface : AppTheme.ink900, tint: isDark ? AppTheme.darkCardAlt : const Color(0xFFF4F4F5));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = _tone(isDark);
    final cardBg = isDark ? AppTheme.darkCard : Colors.white;
    final cardBorder = isDark ? AppTheme.darkBorder : const Color(0xFFE4E4E7);
    final valueColor = isDark ? AppTheme.darkOnSurface : AppTheme.ink900;
    final mutedColor = isDark ? AppTheme.darkSubtext : const Color(0xFF71717A);

    final deltaColor = deltaDir == DeltaDir.down
        ? AppTheme.statusDanger
        : deltaDir == DeltaDir.flat
            ? mutedColor
            : AppTheme.statusCompleted;
    final deltaIcon = deltaDir == DeltaDir.down
        ? Icons.trending_down_rounded
        : deltaDir == DeltaDir.flat
            ? Icons.trending_flat_rounded
            : Icons.trending_up_rounded;

    final card = Container(
      constraints: const BoxConstraints(minHeight: 130),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder, width: 1),
        boxShadow: AppTheme.cardShadow(isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(color: t.tint, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, size: 20, color: t.fg),
              ),
              if (delta != null)
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(deltaIcon, size: 15, color: deltaColor),
                  const SizedBox(width: 2),
                  Text(delta!, style: TextStyle(color: deltaColor, fontSize: 12, fontWeight: FontWeight.w700)),
                ]),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: valueColor, letterSpacing: -0.5, height: 1)),
              ),
              if (unit != null) ...[
                const SizedBox(width: 4),
                Text(unit!, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: mutedColor)),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(label.toUpperCase(),
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8, color: mutedColor)),
          if (caption != null) ...[
            const SizedBox(height: 2),
            Text(caption!, style: TextStyle(fontSize: 12, color: mutedColor.withValues(alpha: 0.85))),
          ],
        ],
      ),
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: card),
    );
  }
}

// ─── WorqlyWorkOrderCard ──────────────────────────────────────────────────────
/// Live operations-feed item mirroring the Operations Dashboard `WorkOrderCard`:
/// status accent rail, service title + order id, client row, assignment footer.
class WorqlyWorkOrderCard extends StatelessWidget {
  final String serviceType;
  final String? orderId;
  final String? clientName;
  final String? staffName;
  final String? officeName;
  final WorqlyOrderStatus status;
  final bool highPriority;
  final bool contactable;
  final VoidCallback? onTap;
  final Widget? actionButton;

  const WorqlyWorkOrderCard({
    super.key,
    required this.serviceType,
    this.orderId,
    this.clientName,
    this.staffName,
    this.officeName,
    this.status = WorqlyOrderStatus.pending,
    this.highPriority = false,
    this.contactable = false,
    this.onTap,
    this.actionButton,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppTheme.darkCard : Colors.white;
    final cardBorder = isDark ? AppTheme.darkBorder : const Color(0xFFE4E4E7);
    final strong = isDark ? AppTheme.darkOnSurface : AppTheme.ink900;
    final body = isDark ? const Color(0xFFD4D4D8) : const Color(0xFF3F3F46);
    final muted = isDark ? AppTheme.darkSubtext : const Color(0xFF71717A);
    final faint = isDark ? const Color(0xFF52525B) : const Color(0xFFA1A1AA);

    final st = _statusMeta(status);
    final showAlert = highPriority && status != WorqlyOrderStatus.completed;
    final accent = showAlert ? AppTheme.statusDanger : st.color;
    final assignment = staffName != null && staffName!.isNotEmpty
        ? (officeName != null && officeName!.isNotEmpty ? '$staffName · $officeName' : staffName!)
        : (officeName != null && officeName!.isNotEmpty ? 'Office: $officeName' : 'Unassigned');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorder, width: 1),
            boxShadow: AppTheme.cardShadow(isDark),
          ),
          clipBehavior: Clip.antiAlias,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 3, color: accent),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Flexible(
                                      child: Text(serviceType,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: strong, letterSpacing: -0.2)),
                                    ),
                                    if (showAlert) ...[
                                      const SizedBox(width: 6),
                                      const Icon(Icons.bolt_rounded, size: 16, color: AppTheme.statusDanger),
                                    ],
                                  ]),
                                  if (orderId != null && orderId!.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(orderId!, style: TextStyle(fontSize: 12, color: faint, fontFeatures: const [], letterSpacing: 0.2)),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            if (actionButton != null) ...[
                              actionButton!,
                              const SizedBox(width: 8),
                            ],
                            WorklyStatusBadge(label: st.label, color: st.color),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(children: [
                          Icon(Icons.person_outline_rounded, size: 16, color: faint),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(clientName ?? 'N/A',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 13, color: body, fontWeight: FontWeight.w500)),
                          ),
                          if (contactable) ...[
                            Icon(Icons.call_rounded, size: 18, color: strong),
                            const SizedBox(width: 10),
                            const Icon(Icons.chat_bubble_outline_rounded, size: 17, color: AppTheme.statusCompleted),
                          ],
                        ]),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Divider(height: 1, thickness: 1, color: cardBorder),
                        ),
                        Row(children: [
                          Icon(staffName != null && staffName!.isNotEmpty ? Icons.account_circle_rounded : Icons.assignment_ind_outlined,
                              size: 16, color: faint),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(assignment,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 12, color: muted)),
                          ),
                        ]),
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

  ({Color color, String label}) _statusMeta(WorqlyOrderStatus s) {
    switch (s) {
      case WorqlyOrderStatus.progress:
        return (color: AppTheme.statusProgress, label: 'In-Progress');
      case WorqlyOrderStatus.completed:
        return (color: AppTheme.statusCompleted, label: 'Completed');
      case WorqlyOrderStatus.pending:
        return (color: AppTheme.statusPending, label: 'Pending');
    }
  }
}

/// Work-order status used by [WorqlyWorkOrderCard].
enum WorqlyOrderStatus { pending, progress, completed }

// ─── WorklyStatusBadge ────────────────────────────────────────────────────────
/// Semi-transparent pill badge for status labels (In Progress, Excellent, etc.).
///
/// Use [dotIndicator] = true for a leading status dot instead of an icon.
class WorklyStatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final bool dotIndicator;

  const WorklyStatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.dotIndicator = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withValues(alpha: 0.22), width: 1),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
        ] else if (dotIndicator) ...[
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
        ],
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ]),
    );
  }
}

// ─── WorklyFilterChip ─────────────────────────────────────────────────────────
/// Elegant pill-shaped filter chip for horizontal-scroll filter rows.
///
/// Active state: Electric Blue tint + blue text.
/// Inactive state: subtle border, muted text.
class WorklyFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  const WorklyFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = AppTheme.primaryAccent(isDark);
    final inactiveText  = isDark ? AppTheme.darkSubtext : const Color(0xFF64748B);
    final inactiveBg    = isDark ? AppTheme.darkCard     : Colors.white;
    final inactiveBorder = isDark ? AppTheme.darkBorder  : const Color(0xFFE2E8F0);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? activeColor.withValues(alpha: isDark ? 0.18 : 0.08)
              : inactiveBg,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: selected
                ? activeColor.withValues(alpha: 0.45)
                : inactiveBorder,
            width: 1,
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 13,
              color: selected ? activeColor : inactiveText,
            ),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              color: selected ? activeColor : inactiveText,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 12,
              letterSpacing: 0.1,
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── WorklyMetricCard ─────────────────────────────────────────────────────────
/// Clean KPI / metric display card — no heavy shadows, crisp border.
///
/// Adapts to light and dark mode automatically.
class WorklyMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final VoidCallback? onTap;

  const WorklyMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppTheme.darkCard : Colors.white;
    final cardBorder = isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0);
    final titleColor = isDark ? AppTheme.darkOnSurface : AppTheme.darkBlue;
    final metaColor = isDark ? AppTheme.darkSubtext : const Color(0xFF64748B);

    Widget card = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder, width: 1),
        boxShadow: AppTheme.cardShadow(isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              if (onTap != null)
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: cardBorder,
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: titleColor,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: metaColor,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ],
        ],
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: card,
        ),
      );
    }
    return card;
  }
}

// ─── WorklyInfoChip ───────────────────────────────────────────────────────────
/// Compact icon + label chip for metadata rows (date, duration, nationality).
class WorklyInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const WorklyInfoChip({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.darkCardAlt : const Color(0xFFF1F5F9);
    final textColor = isDark ? AppTheme.darkOnSurface : AppTheme.darkBlue;
    final iconColor = isDark ? AppTheme.darkSubtext : const Color(0xFF94A3B8);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: iconColor),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: textColor, fontWeight: FontWeight.w500),
        ),
      ]),
    );
  }
}

// ─── WorklySearchBar ─────────────────────────────────────────────────────────
/// Unified search input that adapts to light / dark themes.
class WorklySearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;

  const WorklySearchBar({
    super.key,
    required this.controller,
    required this.hint,
    required this.onChanged,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isDark ? AppTheme.darkCard : Colors.white;
    final borderColor = isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0);
    final hintColor = isDark ? AppTheme.darkSubtext : const Color(0xFFCBD5E1);
    final iconColor = isDark ? AppTheme.darkSubtext : const Color(0xFF94A3B8);
    final activeColor = AppTheme.primaryAccent(isDark);

    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: TextStyle(
        color: isDark ? AppTheme.darkOnSurface : AppTheme.darkBlue,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: hintColor, fontSize: 14),
        prefixIcon: Icon(Icons.search_rounded, color: iconColor, size: 18),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.close_rounded, color: iconColor, size: 16),
                onPressed: onClear,
              )
            : null,
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: activeColor, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        isDense: true,
      ),
    );
  }
}
