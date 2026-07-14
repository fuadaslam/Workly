import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SidebarItem {
  final IconData icon;
  final String label;
  final int? badgeCount;

  const SidebarItem({
    required this.icon,
    required this.label,
    this.badgeCount,
  });
}

class CollapsibleSidebar extends StatefulWidget {
  final int selectedIndex;
  final List<SidebarItem> items;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback onSignOut;
  final String userName;
  final String userRole;
  final String userAvatarUrl;
  final Widget? themeToggle;

  const CollapsibleSidebar({
    super.key,
    required this.selectedIndex,
    required this.items,
    required this.onDestinationSelected,
    required this.onSignOut,
    required this.userName,
    required this.userRole,
    this.userAvatarUrl = '',
    this.themeToggle,
  });

  @override
  State<CollapsibleSidebar> createState() => _CollapsibleSidebarState();
}

class _CollapsibleSidebarState extends State<CollapsibleSidebar> {
  bool _isExpanded = true;
  int? _hoveredIndex;

  // Dynamic colors — updated every build() based on brightness
  late Color _bg;
  late Color _border;
  late Color _divider;
  late Color _footerBg;
  late Color _activeText;
  late Color _mutedIcon;
  late Color _mutedText;
  late Color _hoverBg;
  late Color _activeBg;
  late Color _logoText;
  late Color _chevronBg;
  late Color _chevronBorder;

  static const Color _activeBlue = AppTheme.brand500;

  void _updatePalette(bool isDark) {
    if (isDark) {
      _bg           = AppTheme.ink900;
      _border       = const Color(0xFF1F1F23);
      _divider      = const Color(0xFF1F1F23);
      _footerBg     = const Color(0xFF060607);
      _activeText   = const Color(0xFFFAFAFA);
      _mutedIcon    = const Color(0xFF6B7280);
      _mutedText    = const Color(0xFF8A8A93);
      _hoverBg      = const Color(0x0AFFFFFF);
      _activeBg     = const Color(0x14FFFFFF);
      _logoText     = Colors.white;
      _chevronBg    = const Color(0x0AFFFFFF);
      _chevronBorder= const Color(0xFF1F1F23);
    } else {
      _bg           = Colors.white;
      _border       = const Color(0xFFE5E7EB);
      _divider      = const Color(0xFFE5E7EB);
      _footerBg     = const Color(0xFFF9FAFB);
      _activeText   = const Color(0xFF111827);
      _mutedIcon    = const Color(0xFF9CA3AF);
      _mutedText    = const Color(0xFF6B7280);
      _hoverBg      = const Color(0x08000000);
      _activeBg     = const Color(0x0D000000);
      _logoText     = const Color(0xFF111827);
      _chevronBg    = const Color(0xFFF3F4F6);
      _chevronBorder= const Color(0xFFE5E7EB);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _updatePalette(isDark);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOutQuart,
      width: _isExpanded ? 248 : 72,
      height: double.infinity,
      decoration: BoxDecoration(
        color: _bg,
        border: Border(right: BorderSide(color: _border, width: 1)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 8),
          Expanded(child: _buildNavItems()),
          const SizedBox(height: 8),
          if (widget.themeToggle != null) _buildThemeRow(),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 62,
      padding: EdgeInsets.symmetric(horizontal: _isExpanded ? 16 : 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: _divider, width: 1)),
      ),
      child: Row(
        mainAxisAlignment:
            _isExpanded ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center,
        children: [
          if (_isExpanded)
            Row(children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppTheme.brand500,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Icon(Icons.bolt_rounded, color: AppTheme.ink900, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'Worqly',
                style: TextStyle(
                  color: _logoText,
                  fontSize: 16.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ]),
          GestureDetector(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: _chevronBg,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _chevronBorder),
              ),
              child: Icon(
                _isExpanded ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                color: _mutedText,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItems() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      itemCount: widget.items.length,
      itemBuilder: (context, index) {
        final item = widget.items[index];
        final isSelected = widget.selectedIndex == index;
        final isHovered = _hoveredIndex == index;

        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: MouseRegion(
            onEnter: (_) => setState(() => _hoveredIndex = index),
            onExit:  (_) => setState(() => _hoveredIndex = null),
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => widget.onDestinationSelected(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                height: 46,
                decoration: BoxDecoration(
                  color: isSelected
                      ? _activeBg
                      : isHovered
                          ? _hoverBg
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    // Left indicator bar
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 3,
                      height: isSelected ? 24 : 0,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: _activeBlue,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Icon with optional badge
                    SizedBox(
                      width: 24,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(
                            item.icon,
                            size: 21,
                            color: isSelected
                                ? _activeBlue
                                : isHovered
                                    ? const Color(0xFF9CA3AF)
                                    : _mutedIcon,
                          ),
                          if (item.badgeCount != null && item.badgeCount! > 0)
                            Positioned(
                              right: -6,
                              top: -5,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  color: AppTheme.errorRed,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                                child: Text(
                                  '${item.badgeCount}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (_isExpanded) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.label,
                          style: TextStyle(
                            color: isSelected
                                ? _activeText
                                : isHovered
                                    ? _mutedIcon
                                    : _mutedText,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            fontSize: 14.5,
                            letterSpacing: -0.1,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemeRow() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _isExpanded ? 16 : 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: _divider, width: 1)),
      ),
      child: Row(
        mainAxisAlignment:
            _isExpanded ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center,
        children: [
          if (_isExpanded)
            Text(
              'APPEARANCE',
              style: TextStyle(
                color: _mutedText,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
          widget.themeToggle!,
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      decoration: BoxDecoration(
        color: _footerBg,
        border: Border(top: BorderSide(color: _divider, width: 1)),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: _isExpanded ? 12 : 8,
        vertical: 12,
      ),
      child: Row(
        mainAxisAlignment:
            _isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppTheme.electricBlue.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.person, color: AppTheme.electricBlue, size: 16),
          ),
          if (_isExpanded) ...[
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.userName,
                    style: TextStyle(
                      color: _activeText,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.1,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.userRole,
                    style: TextStyle(
                      color: _mutedText,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: widget.onSignOut,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.logout_rounded, color: _mutedText, size: 16),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
