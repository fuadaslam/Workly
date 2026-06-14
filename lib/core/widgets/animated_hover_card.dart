import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A card widget that lifts up and increases shadow depth when hovered on web/desktop.
/// Provides a highly interactive feel for list items, dashboard grid cells, and buttons.
class AnimatedHoverCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final Border? border;
  final List<BoxShadow>? shadows;
  final double hoverOffset; // How many pixels to lift on hover (default: -4.0)

  const AnimatedHoverCard({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius = 20.0,
    this.padding = const EdgeInsets.all(20.0),
    this.margin,
    this.color,
    this.border,
    this.shadows,
    this.hoverOffset = -5.0,
  });

  @override
  State<AnimatedHoverCard> createState() => _AnimatedHoverCardState();
}

class _AnimatedHoverCardState extends State<AnimatedHoverCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBgColor = isDark ? AppTheme.darkCard : Colors.white;
    final defaultBorder = isDark
        ? Border.all(color: AppTheme.darkBorder, width: 1)
        : Border.all(color: const Color(0x0D000000), width: 1);

    // Active glow shadows on hover
    final defaultShadows = widget.shadows ?? AppTheme.cardShadow(isDark);
    final activeShadows = isDark
        ? [
            BoxShadow(
              color: AppTheme.accentGold.withValues(alpha: 0.15),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
            ...defaultShadows
          ]
        : [
            BoxShadow(
              color: AppTheme.emeraldGreen.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
            ...defaultShadows
          ];

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        margin: widget.margin,
        transform: Matrix4.translationValues(
          0.0,
          _isHovered ? widget.hoverOffset : 0.0,
          0.0,
        ),
        decoration: BoxDecoration(
          color: widget.color ?? defaultBgColor,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: widget.border ?? defaultBorder,
          boxShadow: _isHovered ? activeShadows : defaultShadows,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            hoverColor: Colors.transparent,
            splashColor: isDark
                ? AppTheme.accentGold.withValues(alpha: 0.08)
                : AppTheme.emeraldGreen.withValues(alpha: 0.04),
            highlightColor: Colors.transparent,
            child: Padding(
              padding: widget.padding ?? EdgeInsets.zero,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
