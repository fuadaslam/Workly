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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sidebarBgColor = isDark ? AppTheme.darkSurface : AppTheme.emeraldGreen;
    final activeColor = isDark ? AppTheme.accentGold : AppTheme.accentGold;
    final inactiveColor = Colors.white.withValues(alpha: 0.6);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOutCubic,
      width: _isExpanded ? 240 : 80,
      height: double.infinity,
      decoration: BoxDecoration(
        color: sidebarBgColor,
        border: Border(
          right: BorderSide(
            color: isDark ? AppTheme.darkBorder : Colors.transparent,
            width: 1,
          ),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 15,
            offset: Offset(4, 0),
          )
        ],
      ),
      child: Column(
        children: [
          // 1. Header (Logo & Collapse toggle)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Row(
              mainAxisAlignment:
                  _isExpanded ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center,
              children: [
                if (_isExpanded)
                  const Row(
                    children: [
                      Icon(Icons.auto_graph_rounded, color: AppTheme.accentGold, size: 24),
                      SizedBox(width: 10),
                      Text(
                        'Workly',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                IconButton(
                  onPressed: () => setState(() => _isExpanded = !_isExpanded),
                  icon: Icon(
                    _isExpanded ? Icons.menu_open_rounded : Icons.menu_rounded,
                    color: Colors.white,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 16),

          // 2. Navigation Items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: widget.items.length,
              itemBuilder: (context, index) {
                final item = widget.items[index];
                final isSelected = widget.selectedIndex == index;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => widget.onDestinationSelected(index),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: _isExpanded
                              ? MainAxisAlignment.start
                              : MainAxisAlignment.center,
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Icon(
                                  item.icon,
                                  color: isSelected ? activeColor : inactiveColor,
                                  size: 22,
                                ),
                                if (item.badgeCount != null && item.badgeCount! > 0)
                                  Positioned(
                                    right: -6,
                                    top: -6,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: AppTheme.errorRed,
                                        shape: BoxShape.circle,
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 14,
                                        minHeight: 14,
                                      ),
                                      child: Text(
                                        '${item.badgeCount}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            if (_isExpanded) ...[
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  item.label,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : inactiveColor,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 13,
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
            ),
          ),

          // 3. Footer (Theme Toggle & Profile)
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 12),
          if (widget.themeToggle != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment:
                    _isExpanded ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center,
                children: [
                  if (_isExpanded)
                    Text(
                      isDark ? 'Dark Mode' : 'Light Mode',
                      style: TextStyle(color: inactiveColor, fontSize: 12),
                    ),
                  widget.themeToggle!,
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // User Profile view
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            color: Colors.black.withValues(alpha: 0.12),
            child: Row(
              mainAxisAlignment:
                  _isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.accentGold.withValues(alpha: 0.25),
                  child: const Icon(Icons.person, color: AppTheme.accentGold, size: 20),
                ),
                if (_isExpanded) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          widget.userRole,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 10,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: widget.onSignOut,
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(Icons.logout_rounded, color: Colors.white70, size: 18),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
